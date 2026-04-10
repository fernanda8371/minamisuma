// Shared between ScamFilterExtension and the main app target.
// Add this file to BOTH targets in Xcode (Target Membership).
//
// Uses App Groups so the extension (sandboxed, no network) can write
// detected messages that the main app later uploads to Supabase.

import Foundation

// MARK: - Replace with your actual App Group identifier.
// In Xcode: Signing & Capabilities → + Capability → App Groups for BOTH targets.
private let appGroupID = "group.luisgarcia.MinamisumaCapitalOne.scamfilter"
private let storageKey = "com.minamisuma.pendingScamMessages"

actor SharedScamStore {
    static let shared = SharedScamStore()
    private init() {}

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Write (called from extension)

    func append(_ entry: ScamMessageEntry) {
        var all = loadAll()
        all.append(entry)
        persist(all)
    }

    // MARK: - Read (called from main app)

    func loadPending() -> [ScamMessageEntry] {
        loadAll().filter { !$0.isUploaded }
    }

    // MARK: - Mark uploaded (called from main app after successful Supabase insert)

    func markUploaded(ids: Set<UUID>) {
        var all = loadAll()
        for index in all.indices where ids.contains(all[index].id) {
            all[index].isUploaded = true
        }
        persist(all)
    }

    // MARK: - Housekeeping: remove old uploaded entries

    func pruneUploaded() {
        persist(loadAll().filter { !$0.isUploaded })
    }

    // MARK: - Private helpers

    private func loadAll() -> [ScamMessageEntry] {
        guard
            let data = defaults?.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([ScamMessageEntry].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist(_ entries: [ScamMessageEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults?.set(data, forKey: storageKey)
    }
}
