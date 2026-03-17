import XCTest
@testable import EchoRecorder

final class MeteringServiceTests: XCTestCase {
    func testComputeLevelReturnsExpectedPeakAndNonZeroRMS() {
        let service = MeteringService()
        let samples: [Float] = [0, 0.5, -0.5, 1.0, -1.0]

        let level = service.computeLevel(samples: samples)

        XCTAssertEqual(level.peak, 1.0, accuracy: 0.0001)
        XCTAssertGreaterThan(level.rms, 0)
        XCTAssertEqual(level.rms, sqrt(0.5), accuracy: 0.0001)
    }

    func testComputeLevelReturnsZeroForEmptyInput() {
        let service = MeteringService()

        let level = service.computeLevel(samples: [])

        XCTAssertEqual(level, .zero)
    }

    func testComputeLevelReturnsZeroForSilenceInput() {
        let service = MeteringService()
        let samples: [Float] = [0, 0, 0, 0]

        let level = service.computeLevel(samples: samples)

        XCTAssertEqual(level.peak, 0)
        XCTAssertEqual(level.rms, 0)
    }
}
