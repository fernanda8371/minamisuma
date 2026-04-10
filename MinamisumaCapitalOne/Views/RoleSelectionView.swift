//
//  RoleSelectionView.swift
//  MinamisumaCapitalOne
//
//  Sign-in screen — choose between Cliente or Cuidador
//

import SwiftUI

enum UserRole: String, Equatable {
    case cliente = "cliente"
    case cuidador = "cuidador"
}

struct RoleSelectionView: View {
    
    @Binding var selectedRole: UserRole?
    @State private var animateCards = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.10, blue: 0.22), Color(red: 0.08, green: 0.18, blue: 0.38)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo / branding
                headerSection
                
                Spacer()
                    .frame(height: 50)
                
                // Role cards
                VStack(spacing: 16) {
                    roleCard(
                        role: .cliente,
                        icon: "person.fill",
                        title: "Soy Cliente",
                        subtitle: "Accede a tu cuenta bancaria, realiza transacciones y administra tus finanzas",
                        color: .brandBlue
                    )
                    
                    roleCard(
                        role: .cuidador,
                        icon: "stethoscope",
                        title: "Soy Cuidador",
                        subtitle: "Supervisa la cuenta de tu familiar, revisa alertas y administra el modo de apoyo",
                        color: .brandTeal
                    )
                }
                .padding(.horizontal, 24)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 30)
                
                Spacer()
                
                // Footer
                Text("Tu informacion esta protegida")
                    .font(.seniorCaption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            
            Text("Bienvenido")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Selecciona como deseas ingresar")
                .font(.seniorBody)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Role Card
    
    private func roleCard(role: UserRole, icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedRole = role
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.seniorCaption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(color)
            }
            .padding(20)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}
