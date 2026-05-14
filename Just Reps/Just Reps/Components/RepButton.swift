import SwiftUI

struct RepButton: View {
    let exercise: ExerciseType
    let increment: Int
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(exercise.emoji)
                    .font(.system(size: 20))
                Text("+\(increment)")
                    .font(AppTheme.Font.headline())
                    .fontWeight(.bold)
                Text(exercise.unit)
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.vertical, AppTheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 64)
            .background(Color(UIColor.label))
            .foregroundStyle(Color(UIColor.systemBackground))
            .clipShape(Capsule())
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        withAnimation(.easeOut(duration: 0.1)) { isPressed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.1)) { isPressed = false }
        }
        onTap()
    }
}

// Smaller inline variant for custom increments
struct RepButtonSmall: View {
    let label: String
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            onTap()
        }) {
            Text(label)
                .font(AppTheme.Font.caption())
                .fontWeight(.semibold)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Color(UIColor.secondarySystemBackground))
                .foregroundStyle(Color(UIColor.label))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
