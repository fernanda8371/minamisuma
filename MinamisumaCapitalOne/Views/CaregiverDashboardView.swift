//
//  CaregiverDashboardView.swift
//  MinamisumaCapitalOne
//
//  Dashboard for caregivers — overview of safety mode, alerts, behavior, and movimientos
//

import SwiftUI
import SwiftData

// MARK: - Mock Data

private let mockMovimientos: [Movimiento] = [
    Movimiento(comercio: "Walmart Supercenter", monto: 847.50, fecha: "9 Abr", hora: "14:32", esDeposito: false, descripcion: "Compra de despensa semanal en Walmart"),
    Movimiento(comercio: "Farmacia Guadalajara", monto: 356.00, fecha: "9 Abr", hora: "11:15", esDeposito: false, descripcion: "Medicamentos recetados"),
    Movimiento(comercio: "Pension IMSS", monto: 8500.00, fecha: "8 Abr", hora: "06:00", esDeposito: true, descripcion: "Deposito de pension mensual"),
    Movimiento(comercio: "CFE Luz", monto: 420.00, fecha: "7 Abr", hora: "09:45", esDeposito: false, descripcion: "Pago de recibo de luz"),
    Movimiento(comercio: "Retiro ATM Banamex", monto: 2000.00, fecha: "7 Abr", hora: "16:20", esDeposito: false, descripcion: "Retiro en cajero automatico"),
    Movimiento(comercio: "Soriana", monto: 523.80, fecha: "6 Abr", hora: "13:10", esDeposito: false, descripcion: "Compra en supermercado"),
    Movimiento(comercio: "Transferencia recibida", monto: 1500.00, fecha: "5 Abr", hora: "10:00", esDeposito: true, descripcion: "Transferencia de familiar"),
    Movimiento(comercio: "Retiro ATM HSBC", monto: 3000.00, fecha: "5 Abr", hora: "15:45", esDeposito: false, descripcion: "Retiro inusual — monto elevado"),
    Movimiento(comercio: "Retiro ATM Banorte", monto: 2500.00, fecha: "5 Abr", hora: "16:02", esDeposito: false, descripcion: "Segundo retiro en menos de 20 minutos"),
    Movimiento(comercio: "Telmex", monto: 389.00, fecha: "4 Abr", hora: "08:30", esDeposito: false, descripcion: "Pago de telefono e internet")
]

struct CaregiverDashboardView: View {
    
    @Bindable var safetyController: SafetyModeController
    @State private var showLogoutConfirm = false
    @State private var showRequestSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Elder info card
                    elderInfoCard
                    
                    // Safety mode status card
                    statusCard
                    
                    // Quick actions
                    quickActions
                    
                    // Behavior events timeline
                    if !safetyController.behaviorEvents.isEmpty {
                        behaviorTimeline
                    }
                    
                    // Movimientos section (visible when safety mode active)
                    if safetyController.isActive {
                        movimientosSection
                    } else {
                        movimientosLockedSection
                    }
                    
                    // Safety mode config (if active)
                    if safetyController.isActive {
                        activeConfigSection
                    }
                    
                    // Demo button
                    demoSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Panel de Cuidador")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        Image(systemName: "arrow.right.square.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .alert("Cambiar de rol", isPresented: $showLogoutConfirm) {
                Button("Cambiar") {
                    UserDefaults.standard.removeObject(forKey: "userRole")
                    NotificationCenter.default.post(name: .roleDidChange, object: nil)
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Volveras a la pantalla de seleccion de rol.")
            }
            .sheet(isPresented: $showRequestSheet) {
                CaregiverRequestSheet(safetyController: safetyController)
            }
        }
    }
    
    // MARK: - Elder Info Card
    
    private var elderInfoCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.brandBlue.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.brandBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Lorenzo")
                    .font(.seniorHeadline)
                    .foregroundColor(.textPrimary)
                Text("Familiar supervisado")
                    .font(.seniorCaption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Circle()
                    .fill(Color.statusGreen)
                    .frame(width: 10, height: 10)
                Text("En linea")
                    .font(.system(size: 12))
                    .foregroundColor(.statusGreen)
            }
        }
        .seniorCard()
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(safetyController.isActive ? Color.statusGreen.opacity(0.15) : Color.statusOrange.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: safetyController.isActive ? "shield.checkered" : "shield.slash.fill")
                        .font(.system(size: 28))
                        .foregroundColor(safetyController.isActive ? .statusGreen : .statusOrange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Modo de Apoyo")
                        .font(.seniorHeadline)
                        .foregroundColor(.textPrimary)
                    
                    if safetyController.hasPendingCaregiverRequest {
                        Text("Solicitud pendiente — esperando aprobacion de Lorenzo")
                            .font(.seniorCaption)
                            .foregroundColor(.statusOrange)
                    } else {
                        Text(safetyController.isActive ? "Activo y protegiendo" : "No activado")
                            .font(.seniorBody)
                            .foregroundColor(safetyController.isActive ? .statusGreen : .textSecondary)
                    }
                }
                
                Spacer()
            }
            
            if safetyController.isActive, let activatedAt = safetyController.config.activatedAt {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    Text("Activo desde \(activatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.seniorCaption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                }
            }
            
            // Pending request banner
            if safetyController.hasPendingCaregiverRequest {
                HStack(spacing: 8) {
                    Image(systemName: "hourglass")
                        .foregroundColor(.statusOrange)
                    Text("Esperando que Lorenzo acepte la solicitud")
                        .font(.seniorSmall)
                        .foregroundColor(.statusOrange)
                    Spacer()
                }
                .padding(12)
                .background(Color.statusOrange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Behavior flags count
            let recentCount = safetyController.behaviorEvents.filter {
                $0.timestamp.timeIntervalSinceNow > -86400
            }.count
            
            if recentCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.statusOrange)
                    Text("\(recentCount) alertas en las ultimas 24 horas")
                        .font(.seniorSmall)
                        .foregroundColor(.statusOrange)
                    Spacer()
                }
                .padding(12)
                .background(Color.statusOrange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .seniorCard()
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            if safetyController.isActive {
                quickActionButton(
                    icon: "shield.slash.fill",
                    title: "Desactivar",
                    color: .statusRed
                ) {
                    safetyController.deactivateSafetyMode()
                }
            } else if safetyController.hasPendingCaregiverRequest {
                quickActionButton(
                    icon: "hourglass",
                    title: "Pendiente",
                    color: .statusOrange
                ) {
                    // Already pending
                }
            } else {
                quickActionButton(
                    icon: "shield.checkered",
                    title: "Solicitar",
                    color: .statusGreen
                ) {
                    showRequestSheet = true
                }
            }
            
            quickActionButton(
                icon: "trash",
                title: "Limpiar alertas",
                color: .textSecondary
            ) {
                safetyController.clearEvents()
            }
        }
    }
    
    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.seniorSmall)
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Behavior Timeline
    
    private var behaviorTimeline: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Actividad Detectada")
                    .font(.seniorSubheadline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(safetyController.behaviorEvents.count) eventos")
                    .font(.seniorCaption)
                    .foregroundColor(.textSecondary)
            }
            
            let sortedEvents = safetyController.behaviorEvents.sorted { $0.timestamp > $1.timestamp }
            ForEach(sortedEvents.prefix(10)) { event in
                HStack(spacing: 12) {
                    VStack {
                        Circle()
                            .fill(colorForFlag(event.flag))
                            .frame(width: 12, height: 12)
                    }
                    .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: event.flag.icon)
                                .font(.system(size: 16))
                                .foregroundColor(colorForFlag(event.flag))
                            
                            Text(event.flag.rawValue)
                                .font(.seniorSmall)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text(event.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        
                        Text(event.detail)
                            .font(.seniorCaption)
                            .foregroundColor(.textSecondary)
                        
                        if let amount = event.amount {
                            Text("$\(Int(amount))")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.statusRed)
                        }
                    }
                }
                .padding(12)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Movimientos (when safety mode active)
    
    private var movimientosSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.brandBlue)
                Text("Movimientos de Lorenzo")
                    .font(.seniorSubheadline)
                    .foregroundColor(.textPrimary)
                Spacer()
            }
            
            ForEach(mockMovimientos) { mov in
                HStack(alignment: .top, spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(mov.esDeposito ? Color.statusGreen.opacity(0.15) : Color.textSecondary.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: mov.esDeposito ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(mov.esDeposito ? .statusGreen : .textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(mov.comercio)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("\(mov.fecha), \(mov.hora)")
                            .font(.seniorCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Text(mov.esDeposito ? "+$\(Int(mov.monto))" : "-$\(Int(mov.monto))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(mov.esDeposito ? .statusGreen : .textPrimary)
                }
                .padding(12)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Movimientos Locked
    
    private var movimientosLockedSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundColor(.textSecondary.opacity(0.4))
            
            Text("Movimientos no disponibles")
                .font(.seniorSubheadline)
                .foregroundColor(.textPrimary)
            
            Text("Activa el Modo de Apoyo para ver los movimientos de Lorenzo. El debe aceptar la solicitud.")
                .font(.seniorBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
    
    // MARK: - Active Config
    
    private var activeConfigSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Configuracion Activa")
                .font(.seniorSubheadline)
                .foregroundColor(.textPrimary)
            
            configRow(icon: "arrow.up.circle.fill", label: "Limite de transferencia", value: "$\(Int(safetyController.config.transferLimit))")
            configRow(icon: "banknote.fill", label: "Limite de retiro diario", value: "$\(Int(safetyController.config.dailyWithdrawalLimit))")
            configRow(icon: "checkmark.shield.fill", label: "Aprobacion requerida", value: safetyController.config.requireTransactionApproval ? "Si" : "No")
            configRow(icon: "bell.badge.fill", label: "Notificar familiar", value: safetyController.config.notifyTrustedContact ? "Si" : "No")
        }
        .seniorCard()
    }
    
    private func configRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.brandBlue)
                .frame(width: 28)
            
            Text(label)
                .font(.seniorBody)
                .foregroundColor(.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.brandBlue)
        }
    }
    
    // MARK: - Demo Section
    
    private var demoSection: some View {
        VStack(spacing: 12) {
            Text("Demostracion")
                .font(.seniorCaption)
                .foregroundColor(.textSecondary)
            
            SeniorPrimaryButton(
                "Simular comportamiento inusual",
                icon: "wand.and.stars",
                color: .statusOrange
            ) {
                safetyController.simulateUnusualBehavior()
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
    
    private func colorForFlag(_ flag: BehaviorFlag) -> Color {
        switch flag {
        case .unusualWithdrawal: return .statusRed
        case .repeatedTransfer: return .statusOrange
        case .confusionPattern: return .permCoPilot
        case .largeUnusualPurchase: return .statusRed
        case .rapidSuccessiveTransactions: return .statusOrange
        }
    }
}
