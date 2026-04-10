//
//  ContentView.swift
//  MinamisumaCapitalOne
//
//  Created by Luis Garcia on 4/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .modelContainer(for: [Item.self, AlertEvent.self])
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, AlertEvent.self], inMemory: true)
}
