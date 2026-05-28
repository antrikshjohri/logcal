//
//  AboutView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack {
            Text("About LogCal")
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: horizontalSizeClass == .regular ? 650 : .infinity)
        .frame(maxWidth: .infinity, alignment: .center)
        .navigationTitle("About LogCal")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

