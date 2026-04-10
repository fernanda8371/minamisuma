//
//  TrustedContactsListView.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import SwiftUI
import SwiftData

// MARK: - Trusted Contacts List View (Main Hub)

struct TrustedContactsListView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var controller: TrustedContactController?
    @State private var showAddContact = false
    @State private var showRemoveConfirmation = false
    @State private var contactToRemove: TrustedContact?
    @State private var showExplanation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if showExplanation {
                        ExplanationView(
                            title: "What is Family Visibility?",
                            explanation: "You can invite family members to help watch over your finances. They can only see what you allow — no one can move your money without your permission. You stay in full control."
                        )
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    if let controller {
                        if controller.isLoading {
                            ProgressView("Loading...")
                                .font(.seniorBody)
                                .padding(.vertical, 40)
                        } else if controller.contacts.isEmpty {
                            emptyStateView
                        } else {
                            contactsList(controller: controller)
                        }
                    }
                    
                    SeniorPrimaryButton(
                        "Add a Trusted Person",
                        icon: "person.badge.plus",
                        color: Color.brandBlue
                    ) {
                        showAddContact = true
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("My Trusted People")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showExplanation.toggle()
                        }
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.brandBlue)
                    }
                    .accessibilityLabel("Explain this screen")
                }
            }
            .sheet(isPresented: $showAddContact, onDismiss: {
                if let controller {
                    Task { await controller.fetchContacts() }
                }
            }) {
                if let controller {
                    AddTrustedContactView(controller: controller)
                }
            }
            .alert("Remove this person?", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) {
                    contactToRemove = nil
                }
                Button("Yes, remove", role: .destructive) {
                    if let contact = contactToRemove, let controller {
                        withAnimation {
                            controller.removeContact(contact)
                        }
                    }
                    contactToRemove = nil
                }
            } message: {
                if let contact = contactToRemove {
                    Text("\(contact.name) will no longer be able to see your account information.")
                }
            }
            .onAppear {
                if controller == nil {
                    controller = TrustedContactController(modelContext: modelContext)
                }
            }
            .refreshable {
                if let controller {
                    await controller.fetchContacts()
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.system(size: 36))
                    .foregroundColor(Color.brandTeal)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Family Visibility")
                        .font(.seniorHeadline)
                        .foregroundColor(Color.textPrimary)
                    Text("People you trust to help watch over your finances")
                        .font(.seniorCaption)
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 64))
                .foregroundColor(Color.textSecondary.opacity(0.4))
            
            Text("No trusted people yet")
                .font(.seniorSubheadline)
                .foregroundColor(Color.textPrimary)
            
            Text("Add a family member or caregiver to help keep your finances safe.")
                .font(.seniorBody)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Contacts List
    
    private func contactsList(controller: TrustedContactController) -> some View {
        VStack(spacing: 14) {
            ForEach(controller.contacts) { contact in
                NavigationLink {
                    ContactDetailView(contact: contact, controller: controller)
                } label: {
                    TrustedContactCard(
                        contact: contact,
                        onToggleActive: {
                            withAnimation {
                                controller.toggleContactActive(contact)
                            }
                        },
                        onRemove: {
                            contactToRemove = contact
                            showRemoveConfirmation = true
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Contact Card Component

struct TrustedContactCard: View {
    let contact: TrustedContact
    let onToggleActive: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            topRow
            permissionBadge
        }
        .seniorCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(contact.name), \(contact.relationship.rawValue), permission: \(contact.permissionLevel.rawValue), \(contact.isActive ? "active" : "paused")")
    }
    
    private var topRow: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(contact.permissionLevel.color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: contact.relationship.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(contact.permissionLevel.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.seniorSubheadline)
                    .foregroundColor(Color.textPrimary)
                
                Text(contact.relationship.rawValue)
                    .font(.seniorCaption)
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            let dotColor: Color = contact.isActive ? .statusGreen : Color.textSecondary.opacity(0.3)
            Circle()
                .fill(dotColor)
                .frame(width: 14, height: 14)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.textSecondary)
        }
    }
    
    private var permissionBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: contact.permissionLevel.iconName)
                .font(.system(size: 16))
            
            Text(contact.permissionLevel.rawValue)
                .font(.seniorSmall)
            
            Spacer()
            
            if !contact.isActive {
                Text("Paused")
                    .font(.seniorSmall)
                    .foregroundColor(Color.statusOrange)
            }
        }
        .foregroundColor(contact.permissionLevel.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(contact.permissionLevel.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
