//
//  RetirarView.swift
//  MinamisumaCapitalOne
//
//  Retiro sin tarjeta — flujo 2 pasos + accesibilidad completa + letra adaptable
//

import SwiftUI

struct RetirarView: View {

    var safetyController: SafetyModeController?

    let card = BankCard(
        holderName: "Lorenzo",
        cardType: "Amazon Platinium",
        lastFour: "1234",
        firstFour: "4756",
        balance: 3469.52,
        network: "visa"
    )

    @AppStorage("letraGrande") private var letraGrande: Bool = false

    @State private var paso: Int = 1
    @State private var montoTexto: String = ""
    @State private var codigoGenerado: String = ""
    @State private var segundosRestantes: Int = 600
    @State private var timerActivo: Bool = false
    @State private var showCancelAlert: Bool = false
    @State private var showSafetyBlock: Bool = false
    @State private var timerTask: Task<Void, Never>?

    private let montosSugeridos: [Double] = [200, 500, 1000, 2000]

    private func fs(_ base: CGFloat) -> CGFloat { letraGrande ? ceil(base * 1.3) : base }

    var montoValido: Bool {
        guard let valor = Double(montoTexto), valor > 0, valor <= card.balance else { return false }
        return true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if paso == 1 { paso1 } else { paso2 }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Retiro sin tarjeta")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: timerActivo) { _, activo in
            timerTask?.cancel()
            if activo {
                timerTask = Task {
                    while !Task.isCancelled && segundosRestantes > 0 {
                        try? await Task.sleep(for: .seconds(1))
                        guard !Task.isCancelled else { break }
                        segundosRestantes -= 1
                    }
                    timerActivo = false
                }
            }
        }
        .onDisappear {
            timerTask?.cancel()
        }
        .alert("Cancelar retiro?", isPresented: $showCancelAlert) {
            Button("Si, cancelar", role: .destructive) { resetearFlujo() }
            Button("Continuar", role: .cancel) {}
        } message: {
            Text("El codigo se eliminara y tendras que generar uno nuevo.")
        }
        .alert("Retiro bloqueado", isPresented: $showSafetyBlock) {
            Button("Entendido", role: .cancel) {}
        } message: {
            if let sc = safetyController {
                Text("El Modo de Apoyo limita los retiros diarios a $\(Int(sc.config.dailyWithdrawalLimit)). Contacta a tu familiar de confianza para aprobar esta operacion.")
            }
        }
    }

    // MARK: - Paso 1: elegir monto

    private var paso1: some View {
        VStack(spacing: 20) {
            cardSection
            explicacionBanner
            montoSection

            // Safety mode warning banner
            if let sc = safetyController, sc.isActive {
                HStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: fs(18)))
                        .foregroundColor(.statusOrange)

                    Text("Modo de Apoyo activo — limite diario de $\(Int(sc.config.dailyWithdrawalLimit))")
                        .font(.system(size: fs(13), design: .rounded))
                        .foregroundColor(.statusOrange)
                }
                .padding(14)
                .background(Color.statusOrange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            SeniorPrimaryButton(
                "Generar codigo de retiro",
                icon: "lock.open.fill",
                color: montoValido ? .black : Color(.systemGray3)
            ) {
                if montoValido {
                    if let sc = safetyController, sc.isActive {
                        let montoValue = Double(montoTexto) ?? 0
                        if !sc.isWithdrawalAllowed(amount: montoValue) {
                            showSafetyBlock = true
                            return
                        }
                        sc.trackWithdrawal(amount: montoValue)
                    }
                    generarCodigo()
                }
            }
            .disabled(!montoValido)
            .padding(.top, 4)
            .accessibilityLabel("Generar codigo de retiro")
            .accessibilityHint(montoValido
                ? "Genera un codigo de 6 digitos para usar en el cajero"
                : "Selecciona o escribe un monto valido para continuar")
        }
    }

    // MARK: - Paso 2: codigo generado

    private var paso2: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: fs(52)))
                    .foregroundColor(.statusGreen)
                    .accessibilityHidden(true)

                Text("Tu codigo esta listo")
                    .font(.system(size: fs(22), weight: .bold, design: .rounded))
                    .foregroundColor(.textPrimary)

                Text("Monto: \(montoFormateado)")
                    .font(.system(size: fs(17), design: .rounded))
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tu codigo esta listo. Monto a retirar: \(montoFormateado)")

            VStack(spacing: 14) {
                Text("Codigo de retiro")
                    .font(.system(size: fs(14), weight: .medium, design: .rounded))
                    .foregroundColor(.textSecondary)

                Text(codigoFormateado)
                    .font(.system(size: fs(44), weight: .bold, design: .monospaced))
                    .foregroundColor(.textPrimary)
                    .tracking(letraGrande ? 6 : 8)

                HStack(spacing: 6) {
                    Image(systemName: segundosRestantes > 60 ? "clock" : "exclamationmark.clock")
                        .font(.system(size: fs(14)))
                        .foregroundColor(colorTemporizador)
                        .accessibilityHidden(true)

                    Text("Valido por \(tiempoFormateado)")
                        .font(.system(size: fs(14), weight: .medium, design: .rounded))
                        .foregroundColor(colorTemporizador)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(28)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tu codigo de retiro es \(codigoGenerado.map { String($0) }.joined(separator: " ")). Valido por \(tiempoFormateado).")

            instruccionesSection

            Button(action: { showCancelAlert = true }) {
                Text("Cancelar retiro")
                    .font(.system(size: fs(17), design: .rounded))
                    .foregroundColor(.statusRed)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
            }
            .accessibilityLabel("Cancelar retiro")
            .accessibilityHint("Elimina el codigo y regresa a elegir monto")
        }
    }

    // MARK: - Card Section

    private var cardSection: some View {
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
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.systemGray4), lineWidth: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Tarjeta VISA terminacion \(card.lastFour)")
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

    // MARK: - Explicacion Banner

    private var explicacionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: fs(18)))
                .foregroundColor(.brandBlue)
                .accessibilityHidden(true)

            Text("Elige el monto y la app genera un **codigo temporal**. Ve a cualquier cajero, selecciona \"Retiro sin tarjeta\" e ingresalo.")
                .font(.system(size: fs(14), design: .rounded))
                .foregroundColor(.textSecondary)
        }
        .padding(14)
        .background(Color.brandBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Como funciona: elige el monto, la app genera un codigo temporal. Ve a cualquier cajero, selecciona Retiro sin tarjeta e ingresalo.")
    }

    // MARK: - Monto Section

    private var montoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Cuanto deseas retirar?")
                .font(.system(size: fs(14), design: .rounded))
                .foregroundColor(.textSecondary)
                .accessibilityHidden(true)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(montosSugeridos, id: \.self) { sugerido in
                    let key = String(Int(sugerido))
                    let isSelected = montoTexto == key

                    Button {
                        montoTexto = key
                    } label: {
                        Text("$\(Int(sugerido))")
                            .font(.system(size: fs(18), weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 56)
                            .background(isSelected ? Color.black : Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(Int(sugerido)) pesos")
                    .accessibilityHint("Toca dos veces para seleccionar este monto")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }

            HStack {
                Text("$")
                    .font(.system(size: fs(20), weight: .semibold, design: .rounded))
                    .foregroundColor(.textSecondary)
                    .accessibilityHidden(true)

                TextField("Otro monto", text: $montoTexto)
                    .font(.system(size: fs(20), weight: .semibold, design: .rounded))
                    .keyboardType(.numberPad)
                    .foregroundColor(.textPrimary)
            }
            .padding(16)
            .frame(minHeight: 56)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(montoValido ? Color.brandBlue : Color(.systemGray4),
                            lineWidth: montoValido ? 1.5 : 1)
            )
            .accessibilityLabel("Ingresar otro monto")
            .accessibilityHint("Escribe la cantidad que deseas retirar en pesos")
            .accessibilityValue(montoTexto.isEmpty ? "Vacio" : "\(montoTexto) pesos")

            Text("Maximo $5,000 por retiro")
                .font(.system(size: fs(13), design: .rounded))
                .foregroundColor(Color(.systemGray3))
                .padding(.leading, 4)
        }
    }

    // MARK: - Instrucciones

    private var instruccionesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Como usarlo?")
                .font(.system(size: fs(14), design: .rounded))
                .foregroundColor(.textSecondary)
                .padding(.bottom, 14)

            ForEach(instrucciones.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.brandBlue)
                            .frame(width: 30, height: 30)
                        Text("\(i + 1)")
                            .font(.system(size: fs(13), weight: .bold))
                            .foregroundColor(.white)
                    }
                    .accessibilityHidden(true)

                    Text(instrucciones[i])
                        .font(.system(size: fs(15), design: .rounded))
                        .foregroundColor(.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.vertical, 10)

                if i < instrucciones.count - 1 {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: 1, height: 10)
                        .padding(.leading, 14)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Instrucciones. Paso 1: \(instrucciones[0]). Paso 2: \(instrucciones[1]). Paso 3: \(instrucciones[2]). Paso 4: \(instrucciones[3]).")
    }

    private let instrucciones = [
        "Ve a cualquier cajero automatico.",
        "Selecciona la opcion \"Retiro sin tarjeta\".",
        "Ingresa el codigo de 6 digitos mostrado arriba.",
        "Confirma el monto y retira tu efectivo."
    ]

    // MARK: - Helpers

    private func generarCodigo() {
        codigoGenerado = String(format: "%06d", Int.random(in: 100000...999999))
        segundosRestantes = 600
        timerActivo = true
        withAnimation(.easeInOut(duration: 0.3)) { paso = 2 }
    }

    private func resetearFlujo() {
        timerActivo = false
        codigoGenerado = ""
        montoTexto = ""
        segundosRestantes = 600
        withAnimation { paso = 1 }
    }

    private var codigoFormateado: String {
        guard codigoGenerado.count == 6 else { return codigoGenerado }
        let mid = codigoGenerado.index(codigoGenerado.startIndex, offsetBy: 3)
        return "\(codigoGenerado[..<mid]) \(codigoGenerado[mid...])"
    }

    private var tiempoFormateado: String {
        String(format: "%d:%02d", segundosRestantes / 60, segundosRestantes % 60)
    }

    private var colorTemporizador: Color {
        if segundosRestantes > 120 { return .textSecondary }
        if segundosRestantes > 60  { return .statusOrange }
        return .statusRed
    }

    private var balanceFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: card.balance)) ?? "$0.00"
    }

    private var montoFormateado: String {
        guard let valor = Double(montoTexto) else { return "$0" }
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: valor)) ?? "$0"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { RetirarView() }
}
