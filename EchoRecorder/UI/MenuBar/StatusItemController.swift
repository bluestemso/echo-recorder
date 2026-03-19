import AppKit
import Combine
import QuartzCore
import SwiftUI

protocol StatusItemControlling: AnyObject {
    var configuredTitle: String { get }
}

enum StatusItemAnimationMode: Equatable {
    case none
    case finite
    case continuous
}

struct StatusItemRenderEvent: Equatable {
    let state: RecorderState
    let timestamp: TimeInterval
    let animationMode: StatusItemAnimationMode
    let isRecordingPillVisible: Bool
    let accessibilityLabel: String
}

@MainActor
final class StatusItemController: NSObject, StatusItemControlling {
    let configuredTitle: String
    private(set) var statusItem: NSStatusItem
    private(set) var latestRenderEvent: StatusItemRenderEvent?

    private let popover: NSPopover
    private let recorderCoordinator: RecorderCoordinator
    private let viewModel: RecordingViewModel
    private let nowProvider: () -> TimeInterval
    private let renderEventHandler: ((StatusItemRenderEvent) -> Void)?
    private var cancellables: Set<AnyCancellable> = []
    private var iconAnimationTimer: Timer?
    private weak var animatedButton: NSStatusBarButton?
    private var activeAnimationMode: StatusItemAnimationMode = .none
    private var remainingFiniteAnimationTicks = 0
    private var nextAnimationPulseOpacity: CGFloat = 0.62
    private let recordingPillLayer = CAShapeLayer()

    private let symbolPointSize: CGFloat = 14
    private let recordingPillFadeDuration: CFTimeInterval = 0.12
    private let iconPulseInterval: TimeInterval = 0.18

    init(
        title: String = "Echo",
        recorderCoordinator: RecorderCoordinator,
        viewModel: RecordingViewModel? = nil,
        nowProvider: @escaping () -> TimeInterval = { CACurrentMediaTime() },
        renderEventHandler: ((StatusItemRenderEvent) -> Void)? = nil,
        statusItemFactory: () -> NSStatusItem = {
            NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        }
    ) {
        configuredTitle = title
        self.recorderCoordinator = recorderCoordinator
        self.viewModel = viewModel ?? RecordingViewModel(recorderCoordinator: recorderCoordinator)
        statusItem = statusItemFactory()
        popover = NSPopover()
        self.nowProvider = nowProvider
        self.renderEventHandler = renderEventHandler

        super.init()

        configureStatusButton()

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: RecordingPopoverView(viewModel: self.viewModel))

        recorderCoordinator.$state
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else {
                    return
                }

                render(status: state)
            }
            .store(in: &cancellables)
    }

    deinit {
        iconAnimationTimer?.invalidate()
    }

    convenience init(
        title: String = "Echo",
        viewModel: RecordingViewModel? = nil,
        nowProvider: @escaping () -> TimeInterval = { CACurrentMediaTime() },
        renderEventHandler: ((StatusItemRenderEvent) -> Void)? = nil
    ) {
        self.init(
            title: title,
            recorderCoordinator: RecorderCoordinator(),
            viewModel: viewModel,
            nowProvider: nowProvider,
            renderEventHandler: renderEventHandler
        )
    }

    @objc
    private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            return
        }

        button.title = ""
        button.imagePosition = .imageOnly
        button.target = self
        button.action = #selector(togglePopover(_:))
        button.wantsLayer = true
        configureRecordingPillLayerIfNeeded(for: button)
    }

    private func render(status state: RecorderState) {
        guard let button = statusItem.button else {
            return
        }

        let visualState = statusItemVisualState(for: state, appName: configuredTitle)
        let shouldShowRecordingPill = (state == .recording) && visualState.showRecordingPill

        applySymbol(for: visualState, on: button)
        button.setAccessibilityLabel(visualState.accessibilityLabel)
        setRecordingPillVisible(shouldShowRecordingPill, on: button)
        applyAnimation(for: state, visualState: visualState, button: button)

        let renderEvent = StatusItemRenderEvent(
            state: state,
            timestamp: nowProvider(),
            animationMode: animationMode(for: state, visualState: visualState),
            isRecordingPillVisible: shouldShowRecordingPill,
            accessibilityLabel: visualState.accessibilityLabel
        )
        latestRenderEvent = renderEvent
        renderEventHandler?(renderEvent)
    }

    private func applySymbol(for visualState: StatusItemVisualState, on button: NSStatusBarButton) {
        guard let symbol = NSImage(
            systemSymbolName: visualState.symbolName,
            accessibilityDescription: visualState.accessibilityLabel
        ) else {
            return
        }

        let baseConfiguration = NSImage.SymbolConfiguration(
            pointSize: symbolPointSize,
            weight: visualState.symbolWeight
        )

        var image = symbol.withSymbolConfiguration(baseConfiguration)

        if visualState.usesPaletteColor {
            let paletteConfiguration = NSImage.SymbolConfiguration(
                paletteColors: [Self.recordingSymbolColor(for: button.effectiveAppearance)]
            )
            image = image?.withSymbolConfiguration(paletteConfiguration)
            image?.isTemplate = false
            button.contentTintColor = nil
        } else {
            image?.isTemplate = true
        }

        button.title = ""
        button.image = image
    }

    private func applyAnimation(
        for state: RecorderState,
        visualState: StatusItemVisualState,
        button: NSStatusBarButton
    ) {
        if visualState.isAnimated {
            if state == .recording {
                startContinuousAnimation(on: button)
            } else {
                startFiniteAnimation(on: button)
            }
            return
        }

        stopAnimation(on: button)
    }

    private func startContinuousAnimation(on button: NSStatusBarButton) {
        if latestRenderEvent?.animationMode != .continuous {
            stopAnimation(on: button)
        }

        configureAnimationTimer(on: button, mode: .continuous, finiteTickCount: nil)
    }

    private func startFiniteAnimation(on button: NSStatusBarButton) {
        configureAnimationTimer(on: button, mode: .finite, finiteTickCount: 4)
    }

    private func stopAnimation(on button: NSStatusBarButton) {
        iconAnimationTimer?.invalidate()
        iconAnimationTimer = nil
        animatedButton = nil
        activeAnimationMode = .none
        remainingFiniteAnimationTicks = 0
        nextAnimationPulseOpacity = 0.62
        button.alphaValue = 1
    }

    private func configureAnimationTimer(
        on button: NSStatusBarButton,
        mode: StatusItemAnimationMode,
        finiteTickCount: Int?
    ) {
        iconAnimationTimer?.invalidate()
        iconAnimationTimer = nil

        if mode == .finite {
            remainingFiniteAnimationTicks = finiteTickCount ?? 0
        } else {
            remainingFiniteAnimationTicks = 0
        }

        animatedButton = button
        activeAnimationMode = mode
        nextAnimationPulseOpacity = 0.62
        button.alphaValue = 1

        let timer = Timer(
            timeInterval: iconPulseInterval,
            target: self,
            selector: #selector(handleIconAnimationTick(_:)),
            userInfo: nil,
            repeats: true
        )
        iconAnimationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    @objc
    private func handleIconAnimationTick(_ timer: Timer) {
        guard let button = animatedButton else {
            timer.invalidate()
            iconAnimationTimer = nil
            return
        }

        button.alphaValue = nextAnimationPulseOpacity
        nextAnimationPulseOpacity = nextAnimationPulseOpacity < 0.8 ? 1 : 0.62

        guard activeAnimationMode == .finite else {
            return
        }

        remainingFiniteAnimationTicks -= 1
        if remainingFiniteAnimationTicks > 0 {
            return
        }

        timer.invalidate()
        iconAnimationTimer = nil
        activeAnimationMode = .none
        button.alphaValue = 1
    }

    private func animationMode(
        for state: RecorderState,
        visualState: StatusItemVisualState
    ) -> StatusItemAnimationMode {
        guard visualState.isAnimated else {
            return .none
        }

        return state == .recording ? .continuous : .finite
    }

    private func configureRecordingPillLayerIfNeeded(for button: NSStatusBarButton) {
        guard let hostLayer = button.layer else {
            return
        }

        guard recordingPillLayer.superlayer == nil else {
            updateRecordingPillPath(for: button)
            return
        }

        recordingPillLayer.opacity = 0
        recordingPillLayer.strokeColor = nil
        recordingPillLayer.backgroundColor = Self.recordingIndicatorColor(for: button.effectiveAppearance).cgColor
        hostLayer.insertSublayer(recordingPillLayer, at: 0)
        updateRecordingPillPath(for: button)
    }

    private func updateRecordingPillPath(for button: NSStatusBarButton) {
        let insetBounds = button.bounds.insetBy(dx: 2, dy: 2)
        let radius = insetBounds.height * 0.5

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        recordingPillLayer.frame = button.bounds
        recordingPillLayer.path = CGPath(
            roundedRect: insetBounds,
            cornerWidth: radius,
            cornerHeight: radius,
            transform: nil
        )
        CATransaction.commit()
    }

    private func setRecordingPillVisible(_ isVisible: Bool, on button: NSStatusBarButton) {
        configureRecordingPillLayerIfNeeded(for: button)
        updateRecordingPillPath(for: button)
        recordingPillLayer.backgroundColor = Self.recordingIndicatorColor(for: button.effectiveAppearance).cgColor

        let targetOpacity: Float = isVisible ? 1 : 0
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = recordingPillFadeDuration
        opacityAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        opacityAnimation.fromValue = recordingPillLayer.presentation()?.opacity ?? recordingPillLayer.opacity
        opacityAnimation.toValue = targetOpacity

        recordingPillLayer.opacity = targetOpacity
        recordingPillLayer.add(opacityAnimation, forKey: "recording-pill-opacity")
    }

    static func recordingIndicatorColor(for appearance: NSAppearance?) -> NSColor {
        let match = appearance?.bestMatch(from: [.darkAqua, .vibrantDark, .aqua, .vibrantLight])
        switch match {
        case .darkAqua, .vibrantDark:
            return NSColor(srgbRed: 1.0, green: 0.34, blue: 0.33, alpha: 0.86)
        default:
            return NSColor(srgbRed: 0.82, green: 0.14, blue: 0.16, alpha: 0.74)
        }
    }

    private static func recordingSymbolColor(for appearance: NSAppearance?) -> NSColor {
        let indicator = recordingIndicatorColor(for: appearance)
        return NSColor(
            calibratedRed: indicator.redComponent,
            green: indicator.greenComponent,
            blue: indicator.blueComponent,
            alpha: 1
        )
    }
}
