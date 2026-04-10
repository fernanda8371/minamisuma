// Main app target only.
//
// Uploads pending scam entries from the App Group shared store to Supabase
// using the REST API directly — no third-party SDK needed.
//
// Configuration comes from SupabaseConfig.swift, which is auto-generated
// from .env by scripts/generate_config.sh (Run Script Build Phase).

import Foundation

// MARK: - Supabase REST payload

private struct ScamMessagePayload: Encodable {
    let id: String          // UUID string
    let detected_at: String // ISO 8601
    let sender: String
    let message_preview: String
    let category: String
    let confidence_score: Double
}

// MARK: - Service

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()
    private init() {}

    /// Reads pending entries from the App Group store, uploads them to Supabase,
    /// then marks them as uploaded. Call this on app foreground / scene activation.
    func syncPendingMessages() async {
        let pending = await SharedScamStore.shared.loadPending()
        guard !pending.isEmpty else { return }

        let payloads = pending.map { entry in
            ScamMessagePayload(
                id: entry.id.uuidString,
                detected_at: entry.detectedAt.formatted(.iso8601),
                sender: entry.sender,
                message_preview: entry.messagePreview,
                category: entry.category.rawValue,
                confidence_score: entry.confidenceScore
            )
        }

        guard let url = URL(string: "\(SupabaseConfig.projectURL)/rest/v1/\(SupabaseConfig.tableName)") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try JSONEncoder().encode(payloads)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode) {
                let uploadedIDs = Set(pending.map(\.id))
                await SharedScamStore.shared.markUploaded(ids: uploadedIDs)
                await SharedScamStore.shared.pruneUploaded()
            }
        } catch {
            // Silently fail — the data stays pending and will retry next launch.
            // Wire this to your logging system if needed.
        }
    }
}
