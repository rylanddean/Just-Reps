import SwiftUI

struct StreakEulogySheet: View {
    @Environment(\.dismiss) private var dismiss
    let streakLength: Int

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("\(streakLength) days.")
                    .font(AppTheme.Font.display())
                    .foregroundStyle(Color(UIColor.label))

                Text(copyLine)
                    .font(AppTheme.Font.title())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                dismiss()
            } label: {
                Text("Start again")
                    .font(AppTheme.Font.headline())
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(UIColor.secondarySystemFill))
                    .foregroundStyle(Color(UIColor.label))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.xl)
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.hidden)
    }

    private var copyLine: String {
        switch streakLength {
        case 7..<30: return "That's real."
        case 30..<90: return "That's real progress."
        default: return "That's discipline."
        }
    }
}
