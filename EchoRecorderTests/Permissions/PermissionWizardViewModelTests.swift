import XCTest
@testable import EchoRecorder

final class PermissionWizardViewModelTests: XCTestCase {
    func testCanContinueIsFalseWhenScreenRecordingPermissionIsDenied() {
        let manager = StubPermissionManager(statuses: [
            .microphone: .authorized,
            .screenRecording: .denied,
            .accessibility: .authorized
        ])
        let viewModel = PermissionWizardViewModel(permissionManager: manager)

        XCTAssertFalse(viewModel.canContinue)
        XCTAssertEqual(viewModel.blockingPermission, .screenRecording)
    }

    func testCanContinueIsTrueWhenAllPermissionsAreAuthorized() {
        let manager = StubPermissionManager(statuses: [
            .microphone: .authorized,
            .screenRecording: .authorized,
            .accessibility: .authorized
        ])
        let viewModel = PermissionWizardViewModel(permissionManager: manager)

        XCTAssertTrue(viewModel.canContinue)
        XCTAssertNil(viewModel.blockingPermission)
    }

    func testFirstPermissionInOrderBlocksWhenDenied() {
        let manager = StubPermissionManager(statuses: [
            .microphone: .denied,
            .screenRecording: .authorized,
            .accessibility: .authorized
        ])
        let viewModel = PermissionWizardViewModel(permissionManager: manager)

        XCTAssertFalse(viewModel.canContinue)
        XCTAssertEqual(viewModel.blockingPermission, .microphone)
    }

    func testMultipleBlockedPermissionsReturnsFirstInOrder() {
        let manager = StubPermissionManager(statuses: [
            .microphone: .authorized,
            .screenRecording: .denied,
            .accessibility: .denied
        ])
        let viewModel = PermissionWizardViewModel(permissionManager: manager)

        XCTAssertEqual(viewModel.blockingPermission, .screenRecording)
    }

    func testNotDeterminedIsBlocking() {
        let manager = StubPermissionManager(statuses: [
            .microphone: .notDetermined,
            .screenRecording: .authorized,
            .accessibility: .authorized
        ])
        let viewModel = PermissionWizardViewModel(permissionManager: manager)

        XCTAssertFalse(viewModel.canContinue)
        XCTAssertEqual(viewModel.blockingPermission, .microphone)
    }

    func testCustomPermissionsOrderIsRespected() {
        let manager = StubPermissionManager(statuses: [
            .microphone: .authorized,
            .screenRecording: .denied,
            .accessibility: .denied
        ])
        let customOrder: [PermissionType] = [.accessibility, .screenRecording, .microphone]
        let viewModel = PermissionWizardViewModel(permissionManager: manager, permissionsInOrder: customOrder)

        XCTAssertEqual(viewModel.blockingPermission, .accessibility)
    }

    func testWizardOrderContainsEveryPermissionExactlyOnce() {
        XCTAssertEqual(Set(PermissionType.wizardOrder), Set(PermissionType.allCases))
        XCTAssertEqual(PermissionType.wizardOrder.count, PermissionType.allCases.count)
    }

    func testRequestBlockingPermissionUsesPermissionManagerRequest() async {
        let manager = StubPermissionManager(
            statuses: [.microphone: .notDetermined],
            requestStatuses: [.microphone: .authorized]
        )
        let viewModel = PermissionWizardViewModel(permissionManager: manager)

        let status = await viewModel.requestBlockingPermission()

        XCTAssertEqual(status, .authorized)
    }
}

private struct StubPermissionManager: PermissionManaging {
    let statuses: [PermissionType: PermissionStatus]
    let requestStatuses: [PermissionType: PermissionStatus]

    init(
        statuses: [PermissionType: PermissionStatus],
        requestStatuses: [PermissionType: PermissionStatus] = [:]
    ) {
        self.statuses = statuses
        self.requestStatuses = requestStatuses
    }

    func status(for permission: PermissionType) -> PermissionStatus {
        statuses[permission] ?? .notDetermined
    }

    func request(_ permission: PermissionType) async -> PermissionStatus {
        requestStatuses[permission] ?? status(for: permission)
    }
}
