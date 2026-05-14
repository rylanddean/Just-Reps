import SwiftUI

struct ProgressRing: View {
    let progress: Double  // 0.0 – 1.0
    var size: CGFloat = 80
    var strokeWidth: CGFloat = 8
    var color: Color = AppTheme.Colors.successGreen

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.15), lineWidth: strokeWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)

            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(progress >= 1 ? color : Color(UIColor.label))
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.4), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// Horizontal progress bar variant for exercise cards
struct ProgressBar: View {
    let progress: Double
    var color: Color = AppTheme.Colors.successGreen

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.15))
                    .frame(height: 6)

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * progress, height: 6)
                    .animation(.spring(duration: 0.4), value: progress)
            }
        }
        .frame(height: 6)
    }
}
