enum MicCaptureServiceError: Error, Equatable {
    case alreadyCapturing
    case notCapturing
}

protocol MicCaptureServicing {
    var isCapturing: Bool { get }

    func startCapture() throws
    func stopCapture() throws
}

final class MicCaptureService: MicCaptureServicing {
    private(set) var isCapturing = false

    func startCapture() throws {
        guard !isCapturing else {
            throw MicCaptureServiceError.alreadyCapturing
        }

        isCapturing = true
    }

    func stopCapture() throws {
        guard isCapturing else {
            throw MicCaptureServiceError.notCapturing
        }

        isCapturing = false
    }
}
