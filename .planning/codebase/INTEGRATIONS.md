# Integrations Map

## External Services
There are no external APIs, databases, or third-party SDKs integrated into this application.

## Native Apple Integrations
- **ScreenCaptureKit**: Used to capture system audio streams from the macOS display/audio server.
- **AVFoundation**: Used to access and capture the default microphone.
- **macOS Privacy & Permissions**: Interacts with macOS Settings to request Microphone access (`NSMicrophoneUsageDescription`) and potentially Screen Recording access.
- **File System / Persistence**: Uses local file system APIs (e.g., `FileManager`) to persist recordings out to disk.
