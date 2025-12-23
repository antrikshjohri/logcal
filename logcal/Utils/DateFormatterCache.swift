//
//  DateFormatterCache.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

enum DateFormatterCache {
    private static let formattersQueue = DispatchQueue(label: "com.logcal.dateformatters")
    
    // Cached formatters
    private static var mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = Constants.DateFormats.dateStyle
        formatter.timeStyle = Constants.DateFormats.timeStyle
        return formatter
    }()
    
    private static var fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.DateFormats.fullDate
        return formatter
    }()
    
    // Thread-safe access
    static func mediumDate() -> DateFormatter {
        return formattersQueue.sync {
            return mediumDateFormatter
        }
    }
    
    static func fullDate() -> DateFormatter {
        return formattersQueue.sync {
            return fullDateFormatter
        }
    }
    
    // Helper methods for common formatting
    static func formatDate(_ date: Date) -> String {
        return mediumDate().string(from: date)
    }
    
    static func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return fullDate().string(from: date)
        }
    }
}

