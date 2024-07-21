//
//  CreateSettingsView.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 12/17/23.
//

import SwiftUI
import Foundation

struct CreateSettingsView: View {
    @State private var gridSize: Double = 4

    var body: some View {
        ZStack
        {
            Color.mainBackground.ignoresSafeArea()
            VStack {
                Slider(value: $gridSize, in: 4...15, step: 1)
                    .padding()
                
                Text("Grid Size: \(Int(gridSize))")
                    .padding()
                
                NavigationLink(destination: CreateCrosswordView(gridSize: Int(gridSize))) {
                    Text("Ready")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
    }
}

#Preview {
    CreateSettingsView()
}
