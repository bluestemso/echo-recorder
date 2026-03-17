final class PermissionWizardViewModel {
    private let permissionManager: any PermissionManaging
    private let permissionsInOrder: [PermissionType]

    init(
        permissionManager: any PermissionManaging,
        permissionsInOrder: [PermissionType] = PermissionType.wizardOrder
    ) {
        self.permissionManager = permissionManager
        self.permissionsInOrder = permissionsInOrder
    }

    var blockingPermission: PermissionType? {
        permissionsInOrder.first { permission in
            permissionManager.status(for: permission) != .authorized
        }
    }

    var canContinue: Bool {
        blockingPermission == nil
    }
}
