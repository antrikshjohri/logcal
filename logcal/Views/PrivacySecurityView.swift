//
//  PrivacySecurityView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct PrivacySecurityView: View {
    var body: some View {
        VStack {
            Text("Privacy & Security")
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        PrivacySecurityView()
    }
}

