protocol AudioMixing {
    func mix(_ sources: [[Float]]) -> [Float]
    func applyGain(system: SourceLevel, mic: SourceLevel, gain: SourceGain) -> (system: SourceLevel, mic: SourceLevel)
}

struct SourceGain {
    var system: Float
    var microphone: Float

    static let unity = SourceGain(system: 1, microphone: 1)
}

struct AudioMixerService: AudioMixing {
    private let meteringService: any MeteringServicing

    init(meteringService: any MeteringServicing = MeteringService()) {
        self.meteringService = meteringService
    }

    func mix(_ sources: [[Float]]) -> [Float] {
        let maxSampleCount = sources.map(\.count).max() ?? 0
        guard maxSampleCount > 0 else {
            return []
        }

        var mixed = Array(repeating: Float.zero, count: maxSampleCount)

        for index in 0..<maxSampleCount {
            var samplesAtIndex: [Float] = []
            samplesAtIndex.reserveCapacity(sources.count)

            for source in sources where index < source.count {
                samplesAtIndex.append(source[index])
            }

            samplesAtIndex.sort { lhs, rhs in
                lhs.bitPattern < rhs.bitPattern
            }

            var sum: Double = 0
            for sample in samplesAtIndex {
                sum += Double(sample)
            }

            mixed[index] = Float(sum)
        }

        return mixed
    }

    func applyGain(system: SourceLevel, mic: SourceLevel, gain: SourceGain) -> (system: SourceLevel, mic: SourceLevel) {
        (
            system: meteringService.applyGain(gain.system, to: system),
            mic: meteringService.applyGain(gain.microphone, to: mic)
        )
    }
}
