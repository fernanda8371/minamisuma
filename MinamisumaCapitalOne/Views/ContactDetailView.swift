//
//  ContactDetailView.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import SwiftUI

// MARK: - Contact Detail View

struct ContactDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let contact: TrustedContact
    var controller: TrustedContactController
    
    @State private var showRemoveConfirmation = false
    @State private var showPermissionChange = false
    @State private var showUndoBanner = false
    @State private var previousPermission: PermissionLevel?
    @State private var undoTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                contactHeader
                permissionSection
                alertPreferencesSection
                recentAlertsSection
                actionsSection
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .navigationTitle(contact.name)
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .top) {
            if showUndoBanner {
                undoBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
            }
        }
        .alert("Remove \(contact.name)?", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Yes, remove", role: .destructive) {
                controller.removeContact(contact)
                dismiss()
            }
        } message: {
            Text("They will no longer have access to your account. You can add them back later.")
        }
    }
    
    // MARK: - Contact Header
    
    private var contactHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(contact.permissionLevel.color.opacity(0.15))
                    .frame(width: 88, height: 88)
                
                Image(systemName: contact.relationship.iconName)
                    .font(.system(size: 38))
                    .foregroundColor(contact.permissionLevel.color)
            }
            
            VStack(spacing: 6) {
                Text(contact.name)
                    .font(.seniorHeadline)
                    .foregroundColor(Color.textPrimary)
                
                Text(contact.relationship.rawValue)
                    .font(.seniorBody)
                    .foregroundColor(Color.textSecondary)
            }
            
            statusBadge
            contactInfo
        }
        .frame(maxWidth: .infinity)
        .seniorCard()
    }
    
    private var statusBadge: some View {
        let badgeColor: Color = contact.isActive ? Color.statusGreen : Color.statusOrange
        let badgeText = contact.isActive ? "Active" : "Paused"
        
        return HStack(spacing: 8) {
            Circle()
                .fill(badgeColor)
                .frame(width: 10, height: 10)
            
            Text(badgeText)
                .font(.seniorCaption)
                .foregroundColor(badgeColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(badgeColor.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var contactInfo: some View {
        VStack(spacing: 8) {
            if !contact.phoneNumber.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color.textSecondary)
                    Text(contact.phoneNumber)
                        .font(.seniorCaption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            if !contact.email.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(Color.textSecondary)
                    Text(contact.email)
                        .font(.seniorCaption)
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Permission Section
    
    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Permission")
                .font(.seniorHeadline)
                .foregroundColor(Color.textPrimary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: contact.permissionLevel.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(contact.permissionLevel.color)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.permissionLevel.rawValue)
                            .font(.seniorSubheadline)
                            .foregroundColor(Color.textPrimary)
                        
                        Text(contact.permissionLevel.description)
                            .font(.seniorCaption)
                            .foregroundColor(Color.textSecondary)
                            .lineSpacing(3)
                    }
                }
            }
            .seniorCard()
            
            SeniorPrimaryButton("Change Permission Level", icon: "slider.horizontal.3", color: Color.brandBlue) {
                showPermissionChange = true
            }
        }
        .sheet(isPresented: $showPermissionChange) {
            ChangePermissionSheet(
                contact: contact,
                controller: controller,
                onChanged: { oldLevel in
                    previousPermission = oldLevel
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showUndoBanner = true
                    }
                    undoTimer?.invalidate()
                    undoTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
                        withAnimation {
                            showUndoBanner = false
                        }
                        previousPermission = nil
                    }
                }
            )
        }
    }
    
    // MARK: - Alert Preferences
    
    private var alertPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Alert Settings")
                .font(.seniorHeadline)
                .foregroundColor(Color.textPrimary)
            
            VStack(spacing: 12) {
                let largeDesc = contact.alertOnLargeTransactions
                    ? "Alerts for spending over $\(Int(contact.largeTransactionThreshold))"
                    : "Not enabled"
                alertRow(
                    icon: "dollarsign.circle.fill",
                    title: "Large Transactions",
                    subtitle: largeDesc,
                    isActive: contact.alertOnLargeTransactions,
                    color: Color.statusOrange
                )
                
                let unusualDesc = contact.alertOnUnusualActivity
                    ? "Alerts for suspicious patterns"
                    : "Not enabled"
                alertRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Unusual Activity",
                    subtitle: unusualDesc,
                    isActive: contact.alertOnUnusualActivity,
                    color: Color.statusRed
                )
                
                let billDesc = contact.sendBillReminders
                    ? "Receives your bill due dates"
                    : "Not enabled"
                alertRow(
                    icon: "calendar.badge.clock",
                    title: "Bill Reminders",
                    subtitle: billDesc,
                    isActive: contact.sendBillReminders,
                    color: Color.brandTeal
                )
            }
        }
    }
    
    private func alertRow(icon: String, title: String, subtitle: String, isActive: Bool, color: Color) -> some View {
        let iconColor: Color = isActive ? color : Color.textSecondary.opacity(0.4)
        let checkColor: Color = isActive ? color : Color.textSecondary.opacity(0.3)
        let checkIcon = isActive ? "checkmark.circle.fill" : "circle"
        
        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.seniorBody)
                    .foregroundColor(Color.textPrimary)
                
                Text(subtitle)
                    .font(.seniorCaption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: checkIcon)
                .font(.system(size: 22))
                .foregroundColor(checkColor)
        }
        .seniorCard()
    }
    
    // MARK: - Recent Alerts
    
    private var recentAlertsSection: some View {
        let contactAlerts = controller.alertHistory.filter { $0.contactNotified == contact.name }
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Recent Alerts Sent")
                .font(.seniorHeadline)
                .foregroundColor(Color.textPrimary)
            
            if contactAlerts.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 22))
                        .foregroundColor(Color.textSecondary.opacity(0.4))
                    
                    Text("No alerts have been sent to \(contact.name) yet.")
                        .font(.seniorBody)
                        .foregroundColor(Color.textSecondary)
                }
                .seniorCard()
            } else {
                ForEach(contactAlerts.prefix(5)) { alert in
                    alertHistoryRow(alert: alert)
                }
            }
        }
    }
    
    private func alertHistoryRow(alert: AlertEvent) -> some View {
        HStack(spacing: 14) {
            Image(systemName: alert.alertType.iconName)
                .font(.system(size: 20))
                .foregroundColor(Color.statusOrange)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(alert.title)
                    .font(.seniorBody)
                    .foregroundColor(Color.textPrimary)
                
                Text(alert.timestamp, format: .dateTime.month().day().hour().minute())
                    .font(.seniorCaption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
        }
        .seniorCard()
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        let toggleTitle = contact.isActive ? "Pause Access" : "Resume Access"
        let toggleIcon = contact.isActive ? "pause.circle" : "play.circle"
        let toggleColor: Color = contact.isActive ? Color.statusOrange : Color.statusGreen
        
        return VStack(spacing: 14) {
            SeniorPrimaryButton(toggleTitle, icon: toggleIcon, color: toggleColor) {
                withAnimation {
                    controller.toggleContactActive(contact)
                }
            }
            
            SeniorPrimaryButton("Remove \(contact.name)", icon: "trash", color: Color.statusRed) {
                showRemoveConfirmation = true
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 32)
    }
    
    // MARK: - Undo Banner
    
    private var undoBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Permission changed")
                    .font(.seniorBody)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("You have 30 seconds to undo this change.")
                    .font(.seniorSmall)
                    .foregroundColor(Color.white.opacity(0.85))
            }
            
            Spacer()
            
            Button("Undo") {
                if let prev = previousPermission {
                    controller.updatePermission(for: contact, to: prev)
                    withAnimation {
                        showUndoBanner = false
                    }
                    undoTimer?.invalidate()
                }
            }
            .font(.seniorBody)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.25))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .background(Color.brandBlue)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 4)
    }
}

// MARK: - Change Permission Sheet

struct ChangePermissionSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    let contact: TrustedContact
    var controller: TrustedContactController
    var onChanged: (PermissionLevel) -> Void
    
    @State private var selected: PermissionLevel?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose a new permission level for \(contact.name).")
                        .font(.seniorBody)
                        .foregroundColor(Color.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    VStack(spacing: 12) {
                        ForEach(PermissionLevel.allCases) { level in
                            let isActive = selected == level || (selected == nil && contact.permissionLevel == level)
                            PermissionSheetRow(
                                level: level,
                                isActive: isActive,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selected = level
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if let selected, selected != contact.permissionLevel {
                        SeniorPrimaryButton("Confirm Change", icon: "checkmark.circle", color: Color.statusGreen) {
                            let old = contact.permissionLevel
                            controller.updatePermission(for: contact, to: selected)
                            onChanged(old)
                            dismiss()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Change Permission")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(.seniorBody)
                }
            }
        }
    }
}

// MARK: - Permission Sheet Row (extracted to help compiler)

struct PermissionSheetRow: View {
    let level: PermissionLevel
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: level.iconName)
                    .font(.system(size: 22))
                    .foregroundColor(level.color)
                    .frame(width: 44, height: 44)
                    .background(level.color.opacity(0.12))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.rawValue)
                        .font(.seniorSubheadline)
                        .foregroundColor(Color.textPrimary)
                    
                    Text(level.description)
                        .font(.seniorCaption)
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(level.color)
                }
            }
            .padding(16)
            .background(isActive ? level.color.opacity(0.06) : Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? level.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
