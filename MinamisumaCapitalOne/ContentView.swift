//
//  ContentView.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import SwiftUI
import SwiftData

extension Notification.Name {
    static let roleDidChange = Notification.Name("roleDidChange")
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedRole: UserRole? = {
        if let saved = UserDefaults.standard.string(forKey: "userRole") {
            return UserRole(rawValue: saved)
        }
        return nil
    }()
    @State private var safetyController = SafetyModeController()

    var body: some View {
        Group {
            if let role = selectedRole {
                switch role {
                case .cliente:
                    NavigationStack {
                        HomeView(safetyController: safetyController)
                    }
                case .cuidador:
                    CaregiverDashboardView(safetyController: safetyController)
                }
            } else {
                RoleSelectionView(selectedRole: $selectedRole)
            }
        }
        .onChange(of: selectedRole) { _, newValue in
            if let newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: "userRole")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .roleDidChange)) { _ in
            selectedRole = nil
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, AlertEvent.self], inMemory: true)
}
