//
//  RetirarView.swift
//  MinamisumaCapitalOne
//
//  Pantalla de retiro de efectivo
//

import SwiftUI

// MARK: - Tipo de Retiro

enum TipoRetiro: String, CaseIterable {
    case cajero   = "Cajero ATM"
    case sucursal = "Sucursal"
    case celular  = "Celular"

    var icon: String {
        switch self {
        case .cajero:   return "banknote.fill"
        case .sucursal: return "building.columns.fill"
        case .celular:  return "iphone"
        }
    }
}

// MARK: - Retirar View

struct RetirarView: View {

    let card = BankCard(
        holderName: "Lorenzo",
        cardType: "Amazon Platinium",
        lastFour: "1234",
        firstFour: "4756",
        balance: 3469.52,
        network: "visa"
    )

    @State private var tipoRetiro: TipoRetiro = .cajero
    @State private var montoTexto: String = ""
    @State private var showConfirmacion: Bool = false

    private let montosSugeridos: [Double] = [200, 500, 1000, 2000]

    var montoValido: Bool {
        guard let valor = Double(montoTexto), valor > 0, valor <= card.balance else { return false }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cardSection
                tipoRetiroSection
                montoSection
                infoBanner
                SeniorPrimaryButton(
                    "Confirmar retiro",
                    icon: "banknote.fill",
                    color: montoValido ? .black : Color(.systemGray3)
                ) {
                    if montoValido { showConfirmacion = true }
                }
                .disabled(!montoValido)
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Retirar")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Retiro confirmado", isPresented: $showConfirmacion) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text("Tu retiro de \(montoFormateado) fue registrado.")
        }
    }

    // MARK: - Card Section

    private var cardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.brandBlue)
                    .font(.system(size: 18))

                Text("VISA ****  ****  ****  \(card.lastFour)")
                    .font(.seniorBody)
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )

            HStack(spacing: 6) {
                Text("Balance disponible:")
                    .font(.seniorCaption)
                    .foregroundColor(.textSecondary)
                Text(balanceFormatted)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
        }
    }

    // MARK: - Tipo de Retiro

    private var tipoRetiroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("¿Cómo deseas retirar?")
                .font(.seniorCaption)
                .foregroundColor(.textSecondary)

            HStack(spacing: 10) {
                ForEach(TipoRetiro.allCases, id: \.self) { tipo in
                    tipoButton(tipo)
                }
            }
        }
    }

    private func tipoButton(_ tipo: TipoRetiro) -> some View {
        let isSelected = tipoRetiro == tipo

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                tipoRetiro = tipo
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: tipo.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? .white : .textSecondary)

                Text(tipo.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Color.black : Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Monto Section

    private var montoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("¿Cuánto deseas retirar?")
                .font(.seniorCaption)
                .foregroundColor(.textSecondary)

            // Montos sugeridos
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(montosSugeridos, id: \.self) { sugerido in
                    Button {
                        montoTexto = String(Int(sugerido))
                    } label: {
                        Text("$\(Int(sugerido))")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(montoTexto == String(Int(sugerido)) ? .white : .textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(montoTexto == String(Int(sugerido)) ? Color.black : Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Campo manual
            HStack {
                Text("$")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textSecondary)

                TextField("Otro monto", text: $montoTexto)
                    .font(.system(size: 20, weight: .semibold))
                    .keyboardType(.numberPad)
                    .foregroundColor(.textPrimary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        montoValido ? Color.brandBlue : Color(.systemGray4),
                        lineWidth: montoValido ? 1.5 : 1
                    )
            )
        }
    }

    // MARK: - Info Banner

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(.brandBlue)

            Text("Puedes retirar hasta **$5,000** por día en cajeros automáticos.")
                .font(.seniorCaption)
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.brandBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private var balanceFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: card.balance)) ?? "$0.00"
    }

    private var montoFormateado: String {
        guard let valor = Double(montoTexto) else { return "$0" }
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: valor)) ?? "$0"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RetirarView()
    }
}
