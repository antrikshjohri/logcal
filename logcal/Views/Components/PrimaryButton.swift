//
//  PrimaryButton.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    init(title: String, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isDisabled ? .gray : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isDisabled ? Color.gray.opacity(0.3) : Theme.accentBlue)
                .cornerRadius(25) // Pill shape
        }
        .disabled(isDisabled)
    }
}

#Preview {
    PrimaryButton(title: "Save Goal") {
        print("Tapped")
    }
    .padding()
}

