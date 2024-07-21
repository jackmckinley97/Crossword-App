import UIKit

class KeyboardViewController: UIViewController {

    var onKeyPress: ((String) -> Void)?
    var onBlackSquareToggle: (() -> Void)?
    private var blackSquareButton: UIButton?

    // Define the letters for each row
    let topRow = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    let middleRow = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    let bottomRow = ["Z", "X", "C", "V", "B", "N", "M"]
    let blackSquareKey = "black_square"
    let backspaceKey = "backspace"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
    }

    func setupKeyboard() {
        let rowHeight: CGFloat = 55
        var previousRow: UIView? = nil

        // Create the bottom row first, including the black_square and backspace keys
        previousRow = createRow(with: bottomRow, rowHeight: rowHeight, previousRow: previousRow, widthPercentage: 0.9, specialKeys: [blackSquareKey, backspaceKey])

        // Create the middle row
        previousRow = createRow(with: middleRow, rowHeight: rowHeight, previousRow: previousRow, widthPercentage: 0.88)

        // Create the top row
        _ = createRow(with: topRow, rowHeight: rowHeight, previousRow: previousRow, widthPercentage: 0.99)
    }

    func createRow(with letters: [String], rowHeight: CGFloat, previousRow: UIView?, widthPercentage: CGFloat, specialKeys: [String]? = nil) -> UIView {
        var keys = letters
        if let specialKeys = specialKeys, specialKeys.count == 2 {
            keys.insert(specialKeys[0], at: 0) // Insert black_square key at the beginning
            keys.append(specialKeys[1]) // Append backspace key at the end
        }
        
        let rowView = UIStackView()
        rowView.axis = .horizontal
        rowView.distribution = .fillEqually
        rowView.spacing = 3 // Adjust this value to change the spacing between keys
        rowView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(rowView)

        if let previous = previousRow {
            NSLayoutConstraint.activate([
                rowView.bottomAnchor.constraint(equalTo: previous.topAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                rowView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            rowView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            rowView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: widthPercentage),
            rowView.heightAnchor.constraint(equalToConstant: rowHeight)
        ])
        
        for key in keys {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(named: key), for: .normal)
            button.imageView?.contentMode = .scaleAspectFit
            button.accessibilityIdentifier = key
            button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
            rowView.addArrangedSubview(button)
            
            if key == blackSquareKey {
                blackSquareButton = button
            }
        }

        return rowView
    }

    @objc func keyPressed(_ sender: UIButton) {
        if let key = sender.accessibilityIdentifier {
            if key == blackSquareKey {
                toggleBlackSquareImage()
                onBlackSquareToggle?()
            } else {
                onKeyPress?(key)
            }
        }
    }
    
    func toggleBlackSquareImage() {
        let currentImage = blackSquareButton?.image(for: .normal)
        let newImage = currentImage == UIImage(named: blackSquareKey) ? UIImage(named: "black_square_on") : UIImage(named: blackSquareKey)
        blackSquareButton?.setImage(newImage, for: .normal)
    }
}
