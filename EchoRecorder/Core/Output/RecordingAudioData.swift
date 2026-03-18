struct RecordingAudioData: Equatable {
    let system: SystemAudioSampleBuffer
    let mic: MicSampleBuffer

    static let empty = RecordingAudioData(
        system: SystemAudioSampleBuffer(samples: [], sampleRate: 48_000, channelCount: 1),
        mic: MicSampleBuffer(samples: [], sampleRate: 48_000, channelCount: 1)
    )
}
