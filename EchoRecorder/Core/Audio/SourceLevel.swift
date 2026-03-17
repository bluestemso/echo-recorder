struct SourceLevel: Equatable {
    let peak: Float
    let rms: Float

    static let zero = SourceLevel(peak: 0, rms: 0)
}
