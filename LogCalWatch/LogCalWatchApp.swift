//
//  LogCalWatchApp.swift
//  LogCalWatch
//
//  Created by Antriksh Johri on 17/08/26.
//

import SwiftUI

@main
struct LogCalWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(connectivity)
        }
    }
}
