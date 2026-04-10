import SwiftUI
import SwiftData

struct ScamProtectView: View {
    @Query(sort: \ScamMessage.detectedAt, order: .reverse)
    private var messages: [ScamMessage]

    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Group {
                if messages.isEmpty {
                    ContentUnavailableView(
                        "No Scams Detected",
                        systemImage: "checkmark.shield",
                        description: Text("Suspicious messages from unknown senders will appear here.")
                    )
                } else {
                    List(messages) { message in
                        ScamMessageRow(message: message)
                    }
                }
            }
            .navigationTitle("Scam Protection")
            .toolbar {
                if !messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sync", systemImage: "arrow.clockwise") {
                            Task { await SupabaseService.shared.syncPendingMessages() }
                        }
                    }
                }
            }
        }
        .task {
            await SupabaseService.shared.syncPendingMessages()
        }
    }
}

// MARK: - Row

private struct ScamMessageRow: View {
    let message: ScamMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(message.categoryDisplayName, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)

                Spacer()

                if message.isUploaded {
                    Image(systemName: "checkmark.icloud")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Uploaded to database")
                }
            }

            Text(message.messagePreview)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text(message.sender.isEmpty ? "Unknown sender" : message.sender)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(message.detectedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                ConfidenceBadge(score: message.confidenceScore)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(for: message))
    }

    private func accessibilityLabel(for message: ScamMessage) -> String {
        "\(message.categoryDisplayName) scam detected from \(message.sender.isEmpty ? "unknown sender" : message.sender), \(message.detectedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

// MARK: - Confidence badge

private struct ConfidenceBadge: View {
    let score: Double

    private var label: String {
        switch score {
        case 0.9...: "High"
        case 0.75...: "Med"
        default:    "Low"
        }
    }

    private var color: Color {
        switch score {
        case 0.9...: .red
        case 0.75...: .orange
        default:    .yellow
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: .capsule)
            .foregroundStyle(color)
            .accessibilityLabel("Confidence: \(label)")
    }
}

#Preview {
    ScamProtectView()
        .modelContainer(for: ScamMessage.self, inMemory: true)
}
