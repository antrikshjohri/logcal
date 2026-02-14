//
//  ProgressRingView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ProgressRingView: View {
    /// Progress ratio (e.g. 0.75 = 75%, 1.25 = 125%). Ring caps at 100%; label shows actual %.
    let progress: Double
    var size: CGFloat = 80
    /// Ring color. If nil, uses Theme.accentBlue.
    var ringColor: Color? = nil
    
    private var ringProgress: Double { min(progress, 1.0) }
    private var displayPercent: Int { Int(round(progress * 100)) }
    private var color: Color { ringColor ?? Theme.accentBlue }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Theme.secondaryText.opacity(0.2), lineWidth: 8)
                .frame(width: size, height: size)
            
            // Progress ring (cap at 1.0 so ring doesn't overflow)
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut(duration: 0.5), value: ringProgress)
            
            // Percentage label (can exceed 100%)
            Text("\(displayPercent)%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.75)
        .padding()
}

