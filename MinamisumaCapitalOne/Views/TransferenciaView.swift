//
//  TransferenciaView.swift
//  MinamisumaCapitalOne
//
//  Transferencia con detección automática CLABE/tarjeta
//  + accesibilidad completa + letra adaptable
//

import SwiftUI

// MARK: - Tipo de cuenta detectado

private enum TipoCuentaDetectado: Equatable {
    case clabe       // 18 dígitos
    case tarjeta     // 16 dígitos
    case incompleto

    var etiqueta: String {
        switch self {
        case .clabe:      return "CLABE interbancaria"
        case .tarjeta:    return "Número de tarjeta"
        case .incompleto: return ""
        }
    }
    var icono: String {
        switch self {
        case .clabe:      return "building.columns.fill"
        case .tarjeta:    return "creditcard.fill"
        case .incompleto: return ""
        }
    }
    var color: Color {
        switch self {
        case .clabe:      return .brandTeal
        case .tarjeta:    return .brandBlue
        case .incompleto: return .clear
        }
    }
}

// MARK: - Transferencia View

struct TransferenciaView: View {

    let card = BankCard(
        holderName: "Lorenzo",
        cardType: "Amazon Platinium",
        lastFour: "1234",
        firstFour: "4756",
        balance: 3469.52,
        network: "visa"
    )

    @AppStorage("letraGrande") private var letraGrande: Bool = false

    @State private var nombreBeneficiario: String = ""
    @State private var numeroCuenta: String = ""
    @State private var monto: String = ""
    @State private var confirmarMonto: String = ""
    @State private var guardarContacto: Bool = false
    @State private var showConfirmacion: Bool = false

    private func fs(_ base: CGFloat) -> CGFloat { letraGrande ? ceil(base * 1.3) : base }

    // MARK: - Detección automática

    private var tipoCuenta: TipoCuentaDetectado {
        let n = numeroCuenta.filter(\.isNumber).count
        switch n {
        case 18: return .clabe
        case 16: return .tarjeta
        default: return .incompleto
        }
    }

    private var digitosIngresados: Int { numeroCuenta.filter(\.isNumber).count }

    private var montoCoincide: Bool { !monto.isEmpty && monto == confirmarMonto }
    private var montoNoCoincide: Bool { !confirmarMonto.isEmpty && monto != confirmarMonto }

    private var formularioValido: Bool {
        tipoCuenta != .incompleto &&
        !nombreBeneficiario.trimmingCharacters(in: .whitespaces).isEmpty &&
        !monto.isEmpty &&
        montoCoincide
    }

    var montoEnLetras: String {
        guard let valor = Double(monto.replacingOccurrences(of: "$", with: "")),
              valor > 0 else { return "" }
        return numeroALetras(valor) + " pesos mexicanos"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                cardSelectorSection
                beneficiarioSection
                cuentaDestinoSection
                montoSection
                guardarContactoRow

                SeniorPrimaryButton(
                    "Confirmar transferencia",
                    color: formularioValido ? .black : Color(.systemGray3)
                ) {
                    if formularioValido { showConfirmacion = true }
                }
                .disabled(!formularioValido)
                .padding(.top, 4)
                .accessibilityLabel("Confirmar transferencia")
                .accessibilityHint(formularioValido
                    ? "Toca dos veces para enviar la transferencia"
                    : "Completa todos los campos para activar este botón")
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
    }

    // MARK: - Card Selector

    private var cardSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "creditcard")
                    .foregroundColor(.brandBlue)
                    .font(.system(size: fs(18)))
                    .accessibilityHidden(true)

                Text("VISA ****  ****  ****  \(card.lastFour)")
                    .font(.system(size: fs(17), design: .rounded))
                    .foregroundColor(.textPrimary)

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(minHeight: 52)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tarjeta VISA, terminación \(card.lastFour)")
            .accessibilityHint("Toca para cambiar de tarjeta")

            HStack(spacing: 6) {
                Text("Balance disponible:")
                    .font(.system(size: fs(14), design: .rounded))
                    .foregroundColor(.textSecondary)
                Text(balanceFormatted)
                    .font(.system(size: fs(15), weight: .semibold, design: .rounded))
                    .foregroundColor(.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Balance disponible: \(balanceFormatted)")
        }
    }

    // MARK: - Beneficiario

    private var beneficiarioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("¿A quién le envías?")
                    .font(.system(size: fs(14), design: .rounded))
                    .foregroundColor(.textSecondary)
                Spacer()
                Button("De mis contactos") {}
                    .font(.system(size: fs(14), weight: .semibold, design: .rounded))
                    .foregroundColor(.brandBlue)
                    .accessibilityLabel("Buscar en mis contactos")
                    .accessibilityHint("Abre tu lista de contactos guardados")
            }

            TextField("Nombre del destinatario", text: $nombreBeneficiario)
                .font(.system(size: fs(17), design: .rounded))
                .padding(16)
                .frame(minHeight: 52)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
                .accessibilityLabel("Nombre del destinatario")
                .accessibilityHint("Ingresa el nombre completo de la persona a quien le envías")

            if !nombreBeneficiario.trimmingCharacters(in: .whitespaces).isEmpty {
                Text(nombreBeneficiario)
                    .font(.system(size: fs(24), weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.easeInOut(duration: 0.2), value: nombreBeneficiario)
                    .accessibilityHidden(true)
            }
        }
    }

    // MARK: - Cuenta Destino

    private var cuentaDestinoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CLABE o número de tarjeta")
                .font(.system(size: fs(14), design: .rounded))
                .foregroundColor(.textSecondary)
                .accessibilityHidden(true)

            TextField("16 dígitos (tarjeta) · 18 dígitos (CLABE)", text: $numeroCuenta)
                .font(.system(size: fs(16), weight: .medium, design: .monospaced))
                .keyboardType(.numberPad)
                .padding(16)
                .frame(minHeight: 52)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            tipoCuenta == .incompleto ? Color(.systemGray4) : tipoCuenta.color,
                            lineWidth: tipoCuenta == .incompleto ? 1 : 1.5
                        )
                )
                .onChange(of: numeroCuenta) { _, nuevo in
                    let soloNum = nuevo.filter(\.isNumber)
                    if soloNum.count > 18 { numeroCuenta = String(soloNum.prefix(18)) }
                }
                .accessibilityLabel("Número de cuenta o CLABE")
                .accessibilityHint("Ingresa 16 dígitos para tarjeta o 18 dígitos para CLABE interbancaria")
                .accessibilityValue(
                    tipoCuenta == .incompleto
                        ? "\(digitosIngresados) dígitos ingresados"
                        : "Detectado como \(tipoCuenta.etiqueta)"
                )

            // Badge de detección / contador
            if tipoCuenta != .incompleto {
                HStack(spacing: 8) {
                    Image(systemName: tipoCuenta.icono)
                        .font(.system(size: fs(13), weight: .semibold))
                        .accessibilityHidden(true)
                    Text(tipoCuenta.etiqueta)
                        .font(.system(size: fs(13), weight: .semibold, design: .rounded))
                }
                .foregroundColor(tipoCuenta.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(tipoCuenta.color.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.2), value: tipoCuenta.etiqueta)
                .accessibilityLabel("Tipo detectado: \(tipoCuenta.etiqueta)")
            } else if digitosIngresados > 0 {
                Text("\(digitosIngresados) / 16 tarjeta · 18 CLABE")
                    .font(.system(size: fs(13), design: .rounded))
                    .foregroundColor(Color(.systemGray3))
                    .transition(.opacity)
                    .accessibilityLabel("\(digitosIngresados) dígitos ingresados. Se necesitan 16 para tarjeta o 18 para CLABE.")
            }
        }
    }

    // MARK: - Monto

    private var montoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monto a transferir")
                .font(.system(size: fs(14), design: .rounded))
                .foregroundColor(.textSecondary)
                .accessibilityHidden(true)

            // Monto
            HStack {
                Text("$")
                    .font(.system(size: fs(20), weight: .semibold, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .accessibilityHidden(true)
                TextField("0.00", text: $monto)
                    .font(.system(size: fs(20), weight: .semibold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .foregroundColor(.textPrimary)
            }
            .padding(16)
            .frame(minHeight: 52)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
            .accessibilityLabel("Monto a transferir")
            .accessibilityHint("Ingresa la cantidad en pesos")
            .accessibilityValue(monto.isEmpty ? "Vacío" : "\(monto) pesos")

            // Confirmar monto
            HStack {
                Text("$")
                    .font(.system(size: fs(20), weight: .semibold, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .accessibilityHidden(true)
                TextField("Confirmar monto", text: $confirmarMonto)
                    .font(.system(size: fs(20), weight: .semibold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .foregroundColor(
                        confirmarMonto.isEmpty ? .textPrimary :
                        (montoCoincide ? .statusGreen : .statusRed)
                    )
            }
            .padding(16)
            .frame(minHeight: 52)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        confirmarMonto.isEmpty ? Color(.systemGray4) :
                        (montoCoincide ? Color.statusGreen : Color.statusRed),
                        lineWidth: confirmarMonto.isEmpty ? 1 : 1.5
                    )
            )
            .accessibilityLabel("Confirmar monto")
            .accessibilityHint("Vuelve a ingresar la misma cantidad para confirmar")
            .accessibilityValue(
                confirmarMonto.isEmpty ? "Vacío" :
                (montoCoincide ? "Los montos coinciden" : "Los montos no coinciden")
            )

            // Retroalimentación de coincidencia
            if montoCoincide {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.statusGreen)
                        .accessibilityHidden(true)
                    Text("Los montos coinciden")
                        .font(.system(size: fs(13), design: .rounded))
                        .foregroundColor(.statusGreen)
                }
                .transition(.opacity)
            } else if montoNoCoincide {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.statusRed)
                        .accessibilityHidden(true)
                    Text("Los montos no coinciden")
                        .font(.system(size: fs(13), design: .rounded))
                        .foregroundColor(.statusRed)
                }
                .transition(.opacity)
            }

            // Monto en letras
            if !montoEnLetras.isEmpty {
                Text(montoEnLetras)
                    .font(.system(size: fs(13), design: .rounded))
                    .foregroundColor(.textSecondary)
                    .italic()
                    .padding(.leading, 4)
                    .transition(.opacity)
                    .animation(.easeInOut, value: montoEnLetras)
                    .accessibilityLabel(montoEnLetras)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: montoCoincide)
    }

    // MARK: - Guardar Contacto

    private var guardarContactoRow: some View {
        Button(action: { guardarContacto.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: guardarContacto ? "checkmark.square.fill" : "square")
                    .font(.system(size: fs(22)))
                    .foregroundColor(guardarContacto ? .brandBlue : Color(.systemGray3))

                Text("Guardar contacto")
                    .font(.system(size: fs(17), design: .rounded))
                    .foregroundColor(.textPrimary)

                Spacer()
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .accessibilityLabel("Guardar contacto")
        .accessibilityValue(guardarContacto ? "Activado" : "Desactivado")
        .accessibilityHint("Activa para guardar a esta persona en tus contactos para futuras transferencias")
    }

    // MARK: - Helpers

    private var balanceFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"
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
            return resto == 0 ? centenas[c] : "\(centenas[c]) \(menorMil(resto))"
        }

        var resultado = ""
        if entero >= 1000 {
            let miles = entero / 1000
            resultado = miles == 1 ? "mil" : "\(menorMil(miles)) mil"
            let resto = entero % 1000
            if resto > 0 { resultado += " \(menorMil(resto))" }
        } else {
            resultado = menorMil(entero)
        }
        if centavos > 0 { resultado += " con \(centavos)/100" }
        return resultado.isEmpty ? "cero" : resultado.capitalized
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { TransferenciaView() }
}
