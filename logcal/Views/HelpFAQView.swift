//
//  HelpFAQView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct HelpFAQView: View {
    var body: some View {
        VStack {
            Text("Help & FAQ")
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
        .navigationTitle("Help & FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
        NavigationView {
        HelpFAQView()
    }
}

