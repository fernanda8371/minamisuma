//
//  MovimientosView.swift
//  MinamisumaCapitalOne
//
//  Pantalla de movimientos con popup "¿Qué es esto?" y letra adaptable
//

import SwiftUI

// MARK: - Movimiento Model (placeholder — datos se agregan después)

struct Movimiento: Identifiable {
    let id = UUID()
    let comercio: String
    let monto: Double
    let fecha: String
    let hora: String
    let esDeposito: Bool
    let descripcion: String
}

// MARK: - Movimientos View

struct MovimientosView: View {

    let card = BankCard(
        holderName: "Lorenzo",
        cardType: "Amazon Platinium",
        lastFour: "9018",
        firstFour: "4756",
        balance: 3469.52,
        network: "visa"
    )

    @AppStorage("letraGrande") private var letraGrande: Bool = false

    let movimientos: [Movimiento] = [
        Movimiento(comercio: "Walmart Supercenter", monto: 1245.80, fecha: "9 Abr 2026", hora: "14:32", esDeposito: false,
                   descripcion: "Compra en Walmart Supercenter. Este cargo corresponde a una compra realizada en la tienda con tu tarjeta. Si no la reconoces, puedes reportarla."),
        Movimiento(comercio: "Deposito Nomina", monto: 15000.00, fecha: "8 Abr 2026", hora: "08:00", esDeposito: true,
                   descripcion: "Deposito de nomina quincenal. Este ingreso corresponde al pago de tu empresa depositado automaticamente a tu cuenta."),
        Movimiento(comercio: "CFE Luz", monto: 487.00, fecha: "7 Abr 2026", hora: "10:15", esDeposito: false,
                   descripcion: "Pago del recibo de luz (CFE). Se realizo el pago de tu servicio de energia electrica correspondiente al bimestre actual."),
        Movimiento(comercio: "Farmacia Guadalajara", monto: 362.50, fecha: "6 Abr 2026", hora: "17:45", esDeposito: false,
                   descripcion: "Compra en Farmacia Guadalajara. Este cargo es por medicamentos o productos adquiridos en la farmacia."),
        Movimiento(comercio: "Transferencia a Maria", monto: 2000.00, fecha: "5 Abr 2026", hora: "12:00", esDeposito: false,
                   descripcion: "Transferencia enviada a Maria Garcia. Enviaste esta cantidad desde tu cuenta a un contacto de confianza."),
        Movimiento(comercio: "Pension IMSS", monto: 8500.00, fecha: "1 Abr 2026", hora: "06:00", esDeposito: true,
                   descripcion: "Deposito de pension del IMSS. Este ingreso corresponde al pago mensual de tu pension por parte del seguro social."),
        Movimiento(comercio: "Soriana Super", monto: 876.30, fecha: "31 Mar 2026", hora: "11:20", esDeposito: false,
                   descripcion: "Compra en Soriana. Este cargo corresponde a compras de despensa realizadas en la tienda."),
        Movimiento(comercio: "Telmex Internet", monto: 599.00, fecha: "30 Mar 2026", hora: "09:00", esDeposito: false,
                   descripcion: "Pago del servicio de internet y telefono Telmex. Se cobro automaticamente el servicio del mes."),
        Movimiento(comercio: "Retiro cajero", monto: 3000.00, fecha: "28 Mar 2026", hora: "16:10", esDeposito: false,
                   descripcion: "Retiro de efectivo en cajero automatico. Se retiraron $3,000 pesos en un cajero cercano a tu domicilio."),
        Movimiento(comercio: "Deposito familiar", monto: 5000.00, fecha: "25 Mar 2026", hora: "13:30", esDeposito: true,
                   descripcion: "Deposito recibido de un familiar. Alguien de tu familia realizo una transferencia a tu cuenta.")
    ]

    @State private var selectedMovimiento: Movimiento? = nil
    @State private var showPopup = false

    private var fontScale: CGFloat { letraGrande ? 1.3 : 1.0 }
    private func fs(_ base: CGFloat) -> CGFloat { ceil(base * fontScale) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cardSection
                infoBanner

                if movimientos.isEmpty {
                    emptyStateView
                } else {
                    movimientosSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mis movimientos")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPopup) {
            if let mov = selectedMovimiento {
                MovimientoPopupView(movimiento: mov, isPresented: $showPopup, fontScale: fontScale)
            }
        }
    }

    // MARK: - Card Section (tamaño fijo — representa tarjeta física)

    private var cardSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    ZStack {
                        Circle().fill(Color.blue.opacity(0.7)).frame(width: 160, height: 160).offset(x: 100, y: -40)
                        Circle().fill(Color.blue.opacity(0.5)).frame(width: 120, height: 120).offset(x: 40, y: 20)
                        Circle().fill(Color.black.opacity(0.6)).frame(width: 180, height: 180).offset(x: 60, y: 30)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(card.holderName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(card.cardType)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                HStack(spacing: 6) {
                    Text(card.firstFour).font(.system(size: 14, weight: .medium, design: .monospaced))
                    Text("••••  ••••").font(.system(size: 14, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    Text(card.lastFour).font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.8))
                HStack(alignment: .bottom) {
                    Text(balanceFormatted)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("VISA")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .italic().foregroundColor(.white)
                }
            }
            .padding(20)
        }
        .frame(height: 170)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tarjeta \(card.cardType) de \(card.holderName). Balance: \(balanceFormatted)")
    }

    private var balanceFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: card.balance)) ?? "$0.00"
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: fs(17)))
                .foregroundColor(.brandBlue)
                .accessibilityHidden(true)

            Text("Recuerda que puedes tocar: **¿Qué es esto?** en cualquier movimiento")
                .font(.system(size: fs(14), design: .rounded))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .background(Color.brandBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Consejo: toca el botón ¿Qué es esto? en cualquier movimiento para ver una explicación")
    }

    // MARK: - Movimientos List

    private var movimientosSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(movimientos.enumerated()), id: \.element.id) { index, mov in
                MovimientoRow(movimiento: mov, fontScale: fontScale) {
                    selectedMovimiento = mov
                    showPopup = true
                }
                if index < movimientos.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color(.systemGray3))
                .accessibilityHidden(true)

            Text("Sin movimientos")
                .font(.system(size: fs(22), weight: .semibold, design: .rounded))
                .foregroundColor(.textPrimary)

            Text("Aquí aparecerán tus transacciones")
                .font(.system(size: fs(16), design: .rounded))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sin movimientos. Aquí aparecerán tus transacciones.")
    }
}

// MARK: - Movimiento Row

struct MovimientoRow: View {

    let movimiento: Movimiento
    let fontScale: CGFloat
    let onQueEsEsto: () -> Void

    private func fs(_ base: CGFloat) -> CGFloat { ceil(base * fontScale) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(movimiento.comercio)
                        .font(.system(size: fs(17), weight: .semibold, design: .rounded))
                        .foregroundColor(.textPrimary)

                    Text("\(movimiento.fecha), \(movimiento.hora)")
                        .font(.system(size: fs(14), design: .rounded))
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Text(montoFormatted)
                    .font(.system(size: fs(17), weight: .bold, design: .rounded))
                    .foregroundColor(movimiento.esDeposito ? .statusGreen : .textPrimary)
            }

            Button(action: onQueEsEsto) {
                Text("¿Qué es esto?")
                    .font(.system(size: fs(14), weight: .medium, design: .rounded))
                    .foregroundColor(.brandBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.brandBlue.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("¿Qué es esto? \(movimiento.comercio)")
            .accessibilityHint("Toca para ver una explicación de este movimiento")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(movimiento.comercio), \(movimiento.esDeposito ? "depósito" : "cargo") de \(montoFormatted), \(movimiento.fecha)")
    }

    private var montoFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        let amount = f.string(from: NSNumber(value: abs(movimiento.monto))) ?? "$0.00"
        return movimiento.esDeposito ? "+\(amount)" : "−\(amount)"
    }
}

// MARK: - Movimiento Popup

struct MovimientoPopupView: View {

    let movimiento: Movimiento
    @Binding var isPresented: Bool
    let fontScale: CGFloat

    private func fs(_ base: CGFloat) -> CGFloat { ceil(base * fontScale) }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 20) {
                Text("Te explicamos este movimiento")
                    .font(.system(size: fs(22), weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text(movimiento.descripcion)
                    .font(.system(size: fs(17), design: .rounded))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(5)

                Spacer()

                Button(action: { isPresented = false }) {
                    Text("Confirmar")
                        .font(.system(size: fs(17), weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Confirmar, entendido")
                .accessibilityHint("Cierra esta explicación")

                Button(action: { isPresented = false }) {
                    Text("No reconozco este cobro")
                        .font(.system(size: fs(16), design: .rounded))
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .accessibilityLabel("No reconozco este cobro")
                .accessibilityHint("Reporta este movimiento como desconocido")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { MovimientosView() }
}
