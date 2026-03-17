import AppKit
import Combine
import SwiftUI

protocol StatusItemControlling: AnyObject {
    var configuredTitle: String { get }
}

@MainActor
final class StatusItemController: NSObject, StatusItemControlling {
    let configuredTitle: String
    private(set) var statusItem: NSStatusItem

    private let popover: NSPopover
    private let recorderCoordinator: RecorderCoordinator
    private let viewModel: RecordingViewModel
    private var cancellables: Set<AnyCancellable> = []

    init(
        title: String = "Echo",
        recorderCoordinator: RecorderCoordinator,
        viewModel: RecordingViewModel? = nil
    ) {
        configuredTitle = title
        self.recorderCoordinator = recorderCoordinator
        self.viewModel = viewModel ?? RecordingViewModel(recorderCoordinator: recorderCoordinator)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()

        super.init()

        statusItem.button?.title = title
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: RecordingPopoverView(viewModel: self.viewModel))

        self.viewModel.$isRecording
            .receive(on: RunLoop.main)
            .sink { [weak self] isRecording in
                guard let self else {
                    return
                }

                statusItem.button?.title = isRecording ? "\(configuredTitle) *" : configuredTitle
            }
            .store(in: &cancellables)
    }

    convenience init(title: String = "Echo", viewModel: RecordingViewModel? = nil) {
        self.init(
            title: title,
            recorderCoordinator: RecorderCoordinator(),
            viewModel: viewModel
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
}
