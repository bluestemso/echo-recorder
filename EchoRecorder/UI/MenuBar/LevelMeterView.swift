import SwiftUI

struct LevelMeterView: View {
    let level: SourceLevel

    private var meterColor: Color {
        let peak = level.peak
        if peak >= 0.85 { return .red }
        if peak >= 0.60 { return .yellow }
        return .green
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .cornerRadius(3)
                // Filled level bar
                Rectangle()
                    .fill(meterColor)
                    .cornerRadius(3)
                    .frame(width: geometry.size.width * CGFloat(level.peak))
            }
        }
        .frame(height: 8)
        .animation(.linear(duration: 0.05), value: level.peak)
    }
}
