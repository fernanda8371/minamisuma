//
//  MovimientosView.swift
//  MinamisumaCapitalOne
//
//  Pantalla de movimientos/transacciones con popup "¿Qué es esto?"
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

    // Sin datos por ahora — se agregarán después
    let movimientos: [Movimiento] = []

    @State private var selectedMovimiento: Movimiento? = nil
    @State private var showPopup = false

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
                MovimientoPopupView(movimiento: mov, isPresented: $showPopup)
            }
        }
    }

    // MARK: - Card Section

    private var cardSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [.black, Color(red: 0.1, green: 0.1, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(width: 160, height: 160)
                            .offset(x: 100, y: -40)
                        Circle()
                            .fill(Color.blue.opacity(0.5))
                            .frame(width: 120, height: 120)
                            .offset(x: 40, y: 20)
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 180, height: 180)
                            .offset(x: 60, y: 30)
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
                    Text(card.firstFour)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                    Text("••••  ••••")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                    Text(card.lastFour)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.8))

                HStack(alignment: .bottom) {
                    Text(balanceFormatted)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("VISA")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(.white)
                }
            }
            .padding(20)
        }
        .frame(height: 170)
    }

    private var balanceFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: card.balance)) ?? "$0.00"
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 18))
                .foregroundColor(.brandBlue)

            Text("Recuerda que puedes tocar: **¿Qué es esto?** en cualquier movimiento")
                .font(.seniorCaption)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding(14)
        .background(Color.brandBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Movimientos List

    private var movimientosSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(movimientos.enumerated()), id: \.element.id) { index, mov in
                MovimientoRow(movimiento: mov) {
                    selectedMovimiento = mov
                    showPopup = true
                }

                if index < movimientos.count - 1 {
                    Divider()
                        .padding(.leading, 16)
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

            Text("Sin movimientos")
                .font(.seniorHeadline)
                .foregroundColor(.textPrimary)

            Text("Aquí aparecerán tus transacciones")
                .font(.seniorBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Movimiento Row

struct MovimientoRow: View {

    let movimiento: Movimiento
    let onQueEsEsto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(movimiento.comercio)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.textPrimary)

                    Text("\(movimiento.fecha), \(movimiento.hora)")
                        .font(.seniorCaption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Text(montoFormatted)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(movimiento.esDeposito ? .statusGreen : .textPrimary)
            }

            Button(action: onQueEsEsto) {
                Text("¿Qué es esto?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.brandBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.brandBlue.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var montoFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.locale = Locale(identifier: "en_US")
        let amount = formatter.string(from: NSNumber(value: abs(movimiento.monto))) ?? "$0.00"
        return movimiento.esDeposito ? "+\(amount)" : "−\(amount)"
    }
}

// MARK: - Movimiento Popup

struct MovimientoPopupView: View {

    let movimiento: Movimiento
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 20) {
                // Heading
                Text("Te explicamos este movimiento")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.textPrimary)

                // Description
                Text(movimiento.descripcion)
                    .font(.seniorBody)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(5)

                Spacer()

                // Confirm button
                Button(action: { isPresented = false }) {
                    Text("Confirmar")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Unrecognized charge link
                Button(action: { isPresented = false }) {
                    Text("No reconozco este cobro")
                        .font(.seniorBody)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MovimientosView()
    }
}
