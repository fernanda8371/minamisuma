//
//  TrustedContactController.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import Foundation
import SwiftData
import Observation
import Supabase

// MARK: - Trusted Contact Controller (Supabase + Local AlertEvents)

@Observable
final class TrustedContactController {
    
    private var modelContext: ModelContext
    
    var contacts: [TrustedContact] = []
    var alertHistory: [AlertEvent] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let table = "trusted_contacts"
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAlertHistory()
        Task { await fetchContacts() }
    }
    
    // MARK: - Supabase CRUD Operations
    
    @MainActor
    func fetchContacts() async {
        isLoading = true
        do {
            let result: [TrustedContact] = try await SupabaseManager.client
                .from(table)
                .select()
                .order("date_added", ascending: false)
                .execute()
                .value
            contacts = result
        } catch {
            errorMessage = "Could not load your trusted contacts. Please try again."
            print("Supabase fetch error: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
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
        var contact = TrustedContact(
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
        
        Task {
            do {
                try await SupabaseManager.client
                    .from(table)
                    .insert(contact)
                    .execute()
                await fetchContacts()
            } catch {
                errorMessage = "Could not add contact. Please try again."
                print("Supabase insert error: \(error)")
            }
        }
    }
    
    @MainActor
    func removeContact(_ contact: TrustedContact) {
        Task {
            do {
                try await SupabaseManager.client
                    .from(table)
                    .delete()
                    .eq("id", value: contact.id.uuidString)
                    .execute()
                await fetchContacts()
            } catch {
                errorMessage = "Could not remove contact. Please try again."
                print("Supabase delete error: \(error)")
            }
        }
    }
    
    @MainActor
    func toggleContactActive(_ contact: TrustedContact) {
        let newValue = !contact.isActive
        Task {
            do {
                try await SupabaseManager.client
                    .from(table)
                    .update(["is_active": newValue])
                    .eq("id", value: contact.id.uuidString)
                    .execute()
                await fetchContacts()
            } catch {
                errorMessage = "Could not update contact. Please try again."
                print("Supabase update error: \(error)")
            }
        }
    }
    
    @MainActor
    func updatePermission(for contact: TrustedContact, to newLevel: PermissionLevel) {
        Task {
            do {
                var updates: [String: AnyJSON] = [
                    "permission_level": try AnyJSON(newLevel.rawValue),
                    "alert_on_large_transactions": try AnyJSON(false),
                    "alert_on_unusual_activity": try AnyJSON(false),
                    "send_bill_reminders": try AnyJSON(false)
                ]

                switch newLevel {
                case .viewOnly:
                    break
                case .alertsOnly:
                    updates["alert_on_unusual_activity"] = try AnyJSON(true)
                    updates["alert_on_large_transactions"] = try AnyJSON(true)
                case .billReminders:
                    updates["send_bill_reminders"] = try AnyJSON(true)
                case .fullCoPilot:
                    updates["alert_on_large_transactions"] = try AnyJSON(true)
                    updates["alert_on_unusual_activity"] = try AnyJSON(true)
                    updates["send_bill_reminders"] = try AnyJSON(true)
                }
                try await SupabaseManager.client
                    .from(table)
                    .update(updates)
                    .eq("id", value: contact.id.uuidString)
                    .execute()
                await fetchContacts()
            } catch {
                errorMessage = "Could not update permission. Please try again."
                print("Supabase update error: \(error)")
            }
        }
    }
    
    @MainActor
    func updateThreshold(for contact: TrustedContact, amount: Double) {
        Task {
            do {
                try await SupabaseManager.client
                    .from(table)
                    .update(["large_transaction_threshold": amount])
                    .eq("id", value: contact.id.uuidString)
                    .execute()
                await fetchContacts()
            } catch {
                errorMessage = "Could not update threshold."
                print("Supabase update error: \(error)")
            }
        }
    }
    
    // MARK: - Alert History (still local SwiftData)
    
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
