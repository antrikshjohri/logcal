//
//  PrimaryButton.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.accentBlue)
                .cornerRadius(25) // Pill shape
        }
    }
}

#Preview {
    PrimaryButton(title: "Save Goal") {
        print("Tapped")
    }
    .padding()
}

