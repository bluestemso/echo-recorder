import Foundation

protocol FileWriting {
    func output(fileName: String, directory: URL, recordingData: RecordingAudioData) throws -> FinalizedAudioOutput
}

extension FileWriting {
    func output(fileName: String, directory: URL) throws -> FinalizedAudioOutput {
        try output(fileName: fileName, directory: directory, recordingData: .empty)
    }
}

struct FileWriterService: FileWriting {
    private let pipeline: any AudioWriterPipelining

    init(pipeline: any AudioWriterPipelining = AudioWriterPipeline()) {
        self.pipeline = pipeline
    }

    func output(fileName: String, directory: URL, recordingData: RecordingAudioData) throws -> FinalizedAudioOutput {
        try pipeline.writeAudioOutputs(
            recordingName: fileName,
            in: directory,
            recordingData: recordingData
        )
    }
}
