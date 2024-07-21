//
//  PlayView.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 12/17/23.
//

import SwiftUI
import Foundation

struct KeyboardViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> KeyboardViewController {
        return KeyboardViewController()
    }

    func updateUIViewController(_ uiViewController: KeyboardViewController, context: Context) {
        // No update needed for this simple example
    }
}

struct PlayView: View {
    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            VStack {
                Spacer()
                KeyboardViewControllerRepresentable()
                    .frame(height: 200) // Adjust the height to fit three rows of keys
                Rectangle()
                    .frame(height: 40) // Adjust this height to control how much the keyboard is pushed up
                    .foregroundColor(.clear) // Make the rectangle invisible
            }
        }
    }
}

#Preview {
    PlayView()
}



