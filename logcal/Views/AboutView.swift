//
//  AboutView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Text("About LogCal")
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
        .navigationTitle("About LogCal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}

