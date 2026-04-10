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

    @AppStorage("letraGrande") private var letraGrande: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    settingsSection
                }
                .padding(.bottom, 32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
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

    private var settingsSection: some View {
        VStack(spacing: 12) {
            letraGrandeRow
            profileRow(icon: "moon.fill", title: "Modo oscuro", value: "Desactivado")
            profileRow(icon: "bell.fill", title: "Notificaciones", value: "Activadas")
            profileRow(icon: "lock.fill", title: "Seguridad", value: "PIN activado")
        }
        .padding(.horizontal, 20)
    }

    private var letraGrandeRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 20))
                    .foregroundColor(Color.brandBlue)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Texto más grande")
                        .font(.seniorBody)
                        .foregroundColor(Color.textPrimary)
                    Text("Aumenta la letra en toda la app")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $letraGrande)
                    .tint(Color.brandBlue)
                    .labelsHidden()
                    .accessibilityLabel("Texto más grande")
                    .accessibilityValue(letraGrande ? "Activado" : "Desactivado")
            }

            // Vista previa en tiempo real
            HStack(spacing: 12) {
                Text("Aa")
                    .font(.system(size: letraGrande ? 34 : 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color.brandBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Hola, Lorenzo")
                        .font(.system(size: letraGrande ? 20 : 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                    Text("Balance: $3,469.52")
                        .font(.system(size: letraGrande ? 17 : 13, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                }
                Spacer()
            }
            .padding(14)
            .background(Color.brandBlue.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeInOut(duration: 0.25), value: letraGrande)
        }
        .seniorCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Texto más grande, \(letraGrande ? "activado" : "desactivado"). Vista previa: Hola Lorenzo, Balance 3469 pesos.")
        .accessibilityHint("Activa para ver letras más grandes en toda la app")
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