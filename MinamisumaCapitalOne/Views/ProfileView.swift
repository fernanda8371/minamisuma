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
            profileRow(icon: "textformat.size", title: "Tamaño de texto", value: "Grande")
            profileRow(icon: "moon.fill", title: "Modo oscuro", value: "Desactivado")
            profileRow(icon: "bell.fill", title: "Notificaciones", value: "Activadas")
            profileRow(icon: "lock.fill", title: "Seguridad", value: "PIN activado")
        }
        .padding(.horizontal, 20)
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