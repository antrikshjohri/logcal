//
//  ProgressRingView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ProgressRingView: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Theme.secondaryText.opacity(0.2), lineWidth: 8)
                .frame(width: size, height: size)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Theme.accentBlue,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Percentage label
            Text("\(Int(progress * 100))%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    ProgressRingView(progress: 0.75)
        .padding()
}

