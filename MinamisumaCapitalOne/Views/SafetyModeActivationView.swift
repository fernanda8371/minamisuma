//
//  SafetyModeActivationView.swift
//  MinamisumaCapitalOne
//
//  "Would you like to activate support mode?" — activation & config UI
//

import SwiftUI

struct SafetyModeActivationView: View {
    
    @Bindable var safetyController: SafetyModeController
    @Environment(\.dismiss) private var dismiss
    
    @State private var transferLimit: Double = 5000
    @State private var withdrawalLimit: Double = 2000
    @State private var requireApproval: Bool = true
    @State private var notifyContact: Bool = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header illustration
                    headerSection
                    
                    // Detected patterns (if any)
                    if !safetyController.behaviorEvents.isEmpty {
                        detectedPatternsSection
                    }
                    
                    // What support mode does
                    featuresSection
                    
                    // Configuration
                    configSection
                    
                    // Activate button
                    SeniorPrimaryButton(
                        "Activar Modo de Apoyo",
                        icon: "shield.checkered",
                        color: .brandBlue
                    ) {
                        safetyController.config.transferLimit = transferLimit
                        safetyController.config.dailyWithdrawalLimit = withdrawalLimit
                        safetyController.config.requireTransactionApproval = requireApproval
                        safetyController.config.notifyTrustedContact = notifyContact
                        safetyController.activateSafetyMode(by: "user")
                        dismiss()
                    }
                    
                    // Skip button
                    Button("Ahora no") {
                        dismiss()
                    }
                    .font(.seniorBody)
                    .foregroundColor(.textSecondary)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Modo de Apoyo")
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
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.statusOrange.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 44))
                    .foregroundColor(.statusOrange)
            }
            
            Text("Detectamos actividad inusual")
                .font(.seniorHeadline)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Te sugerimos activar el Modo de Apoyo para proteger tu cuenta con limites y notificaciones a tu familia.")
                .font(.seniorBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Detected Patterns
    
    private var detectedPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actividad detectada")
                .font(.seniorSubheadline)
                .foregroundColor(.textPrimary)
            
            let recentEvents = Array(safetyController.behaviorEvents.suffix(5))
            ForEach(recentEvents) { event in
                HStack(spacing: 12) {
                    Image(systemName: event.flag.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.statusOrange)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.flag.rawValue)
                            .font(.seniorSmall)
                            .foregroundColor(.textPrimary)
                        Text(event.detail)
                            .font(.seniorCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.statusOrange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Features
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("El Modo de Apoyo te protege")
                .font(.seniorSubheadline)
                .foregroundColor(.textPrimary)
            
            featureRow(icon: "checkmark.shield.fill", text: "Aprobacion requerida para transacciones grandes", color: .brandBlue)
            featureRow(icon: "bell.badge.fill", text: "Tu familiar de confianza recibe notificaciones", color: .statusOrange)
            featureRow(icon: "arrow.down.circle.fill", text: "Limites de transferencia y retiro ajustados", color: .statusGreen)
            featureRow(icon: "lock.shield.fill", text: "Tu siempre mantienes el control total", color: .brandTeal)
        }
        .padding(18)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
    
    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.seniorBody)
                .foregroundColor(.textPrimary)
        }
    }
    
    // MARK: - Configuration
    
    private var configSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuracion")
                .font(.seniorSubheadline)
                .foregroundColor(.textPrimary)
            
            // Transfer limit
            VStack(alignment: .leading, spacing: 8) {
                Text("Limite de transferencia")
                    .font(.seniorCaption)
                    .foregroundColor(.textSecondary)
                
                HStack {
                    Text("$\(Int(transferLimit))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                
                Slider(value: $transferLimit, in: 500...10000, step: 500)
                    .tint(.brandBlue)
            }
            
            // Withdrawal limit
            VStack(alignment: .leading, spacing: 8) {
                Text("Limite de retiro diario")
                    .font(.seniorCaption)
                    .foregroundColor(.textSecondary)
                
                HStack {
                    Text("$\(Int(withdrawalLimit))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                
                Slider(value: $withdrawalLimit, in: 500...5000, step: 500)
                    .tint(.brandBlue)
            }
            
            // Toggles
            Toggle(isOn: $requireApproval) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.brandBlue)
                    Text("Requerir aprobacion")
                        .font(.seniorBody)
                }
            }
            .tint(.brandBlue)
            
            Toggle(isOn: $notifyContact) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundColor(.statusOrange)
                    Text("Notificar a familiar")
                        .font(.seniorBody)
                }
            }
            .tint(.brandBlue)
        }
        .seniorCard()
    }
}
