import Foundation

protocol FileWriting {
    func output(fileName: String, directory: URL) throws -> FinalizedAudioOutput
}

struct FileWriterService: FileWriting {
    private let pipeline: any AudioWriterPipelining

    init(pipeline: any AudioWriterPipelining = AudioWriterPipeline()) {
        self.pipeline = pipeline
    }

    func output(fileName: String, directory: URL) throws -> FinalizedAudioOutput {
        try pipeline.writeAudioOutputs(recordingName: fileName, in: directory)
    }
}
