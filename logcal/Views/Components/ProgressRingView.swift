//
//  ProgressRingView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ProgressRingView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            Circle()
                .stroke(Theme.cardBorder(colorScheme: colorScheme).opacity(0.8), lineWidth: 8)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: ringProgress)
            
            Text("\(displayPercent)%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.primaryText(colorScheme: colorScheme))
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.75)
        .padding()
}
