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
    private let recordingPillLayer = CAShapeLayer()
    private var lastRenderedState: RecorderState?
    private var finalizingRenderedAt: TimeInterval?
    private var deferredIdleWorkItem: DispatchWorkItem?

    private let symbolPointSize: CGFloat = 14
    private let recordingPillFadeDuration: CFTimeInterval = 0.12
    private let recordingAnimationDuration: CFTimeInterval = 1.0
    private let transitionAnimationDuration: CFTimeInterval = 0.28
    private let transitionAnimationRepeatCount: Float = 2
    private let minimumFinalizingDisplayDuration: TimeInterval = 0.35
    private let iconAnimationKey = "status-item-icon-opacity"

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

                renderStateChange(state)
            }
            .store(in: &cancellables)
    }

    deinit {
        deferredIdleWorkItem?.cancel()
    }

    private func renderStateChange(_ state: RecorderState) {
        deferredIdleWorkItem?.cancel()
        deferredIdleWorkItem = nil

        let now = nowProvider()
        if state == .idle,
           lastRenderedState == .finalizing,
           let finalizingRenderedAt,
           now - finalizingRenderedAt < minimumFinalizingDisplayDuration {
            let remainingDelay = minimumFinalizingDisplayDuration - (now - finalizingRenderedAt)
            let workItem = DispatchWorkItem { [weak self] in
                self?.render(status: .idle)
            }
            deferredIdleWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + remainingDelay, execute: workItem)
            return
        }

        render(status: state)
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
        lastRenderedState = state
        if state == .finalizing {
            finalizingRenderedAt = renderEvent.timestamp
        } else if state == .idle || state == .preparing || state == .recording || state == .pendingFinalize {
            finalizingRenderedAt = nil
        }
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
            button.contentTintColor = nil
        }

        button.title = ""
        button.image = image
    }

    private func applyAnimation(
        for state: RecorderState,
        visualState: StatusItemVisualState,
        button: NSStatusBarButton
    ) {
        guard let layer = button.layer else {
            return
        }

        layer.removeAnimation(forKey: iconAnimationKey)

        guard visualState.isAnimated else {
            button.alphaValue = 1
            return
        }

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.72
        animation.autoreverses = true
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.isRemovedOnCompletion = true

        if state == .recording {
            animation.duration = recordingAnimationDuration
            animation.repeatCount = .greatestFiniteMagnitude
        } else {
            animation.duration = transitionAnimationDuration
            animation.repeatCount = transitionAnimationRepeatCount
        }

        layer.add(animation, forKey: iconAnimationKey)
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
        recordingPillLayer.backgroundColor = nil
        recordingPillLayer.fillColor = Self.recordingIndicatorColor(for: button.effectiveAppearance).cgColor
        hostLayer.insertSublayer(recordingPillLayer, at: 0)
        updateRecordingPillPath(for: button)
    }

    private func updateRecordingPillPath(for button: NSStatusBarButton) {
        let insetBounds = CGRect(origin: .zero, size: button.bounds.size).insetBy(dx: 2, dy: 2)
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
        recordingPillLayer.fillColor = Self.recordingIndicatorColor(for: button.effectiveAppearance).cgColor

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
