//
//  TrustedContactController.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import Foundation
import SwiftData
import Observation

// MARK: - Trusted Contact Controller (MVC Controller Layer)

@Observable
final class TrustedContactController {
    
    private var modelContext: ModelContext
    
    var contacts: [TrustedContact] = []
    var alertHistory: [AlertEvent] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchContacts()
        fetchAlertHistory()
    }
    
    // MARK: - CRUD Operations
    
    func fetchContacts() {
        let descriptor = FetchDescriptor<TrustedContact>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        do {
            contacts = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Could not load your trusted contacts. Please try again."
        }
    }
    
    func addContact(
        name: String,
        phoneNumber: String,
        email: String,
        relationship: ContactRelationship,
        permissionLevel: PermissionLevel,
        alertOnLargeTransactions: Bool = false,
        largeTransactionThreshold: Double = 500.0,
        alertOnUnusualActivity: Bool = false,
        sendBillReminders: Bool = false
    ) {
        let contact = TrustedContact(
            name: name,
            phoneNumber: phoneNumber,
            email: email,
            relationship: relationship,
            permissionLevel: permissionLevel,
            alertOnLargeTransactions: alertOnLargeTransactions,
            largeTransactionThreshold: largeTransactionThreshold,
            alertOnUnusualActivity: alertOnUnusualActivity,
            sendBillReminders: sendBillReminders
        )
        
        switch permissionLevel {
        case .alertsOnly:
            contact.alertOnUnusualActivity = true
            contact.alertOnLargeTransactions = true
        case .billReminders:
            contact.sendBillReminders = true
        case .fullCoPilot:
            contact.alertOnLargeTransactions = true
            contact.alertOnUnusualActivity = true
            contact.sendBillReminders = true
        case .viewOnly:
            break
        }
        
        modelContext.insert(contact)
        saveContext()
        fetchContacts()
    }
    
    func removeContact(_ contact: TrustedContact) {
        modelContext.delete(contact)
        saveContext()
        fetchContacts()
    }
    
    func toggleContactActive(_ contact: TrustedContact) {
        contact.isActive.toggle()
        saveContext()
        fetchContacts()
    }
    
    func updatePermission(for contact: TrustedContact, to newLevel: PermissionLevel) {
        contact.permissionLevel = newLevel
        
        contact.alertOnLargeTransactions = false
        contact.alertOnUnusualActivity = false
        contact.sendBillReminders = false
        
        switch newLevel {
        case .viewOnly:
            break
        case .alertsOnly:
            contact.alertOnUnusualActivity = true
            contact.alertOnLargeTransactions = true
        case .billReminders:
            contact.sendBillReminders = true
        case .fullCoPilot:
            contact.alertOnLargeTransactions = true
            contact.alertOnUnusualActivity = true
            contact.sendBillReminders = true
        }
        
        saveContext()
        fetchContacts()
    }
    
    func updateThreshold(for contact: TrustedContact, amount: Double) {
        contact.largeTransactionThreshold = amount
        saveContext()
    }
    
    // MARK: - Alert History
    
    func fetchAlertHistory() {
        let descriptor = FetchDescriptor<AlertEvent>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        do {
            alertHistory = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Could not load alert history."
        }
    }
    
    func simulateAlert(for contact: TrustedContact, type: AlertType) {
        let alert: AlertEvent
        
        switch type {
        case .largeTransaction:
            alert = AlertEvent(
                alertType: .largeTransaction,
                title: "Large Transaction Detected",
                message: "A transaction of $\(Int(contact.largeTransactionThreshold)) or more was made.",
                amount: contact.largeTransactionThreshold,
                contactNotified: contact.name
            )
        case .unusualActivity:
            alert = AlertEvent(
                alertType: .unusualActivity,
                title: "Unusual Activity Noticed",
                message: "Multiple transactions in a short time were detected.",
                contactNotified: contact.name
            )
        case .billReminder:
            alert = AlertEvent(
                alertType: .billReminder,
                title: "Bill Reminder Sent",
                message: "A reminder for your electricity bill was sent.",
                contactNotified: contact.name
            )
        case .repeatedTransfer:
            alert = AlertEvent(
                alertType: .repeatedTransfer,
                title: "Repeated Transfer Warning",
                message: "The same transfer was made multiple times today.",
                contactNotified: contact.name
            )
        case .newPayee:
            alert = AlertEvent(
                alertType: .newPayee,
                title: "New Payee Added",
                message: "A new payee was added to your account.",
                contactNotified: contact.name
            )
        }
        
        modelContext.insert(alert)
        saveContext()
        fetchAlertHistory()
    }
    
    var activeContacts: [TrustedContact] {
        contacts.filter { $0.isActive }
    }
    
    var contactsWithAlerts: [TrustedContact] {
        contacts.filter { $0.alertOnUnusualActivity || $0.alertOnLargeTransactions }
    }
    
    func unreadAlertCount() -> Int {
        alertHistory.filter { !$0.isRead }.count
    }
    
    func markAlertAsRead(_ alert: AlertEvent) {
        alert.isRead = true
        saveContext()
        fetchAlertHistory()
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Something went wrong saving your changes. Please try again."
        }
    }
}
