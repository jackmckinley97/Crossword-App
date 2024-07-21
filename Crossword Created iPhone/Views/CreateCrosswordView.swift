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

    private func updateClueNumbersIfNeeded() {
        updateClueNumbers()
    }

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

    func updateIsWordSelected() {
        isWordSelected = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        guard blockText.indices.contains(yCoordinate), blockText[yCoordinate].indices.contains(xCoordinate), blockText[yCoordinate][xCoordinate] != "." else {
            return
        }
        guard !isBlackSquareModeOn else {
            return
        }

        var currentRow = yCoordinate
        var currentCol = xCoordinate

        if horizontalType {
            while currentCol < gridSize {
                if blockText[currentRow][currentCol] == "." {
                    break
                }
                isWordSelected[currentRow][currentCol] = true
                currentCol += 1
            }
        } else {
            while currentRow < gridSize {
                if blockText[currentRow][currentCol] == "." {
                    break
                }
                isWordSelected[currentRow][currentCol] = true
                currentRow += 1
            }
        }

        currentRow = yCoordinate
        currentCol = xCoordinate

        if horizontalType {
            while currentCol >= 0 {
                if blockText[currentRow][currentCol] == "." {
                    break
                }
                isWordSelected[currentRow][currentCol] = true
                currentCol -= 1
            }
        } else {
            while currentRow >= 0 {
                if blockText[currentRow][currentCol] == "." {
                    break
                }
                isWordSelected[currentRow][currentCol] = true
                currentRow -= 1
            }
        }
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

    private func updateWordEntries() {
        wordEntries.removeAll()

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if let clueNumber = clueNumbers[row][col] {
                    if acrossClues[row][col] {
                        if let acrossWord = extractWord(at: row, col: col, direction: .across) {
                            let wordEntry = WordEntry(word: acrossWord, clueNumber: clueNumber, direction: .across, filledOutLetters: [])
                            wordEntries.append(wordEntry)
                        }
                    }

                    if downClues[row][col] {
                        if let downWord = extractWord(at: row, col: col, direction: .down) {
                            let wordEntry = WordEntry(word: downWord, clueNumber: clueNumber, direction: .down, filledOutLetters: [])
                            wordEntries.append(wordEntry)
                        }
                    }
                }
            }
        }
    }

    func increaseSelectedIndex() {
        if horizontalType {
            repeat {
                xCoordinate = (xCoordinate + 1) % gridSize
                if xCoordinate == 0 {
                    yCoordinate = (yCoordinate + 1) % gridSize
                }
            } while blockText[yCoordinate][xCoordinate] == "."
        } else {
            repeat {
                if yCoordinate == gridSize - 1 {
                    xCoordinate = (xCoordinate + 1) % gridSize
                    yCoordinate = 0
                } else {
                    yCoordinate = (yCoordinate + 1) % gridSize
                }
            } while blockText[yCoordinate][xCoordinate] == "."
        }
    }

    func decreaseSelectedIndex() {
        if horizontalType {
            repeat {
                if xCoordinate == 0 {
                    yCoordinate = (yCoordinate - 1 + gridSize) % gridSize
                    xCoordinate = gridSize - 1
                } else {
                    xCoordinate = (xCoordinate - 1 + gridSize) % gridSize
                }
            } while blockText[yCoordinate][xCoordinate] == "."
        } else {
            repeat {
                if yCoordinate == 0 {
                    xCoordinate = (xCoordinate - 1 + gridSize) % gridSize
                    yCoordinate = gridSize - 1
                } else {
                    yCoordinate = (yCoordinate - 1 + gridSize) % gridSize
                }
            } while blockText[yCoordinate][xCoordinate] == "."
        }
    }

    func findFirstNonBlackSquare() -> (Int, Int) {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if blockText[row][col] != "." {
                    return (row, col)
                }
            }
        }
        return (0, 0)
    }

    func toggleBlackSquareMode() {
        isBlackSquareModeOn.toggle()
        if isBlackSquareModeOn {
            xCoordinate = -1
            yCoordinate = -1
        } else {
            let (newY, newX) = findFirstNonBlackSquare()
            yCoordinate = newY
            xCoordinate = newX
        }
    }

    private func findStartOfCurrentAcrossWord() -> (row: Int, col: Int)? {
        var currentCol = xCoordinate
        while currentCol >= 0 {
            if clueNumbers[yCoordinate][currentCol] != nil && acrossClues[yCoordinate][currentCol] {
                return (yCoordinate, currentCol)
            }
            currentCol -= 1
        }
        return nil
    }

    private func findStartOfCurrentWord() -> (row: Int, col: Int)? {
        if horizontalType {
            var currentCol = xCoordinate
            while currentCol >= 0 {
                if clueNumbers[yCoordinate][currentCol] != nil && acrossClues[yCoordinate][currentCol] {
                    return (yCoordinate, currentCol)
                }
                currentCol -= 1
            }
        } else {
            var currentRow = yCoordinate
            while currentRow >= 0 {
                if clueNumbers[currentRow][xCoordinate] != nil && downClues[currentRow][xCoordinate] {
                    return (currentRow, xCoordinate)
                }
                currentRow -= 1
            }
        }
        return nil
    }

    func nextWord() {
        guard !isBlackSquareModeOn else { return }
        if horizontalType {
            moveToNextAcrossWord()
        } else {
            moveToNextDownWord()
        }
    }

    func previousWord() {
        guard !isBlackSquareModeOn else { return }
        if horizontalType {
            moveToPreviousAcrossWord()
        } else {
            moveToPreviousDownWord()
        }
    }

    private func moveToNextAcrossWord() {
        guard let start = findStartOfCurrentAcrossWord() else { return }

        var foundNext = false

        for col in (start.col + 1)..<gridSize {
            if clueNumbers[start.row][col] != nil && acrossClues[start.row][col] {
                xCoordinate = col
                yCoordinate = start.row
                updateIsWordSelected()
                foundNext = true
                break
            }
        }

        if !foundNext {
            for row in (start.row + 1)..<gridSize {
                for col in 0..<gridSize {
                    if clueNumbers[row][col] != nil && acrossClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        foundNext = true
                        break
                    }
                }
                if foundNext { break }
            }
        }

        if !foundNext {
            for row in 0...start.row {
                for col in 0..<gridSize {
                    if clueNumbers[row][col] != nil && acrossClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        return
                    }
                }
            }
        }
    }

    private func moveToPreviousAcrossWord() {
        guard let start = findStartOfCurrentAcrossWord() else { return }

        var foundPrevious = false

        for col in stride(from: start.col - 1, through: 0, by: -1) {
            if clueNumbers[start.row][col] != nil && acrossClues[start.row][col] {
                xCoordinate = col
                yCoordinate = start.row
                updateIsWordSelected()
                foundPrevious = true
                break
            }
        }

        if !foundPrevious {
            for row in stride(from: start.row - 1, through: 0, by: -1) {
                for col in stride(from: gridSize - 1, through: 0, by: -1) {
                    if clueNumbers[row][col] != nil && acrossClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        foundPrevious = true
                        break
                    }
                }
                if foundPrevious { break }
            }
        }

        if !foundPrevious {
            for row in stride(from: gridSize - 1, through: start.row + 1, by: -1) {
                for col in stride(from: gridSize - 1, through: 0, by: -1) {
                    if clueNumbers[row][col] != nil && acrossClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        return
                    }
                }
            }
        }
    }

    private func moveToNextDownWord() {
        guard let start = findStartOfCurrentWord() else { return }

        var foundNext = false

        for col in (start.col + 1)..<gridSize {
            if clueNumbers[start.row][col] != nil && downClues[start.row][col] {
                xCoordinate = col
                yCoordinate = start.row
                updateIsWordSelected()
                foundNext = true
                break
            }
        }

        if !foundNext {
            for row in (start.row + 1)..<gridSize {
                for col in 0..<gridSize {
                    if clueNumbers[row][col] != nil && downClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        foundNext = true
                        break
                    }
                }
                if foundNext { break }
            }
        }

        if !foundNext {
            for row in 0...start.row {
                for col in 0..<gridSize {
                    if clueNumbers[row][col] != nil && downClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        return
                    }
                }
            }
        }
    }

    private func moveToPreviousDownWord() {
        guard let start = findStartOfCurrentWord() else { return }

        var foundPrevious = false

        for col in stride(from: start.col - 1, through: 0, by: -1) {
            if clueNumbers[start.row][col] != nil && downClues[start.row][col] {
                xCoordinate = col
                yCoordinate = start.row
                updateIsWordSelected()
                foundPrevious = true
                break
            }
        }

        if !foundPrevious {
            for row in stride(from: start.row - 1, through: 0, by: -1) {
                for col in stride(from: gridSize - 1, through: 0, by: -1) {
                    if clueNumbers[row][col] != nil && downClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        foundPrevious = true
                        break
                    }
                }
                if foundPrevious { break }
            }
        }

        if !foundPrevious {
            for row in stride(from: gridSize - 1, through: start.row + 1, by: -1) {
                for col in stride(from: gridSize - 1, through: 0, by: -1) {
                    if clueNumbers[row][col] != nil && downClues[row][col] {
                        xCoordinate = col
                        yCoordinate = row
                        updateIsWordSelected()
                        return
                    }
                }
            }
        }
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
                    Button(action: previousWord) {
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
                    Button(action: nextWord) {
                        Image(systemName: "arrow.right.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal)
                CrosswordKeyboard(
                    text: selectedBinding,
                    isBlackSquareModeOn: $isBlackSquareModeOn,
                    onType: increaseSelectedIndex,
                    onDelete: decreaseSelectedIndex,
                    onBlackSquareToggle: {
                        toggleBlackSquareMode()
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
            updateIsWordSelected()
        }
        .onChange(of: blockText) { _ in
            updateClueNumbersIfNeeded()
        }
        .onAppear {
            updateClueNumbers()
            updateIsWordSelected()
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
            guard let wordWithLeastOptions = getWordWithLeastOptions() else {
                print("No more words to fill or crossword is complete.")
                break
            }

            let (row, col, direction, _) = wordWithLeastOptions
            let wordPattern = generatePattern(from: extractWord(at: row, col: col, direction: direction)!)
            let tableName = "word\(wordPattern.count)"
            let candidates = getWords(pattern: wordPattern, tableName: tableName)
            
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
                updateIsWordSelected()
            }
        )
    }

    func updateAcrossClueNumbers() {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if blockText[row][col] != "." {
                    if col == 0 || blockText[row][col - 1] == "." {
                        acrossClues[row][col] = true
                    } else {
                        acrossClues[row][col] = false
                    }
                }
            }
        }
    }

    func updateDownClueNumbers() {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if blockText[row][col] != "." {
                    if row == 0 || blockText[row - 1][col] == "." {
                        downClues[row][col] = true
                    } else {
                        downClues[row][col] = false
                    }
                }
            }
        }
    }

    func updateMasterClueNumbers() {
        var currentClueNumber = 1

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                clueNumbers[row][col] = nil

                if acrossClues[row][col] || downClues[row][col] {
                    clueNumbers[row][col] = currentClueNumber
                    currentClueNumber += 1
                }
            }
        }
    }

    func updateClueNumbers() {
        acrossClues = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        downClues = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        clueNumbers = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)

        updateAcrossClueNumbers()
        updateDownClueNumbers()
        updateMasterClueNumbers()
        updateWordEntries()
    }
    
    
    func getWordWithLeastOptions() -> (row: Int, col: Int, direction: WordEntry.Direction, count: Int)? {
        var minCount = Int.max
        var result: (row: Int, col: Int, direction: WordEntry.Direction, count: Int)?

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if let clueNumber = clueNumbers[row][col] {
                    if acrossClues[row][col], let acrossWord = extractWord(at: row, col: col, direction: .across), !isWordFullyFilled(acrossWord) {
                        let pattern = generatePattern(from: acrossWord)
                        let tableName = "word\(acrossWord.count)"
                        let wordCount = getWordCount(for: pattern, tableName: tableName)
                        if wordCount < minCount {
                            minCount = wordCount
                            result = (row, col, .across, wordCount)
                        }
                    }
                    if downClues[row][col], let downWord = extractWord(at: row, col: col, direction: .down), !isWordFullyFilled(downWord) {
                        let pattern = generatePattern(from: downWord)
                        let tableName = "word\(downWord.count)"
                        let wordCount = getWordCount(for: pattern, tableName: tableName)
                        if wordCount < minCount {
                            minCount = wordCount
                            result = (row, col, .down, wordCount)
                        }
                    }
                }
            }
        }

        return result
    }

    func isWordFullyFilled(_ word: String) -> Bool {
        return !word.contains(" ")
    }

    func extractWord(at row: Int, col: Int, direction: WordEntry.Direction) -> String? {
        var word = ""
        var currentRow = row
        var currentCol = col

        while currentRow < gridSize, currentCol < gridSize {
            if blockText[currentRow][currentCol] == "." {
                break
            }
            word.append(blockText[currentRow][currentCol])
            if direction == .across {
                currentCol += 1
            } else {
                currentRow += 1
            }
        }

        return word.isEmpty ? nil : word
    }

}







struct CrosswordBlock: View {
    var xIndex: Int
    var yIndex: Int
    var tip = -1

    @Binding var selectedXIndex: Int
    @Binding var selectedYIndex: Int
    @Binding var text: String
    @Binding var isBlackSquareModeOn: Bool

    var clueNumber: Int?
    var blockSize: CGFloat
    var isWordSelected: Bool
    var horizontalTypeToggleAction: () -> Void

    var body: some View {
        let isPeriod = text == "."
        let isSelected = selectedXIndex == xIndex && selectedYIndex == yIndex
        let blockColor = getBlockColor(isSelected: isSelected, isWordSelected: isWordSelected, isPeriod: isPeriod)

        return ZStack {
            if let clueNumber = clueNumber {
                Text("\(clueNumber)")
                    .frame(width: blockSize, height: blockSize, alignment: .topLeading)
                    .font(.system(size: blockSize * 0.25))
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                    .offset(x: blockSize * 0.05, y: 0)
            }

            Text(isPeriod ? "." : text)
                .frame(width: blockSize, height: blockSize, alignment: .center)
                .font(.system(size: blockSize * 0.6))
                .fontWeight(.bold)
                .foregroundColor(isPeriod ? .clear : .black)
        }
        .foregroundColor(.white)
        .frame(width: blockSize, height: blockSize)
        .background(
            Rectangle()
                .foregroundColor(blockColor)
                .cornerRadius(blockSize * 0.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: blockSize * 0.1)
                .stroke(Color.selectedBlockBorder, lineWidth: isSelected ? blockSize * 0.05 : 0)
        )
        .onTapGesture {
            if isBlackSquareModeOn {
                text = (text == ".") ? " " : "."
            } else {
                if text != "." {
                    if selectedXIndex == xIndex && selectedYIndex == yIndex {
                        horizontalTypeToggleAction()
                    }
                    selectedXIndex = xIndex
                    selectedYIndex = yIndex
                }
            }
        }

        func getBlockColor(isSelected: Bool, isWordSelected: Bool, isPeriod: Bool) -> Color {
            if isPeriod {
                return .black
            }
            if isSelected {
                return .selectedBlockBackground
            }
            if isWordSelected {
                return .selectedWordBackgroundGood
            }
            return .unselectedBlockBackground
        }
    }
}
