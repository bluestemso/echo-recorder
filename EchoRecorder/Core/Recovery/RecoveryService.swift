import Foundation

struct RecoveryService {
    private static let requiredAudioArtifacts: Set<String> = [
        "mixed.m4a",
        "system_audio.m4a",
        "mic_audio.m4a"
    ]

    private let manifestsDirectory: URL
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let onDiagnostic: (String) -> Void

    init(
        manifestsDirectory: URL,
        fileManager: FileManager = .default,
        onDiagnostic: @escaping (String) -> Void = { _ in }
    ) {
        self.manifestsDirectory = manifestsDirectory
        self.fileManager = fileManager
        self.decoder = JSONDecoder()
        self.onDiagnostic = onDiagnostic
    }

    func findUnfinalizedManifests() -> [RecordingManifest] {
        let fileURLs: [URL]
        do {
            fileURLs = try fileManager.contentsOfDirectory(
                at: manifestsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
        } catch {
            onDiagnostic("RecoveryService could not read manifests directory: \(error.localizedDescription)")
            return []
        }

        var manifestsNeedingRecovery: [RecordingManifest] = []

        for fileURL in fileURLs where fileURL.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: fileURL)
                let manifest = try decoder.decode(RecordingManifest.self, from: data)
                if !manifest.isFinalized {
                    manifestsNeedingRecovery.append(manifest)
                }
            } catch {
                onDiagnostic("RecoveryService skipped invalid manifest \(fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return manifestsNeedingRecovery
    }

    func findUnfinalizedAudioManifests() -> [RecordingManifest] {
        findUnfinalizedManifests().filter { manifest in
            let fileNames = Set(manifest.recordingFileNames)
            return fileNames.isSuperset(of: RecoveryService.requiredAudioArtifacts)
        }
    }
}
