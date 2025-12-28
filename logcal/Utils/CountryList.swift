//
//  CountryList.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import Foundation
import Combine

struct Country: Identifiable, Hashable {
    let id: String // ISO country code
    let name: String // Localized country name
    
    static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class CountryList: ObservableObject {
    @Published var countries: [Country] = []
    @Published var searchText: String = ""
    
    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return countries
        }
        return countries.filter { country in
            country.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    init() {
        loadCountries()
    }
    
    private func loadCountries() {
        var countryList: [Country] = []
        
        // Get all ISO country codes (using iOS 16+ API if available, fallback to deprecated)
        let regionCodes: [String]
        if #available(iOS 16, *) {
            regionCodes = Locale.Region.isoRegions.map { $0.identifier }
        } else {
            regionCodes = Locale.isoRegionCodes
        }
        
        for code in regionCodes {
            if let name = Locale.current.localizedString(forRegionCode: code) {
                countryList.append(Country(id: code, name: name))
            }
        }
        
        // Sort alphabetically by name
        countries = countryList.sorted { $0.name < $1.name }
    }
    
    func countryName(for code: String) -> String? {
        return countries.first { $0.id == code }?.name
    }
}

