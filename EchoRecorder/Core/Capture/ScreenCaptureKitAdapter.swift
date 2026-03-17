@MainActor
protocol ScreenCaptureKitAdapting {
    func startCapture(source: CaptureSourceDescriptor) async throws
    func stopCapture() async throws
}

@MainActor
struct ScreenCaptureKitAdapter: ScreenCaptureKitAdapting {
    func startCapture(source: CaptureSourceDescriptor) async throws {}

    func stopCapture() async throws {}
}
