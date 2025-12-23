//
//  AppError.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

enum AppError: LocalizedError {
    case apiKeyNotFound
    case invalidURL
    case invalidHTTPResponse
    case apiError(statusCode: Int, message: String)
    case parseError
    case dataConversionError
    case networkError(Error)
    case audioConfigurationError(String)
    case speechRecognitionError(String)
    case permissionDenied(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotFound:
            return "API key not found. Please check your Secrets.plist file."
        case .invalidURL:
            return "Invalid URL. Please check your configuration."
        case .invalidHTTPResponse:
            return "Invalid HTTP response received."
        case .apiError(let statusCode, let message):
            return "API error (Status \(statusCode)): \(message)"
        case .parseError:
            return "Failed to parse response from server."
        case .dataConversionError:
            return "Failed to convert data."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .audioConfigurationError(let message):
            return "Audio configuration error: \(message)"
        case .speechRecognitionError(let message):
            return "Speech recognition error: \(message)"
        case .permissionDenied(let permission):
            return "\(permission) permission denied. Please enable it in Settings."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .apiKeyNotFound:
            return "Make sure Secrets.plist exists and contains OPENAI_API_KEY."
        case .networkError:
            return "Please check your internet connection and try again."
        case .permissionDenied:
            return "Go to Settings > Privacy & Security to enable the required permissions."
        default:
            return "Please try again later."
        }
    }
}

