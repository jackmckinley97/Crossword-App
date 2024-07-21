import SwiftUI

class UpdateViewOnUserInteraction {
    var gridSize: Int
    @Binding var acrossClues: [[Bool]]
    @Binding var downClues: [[Bool]]
    @Binding var clueNumbers: [[Int?]]
    @Binding var blockText: [[String]]
    @Binding var isWordSelected: [[Bool]]
    @Binding var isBlackSquareModeOn: Bool
    @Binding var xCoordinate: Int
    @Binding var yCoordinate: Int
    @Binding var wordEntries: [WordEntry]
    @Binding var horizontalType: Bool

    init(gridSize: Int, acrossClues: Binding<[[Bool]]>, downClues: Binding<[[Bool]]>, clueNumbers: Binding<[[Int?]]>, blockText: Binding<[[String]]>, isWordSelected: Binding<[[Bool]]>, isBlackSquareModeOn: Binding<Bool>, xCoordinate: Binding<Int>, yCoordinate: Binding<Int>, wordEntries: Binding<[WordEntry]>, horizontalType: Binding<Bool>) {
        self.gridSize = gridSize
        self._acrossClues = acrossClues
        self._downClues = downClues
        self._clueNumbers = clueNumbers
        self._blockText = blockText
        self._isWordSelected = isWordSelected
        self._isBlackSquareModeOn = isBlackSquareModeOn
        self._xCoordinate = xCoordinate
        self._yCoordinate = yCoordinate
        self._wordEntries = wordEntries
        self._horizontalType = horizontalType
    }

    func updateClueNumbersIfNeeded() {
        updateClueNumbers()
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

    private func updateAcrossClueNumbers() {
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

    private func updateDownClueNumbers() {
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

    private func updateMasterClueNumbers() {
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

    func updateWordEntries() {
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

    func generatePattern(from word: String) -> String {
        var pattern = ""
        for char in word {
            pattern.append(char == " " ? "*" : char)
        }
        return pattern
    }

    func getWordCount(for pattern: String, tableName: String) -> Int {
        // This function should interact with your database to get the word count for the given pattern and tableName.
        // Since database interaction code is not provided, this is a placeholder function.
        return 0
    }
}
