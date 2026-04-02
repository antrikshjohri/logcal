//
//  MacrosCaptionLine.swift
//  logcal
//

import SwiftUI

/// One-line macros with explicit labels and grams: **P: 9g · C: 3g · F: 4g**
/// Used for history rows, post-log preview items, and meal detail/edit breakdowns so formatting stays consistent.
struct MacrosCaptionLine: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    var font: Font = .caption

    var body: some View {
        Text("P: \(Int(protein))g  ·  C: \(Int(carbs))g  ·  F: \(Int(fat))g")
            .font(font)
            .foregroundColor(.secondary)
    }
}
