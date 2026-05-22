import GameKit
import SwiftUI

@Observable
final class GameCenterManager {
    static let shared = GameCenterManager()
    private init() {}

    // MARK: - State

    private(set) var isAuthenticated = false
    private(set) var authError: String?
    private(set) var friendEntries: [FriendEntry] = []
    private(set) var isLoadingFriends = false
    private(set) var friendLoadError: String?

    // MARK: - Types

    struct FriendEntry: Identifiable {
        let id: String
        let displayName: String
        let streak: Int
        let isLocalPlayer: Bool
    }

    // MARK: - Constants

    static let leaderboardID = "rep_streak"
    private static let lastSubmitDayKey = "gcLastStreakSubmitDay"

    // MARK: - Authentication

    func authenticateLocalPlayer() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] _, error in
            guard let self else { return }
            // GK delivers this on an unspecified queue — hop to MainActor before mutating state.
            Task { @MainActor in
                if let error {
                    self.authError = error.localizedDescription
                    self.isAuthenticated = false
                } else {
                    self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                    self.authError = nil
                }
            }
        }
    }

    // MARK: - Score submission

    func submitStreak(_ streak: Int) {
        guard isAuthenticated, streak > 0 else { return }
        let todayKey = currentDayKey()
        guard UserDefaults.standard.string(forKey: Self.lastSubmitDayKey) != todayKey else { return }

        GKLeaderboard.submitScore(
            streak,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [Self.leaderboardID]
        ) { error in
            guard error == nil else { return }
            Task { @MainActor in
                UserDefaults.standard.set(todayKey, forKey: Self.lastSubmitDayKey)
            }
        }
    }

    // MARK: - Friend entries

    func loadFriendEntries() async {
        guard isAuthenticated else { return }
        isLoadingFriends = true
        friendLoadError = nil

        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID])
            guard let board = leaderboards.first else {
                isLoadingFriends = false
                return
            }

            let (localEntry, friendsEntries, _) = try await board.loadEntries(
                for: .friendsOnly,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 100)
            )

            let localID = GKLocalPlayer.local.gamePlayerID
            var result: [FriendEntry] = []

            if let local = localEntry {
                result.append(FriendEntry(
                    id: localID,
                    displayName: "You",
                    streak: local.score,
                    isLocalPlayer: true
                ))
            }

            for entry in (friendsEntries ?? []) where entry.player.gamePlayerID != localID {
                result.append(FriendEntry(
                    id: entry.player.gamePlayerID,
                    displayName: entry.player.displayName,
                    streak: entry.score,
                    isLocalPlayer: false
                ))
            }

            result.sort { $0.streak > $1.streak }
            friendEntries = result
            isLoadingFriends = false
        } catch {
            friendLoadError = error.localizedDescription
            isLoadingFriends = false
        }
    }

    // MARK: - Helpers

    private func currentDayKey() -> String {
        let dc = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return String(format: "%04d-%02d-%02d", dc.year ?? 0, dc.month ?? 0, dc.day ?? 0)
    }
}
