//
//  AyudaView.swift
//  MinamisumaCapitalOne
//
//  Pantalla de ayuda con FAQ y contacto
//

import SwiftUI

// MARK: - FAQ Item

struct FAQItem: Identifiable {
    let id = UUID()
    let pregunta: String
    let respuesta: String
}

// MARK: - Ayuda View

struct AyudaView: View {

    @State private var expandedFAQ: UUID? = nil

    private let faqs: [FAQItem] = [
        FAQItem(
            pregunta: "¿Cómo bloqueo mi tarjeta?",
            respuesta: "Puedes bloquear tu tarjeta desde la sección de Seguridad en Configurar perfil, o llamando al número en el reverso de tu tarjeta."
        ),
        FAQItem(
            pregunta: "¿Qué hago si no reconozco un cobro?",
            respuesta: "Ve a Movimientos, toca el movimiento desconocido y selecciona \"No reconozco este cobro\". Un asesor te contactará en menos de 24 horas."
        ),
        FAQItem(
            pregunta: "¿Cuánto tiempo tarda una transferencia?",
            respuesta: "Las transferencias SPEI se procesan el mismo día hábil si se realizan antes de las 5:00 pm. Las realizadas después se procesan el siguiente día hábil."
        ),
        FAQItem(
            pregunta: "¿Cómo agrego a un familiar de confianza?",
            respuesta: "Ve a la sección \"Familia\" en el menú principal. Ahí puedes agregar un contacto de confianza para que te apoye con tu cuenta."
        ),
        FAQItem(
            pregunta: "¿Cómo activo la guía por voz?",
            respuesta: "Toca el botón \"Activa la guía por voz\" en la pantalla principal. Puedes activarla o desactivarla en cualquier momento."
        ),
        FAQItem(
            pregunta: "¿Cuál es mi límite de retiro diario?",
            respuesta: "El límite de retiro en cajeros es de $5,000 pesos por día. Para retiros mayores, acude a cualquier sucursal con tu identificación oficial."
        ),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                llamarBancoSection
                asesorSection
                faqSection
                reportarSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Ayuda")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Llamar al Banco

    private var llamarBancoSection: some View {
        Button(action: {
            if let url = URL(string: "tel://8001234567") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 52, height: 52)
                    Image(systemName: "phone.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Llama al banco")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("800 123 4567 — Disponible 24/7")
                        .font(.seniorCaption)
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.brandBlue, Color.brandTeal],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Chatear con Asesor

    private var asesorSection: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.brandBlue.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Image(systemName: "message.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.brandBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Chatear con un asesor")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("Tiempo de espera aprox. 5 minutos")
                        .font(.seniorCaption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preguntas Frecuentes

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preguntas frecuentes")
                .font(.seniorSubheadline)
                .foregroundColor(.textPrimary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(faqs.enumerated()), id: \.element.id) { index, faq in
                    FAQRow(
                        item: faq,
                        isExpanded: expandedFAQ == faq.id
                    ) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedFAQ = expandedFAQ == faq.id ? nil : faq.id
                        }
                    }

                    if index < faqs.count - 1 {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }

    // MARK: - Reportar Problema

    private var reportarSection: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.statusRed.opacity(0.10))
                        .frame(width: 52, height: 52)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.statusRed)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reportar un problema")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("Fraudes, cobros no reconocidos o errores")
                        .font(.seniorCaption)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FAQ Row

struct FAQRow: View {

    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Text(item.pregunta)
                        .font(.seniorBody)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(item.respuesta)
                    .font(.seniorCaption)
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AyudaView()
    }
}
