//
//  ProfileView.swift
//  logcal
//
//  Created by Antriksh Johri on 15/12/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile")
                    .font(.largeTitle)
                    .foregroundColor(.primary)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}

