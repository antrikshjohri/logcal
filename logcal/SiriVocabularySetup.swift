//
//  SiriVocabularySetup.swift
//  logcal
//
//  Sets up Siri vocabulary for LogCal intents
//

import Foundation
import Intents

/// Sets up Siri vocabulary to help Siri recognize LogCal commands
class SiriVocabularySetup {
    
    static func setup() {
        print("DEBUG: Setting up Siri vocabulary...")
        
        let vocabulary = INVocabulary.shared()
        
        // Register app-specific phrases that Siri should recognize
        // These help Siri understand when users want to use LogCal
        
        let intentPhrases = NSOrderedSet(array: [
            "log my calories",
            "log calories",
            "log meal",
            "log breakfast",
            "log lunch",
            "log dinner",
            "log snack",
            "log my meal",
            "log calories in LogCal",
            "log meal in LogCal"
        ])
        
        // Note: We use .workoutActivityName as a workaround since there's no
        // specific category for custom intents. This is a common pattern.
        vocabulary.setVocabularyStrings(intentPhrases, of: .workoutActivityName)
        
        print("DEBUG: Siri vocabulary setup complete")
    }
    
    /// Note: Intent donation is not needed - the shortcut appears automatically in Shortcuts app
    /// when the Intent Definition file is properly configured. Manual donation with nil parameters
    /// causes errors. Users can add the shortcut via Shortcuts app or by using Siri.
    static func donateIntent() {
        // Intent donation removed - not needed and causes errors
        // The shortcut will appear in Shortcuts app automatically
        print("DEBUG: Intent donation skipped - shortcut appears automatically in Shortcuts app")
    }
}

