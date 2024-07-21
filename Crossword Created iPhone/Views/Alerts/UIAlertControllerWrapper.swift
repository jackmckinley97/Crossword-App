//
//  UIAlertControllerWrapper.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 7/13/24.
//

import SwiftUI
import UIKit

struct UIAlertControllerWrapper: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var title: String
    var message: String
    var textFieldPlaceholder: String
    var onSave: (String) -> Void

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UIAlertControllerWrapper

        init(parent: UIAlertControllerWrapper) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isPresented {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = textFieldPlaceholder
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                isPresented = false
            })
            alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                if let text = alert.textFields?.first?.text, !text.isEmpty {
                    onSave(text)
                }
                isPresented = false
            })
            DispatchQueue.main.async {
                uiViewController.present(alert, animated: true)
            }
        }
    }
}
