import SwiftData
import Foundation

@Model
final class ScamMessage {
    var id: UUID
    var detectedAt: Date
    var sender: String
    var messagePreview: String
    var category: String
    var confidenceScore: Double
    var isUploaded: Bool

    init(from entry: ScamMessageEntry) {
        self.id = entry.id
        self.detectedAt = entry.detectedAt
        self.sender = entry.sender
        self.messagePreview = entry.messagePreview
        self.category = entry.category.rawValue
        self.confidenceScore = entry.confidenceScore
        self.isUploaded = entry.isUploaded
    }

    var categoryDisplayName: String {
        ScamMessageEntry.ScamCategory(rawValue: category)?.displayName ?? category
    }
}
