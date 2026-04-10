//
//  CaregiverRequestSheet.swift
//  MinamisumaCapitalOne
//
//  Caregiver selects permission level when requesting access
//

import SwiftUI

// MARK: - Caregiver Request Sheet (used by caregiver)

struct CaregiverRequestSheet: View {
    
    @Bindable var safetyController: SafetyModeController
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedLevel: CaregiverPermissionLevel = .alertsOnly
    @State private var transferLimit: Double = 5000
    @State private var withdrawalLimit: Double = 2000
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    headerSection
                    
                    // Permission level cards
                    permissionCards
                    
                    // Limits config (only for Co-Pilot)
                    if selectedLevel == .fullCoPilot {
                        limitsSection
                    }
                    
                    // Send request button
                    SeniorPrimaryButton(
                        "Enviar solicitud a Lorenzo",
                        icon: "paperplane.fill",
                        color: selectedLevel.color
                    ) {
                        safetyController.requestActivationFromCaregiver(
                            permission: selectedLevel,
                            transferLimit: selectedLevel == .fullCoPilot ? transferLimit : nil,
                            withdrawalLimit: selectedLevel == .fullCoPilot ? withdrawalLimit : nil
                        )
                        showConfirmation = true
                    }
                    .disabled(safetyController.hasPendingCaregiverRequest)
                    
                    if safetyController.hasPendingCaregiverRequest {
                        HStack(spacing: 8) {
                            Image(systemName: "hourglass")
                                .foregroundColor(.statusOrange)
                            Text("Ya hay una solicitud pendiente")
                                .font(.seniorCaption)
                                .foregroundColor(.statusOrange)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Solicitar acceso")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .alert("Solicitud enviada", isPresented: $showConfirmation) {
                Button("Entendido") { dismiss() }
            } message: {
                Text("Lorenzo recibira tu solicitud de \(selectedLevel.rawValue). El debe aceptarla para mantener su independencia.")
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Que tipo de acceso necesitas?")
                .font(.seniorHeadline)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Lorenzo vera exactamente que permisos le estas pidiendo y debera aceptar.")
                .font(.seniorBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Permission Cards
    
    private var permissionCards: some View {
        VStack(spacing: 12) {
            ForEach(CaregiverPermissionLevel.allCases) { level in
                permissionCard(level)
            }
        }
    }
    
    private func permissionCard(_ level: CaregiverPermissionLevel) -> some View {
        let isSelected = selectedLevel == level
        
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedLevel = level
            }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(level.color.opacity(isSelected ? 0.2 : 0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: level.icon)
                            .font(.system(size: 22))
                            .foregroundColor(level.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(level.rawValue)
                            .font(.seniorBody)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? level.color : .textSecondary.opacity(0.3))
                }
                
                // Permission list
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(level.permissions, id: \.self) { perm in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(level.color)
                            Text(perm)
                                .font(.seniorCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.leading, 60)
            }
            .padding(16)
            .background(isSelected ? level.color.opacity(0.06) : Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? level.color : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Limits (Co-Pilot only)
    
    private var limitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.permCoPilot)
                Text("Configurar limites")
                    .font(.seniorSubheadline)
                    .foregroundColor(.textPrimary)
            }
            
            Text("Estos limites se enviaran a Lorenzo para su aprobacion.")
                .font(.seniorCaption)
                .foregroundColor(.textSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Limite de transferencia: $\(Int(transferLimit))")
                    .font(.seniorBody)
                    .foregroundColor(.textPrimary)
                Slider(value: $transferLimit, in: 500...10000, step: 500)
                    .tint(.permCoPilot)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Limite de retiro diario: $\(Int(withdrawalLimit))")
                    .font(.seniorBody)
                    .foregroundColor(.textPrimary)
                Slider(value: $withdrawalLimit, in: 500...5000, step: 500)
                    .tint(.permCoPilot)
            }
        }
        .seniorCard()
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Client Approval Popup (fullscreen, shown to client)

struct ClientApprovalPopup: View {
    
    let request: CaregiverRequest
    let onApprove: () -> Void
    let onDeny: () -> Void
    
    @State private var showPermissions = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    
                    // Header with icon
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(request.permissionLevel.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: request.permissionLevel.icon)
                                .font(.system(size: 36))
                                .foregroundColor(request.permissionLevel.color)
                        }
                        
                        Text("Tu cuidador solicita acceso")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.textPrimary)
                            .multilineTextAlignment(.center)
                        
                        // Permission level badge
                        Text(request.permissionLevel.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(request.permissionLevel.color)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    // Description
                    Text(request.permissionLevel.clientDescription)
                        .font(.seniorBody)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                    
                    // Permissions list
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Permisos que otorgaras:")
                            .font(.seniorSmall)
                            .foregroundColor(.textPrimary)
                        
                        ForEach(request.permissionLevel.permissions, id: \.self) { perm in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(request.permissionLevel.color)
                                Text(perm)
                                    .font(.seniorCaption)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(request.permissionLevel.color.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    // Limits info (if Co-Pilot)
                    if request.permissionLevel == .fullCoPilot {
                        VStack(spacing: 10) {
                            if let limit = request.transferLimit {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .foregroundColor(.statusRed)
                                    Text("Limite de transferencia:")
                                        .font(.seniorCaption)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text("$\(Int(limit))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.statusRed)
                                }
                            }
                            if let limit = request.withdrawalLimit {
                                HStack {
                                    Image(systemName: "banknote.fill")
                                        .foregroundColor(.statusRed)
                                    Text("Limite de retiro diario:")
                                        .font(.seniorCaption)
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text("$\(Int(limit))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.statusRed)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.statusRed.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.statusOrange)
                            Text("No podras modificar estos limites sin aprobacion de tu cuidador")
                                .font(.system(size: 13))
                                .foregroundColor(.statusOrange)
                        }
                    }
                    
                    // Buttons
                    VStack(spacing: 10) {
                        Button(action: onApprove) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.shield.fill")
                                Text("Aceptar")
                            }
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(request.permissionLevel.color)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        Button(action: onDeny) {
                            Text("No, gracias")
                                .font(.seniorBody)
                                .foregroundColor(.statusRed)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                    }
                }
                .padding(24)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                .padding(.horizontal, 16)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .transition(.opacity)
    }
}
