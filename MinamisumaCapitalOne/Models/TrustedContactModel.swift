//
//  TrustedContactModel.swift
//  MinamisumaCapitalOne
//
//  Created by Daniela Caiceros on 10/04/26.
//

import Foundation

// MARK: - Permission Level Enum

enum PermissionLevel: String, Codable, CaseIterable, Identifiable {
    case viewOnly = "View Only"
    case alertsOnly = "Alerts Only"
    case billReminders = "Bill Reminders"
    case fullCoPilot = "Full Co-Pilot"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .viewOnly:
            return "Can see your transactions but cannot move money"
        case .alertsOnly:
            return "Gets notified when unusual spending happens"
        case .billReminders:
            return "Receives reminders when your bills are due"
        case .fullCoPilot:
            return "Can see transactions, gets alerts, and receives bill reminders"
        }
    }
    
    var iconName: String {
        switch self {
        case .viewOnly:
            return "eye.fill"
        case .alertsOnly:
            return "bell.badge.fill"
        case .billReminders:
            return "calendar.badge.clock"
        case .fullCoPilot:
            return "person.2.fill"
        }
    }
}

// MARK: - Contact Relationship Enum

enum ContactRelationship: String, Codable, CaseIterable, Identifiable {
    case son = "Son"
    case daughter = "Daughter"
    case spouse = "Spouse"
    case caregiver = "Caregiver"
    case sibling = "Sibling"
    case grandchild = "Grandchild"
    case other = "Other"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .son, .daughter, .grandchild:
            return "figure.and.child.holdinghands"
        case .spouse:
            return "heart.fill"
        case .caregiver:
            return "cross.case.fill"
        case .sibling:
            return "person.2.fill"
        case .other:
            return "person.fill"
        }
    }
}

// MARK: - Trusted Contact Model (Supabase Codable)

struct TrustedContact: Codable, Identifiable {
    var id: UUID
    var name: String
    var phoneNumber: String
    var email: String
    var relationship: ContactRelationship
    var permissionLevel: PermissionLevel
    var isActive: Bool
    var dateAdded: Date
    
    // Alert preferences
    var alertOnLargeTransactions: Bool
    var largeTransactionThreshold: Double
    var alertOnUnusualActivity: Bool
    var sendBillReminders: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phoneNumber = "phone_number"
        case email
        case relationship
        case permissionLevel = "permission_level"
        case isActive = "is_active"
        case dateAdded = "date_added"
        case alertOnLargeTransactions = "alert_on_large_transactions"
        case largeTransactionThreshold = "large_transaction_threshold"
        case alertOnUnusualActivity = "alert_on_unusual_activity"
        case sendBillReminders = "send_bill_reminders"
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        phoneNumber: String,
        email: String,
        relationship: ContactRelationship,
        permissionLevel: PermissionLevel,
        isActive: Bool = true,
        dateAdded: Date = Date(),
        alertOnLargeTransactions: Bool = false,
        largeTransactionThreshold: Double = 500.0,
        alertOnUnusualActivity: Bool = false,
        sendBillReminders: Bool = false
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.email = email
        self.relationship = relationship
        self.permissionLevel = permissionLevel
        self.isActive = isActive
        self.dateAdded = dateAdded
        self.alertOnLargeTransactions = alertOnLargeTransactions
        self.largeTransactionThreshold = largeTransactionThreshold
        self.alertOnUnusualActivity = alertOnUnusualActivity
        self.sendBillReminders = sendBillReminders
    }
}
