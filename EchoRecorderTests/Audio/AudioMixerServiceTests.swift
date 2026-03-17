import XCTest
@testable import EchoRecorder

final class AudioMixerServiceTests: XCTestCase {
    func testMixReturnsEmptyWhenNoSourcesProvided() {
        let service = AudioMixerService()

        let mixed = service.mix([])

        XCTAssertEqual(mixed, [])
    }

    func testMixZeroPadsToLongestSource() {
        let service = AudioMixerService()

        let mixed = service.mix([[1, 2], [3]])

        XCTAssertEqual(mixed, [4, 2])
    }

    func testMixIsOrderIndependentWhenSourceLengthsDiffer() {
        let service = AudioMixerService()

        let mixedForward = service.mix([[1], [2, 3]])
        let mixedReversed = service.mix([[2, 3], [1]])

        XCTAssertEqual(mixedForward, mixedReversed)
    }

    func testMixIsOrderIndependentForNumericallySensitiveSamples() {
        let service = AudioMixerService()

        let firstOrder = service.mix([[1.0e20, 1.0], [-1.0e20], [3.0]])
        let secondOrder = service.mix([[3.0], [1.0e20, 1.0], [-1.0e20]])

        XCTAssertEqual(firstOrder, secondOrder)
    }
}
