import XCTest
@testable import EchoRecorder

@MainActor
final class AudioGainPipelineTests: XCTestCase {
    func testApplyGainChangesMeteredPeakForMicSource() {
        let vm = RecordingViewModel()

        vm.setGain(0.5, for: .microphone)
        vm.applyMeterSnapshot(
            system: .init(peak: 1.0, rms: 0.5),
            mic: .init(peak: 0.8, rms: 0.4)
        )

        XCTAssertEqual(vm.levelRows.last?.level.peak ?? 0, 0.4, accuracy: 0.001)
    }
}
