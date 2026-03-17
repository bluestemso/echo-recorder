protocol PermissionManaging {
    func status(for permission: PermissionType) -> PermissionStatus
}

struct PermissionManager: PermissionManaging {
    typealias StatusProvider = (PermissionType) -> PermissionStatus

    private let statusProvider: StatusProvider

    init(statusProvider: @escaping StatusProvider = { _ in .notDetermined }) {
        self.statusProvider = statusProvider
    }

    func status(for permission: PermissionType) -> PermissionStatus {
        statusProvider(permission)
    }
}
