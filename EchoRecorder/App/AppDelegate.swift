import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let makeStatusItemController: () -> StatusItemControlling
    private let runLaunchRecoveryCheck: () -> Void
    private(set) var statusItemController: StatusItemControlling?

    override init() {
        makeStatusItemController = { StatusItemController() }
        runLaunchRecoveryCheck = {}
        super.init()
    }

    init(
        makeStatusItemController: @escaping () -> StatusItemControlling,
        runLaunchRecoveryCheck: @escaping () -> Void = {}
    ) {
        self.makeStatusItemController = makeStatusItemController
        self.runLaunchRecoveryCheck = runLaunchRecoveryCheck
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        runLaunchRecoveryCheck()
        statusItemController = makeStatusItemController()
    }
}
