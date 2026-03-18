import AVFoundation
import CoreGraphics

protocol PermissionManaging {
    func status(for permission: PermissionType) -> PermissionStatus
    func request(_ permission: PermissionType) async -> PermissionStatus
}

struct PermissionManager: PermissionManaging {
    typealias StatusProvider = (PermissionType) -> PermissionStatus
    typealias RequestProvider = (PermissionType) async -> PermissionStatus

    private let statusProvider: StatusProvider
    private let requestProvider: RequestProvider

    init(
        statusProvider: @escaping StatusProvider = PermissionManager.liveStatus(for:),
        requestProvider: @escaping RequestProvider = PermissionManager.liveRequest(for:)
    ) {
        self.statusProvider = statusProvider
        self.requestProvider = requestProvider
    }

    func status(for permission: PermissionType) -> PermissionStatus {
        statusProvider(permission)
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        await requestProvider(permission)
    }

    private static func liveStatus(for permission: PermissionType) -> PermissionStatus {
        switch permission {
        case .microphone:
            return map(AVCaptureDevice.authorizationStatus(for: .audio))
        case .screenRecording:
            return CGPreflightScreenCaptureAccess() ? .authorized : .notDetermined
        case .accessibility:
            return .notDetermined
        }
    }

    private static func liveRequest(for permission: PermissionType) async -> PermissionStatus {
        switch permission {
        case .microphone:
            let granted = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
            return granted ? .authorized : .denied
        case .screenRecording:
            return CGRequestScreenCaptureAccess() ? .authorized : .denied
        case .accessibility:
            return liveStatus(for: permission)
        }
    }

    private static func map(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .notDetermined:
            return .notDetermined
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }
}
