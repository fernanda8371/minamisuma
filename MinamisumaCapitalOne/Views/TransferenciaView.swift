//
//  TransferenciaView.swift
//  MinamisumaCapitalOne
//
//  Pantalla de envío de dinero / transferencia
//

import SwiftUI

// MARK: - Tipo de Transacción

enum TipoTransaccion: String, CaseIterable {
    case numeroTarjeta = "Número\nde tarjeta"
    case cuenta        = "Cuenta"
    case cheque        = "Cheque"

    var icon: String {
        switch self {
        case .numeroTarjeta: return "creditcard.fill"
        case .cuenta:        return "person.fill"
        case .cheque:        return "building.columns.fill"
        }
    }
}

// MARK: - Transferencia View

struct TransferenciaView: View {

    var safetyController: SafetyModeController?

    let card = BankCard(
        holderName: "Lorenzo",
        cardType: "Amazon Platinium",
        lastFour: "1234",
        firstFour: "4756",
        balance: 3469.52,
        network: "visa"
    )

    @State private var tipoSeleccionado: TipoTransaccion = .numeroTarjeta
    @State private var nombreBeneficiario: String = ""
    @State private var numeroCuenta: String = ""
    @State private var monto: String = ""
    @State private var confirmarMonto: String = ""
    @State private var guardarContacto: Bool = false
    @State private var showConfirmacion: Bool = false
    @State private var showSafetyBlock: Bool = false

    var montoEnLetras: String {
        guard let valor = Double(monto.replacingOccurrences(of: "$", with: "")),
              valor > 0 else { return "" }
        return numeroALetras(valor) + " pesos mexicanos"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cardSelectorSection
                tipoTransaccionSection
                beneficiarioSection
                formSection
                guardarContactoRow

                // Safety mode warning banner
                if let sc = safetyController, sc.isActive {
                    HStack(spacing: 12) {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 18))
                            .foregroundColor(.statusOrange)
                        
                        Text("Modo de Apoyo activo — limite de $\(Int(sc.config.transferLimit)) por transferencia")
                            .font(.seniorCaption)
                            .foregroundColor(.statusOrange)
                    }
                    .padding(14)
                    .background(Color.statusOrange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                SeniorPrimaryButton("Confirmar transferencia", color: .black) {
                    if let sc = safetyController, sc.isActive {
                        let montoValue = Double(monto.replacingOccurrences(of: "$", with: "")) ?? 0
                        if !sc.isTransferAllowed(amount: montoValue) {
                            showSafetyBlock = true
                            return
                        }
                        sc.trackTransfer(to: nombreBeneficiario, amount: montoValue)
                    }
                    showConfirmacion = true
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Transferencia")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Transferencia enviada", isPresented: $showConfirmacion) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text("Tu transferencia fue registrada correctamente.")
        }
        .alert("Transferencia bloqueada", isPresented: $showSafetyBlock) {
            Button("Entendido", role: .cancel) {}
        } message: {
            if let sc = safetyController {
                Text("El Modo de Apoyo limita las transferencias a $\(Int(sc.config.transferLimit)). Contacta a tu familiar de confianza para aprobar esta operacion.")
            }
        }
    }

    // MARK: - Card Selector

    private var cardSelectorSection: some View {
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

    // MARK: - Tipo de Transacción

    private var tipoTransaccionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tipo de transacción")
                .font(.seniorCaption)
                .foregroundColor(.textSecondary)

            HStack(spacing: 10) {
                ForEach(TipoTransaccion.allCases, id: \.self) { tipo in
                    tipoButton(tipo)
                }
            }
        }
    }

    private func tipoButton(_ tipo: TipoTransaccion) -> some View {
        let isSelected = tipoSeleccionado == tipo

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                tipoSeleccionado = tipo
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
                    .lineLimit(2)
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

    // MARK: - Beneficiario

    private var beneficiarioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Elige beneficiario")
                    .font(.seniorCaption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Button("Buscar otro") {}
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brandBlue)
            }

            if !nombreBeneficiario.isEmpty {
                Text(nombreBeneficiario)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
            } else {
                Text("Sin beneficiario")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(.systemGray3))
            }
        }
    }

    // MARK: - Form Fields

    private var formSection: some View {
        VStack(spacing: 12) {
            transferField(placeholder: "Nombre del destinatario", text: $nombreBeneficiario, keyboardType: .default)
            transferField(placeholder: "Número de cuenta o tarjeta", text: $numeroCuenta, keyboardType: .numberPad)
            transferField(placeholder: "$0.00", text: $monto, keyboardType: .decimalPad)
            transferField(placeholder: "Confirmar monto", text: $confirmarMonto, keyboardType: .decimalPad)

            if !montoEnLetras.isEmpty {
                HStack {
                    Text(montoEnLetras)
                        .font(.seniorCaption)
                        .foregroundColor(.textSecondary)
                        .italic()
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.opacity)
            }
        }
    }

    private func transferField(placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .font(.seniorBody)
            .keyboardType(keyboardType)
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }

    // MARK: - Guardar Contacto

    private var guardarContactoRow: some View {
        HStack(spacing: 12) {
            Image(systemName: guardarContacto ? "checkmark.square.fill" : "square")
                .font(.system(size: 22))
                .foregroundColor(guardarContacto ? .brandBlue : Color(.systemGray3))
                .onTapGesture { guardarContacto.toggle() }

            Text("Guardar contacto")
                .font(.seniorBody)
                .foregroundColor(.textPrimary)
                .onTapGesture { guardarContacto.toggle() }

            Spacer()
        }
    }

    // MARK: - Helpers

    private var balanceFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: card.balance)) ?? "$0.00"
    }

    private func numeroALetras(_ valor: Double) -> String {
        let entero = Int(valor)
        let centavos = Int((valor - Double(entero)) * 100)
        let unidades = ["", "un", "dos", "tres", "cuatro", "cinco", "seis", "siete",
                        "ocho", "nueve", "diez", "once", "doce", "trece", "catorce",
                        "quince", "dieciséis", "diecisiete", "dieciocho", "diecinueve"]
        let decenas = ["", "", "veinte", "treinta", "cuarenta", "cincuenta",
                       "sesenta", "setenta", "ochenta", "noventa"]
        let centenas = ["", "cien", "doscientos", "trescientos", "cuatrocientos",
                        "quinientos", "seiscientos", "setecientos", "ochocientos", "novecientos"]

        func menorMil(_ n: Int) -> String {
            if n == 0 { return "" }
            if n < 20 { return unidades[n] }
            if n < 100 {
                let d = n / 10, u = n % 10
                return u == 0 ? decenas[d] : "\(decenas[d]) y \(unidades[u])"
            }
            let c = n / 100, resto = n % 100
            if resto == 0 { return centenas[c] }
            return "\(centenas[c]) \(menorMil(resto))"
        }

        var resultado = ""
        if entero >= 1000 {
            let miles = entero / 1000
            resultado += miles == 1 ? "mil" : "\(menorMil(miles)) mil"
            let resto = entero % 1000
            if resto > 0 { resultado += " \(menorMil(resto))" }
        } else {
            resultado = menorMil(entero)
        }

        if centavos > 0 {
            resultado += " con \(centavos)/100"
        }

        return resultado.isEmpty ? "cero" : resultado.capitalized
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TransferenciaView()
    }
}
