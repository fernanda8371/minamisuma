//
//  VoiceGuideView.swift
//  MinamisumaCapitalOne
//
//  Created by Daniela Caiceros on 10/04/26.
//


//
//  VoiceGuideView.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import SwiftUI

struct VoiceGuideView: View {
    @State private var isVoiceEnabled: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    toggleSection
                    
                    if isVoiceEnabled {
                        ExplanationView(
                            title: "¿Cómo funciona?",
                            explanation: "Cada vez que realices una acción, escucharás una confirmación en voz alta. Esto te ayuda a estar seguro de lo que sucede en tu cuenta."
                        )
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: isVoiceEnabled)
                .padding(.bottom, 32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Guía por Voz")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            let iconColor: Color = isVoiceEnabled ? Color.brandTeal : Color.textSecondary.opacity(0.3)

            Image(systemName: "speaker.wave.2.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(iconColor)

            let statusText = isVoiceEnabled ? "Guía por voz activada" : "Guía por voz desactivada"
            Text(statusText)
                .font(.seniorHeadline)
                .foregroundColor(Color.textPrimary)

            Text("La guía por voz te describe cada acción que realizas. Por ejemplo: \"Acabas de pagar tu recibo de luz.\"")
                .font(.seniorBody)
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 32)
    }

    private var toggleSection: some View {
        Toggle(isOn: $isVoiceEnabled) {
            HStack(spacing: 14) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.brandTeal)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activar Guía por Voz")
                        .font(.seniorSubheadline)
                        .foregroundColor(Color.textPrimary)
                    Text("Escucha descripciones de cada acción")
                        .font(.seniorCaption)
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .tint(Color.brandTeal)
        .seniorCard()
        .padding(.horizontal, 20)
    }
}