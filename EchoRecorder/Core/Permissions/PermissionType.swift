enum PermissionType: CaseIterable, Hashable {
    case microphone
    case screenRecording
    case accessibility

    static let wizardOrder: [PermissionType] = [
        .microphone,
        .screenRecording,
        .accessibility
    ]
}

enum PermissionStatus: Equatable {
    case notDetermined
    case denied
    case authorized
}
