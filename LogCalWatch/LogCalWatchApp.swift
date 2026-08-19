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
    @State private var openVoiceLog: Bool = false
    
    var body: some Scene {
        WindowGroup {
            WatchHomeView(openVoiceLogDirectly: $openVoiceLog)
                .environmentObject(connectivity)
                .onOpenURL { url in
                    if url.host == "voice-log" || url.absoluteString.contains("voice-log") {
                        openVoiceLog = true
                    }
                }
        }
    }
}
