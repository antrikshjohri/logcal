//
//  logcalApp.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData

@main
struct logcalApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Log", systemImage: "plus.circle")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "list.bullet")
                    }
            }
            .modelContainer(for: MealEntry.self)
        }
    }
}
