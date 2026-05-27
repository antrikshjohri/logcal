//
//  ProgressRingView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ProgressRingView: View {
    @Environment(\.colorScheme) private var colorScheme
    let progress: Double
    var size: CGFloat = 80
    var strokeWidth: CGFloat = 8
    var ringColor: Color? = nil
    
    private var ringProgress: Double { min(max(progress, 0), 1.0) }
    private var color: Color { ringColor ?? Theme.accentBlue }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.primaryGreen.opacity(colorScheme == .dark ? 0.15 : 0.1), lineWidth: strokeWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: ringProgress)
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.75)
        .padding()
}
