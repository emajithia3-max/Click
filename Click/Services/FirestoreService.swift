import Foundation
import FirebaseFirestore
import Combine

final class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    private init() {}

    deinit {
        removeAllListeners()
    }

    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    func fetchUserData(uid: String) async throws -> UserData? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let data = doc.data() else { return nil }
        return UserData(
            displayName: data["displayName"] as? String ?? "",
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
            lifetimeTaps: data["lifetimeTaps"] as? Double ?? 0,
            lifetimeBestRankIndex: data["lifetimeBestRankIndex"] as? Int ?? 1,
            cosmetics: data["cosmetics"] as? [String] ?? [],
            leaderboardOptIn: data["leaderboardOptIn"] as? Bool ?? false
        )
    }

    func createUserData(uid: String, data: UserData) async throws {
        let docData: [String: Any] = [
            "displayName": data.displayName,
            "createdAt": Timestamp(date: data.createdAt),
            "lifetimeTaps": data.lifetimeTaps,
            "lifetimeBestRankIndex": data.lifetimeBestRankIndex,
            "cosmetics": data.cosmetics,
            "leaderboardOptIn": data.leaderboardOptIn
        ]
        try await db.collection("users").document(uid).setData(docData)
    }

    func updateUserData(uid: String, fields: [String: Any]) async throws {
        try await db.collection("users").document(uid).updateData(fields)
    }

    func fetchSeasonData(uid: String, seasonId: String) async throws -> SeasonUserData? {
        let doc = try await db.collection("users").document(uid)
            .collection("season").document(seasonId).getDocument()
        guard let data = doc.data() else { return nil }
        return SeasonUserData.fromFirestore(data)
    }

    func createSeasonData(uid: String, seasonId: String, data: SeasonUserData) async throws {
        try await db.collection("users").document(uid)
            .collection("season").document(seasonId).setData(data.toFirestore())
    }

    func updateSeasonData(uid: String, seasonId: String, fields: [String: Any]) async throws {
        try await db.collection("users").document(uid)
            .collection("season").document(seasonId).updateData(fields)
    }

    func saveSeasonData(uid: String, seasonId: String, data: SeasonUserData) async throws {
        try await db.collection("users").document(uid)
            .collection("season").document(seasonId).setData(data.toFirestore(), merge: true)
    }

    func fetchSeason(seasonId: String) async throws -> Season? {
        let doc = try await db.collection("seasons").document(seasonId).getDocument()
        guard let data = doc.data() else { return nil }
        return Season.fromFirestore(data, id: seasonId)
    }

    func fetchActiveSeason() async throws -> Season? {
        let snapshot = try await db.collection("seasons")
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snapshot.documents.first else { return nil }
        return Season.fromFirestore(doc.data(), id: doc.documentID)
    }

    func fetchLeaderboard(seasonId: String) async throws -> LeaderboardData {
        let doc = try await db.collection("leaderboards").document(seasonId).getDocument()
        guard let data = doc.data() else { return LeaderboardData() }
        return LeaderboardData.fromFirestore(data)
    }

    func listenToLeaderboard(seasonId: String, onUpdate: @escaping (LeaderboardData) -> Void) {
        let listener = db.collection("leaderboards").document(seasonId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else { return }
                let leaderboard = LeaderboardData.fromFirestore(data)
                onUpdate(leaderboard)
            }
        listeners.append(listener)
    }

    func updateLeaderboardEntry(uid: String, seasonId: String, displayName: String, taps: Double, rankIndex: Int) async throws {
        let entryData: [String: Any] = [
            "uid": uid,
            "displayName": displayName,
            "taps": taps,
            "rankIndex": rankIndex,
            "updatedAt": Timestamp(date: Date())
        ]
        try await db.collection("leaderboardEntries").document(seasonId)
            .collection("entries").document(uid).setData(entryData, merge: true)
    }

    func updateLeaderboardOptIn(uid: String, optIn: Bool, displayName: String?) async throws {
        var fields: [String: Any] = ["leaderboardOptIn": optIn]
        if let name = displayName {
            fields["displayName"] = name
        }
        try await updateUserData(uid: uid, fields: fields)

        let privacyData: [String: Any] = [
            optIn ? "optInTimestamp" : "optOutTimestamp": Timestamp(date: Date()),
            "currentOptInState": optIn
        ]
        try await db.collection("privacyLogs").document(uid).setData(privacyData, merge: true)
    }

    func archiveSeasonHistory(uid: String, seasonId: String, history: SeasonHistory) async throws {
        let historyData: [String: Any] = [
            "seasonName": history.seasonName,
            "finalTaps": history.finalTaps,
            "finalRankIndex": history.finalRankIndex,
            "finalPrestigeCount": history.finalPrestigeCount,
            "endDate": Timestamp(date: history.endDate)
        ]
        try await db.collection("users").document(uid)
            .collection("seasonHistory").document(seasonId).setData(historyData)
    }

    func fetchSeasonHistory(uid: String) async throws -> [SeasonHistory] {
        let snapshot = try await db.collection("users").document(uid)
            .collection("seasonHistory")
            .order(by: "endDate", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            return SeasonHistory(
                id: doc.documentID,
                seasonName: data["seasonName"] as? String ?? "",
                finalTaps: data["finalTaps"] as? Double ?? 0,
                finalRankIndex: data["finalRankIndex"] as? Int ?? 1,
                finalPrestigeCount: data["finalPrestigeCount"] as? Int ?? 0,
                endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }
}
