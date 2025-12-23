//
//  Secrets.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation

struct Secrets {
    static func getAPIKey() throws -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let apiKey = plist["OPENAI_API_KEY"] as? String else {
            throw AppError.apiKeyNotFound
        }
        return apiKey
    }
}

