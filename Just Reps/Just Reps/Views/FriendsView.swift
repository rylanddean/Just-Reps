import SwiftUI

struct FriendsView: View {
    private let gc = GameCenterManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if !gc.isAuthenticated {
                    notAuthenticatedState
                } else if gc.isLoadingFriends && gc.friendEntries.isEmpty {
                    loadingState
                } else if gc.friendEntries.isEmpty {
                    emptyState
                } else {
                    friendsList
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if gc.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task { await gc.loadFriendEntries() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .tint(AppTheme.Colors.successGreen)
                        .disabled(gc.isLoadingFriends)
                    }
                }
            }
            .task {
                if gc.isAuthenticated {
                    await gc.loadFriendEntries()
                }
            }
            .onChange(of: gc.isAuthenticated) { _, isAuth in
                if isAuth {
                    Task { await gc.loadFriendEntries() }
                }
            }
        }
    }

    // MARK: - Populated list

    private var friendsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(gc.friendEntries.enumerated()), id: \.element.id) { index, entry in
                    FriendStreakRow(entry: entry)
                    if index < gc.friendEntries.count - 1 {
                        Divider()
                            .padding(.leading, AppTheme.Spacing.md)
                    }
                }
            }
            .padding(AppTheme.Spacing.xs)
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .padding(AppTheme.Spacing.md)

            if let error = gc.friendLoadError {
                Text(error)
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .padding(AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - States

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("No friends yet")
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.primaryText)
            Text("Friends who use Just Reps with Game Center enabled will appear here once they log their first streak.")
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var notAuthenticatedState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Game Center not connected")
                .font(AppTheme.Font.headline())
                .foregroundStyle(AppTheme.Colors.primaryText)
            Text("Sign in to Game Center in Settings to see friends' streaks.")
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(AppTheme.Font.body())
            .foregroundStyle(AppTheme.Colors.successGreen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
                .tint(AppTheme.Colors.successGreen)
            Text("Loading friends...")
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
