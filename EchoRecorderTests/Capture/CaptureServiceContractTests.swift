import XCTest
@testable import EchoRecorder

@MainActor
final class CaptureServiceContractTests: XCTestCase {
    func testStartCaptureSetsRunningStateTrue() async throws {
        let adapter = FakeScreenCaptureKitAdapter()
        let service = CaptureService(adapter: adapter)

        try await service.startCapture(source: .systemAudio)

        let isRunning = service.isRunning
        XCTAssertTrue(isRunning)
        let startCallCount = adapter.startCallCount
        XCTAssertEqual(startCallCount, 1)
    }

    func testStopCaptureSetsRunningStateFalse() async throws {
        let adapter = FakeScreenCaptureKitAdapter()
        let service = CaptureService(adapter: adapter)

        try await service.startCapture(source: .systemAudio)
        try await service.stopCapture()

        let isRunning = service.isRunning
        XCTAssertFalse(isRunning)
        let stopCallCount = adapter.stopCallCount
        XCTAssertEqual(stopCallCount, 1)
    }

    func testStartCaptureFailureKeepsRunningStateFalse() async {
        let adapter = FakeScreenCaptureKitAdapter(failStart: true)
        let service = CaptureService(adapter: adapter)

        await XCTAssertThrowsErrorAsync(try await service.startCapture(source: .systemAudio)) { error in
            guard case FakeAdapterError.startFailed = error else {
                XCTFail("Expected startFailed error")
                return
            }
        }

        let isRunning = service.isRunning
        XCTAssertFalse(isRunning)
    }

    func testStartCaptureWhileRunningThrowsAlreadyRunning() async throws {
        let adapter = FakeScreenCaptureKitAdapter()
        let service = CaptureService(adapter: adapter)

        try await service.startCapture(source: .systemAudio)

        await XCTAssertThrowsErrorAsync(try await service.startCapture(source: .systemAudio)) { error in
            guard case CaptureServiceError.alreadyRunning = error else {
                XCTFail("Expected alreadyRunning error")
                return
            }
        }

        let startCallCount = adapter.startCallCount
        XCTAssertEqual(startCallCount, 1)
    }

    func testStopCaptureWhileStoppedThrowsNotRunning() async {
        let adapter = FakeScreenCaptureKitAdapter()
        let service = CaptureService(adapter: adapter)

        await XCTAssertThrowsErrorAsync(try await service.stopCapture()) { error in
            guard case CaptureServiceError.notRunning = error else {
                XCTFail("Expected notRunning error")
                return
            }
        }

        let stopCallCount = adapter.stopCallCount
        XCTAssertEqual(stopCallCount, 0)
    }

    func testConcurrentStartInvokesAdapterOnlyOnce() async throws {
        let adapter = FakeScreenCaptureKitAdapter(blockStartUntilResumed: true)
        let service = CaptureService(adapter: adapter)

        let firstStart = Task {
            try await service.startCapture(source: .systemAudio)
        }

        await Task.yield()

        await XCTAssertThrowsErrorAsync(try await service.startCapture(source: .systemAudio)) { error in
            guard case CaptureServiceError.alreadyRunning = error else {
                XCTFail("Expected alreadyRunning error")
                return
            }
        }

        adapter.resumeStartIfNeeded()
        try await firstStart.value

        XCTAssertEqual(adapter.startCallCount, 1)
        XCTAssertTrue(service.isRunning)
    }

    func testConcurrentStopInvokesAdapterOnlyOnce() async throws {
        let adapter = FakeScreenCaptureKitAdapter(blockStopUntilResumed: true)
        let service = CaptureService(adapter: adapter)
        try await service.startCapture(source: .systemAudio)

        let firstStop = Task {
            try await service.stopCapture()
        }

        await Task.yield()

        await XCTAssertThrowsErrorAsync(try await service.stopCapture()) { error in
            guard case CaptureServiceError.notRunning = error else {
                XCTFail("Expected notRunning error")
                return
            }
        }

        adapter.resumeStopIfNeeded()
        try await firstStop.value

        XCTAssertEqual(adapter.stopCallCount, 1)
        XCTAssertFalse(service.isRunning)
    }

    func testStopFailureKeepsRunningStateTrue() async throws {
        let adapter = FakeScreenCaptureKitAdapter(failStop: true)
        let service = CaptureService(adapter: adapter)
        try await service.startCapture(source: .systemAudio)

        await XCTAssertThrowsErrorAsync(try await service.stopCapture()) { error in
            guard case FakeAdapterError.stopFailed = error else {
                XCTFail("Expected stopFailed error")
                return
            }
        }

        XCTAssertTrue(service.isRunning)
    }
}

private enum FakeAdapterError: Error {
    case startFailed
    case stopFailed
}

@MainActor
private final class FakeScreenCaptureKitAdapter: ScreenCaptureKitAdapting {
    private let failStart: Bool
    private let failStop: Bool
    private let blockStartUntilResumed: Bool
    private let blockStopUntilResumed: Bool

    private var startContinuation: CheckedContinuation<Void, Never>?
    private var stopContinuation: CheckedContinuation<Void, Never>?

    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)?

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    init(
        failStart: Bool = false,
        failStop: Bool = false,
        blockStartUntilResumed: Bool = false,
        blockStopUntilResumed: Bool = false
    ) {
        self.failStart = failStart
        self.failStop = failStop
        self.blockStartUntilResumed = blockStartUntilResumed
        self.blockStopUntilResumed = blockStopUntilResumed
    }

    func startCapture(source: CaptureSourceDescriptor) async throws {
        startCallCount += 1

        if blockStartUntilResumed {
            await withCheckedContinuation { continuation in
                startContinuation = continuation
            }
        }

        if failStart {
            throw FakeAdapterError.startFailed
        }
    }

    func stopCapture() async throws {
        stopCallCount += 1

        if blockStopUntilResumed {
            await withCheckedContinuation { continuation in
                stopContinuation = continuation
            }
        }

        if failStop {
            throw FakeAdapterError.stopFailed
        }
    }

    func resumeStartIfNeeded() {
        startContinuation?.resume()
        startContinuation = nil
    }

    func resumeStopIfNeeded() {
        stopContinuation?.resume()
        stopContinuation = nil
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure () async throws -> Void,
    _ errorHandler: (Error) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
