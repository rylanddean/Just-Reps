import SwiftUI

struct EffortPickerSheet: View {
    var onSelect: (WorkoutEffort?) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("How did that feel?")
                .font(AppTheme.Font.headline())
                .padding(.top, AppTheme.Spacing.lg)

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.sm) {
                ForEach(WorkoutEffort.allCases, id: \.label) { effort in
                    effortCell(effort)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)

            Button("Skip") { onSelect(nil) }
                .font(AppTheme.Font.caption())
                .foregroundStyle(.secondary)
                .padding(.bottom, AppTheme.Spacing.lg)
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(UIColor.systemBackground))
    }

    private func effortCell(_ effort: WorkoutEffort) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            onSelect(effort)
        } label: {
            VStack(spacing: AppTheme.Spacing.xs) {
                Text(effort.label)
                    .font(AppTheme.Font.headline())
                Text("RPE \(effort.rpeRange)")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        }
        .buttonStyle(.plain)
    }
}
