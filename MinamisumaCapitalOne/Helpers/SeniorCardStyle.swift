//
//  SeniorCardStyle.swift
//  MinamisumaCapitalOne
//
//  Created by Daniela Caiceros on 10/04/26.
//

import SwiftUI

// MARK: - Color Palette (High Contrast for Seniors)

extension Color {
    
    // Primary brand
    static let brandNavy = Color(red: 0.05, green: 0.10, blue: 0.22)
    static let brandBlue = Color(red: 0.15, green: 0.40, blue: 0.75)
    static let brandTeal = Color(red: 0.12, green: 0.58, blue: 0.56)
    
    // Backgrounds
    static let bgPrimary = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let bgCard = Color.white
    static let bgDark = Color(red: 0.05, green: 0.10, blue: 0.22)
    
    // Text (high contrast)
    static let textPrimary = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let textSecondary = Color(red: 0.38, green: 0.40, blue: 0.48)
    static let textOnDark = Color.white
    
    // Status colors (strong, visible)
    static let statusGreen = Color(red: 0.13, green: 0.62, blue: 0.35)
    static let statusOrange = Color(red: 0.88, green: 0.55, blue: 0.10)
    static let statusRed = Color(red: 0.82, green: 0.18, blue: 0.18)
    static let statusBlue = Color(red: 0.15, green: 0.40, blue: 0.75)
    
    // Permission level colors
    static let permViewOnly = Color(red: 0.15, green: 0.40, blue: 0.75)
    static let permAlerts = Color(red: 0.88, green: 0.55, blue: 0.10)
    static let permBills = Color(red: 0.12, green: 0.58, blue: 0.56)
    static let permCoPilot = Color(red: 0.50, green: 0.28, blue: 0.72)
}

// MARK: - Typography (Large, Readable)

extension Font {
    static let seniorTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let seniorHeadline = Font.system(size: 24, weight: .semibold, design: .rounded)
    static let seniorSubheadline = Font.system(size: 20, weight: .medium, design: .rounded)
    static let seniorBody = Font.system(size: 18, weight: .regular, design: .rounded)
    static let seniorCaption = Font.system(size: 16, weight: .regular, design: .rounded)
    static let seniorSmall = Font.system(size: 14, weight: .medium, design: .rounded)
}

// MARK: - Reusable Card Style

struct SeniorCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func seniorCard() -> some View {
        modifier(SeniorCardStyle())
    }
}

// MARK: - Large Accessible Button

struct SeniorPrimaryButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, color: Color = .brandBlue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                }
                Text(title)
                    .font(.seniorSubheadline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .accessibilityLabel(title)
    }
}

// MARK: - Confirmation Banner

struct ConfirmationBanner: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.white)
            
            Text(message)
                .font(.seniorBody)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(18)
        .background(Color.statusGreen)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Explanation Tooltip View

struct ExplanationView: View {
    let title: String
    let explanation: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color.brandBlue)
                Text(title)
                    .font(.seniorSubheadline)
                    .foregroundColor(Color.textPrimary)
            }
            
            Text(explanation)
                .font(.seniorBody)
                .foregroundColor(Color.textSecondary)
                .lineSpacing(4)
        }
        .padding(18)
        .background(Color.brandBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Permission Level Color Helper

extension PermissionLevel {
    var color: Color {
        switch self {
        case .viewOnly: return .permViewOnly
        case .alertsOnly: return .permAlerts
        case .billReminders: return .permBills
        case .fullCoPilot: return .permCoPilot
        }
    }
}
