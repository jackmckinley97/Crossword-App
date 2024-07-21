import SwiftUI
import Foundation

struct CrosswordKeyboard: UIViewControllerRepresentable {
    @Binding var text: String
    @Binding var isBlackSquareModeOn: Bool
    var onType: () -> Void
    var onDelete: () -> Void
    var onBlackSquareToggle: () -> Void

    class Coordinator: NSObject {
        var parent: CrosswordKeyboard

        init(_ parent: CrosswordKeyboard) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> KeyboardViewController {
        let keyboardViewController = KeyboardViewController()

        // Pass in the bindings to handle key presses and mode changes
        keyboardViewController.onKeyPress = { key in
            DispatchQueue.main.async {
                if self.isBlackSquareModeOn || self.text == "." {
                    // Handle black square mode behavior
                    self.text = "."
                } else {
                    if key == "backspace" {
                        if self.text == " " {
                            self.onDelete()
                        }
                        self.text = " "
                    } else {
                        self.text = key
                        self.onType()
                    }
                }
            }
        }

        keyboardViewController.onBlackSquareToggle = {
            DispatchQueue.main.async {
                self.onBlackSquareToggle()
            }
        }

        return keyboardViewController
    }

    func updateUIViewController(_ uiViewController: KeyboardViewController, context: Context) {
        // No update needed for this simple example
    }
}
