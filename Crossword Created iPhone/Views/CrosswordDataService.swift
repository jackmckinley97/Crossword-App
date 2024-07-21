//
//  CrosswordDataService.swift
//  Crossword Created iPhone
//
//  Created by Jack McKinley on 7/6/24.
//

import Foundation

class CrosswordDataService {
    private let crosswordsKey = "savedCrosswords"

    func saveCrossword(_ crossword: Crossword) {
        var crosswords = fetchCrosswords()
        if let index = crosswords.firstIndex(where: { $0.id == crossword.id }) {
            crosswords[index] = crossword
        } else {
            crosswords.append(crossword)
        }
        if let data = try? JSONEncoder().encode(crosswords) {
            UserDefaults.standard.set(data, forKey: crosswordsKey)
        }
    }

    func fetchCrosswords() -> [Crossword] {
        if let data = UserDefaults.standard.data(forKey: crosswordsKey),
           let crosswords = try? JSONDecoder().decode([Crossword].self, from: data) {
            return crosswords
        }
        return []
    }

    func deleteCrossword(_ crossword: Crossword) {
        var crosswords = fetchCrosswords()
        crosswords.removeAll { $0.id == crossword.id }
        if let data = try? JSONEncoder().encode(crosswords) {
            UserDefaults.standard.set(data, forKey: crosswordsKey)
        }
    }
}
