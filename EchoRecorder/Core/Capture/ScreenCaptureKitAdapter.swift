@MainActor
protocol ScreenCaptureKitAdapting: AnyObject {
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)? { get set }

    func startCapture(source: CaptureSourceDescriptor) async throws
    func stopCapture() async throws
}

@MainActor
final class ScreenCaptureKitAdapter: ScreenCaptureKitAdapting {
    var onSystemAudioSamples: ((SystemAudioSampleBuffer) -> Void)?

    func startCapture(source: CaptureSourceDescriptor) async throws {}

    func stopCapture() async throws {}
}
