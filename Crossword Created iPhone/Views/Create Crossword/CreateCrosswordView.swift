import SwiftUI
import Foundation



struct WordEntry: Identifiable {
    let id = UUID()
    let word: String
    let clueNumber: Int
    let direction: Direction
    let filledOutLetters: [String]
    
    enum Direction: String {
        case across = "Across"
        case down = "Down"
    }
}


struct Crossword: Identifiable, Codable {
    let id: UUID
    let title: String
    let gridSize: Int
    var gridData: [[String]]
    var clues: [UUID: String]
}

import SwiftUI

struct CreateCrosswordView: View {
    @State private var blockText: [[String]]
    @State private var horizontalType = true
    @State private var acrossClues: [[Bool]]
    @State private var downClues: [[Bool]]
    @State private var clueNumbers: [[Int?]]
    @State private var xCoordinate: Int = 0
    @State private var yCoordinate: Int = 0
    @State private var wordEntries: [WordEntry] = []
    @State private var isWordSelected: [[Bool]] = []
    @State private var isBlackSquareModeOn = false
    @State private var text: String = " "
    @State private var clues: [UUID: String] = [:]
    @State private var crosswordTitle: String = ""
    @State private var crosswordID: UUID? = nil
    @State private var showingFillResults = false
    @State private var showingTitlePrompt = false
    @State private var showingSaveConfirmation = false
    @State private var isSavingFromBackButton = false
    @State private var fillResults: [(String, Int, Int)] = []
    private var gridSize: Int

    @Environment(\.presentationMode) var presentationMode

    private let dataService = CrosswordDataService()

    private var blockSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalSpacing: CGFloat = 30
        return (screenWidth - totalSpacing) / CGFloat(gridSize)
    }

    private var coordinateKey: String {
        "\(xCoordinate),\(yCoordinate)"
    }

    @State private var interactionHandler: UpdateViewOnUserInteraction?

    init(gridSize: Int) {
        self.gridSize = gridSize
        self._acrossClues = State(initialValue: Array(repeating: Array(repeating: false, count: gridSize), count: gridSize))
        self._downClues = State(initialValue: Array(repeating: Array(repeating: false, count: gridSize), count: gridSize))
        self._clueNumbers = State(initialValue: Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize))
        self._blockText = State(initialValue: Array(repeating: Array(repeating: " ", count: gridSize), count: gridSize))
        self._isWordSelected = State(initialValue: Array(repeating: Array(repeating: false, count: gridSize), count: gridSize))
    }

    init(crossword: Crossword) {
        self.gridSize = crossword.gridSize
        self._acrossClues = State(initialValue: Array(repeating: Array(repeating: false, count: crossword.gridSize), count: crossword.gridSize))
        self._downClues = State(initialValue: Array(repeating: Array(repeating: false, count: crossword.gridSize), count: crossword.gridSize))
        self._clueNumbers = State(initialValue: Array(repeating: Array(repeating: nil, count: crossword.gridSize), count: crossword.gridSize))
        self._blockText = State(initialValue: crossword.gridData)
        self._isWordSelected = State(initialValue: Array(repeating: Array(repeating: false, count: crossword.gridSize), count: crossword.gridSize))
        self._clues = State(initialValue: crossword.clues)
        self._crosswordTitle = State(initialValue: crossword.title)
        self._crosswordID = State(initialValue: crossword.id)
    }

    var selectedBinding: Binding<String> {
        Binding<String>(
            get: {
                guard yCoordinate >= 0, xCoordinate >= 0, yCoordinate < gridSize, xCoordinate < gridSize else {
                    return ""
                }
                return blockText[yCoordinate][xCoordinate]
            },
            set: {
                guard yCoordinate >= 0, xCoordinate >= 0, yCoordinate < gridSize, xCoordinate < gridSize else {
                    return
                }
                blockText[yCoordinate][xCoordinate] = $0
            }
        )
    }

    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            VStack {
                HStack {
                    Button(action: { showingSaveConfirmation = true }) {
                        Image(systemName: "arrow.left")
                    }
                    .padding()
                    NavigationLink(destination: CreateCluesView(wordEntries: wordEntries, clues: $clues)) {
                        Text("Add Clues")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    Button(action: saveCrossword) {
                        Text("Save")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                Spacer()
                VStack(spacing: 30 / CGFloat((gridSize + 1))) {
                    ForEach(0..<gridSize, id: \.self) { row in
                        HStack(spacing: 30 / CGFloat((gridSize + 1))) {
                            ForEach(0..<gridSize, id: \.self) { col in
                                createBlock(x: col, y: row, isWordSelected: isWordSelected[row][col])
                            }
                        }
                    }
                }
                HStack {
                    Button(action: {
                        interactionHandler?.previousWord()
                    }) {
                        Image(systemName: "arrow.left.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                    Spacer()
                    Button(action: {
                        showFillResults()
                    }) {
                        Text("Get Words")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    Spacer()
                    Button(action: {
                        fillCrosswordAlgorithm()
                    }) {
                        Text("Fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    Spacer()
                    Button(action: {
                        interactionHandler?.nextWord()
                    }) {
                        Image(systemName: "arrow.right.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal)
                CrosswordKeyboard(
                    text: selectedBinding,
                    isBlackSquareModeOn: $isBlackSquareModeOn,
                    onType: {
                        interactionHandler?.increaseSelectedIndex()
                    },
                    onDelete: {
                        interactionHandler?.decreaseSelectedIndex()
                    },
                    onBlackSquareToggle: {
                        interactionHandler?.toggleBlackSquareMode()
                    }
                )
                .frame(height: 200)
                Rectangle()
                    .frame(height: 40)
                    .foregroundColor(.clear)
            }
            .alert(isPresented: $showingSaveConfirmation) {
                Alert(
                    title: Text("Save Crossword"),
                    message: Text("Would you like to save the crossword before exiting?"),
                    primaryButton: .default(Text("Yes"), action: {
                        saveCrosswordAndExit()
                    }),
                    secondaryButton: .cancel(Text("No"), action: {
                        presentationMode.wrappedValue.dismiss()
                    })
                )
            }
            if showingTitlePrompt {
                UIAlertControllerWrapper(
                    isPresented: $showingTitlePrompt,
                    title: "Enter Title",
                    message: "Please enter a title for your crossword.",
                    textFieldPlaceholder: "Crossword Title",
                    onSave: { title in
                        crosswordTitle = title
                        saveOrUpdateCrossword(with: title)
                        if isSavingFromBackButton {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }

            if showingFillResults {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            showingFillResults = false
                        }) {
                            Image(systemName: "xmark.circle")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .padding()
                        }
                    }
                    Text("Suggested Words").font(.headline).padding()
                    HStack {
                        Text("Word").font(.subheadline).bold().frame(maxWidth: .infinity, alignment: .leading)
                        Text("Score").font(.subheadline).bold().frame(maxWidth: .infinity, alignment: .center)
                        Text("xScore").font(.subheadline).bold().frame(maxWidth: .infinity, alignment: .trailing)
                    }.padding([.leading, .trailing])
                    ScrollView {
                        VStack(alignment: .leading) {
                            if fillResults.isEmpty {
                                Text("No words found")
                            } else {
                                ForEach(fillResults, id: \.0) { word, score, xScore in
                                    HStack {
                                        Text(word).frame(maxWidth: .infinity, alignment: .leading)
                                        Text("\(score)").frame(maxWidth: .infinity, alignment: .center)
                                        Text("\(xScore)").frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .padding(.horizontal)
                                    .background(Color.clear)
                                    .onTapGesture {
                                        print("Tapped word: \(word)")
                                        fillSelectedWord(with: word)
                                        showingFillResults = false
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    Spacer()
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding()
            }
        }
        .onChange(of: coordinateKey) { _ in
            interactionHandler?.updateIsWordSelected()
        }
        .onChange(of: blockText) { _ in
            interactionHandler?.updateClueNumbersIfNeeded()
        }
        .onAppear {
            interactionHandler = UpdateViewOnUserInteraction(
                gridSize: gridSize,
                acrossClues: $acrossClues,
                downClues: $downClues,
                clueNumbers: $clueNumbers,
                blockText: $blockText,
                isWordSelected: $isWordSelected,
                isBlackSquareModeOn: $isBlackSquareModeOn,
                xCoordinate: $xCoordinate,
                yCoordinate: $yCoordinate,
                wordEntries: $wordEntries,
                horizontalType: $horizontalType
            )
            interactionHandler?.updateClueNumbers()
            interactionHandler?.updateIsWordSelected()
        }
        .navigationBarBackButtonHidden(true)
    }

    private func showFillResults() {
        guard let selectedWordPattern = getSelectedWordPattern() else {
            fillResults = [("No word selected", 0, 0)]
            showingFillResults = true
            return
        }

        let pattern = selectedWordPattern
        print("Pattern generated: \(pattern)")

        openDatabase()
        listTables()
        let results = getWords(pattern: pattern, tableName: "word\(pattern.count)")
        fillResults = results
        print("Suggested words: \(fillResults)")
        closeDatabase()

        showingFillResults = true
    }

    func fillCrosswordAlgorithm() {
        openDatabase()
        defer { closeDatabase() }

        var filledWords = Set<String>()

        while true {
            guard let wordWithLeastOptions = interactionHandler?.getWordWithLeastOptions() else {
                print("No more words to fill or crossword is complete.")
                break
            }

            let (row, col, direction, _) = wordWithLeastOptions
            let wordPattern = interactionHandler?.generatePattern(from: interactionHandler?.extractWord(at: row, col: col, direction: direction) ?? "")
            let tableName = "word\(wordPattern?.count ?? 0)"
            let candidates = getWords(pattern: wordPattern ?? "", tableName: tableName)
            
            if candidates.isEmpty {
                print("No candidates found for the word at row \(row) and col \(col). Stopping the algorithm.")
                break
            }

            var bestWord: String?
            var bestMatchScore = -1
            
            for (candidate, _, _) in candidates {
                let matchScore = calculateMatchScore(word: candidate, row: row, col: col, direction: direction, blockText: blockText, gridSize: gridSize)
                if matchScore > bestMatchScore {
                    bestMatchScore = matchScore
                    bestWord = candidate
                }
            }
            
            guard let selectedWord = bestWord else {
                print("No valid word found for the word at row \(row) and col \(col). Stopping the algorithm.")
                break
            }

            fillSelectedWord(with: selectedWord, row: row, col: col, direction: direction)
            filledWords.insert(selectedWord)
            print("Filled word: \(selectedWord) at row \(row), col \(col), direction: \(direction)")
        }
    }

    func generatePattern(from word: String) -> String {
        var pattern = ""
        for char in word {
            pattern.append(char == " " ? "*" : char)
        }
        return pattern
    }

    func fillSelectedWord(with word: String, row: Int, col: Int, direction: WordEntry.Direction) {
        var currentRow = row
        var currentCol = col

        if direction == .across {
            for char in word {
                if currentCol < gridSize {
                    blockText[currentRow][currentCol] = String(char)
                    currentCol += 1
                }
            }
        } else {
            for char in word {
                if currentRow < gridSize {
                    blockText[currentRow][currentCol] = String(char)
                    currentRow += 1
                }
            }
        }
    }

    private func printCrosswordToDebugger() {
        for row in 0..<gridSize {
            var rowString = ""
            for col in 0..<gridSize {
                if blockText[row][col] == "." {
                    rowString.append("-")
                } else if blockText[row][col] == " " {
                    rowString.append("*")
                } else {
                    rowString.append(blockText[row][col])
                }
            }
            print(rowString)
        }
    }

    private func getSelectedWordPattern() -> String? {
        guard yCoordinate >= 0, xCoordinate >= 0, yCoordinate < gridSize, xCoordinate < gridSize else {
            return nil
        }

        var pattern = ""
        var currentRow = yCoordinate
        var currentCol = xCoordinate

        if horizontalType {
            while currentCol > 0, blockText[currentRow][currentCol - 1] != "." {
                currentCol -= 1
            }
            while currentCol < gridSize, blockText[currentRow][currentCol] != "." {
                pattern.append(blockText[currentRow][currentCol] == " " ? "*" : blockText[currentRow][currentCol])
                currentCol += 1
            }
        } else {
            while currentRow > 0, blockText[currentRow - 1][currentCol] != "." {
                currentRow -= 1
            }
            while currentRow < gridSize, blockText[currentRow][currentCol] != "." {
                pattern.append(blockText[currentRow][currentCol] == " " ? "*" : blockText[currentRow][currentCol])
                currentRow += 1
            }
        }

        return pattern.isEmpty ? nil : pattern
    }

    private func saveCrossword() {
        if crosswordTitle.isEmpty {
            promptForTitle()
        } else {
            saveOrUpdateCrossword(with: crosswordTitle)
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func saveCrosswordAndExit() {
        if crosswordTitle.isEmpty {
            promptForTitle()
            isSavingFromBackButton = true
        } else {
            saveOrUpdateCrossword(with: crosswordTitle)
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func fillSelectedWord(with word: String) {
        var currentRow = yCoordinate
        var currentCol = xCoordinate

        if horizontalType {
            while currentCol > 0 && blockText[currentRow][currentCol - 1] != "." {
                currentCol -= 1
            }
            for char in word {
                if currentCol < gridSize {
                    blockText[currentRow][currentCol] = String(char)
                    currentCol += 1
                }
            }
        } else {
            while currentRow > 0 && blockText[currentRow - 1][currentCol] != "." {
                currentRow -= 1
            }
            for char in word {
                if currentRow < gridSize {
                    blockText[currentRow][currentCol] = String(char)
                    currentRow += 1
                }
            }
        }
    }

    private func promptForTitle() {
        let alert = UIAlertController(title: "Enter Title", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Crossword Title"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                crosswordTitle = title
                saveOrUpdateCrossword(with: title)
                if isSavingFromBackButton {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }))
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    private func saveOrUpdateCrossword(with title: String) {
        let id = crosswordID ?? UUID()
        let crossword = Crossword(id: id, title: title, gridSize: gridSize, gridData: blockText, clues: clues)
        dataService.saveCrossword(crossword)
        crosswordID = id
    }

    func txtBind(x: Int, y: Int) -> Binding<String> {
        Binding<String>(
            get: {
                blockText[y][x]
            },
            set: {
                blockText[y][x] = $0
            }
        )
    }

    func createBlock(x: Int, y: Int, isWordSelected: Bool) -> CrosswordBlock {
        return CrosswordBlock(
            xIndex: x,
            yIndex: y,
            selectedXIndex: $xCoordinate,
            selectedYIndex: $yCoordinate,
            text: txtBind(x: x, y: y),
            isBlackSquareModeOn: $isBlackSquareModeOn,
            clueNumber: clueNumbers[y][x],
            blockSize: blockSize,
            isWordSelected: isWordSelected,
            horizontalTypeToggleAction: {
                horizontalType.toggle()
                interactionHandler?.updateIsWordSelected()
            }
        )
    }
}
