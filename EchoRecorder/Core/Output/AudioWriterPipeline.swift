import Foundation

struct FinalizedAudioOutput: Equatable {
    let folder: URL
    let mixed: URL
    let system: URL
    let mic: URL
}

protocol AudioWriterPipelining {
    func writeAudioOutputs(recordingName: String, in directory: URL) throws -> FinalizedAudioOutput
}

struct AudioWriterPipeline: AudioWriterPipelining {
    func writeAudioOutputs(recordingName: String, in directory: URL) throws -> FinalizedAudioOutput {
        let folder = directory.appendingPathComponent(recordingName, isDirectory: true)
        return FinalizedAudioOutput(
            folder: folder,
            mixed: folder.appendingPathComponent("mixed.m4a", isDirectory: false),
            system: folder.appendingPathComponent("system_audio.m4a", isDirectory: false),
            mic: folder.appendingPathComponent("mic_audio.m4a", isDirectory: false)
        )
    }
}
