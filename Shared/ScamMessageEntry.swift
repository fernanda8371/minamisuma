// Shared between ScamFilterExtension and the main app target.
// Add this file to BOTH targets in Xcode (Target Membership).

import Foundation

struct ScamMessageEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let detectedAt: Date
    let sender: String
    let messagePreview: String   // max 140 chars — never store full message text
    let category: ScamCategory
    let confidenceScore: Double  // 0.0 – 1.0
    var isUploaded: Bool

    enum ScamCategory: String, Codable, Sendable, CaseIterable {
        case pointsExpiring       = "points_expiring"
        case unauthorizedWithdrawal = "unauthorized_withdrawal"
        case accountAlert         = "account_alert"
        case suspiciousAccess     = "suspicious_access"
        case phishingLink         = "phishing_link"
        case fraudAlert           = "fraud_alert"
        case verificationRequest  = "verification_request"
        case other                = "other"

        var displayName: String {
            switch self {
            case .pointsExpiring:         "Points Expiring"
            case .unauthorizedWithdrawal: "Unauthorized Withdrawal"
            case .accountAlert:           "Account Alert"
            case .suspiciousAccess:       "Suspicious Access"
            case .phishingLink:           "Phishing Link"
            case .fraudAlert:             "Fraud Alert"
            case .verificationRequest:    "Verification Request"
            case .other:                  "Other"
            }
        }
    }

    init(
        detectedAt: Date = .now,
        sender: String,
        messagePreview: String,
        category: ScamCategory,
        confidenceScore: Double
    ) {
        self.id = UUID()
        self.detectedAt = detectedAt
        self.sender = sender
        self.messagePreview = String(messagePreview.prefix(140))
        self.category = category
        self.confidenceScore = max(0, min(1, confidenceScore))
        self.isUploaded = false
    }
}
