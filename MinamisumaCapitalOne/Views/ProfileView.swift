//
//  ProfileView.swift
//  MinamisumaCapitalOne
//
//  Created by Daniela Caiceros on 10/04/26.
//


//
//  ProfileView.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import SwiftUI

struct ProfileView: View {
    
    @Bindable var safetyController: SafetyModeController
    @State private var showSafetyActivation = false
    @State private var showLogoutConfirm = false
    @State private var showApprovalPopup = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection
                
                // Pending caregiver request
                if safetyController.hasPendingCaregiverRequest {
                    pendingRequestBanner
                }
                
                // Safety mode section
                safetyModeSection
                
                settingsSection
                
                // Logout
                logoutSection
            }
            .padding(.bottom, 32)
        }
        .background(Color.bgPrimary)
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSafetyActivation) {
            SafetyModeActivationView(safetyController: safetyController)
        }
        .overlay {
            if showApprovalPopup, let request = safetyController.pendingRequest {
                ClientApprovalPopup(
                    request: request,
                    onApprove: {
                        safetyController.approveCaregiver()
                        showApprovalPopup = false
                    },
                    onDeny: {
                        safetyController.denyCaregiver()
                        showApprovalPopup = false
                    }
                )
                .animation(.easeInOut, value: showApprovalPopup)
            }
        }
        .alert("Cerrar sesion", isPresented: $showLogoutConfirm) {
            Button("Cerrar sesion", role: .destructive) {
                UserDefaults.standard.removeObject(forKey: "userRole")
                NotificationCenter.default.post(name: .roleDidChange, object: nil)
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Volveras a la pantalla de inicio para elegir tu rol.")
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.brandBlue.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundColor(Color.brandBlue)
            }

            Text("Mi Perfil")
                .font(.seniorHeadline)
                .foregroundColor(Color.textPrimary)
        }
        .padding(.top, 24)
    }
    
    // MARK: - Safety Mode Section
    
    private var safetyModeSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(safetyController.isActive ? Color.statusGreen.opacity(0.15) : Color.statusOrange.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: safetyController.isActive ? "shield.checkered" : "shield.lefthalf.filled")
                        .font(.system(size: 22))
                        .foregroundColor(safetyController.isActive ? .statusGreen : .statusOrange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Modo de Apoyo")
                        .font(.seniorBody)
                        .foregroundColor(.textPrimary)

                    if safetyController.isActive, let level = safetyController.activePermissionLevel {
                        Text("\(level.rawValue) — limite $\(Int(safetyController.config.transferLimit))")
                            .font(.seniorCaption)
                            .foregroundColor(level.color)
                    } else {
                        Text(safetyController.isActive
                             ? "Proteccion activa — limite $\(Int(safetyController.config.transferLimit))"
                             : "Protege tu cuenta con limites y alertas")
                            .font(.seniorCaption)
                            .foregroundColor(safetyController.isActive ? .statusGreen : .textSecondary)
                    }
                }

                Spacer()

                Button {
                    if safetyController.isActive {
                        safetyController.deactivateSafetyMode()
                    } else {
                        showSafetyActivation = true
                    }
                } label: {
                    Text(safetyController.isActive ? "Desactivar" : "Activar")
                        .font(.seniorSmall)
                        .foregroundColor(safetyController.isActive ? .statusRed : .white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(safetyController.isActive ? Color.statusRed.opacity(0.15) : Color.brandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .seniorCard()

            // Locked limits warning for Co-Pilot mode
            if !safetyController.clientCanEditLimits {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.statusOrange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Limites bloqueados por Co-Pilot")
                            .font(.seniorSmall)
                            .foregroundColor(.textPrimary)
                        Text("Tu cuidador debe aprobar cambios a los limites de transferencia ($\(Int(safetyController.config.transferLimit))) y retiro ($\(Int(safetyController.config.dailyWithdrawalLimit)))")
                            .font(.seniorCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(14)
                .background(Color.statusOrange.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 20)
    }

    private var settingsSection: some View {
        VStack(spacing: 12) {
            profileRow(icon: "textformat.size", title: "Tamano de texto", value: "Grande")
            profileRow(icon: "moon.fill", title: "Modo oscuro", value: "Desactivado")
            profileRow(icon: "bell.fill", title: "Notificaciones", value: "Activadas")
            profileRow(icon: "lock.fill", title: "Seguridad", value: "PIN activado")
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Pending Caregiver Request

    private var pendingRequestBanner: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                if let request = safetyController.pendingRequest {
                    ZStack {
                        Circle()
                            .fill(request.permissionLevel.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                        Image(systemName: request.permissionLevel.icon)
                            .font(.system(size: 22))
                            .foregroundColor(request.permissionLevel.color)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tu cuidador solicita acceso")
                            .font(.seniorBody)
                            .foregroundColor(.textPrimary)
                        Text(request.permissionLevel.rawValue)
                            .font(.seniorSmall)
                            .foregroundColor(request.permissionLevel.color)
                    }
                }

                Spacer()
            }

            Button {
                showApprovalPopup = true
            } label: {
                Text("Ver solicitud completa")
                    .font(.seniorSmall)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brandTeal)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(18)
        .background(Color.brandTeal.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Logout
    
    private var logoutSection: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.statusRed)
                
                Text("Cerrar sesion")
                    .font(.seniorBody)
                    .foregroundColor(.statusRed)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.textSecondary.opacity(0.5))
            }
            .seniorCard()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
    
    private func profileRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.brandBlue)
                .frame(width: 36)

            Text(title)
                .font(.seniorBody)
                .foregroundColor(Color.textPrimary)

            Spacer()

            Text(value)
                .font(.seniorCaption)
                .foregroundColor(Color.textSecondary)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.textSecondary.opacity(0.5))
        }
        .seniorCard()
    }
}