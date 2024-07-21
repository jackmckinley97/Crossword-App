//
//  KeyboardViewControllerRepresentable.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 7/5/24.
//

import SwiftUI
import UIKit

struct KeyboardViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> KeyboardViewController {
        return KeyboardViewController()
    }

    func updateUIViewController(_ uiViewController: KeyboardViewController, context: Context) {
        // No update needed for this simple example
    }
}
