//
//  AddTrustedContactView.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import SwiftUI

// MARK: - Add Trusted Contact Flow (One-Task-Per-Screen)

struct AddTrustedContactView: View {
    
    @Environment(\.dismiss) private var dismiss
    var controller: TrustedContactController
    
    @State private var currentStep: AddContactStep = .name
    @State private var showConfirmation = false
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var relationship: ContactRelationship = .daughter
    @State private var permissionLevel: PermissionLevel = .viewOnly
    @State private var alertOnLargeTransactions: Bool = false
    @State private var largeTransactionThreshold: Double = 500
    @State private var alertOnUnusualActivity: Bool = false
    @State private var sendBillReminders: Bool = false
    
    enum AddContactStep: Int, CaseIterable {
        case name = 0
        case relationship = 1
        case permission = 2
        case alerts = 3
        case review = 4
        
        var title: String {
            switch self {
            case .name: return "Who do you want to add?"
            case .relationship: return "What is their relationship to you?"
            case .permission: return "What can they see?"
            case .alerts: return "Set up alerts"
            case .review: return "Review and confirm"
            }
        }
        
        var subtitle: String {
            switch self {
            case .name: return "Enter their name and contact information."
            case .relationship: return "This helps us personalize their experience."
            case .permission: return "Choose what this person is allowed to see."
            case .alerts: return "Decide when they should be notified."
            case .review: return "Make sure everything looks right."
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        stepHeader
                        stepContent
                    }
                    .padding(20)
                }
                
                navigationButtons
            }
            .background(Color.bgPrimary)
            .navigationTitle("Add Trusted Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.seniorBody)
                }
            }
            .overlay {
                if showConfirmation {
                    confirmationOverlay
                }
            }
        }
    }
    
    // MARK: - Step Content Router
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .name:
            nameStep
        case .relationship:
            relationshipStep
        case .permission:
            permissionStep
        case .alerts:
            alertsStep
        case .review:
            reviewStep
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        let total = Double(AddContactStep.allCases.count)
        let current = Double(currentStep.rawValue + 1)
        let fraction = current / total
        
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.brandBlue.opacity(0.12))
                    .frame(height: 6)
                
                Rectangle()
                    .fill(Color.brandBlue)
                    .frame(width: geo.size.width * fraction, height: 6)
                    .animation(.easeInOut(duration: 0.4), value: currentStep)
            }
        }
        .frame(height: 6)
    }
    
    // MARK: - Step Header
    
    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            let stepLabel = "Step \(currentStep.rawValue + 1) of \(AddContactStep.allCases.count)"
            Text(stepLabel)
                .font(.seniorSmall)
                .foregroundColor(Color.brandBlue)
            
            Text(currentStep.title)
                .font(.seniorHeadline)
                .foregroundColor(Color.textPrimary)
            
            Text(currentStep.subtitle)
                .font(.seniorBody)
                .foregroundColor(Color.textSecondary)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Step 1: Name & Contact
    
    private var nameStep: some View {
        VStack(spacing: 20) {
            SeniorTextField(label: "Full Name", placeholder: "e.g. Maria Garcia", text: $name)
            SeniorTextField(label: "Phone Number", placeholder: "e.g. (555) 123-4567", text: $phoneNumber, keyboardType: .phonePad)
            SeniorTextField(label: "Email Address", placeholder: "e.g. maria@email.com", text: $email, keyboardType: .emailAddress)
        }
    }
    
    // MARK: - Step 2: Relationship
    
    private var relationshipStep: some View {
        VStack(spacing: 12) {
            ForEach(ContactRelationship.allCases) { rel in
                RelationshipOptionRow(
                    rel: rel,
                    isSelected: relationship == rel,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            relationship = rel
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Step 3: Permission Level
    
    private var permissionStep: some View {
        VStack(spacing: 14) {
            ForEach(PermissionLevel.allCases) { level in
                PermissionOptionRow(
                    level: level,
                    isSelected: permissionLevel == level,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            permissionLevel = level
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Step 4: Alert Configuration
    
    private var alertsStep: some View {
        VStack(spacing: 18) {
            let displayName = name.isEmpty ? "this person" : name
            
            SeniorToggleCard(
                icon: "dollarsign.circle.fill",
                title: "Large Transactions",
                description: "Notify \(displayName) when you spend over a certain amount.",
                isOn: $alertOnLargeTransactions,
                accentColor: Color.statusOrange
            )
            
            if alertOnLargeTransactions {
                thresholdSlider
            }
            
            SeniorToggleCard(
                icon: "exclamationmark.triangle.fill",
                title: "Unusual Activity",
                description: "Notify when something unusual happens, like multiple transfers in a short time.",
                isOn: $alertOnUnusualActivity,
                accentColor: Color.statusRed
            )
            
            SeniorToggleCard(
                icon: "calendar.badge.clock",
                title: "Bill Reminders",
                description: "Send reminders when your bills are due.",
                isOn: $sendBillReminders,
                accentColor: Color.brandTeal
            )
        }
    }
    
    private var thresholdSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Alert when spending over:")
                .font(.seniorBody)
                .foregroundColor(Color.textPrimary)
            
            let amountText = "$\(Int(largeTransactionThreshold))"
            Text(amountText)
                .font(.seniorTitle)
                .foregroundColor(Color.statusOrange)
            
            Slider(value: $largeTransactionThreshold, in: 50...5000, step: 50)
                .tint(Color.statusOrange)
            
            HStack {
                Text("$50")
                    .font(.seniorSmall)
                    .foregroundColor(Color.textSecondary)
                Spacer()
                Text("$5,000")
                    .font(.seniorSmall)
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(18)
        .background(Color.statusOrange.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Step 5: Review
    
    private var reviewStep: some View {
        VStack(spacing: 16) {
            reviewRow(label: "Name", value: name, icon: "person.fill")
            reviewRow(label: "Phone", value: phoneNumber, icon: "phone.fill")
            reviewRow(label: "Email", value: email, icon: "envelope.fill")
            reviewRow(label: "Relationship", value: relationship.rawValue, icon: relationship.iconName)
            reviewRow(label: "Permission", value: permissionLevel.rawValue, icon: permissionLevel.iconName)
            
            Divider().padding(.vertical, 4)
            
            alertsSummary
            
            let displayName = name.isEmpty ? "This person" : name
            ExplanationView(
                title: "What happens next?",
                explanation: "\(displayName) will receive an invitation. They can only see what you've allowed. You can change or remove their access at any time."
            )
        }
    }
    
    private var alertsSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Alerts enabled:")
                .font(.seniorBody)
                .foregroundColor(Color.textPrimary)
            
            if alertOnLargeTransactions {
                let label = "Transactions over $\(Int(largeTransactionThreshold))"
                alertBadge(label, color: Color.statusOrange)
            }
            if alertOnUnusualActivity {
                alertBadge("Unusual activity", color: Color.statusRed)
            }
            if sendBillReminders {
                alertBadge("Bill reminders", color: Color.brandTeal)
            }
            if !alertOnLargeTransactions && !alertOnUnusualActivity && !sendBillReminders {
                Text("No alerts configured")
                    .font(.seniorCaption)
                    .foregroundColor(Color.textSecondary)
            }
        }
    }
    
    private func reviewRow(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.brandBlue)
                .frame(width: 36)
            
            Text(label)
                .font(.seniorCaption)
                .foregroundColor(Color.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.seniorBody)
                .foregroundColor(Color.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private func alertBadge(_ text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.seniorCaption)
                .foregroundColor(Color.textPrimary)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 14) {
            if currentStep != .name {
                backButton
            }
            
            Spacer()
            
            if currentStep == .review {
                SeniorPrimaryButton("Confirm", icon: "checkmark.circle", color: Color.statusGreen) {
                    saveContact()
                }
                .frame(maxWidth: 200)
            } else {
                SeniorPrimaryButton("Next Step", icon: "chevron.right", color: Color.brandBlue) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let next = AddContactStep(rawValue: currentStep.rawValue + 1) {
                            currentStep = next
                        }
                    }
                }
                .frame(maxWidth: 200)
                .disabled(!canProceed)
                .opacity(canProceed ? 1 : 0.5)
            }
        }
        .padding(20)
        .background(Color.bgCard.shadow(.drop(color: Color.black.opacity(0.06), radius: 8, y: -4)))
    }
    
    private var backButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                if let prev = AddContactStep(rawValue: currentStep.rawValue - 1) {
                    currentStep = prev
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .font(.seniorBody)
            .foregroundColor(Color.brandBlue)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(Color.brandBlue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    // MARK: - Validation
    
    private var canProceed: Bool {
        switch currentStep {
        case .name:
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
        default:
            return true
        }
    }
    
    // MARK: - Save
    
    private func saveContact() {
        controller.addContact(
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
        showConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            dismiss()
        }
    }
    
    // MARK: - Confirmation Overlay
    
    private var confirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Color.statusGreen)
                
                Text("\(name) has been added!")
                    .font(.seniorHeadline)
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("They will receive an invitation to connect with your account.")
                    .font(.seniorBody)
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
            .padding(40)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showConfirmation)
    }
}

// MARK: - Relationship Option Row (extracted to help compiler)

struct RelationshipOptionRow: View {
    let rel: ContactRelationship
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                let iconBg: Color = isSelected ? Color.brandBlue : Color.brandBlue.opacity(0.1)
                let iconFg: Color = isSelected ? .white : Color.brandBlue
                
                Image(systemName: rel.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconFg)
                    .frame(width: 48, height: 48)
                    .background(iconBg)
                    .clipShape(Circle())
                
                Text(rel.rawValue)
                    .font(.seniorSubheadline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color.brandBlue)
                }
            }
            .padding(16)
            .background(isSelected ? Color.brandBlue.opacity(0.08) : Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.brandBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Permission Option Row (extracted to help compiler)

struct PermissionOptionRow: View {
    let level: PermissionLevel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    Image(systemName: level.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(level.color)
                        .frame(width: 44, height: 44)
                        .background(level.color.opacity(0.12))
                        .clipShape(Circle())
                    
                    Text(level.rawValue)
                        .font(.seniorSubheadline)
                        .foregroundColor(Color.textPrimary)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(level.color)
                    }
                }
                
                Text(level.description)
                    .font(.seniorCaption)
                    .foregroundColor(Color.textSecondary)
                    .lineSpacing(3)
            }
            .padding(16)
            .background(isSelected ? level.color.opacity(0.06) : Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reusable Senior Text Field

struct SeniorTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.seniorBody)
                .foregroundColor(Color.textPrimary)
            
            TextField(placeholder, text: $text)
                .font(.seniorBody)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color.bgPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Reusable Senior Toggle Card

struct SeniorToggleCard: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    var accentColor: Color = Color.brandBlue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.seniorSubheadline)
                    .foregroundColor(Color.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(accentColor)
            }
            
            Text(description)
                .font(.seniorCaption)
                .foregroundColor(Color.textSecondary)
                .lineSpacing(3)
        }
        .seniorCard()
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}
