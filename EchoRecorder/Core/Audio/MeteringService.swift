protocol MeteringServicing {
    func computeLevel(samples: [Float]) -> SourceLevel
}

struct MeteringService: MeteringServicing {
    func computeLevel(samples: [Float]) -> SourceLevel {
        guard !samples.isEmpty else {
            return .zero
        }

        var peak: Float = 0
        var sumOfSquares: Double = 0

        for sample in samples {
            let magnitude = abs(sample)
            peak = max(peak, magnitude)
            let sampleValue = Double(sample)
            sumOfSquares += sampleValue * sampleValue
        }

        let meanSquare = sumOfSquares / Double(samples.count)
        let rms = Float(meanSquare.squareRoot())

        return SourceLevel(peak: peak, rms: rms)
    }
}
