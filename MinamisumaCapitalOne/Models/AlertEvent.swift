//
//  AlertEvent.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import Foundation
import SwiftData

// MARK: - Alert Type Enum

enum AlertType: String, Codable, CaseIterable, Identifiable {
    case largeTransaction = "Large Transaction"
    case unusualActivity = "Unusual Activity"
    case billReminder = "Bill Reminder"
    case repeatedTransfer = "Repeated Transfer"
    case newPayee = "New Payee"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .largeTransaction:
            return "dollarsign.circle.fill"
        case .unusualActivity:
            return "exclamationmark.triangle.fill"
        case .billReminder:
            return "calendar.badge.exclamationmark"
        case .repeatedTransfer:
            return "arrow.triangle.2.circlepath"
        case .newPayee:
            return "person.badge.plus"
        }
    }
}

// MARK: - Alert Event Model

@Model
final class AlertEvent {
    var id: UUID
    var alertType: AlertType
    var title: String
    var message: String
    var amount: Double?
    var timestamp: Date
    var isRead: Bool
    var contactNotified: String
    
    init(
        alertType: AlertType,
        title: String,
        message: String,
        amount: Double? = nil,
        contactNotified: String,
        isRead: Bool = false
    ) {
        self.id = UUID()
        self.alertType = alertType
        self.title = title
        self.message = message
        self.amount = amount
        self.timestamp = Date()
        self.isRead = isRead
        self.contactNotified = contactNotified
    }
}
