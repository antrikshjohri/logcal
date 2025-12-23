//
//  logcalApp.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct logcalApp: App {
    init() {
        print("DEBUG: App initializing...")
        // Initialize Firebase
        FirebaseApp.configure()
        print("DEBUG: Firebase configured")
    }
    
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
