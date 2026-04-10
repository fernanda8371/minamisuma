import SwiftUI

struct ScamProtectView: View {
    @State private var entries: [ScamMessageEntry] = []

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "Sin movimientos sospechosos",
                    systemImage: "checkmark.shield",
                    description: Text("Los mensajes sospechosos de remitentes desconocidos aparecerán aquí.")
                )
            } else {
                List(entries) { entry in
                    ScamEntryRow(entry: entry)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Movimientos sospechosos")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sincronizar", systemImage: "arrow.clockwise") {
                        Task { await SupabaseService.shared.syncPendingMessages() }
                    }
                }
            }
        }
        .task {
            await reload()
        }
        .refreshable {
            await reload()
        }
    }

    private func reload() async {
        await SupabaseService.shared.syncPendingMessages()
        entries = await SharedScamStore.shared.loadPending()
    }
}

// MARK: - Row

private struct ScamEntryRow: View {
    let entry: ScamMessageEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(entry.category.displayName, systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)

                Spacer()

                ConfidenceBadge(score: entry.confidenceScore)
            }

            Text(entry.messagePreview)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text(entry.sender.isEmpty ? "Remitente desconocido" : entry.sender)
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                Spacer()

                Text(entry.detectedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(entry.category.displayName), de \(entry.sender.isEmpty ? "remitente desconocido" : entry.sender), \(entry.detectedAt.formatted(date: .abbreviated, time: .shortened))"
        )
    }
}

// MARK: - Confidence badge

private struct ConfidenceBadge: View {
    let score: Double

    private var label: String {
        switch score {
        case 0.9...: "Alto"
        case 0.75...: "Medio"
        default:    "Bajo"
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
            .accessibilityLabel("Nivel de riesgo: \(label)")
    }
}

#Preview {
    NavigationStack {
        ScamProtectView()
    }
}
