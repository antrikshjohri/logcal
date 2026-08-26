//
//  FirebaseBootstrap.swift
//  logcal
//
//  Allows app intents to safely use Firebase-backed services.
//

import Foundation
import FirebaseCore

enum FirebaseBootstrap {
    static func configureIfNeeded() {
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
    }
}

