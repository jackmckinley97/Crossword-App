//
//  CreateCrosswordViewModel.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 7/14/24.
//

import SwiftUI
import Foundation

struct WordEntry: Identifiable {
    let id = UUID()
    let word: String
    let clueNumber: Int
    let direction: Direction
    let filledOutLetters: [String]
    
    enum Direction {
        case across
        case down
    }
}

struct Crossword: Identifiable, Codable {
    let id: UUID
    let title: String
    let gridSize: Int
    var gridData: [[String]]
    var clues: [UUID: String]
}

class CreateCrosswordViewModel: ObservableObject {
    @Published var blockText: [[String]]
    @Published var horizontalType = true
    @Published var acrossClues: [[Bool]]
    @Published var downClues: [[Bool]]
    @Published var clueNumbers: [[Int?]]
    @Published var xCoordinate: Int = 0
    @Published var yCoordinate: Int = 0
    @Published var wordEntries: [WordEntry] = []
    @Published var isWordSelected: [[Bool]]
    @Published var isBlackSquareModeOn = false
    @Published var text: String = " "
    @Published var clues: [UUID: String] = [:]
    @Published var crosswordTitle: String = ""
    @Published var crosswordID: UUID? = nil
    @Published var showingFillResults = false
    @Published var fillResults: [String] = []
    @Published var showingTitlePrompt = false
    @Published var showingSaveConfirmation = false
    @Published var isSavingFromBackButton = false

    let gridSize: Int
    private let dataService = CrosswordDataService()

    init(gridSize: Int) {
        self.gridSize = gridSize
        self.acrossClues = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        self.downClues = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
        self.clueNumbers = Array(repeating: Array(repeating: nil, count: gridSize), count: gridSize)
        self.blockText = Array(repeating: Array(repeating: " ", count: gridSize), count: gridSize)
        self.isWordSelected = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)
    }

    init(crossword: Crossword) {
        self.gridSize = crossword.gridSize
        self.acrossClues = Array(repeating: Array(repeating: false, count: crossword.gridSize), count: crossword.gridSize)
        self.downClues = Array(repeating: Array(repeating: false, count: crossword.gridSize), count: crossword.gridSize)
        self.clueNumbers = Array(repeating: Array(repeating: nil, count: crossword.gridSize), count: crossword.gridSize)
        self.blockText = crossword.gridData
        self.isWordSelected = Array(repeating: Array(repeating: false, count: crossword.gridSize), count: crossword.gridSize)
        self.clues = crossword.clues
        self.crosswordTitle = crossword.title
        self.crosswordID = crossword.id
    }
}
