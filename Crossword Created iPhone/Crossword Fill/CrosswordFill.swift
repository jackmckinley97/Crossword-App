import SQLite3
import Foundation

var db: OpaquePointer?
var queryStatement: OpaquePointer?

func openDatabase() {
    guard let fileURL = Bundle.main.url(forResource: "Crossword_Word_List_Database", withExtension: "db", subdirectory: "Databases") else {
        print("Crossword_Word_List_Database.db not found in the app bundle.")
        return
    }

    if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
        print("Successfully opened connection to database at \(fileURL.path)")
    } else {
        print("Unable to open database.")
    }
}

func getWords(pattern: String, tableName: String) -> [(String, Int, Int)] {
    let queryString = buildQueryString(from: pattern, tableName: tableName)
    var words: [(String, Int, Int)] = []

    print("Getting words for pattern: \(pattern)")
    print("Pattern length: \(pattern.count)")
    print("Using table name: \(tableName)")
    print("Building query string for pattern: \(pattern) and table: \(tableName)")
    print("Built query string: \(queryString)")

    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        print("Query prepared successfully.")
        while(sqlite3_step(queryStatement) == SQLITE_ROW) {
            let word = String(cString: sqlite3_column_text(queryStatement, 0))
            let score = Int(sqlite3_column_int(queryStatement, 1))
            let xScore = Int.random(in: 1...50)
            words.append((word, score, xScore))
        }
        sqlite3_finalize(queryStatement)
    } else {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("Error preparing select: \(errmsg)")
    }

    print("Words found: \(words)")
    return words
}


func buildQueryString(from pattern: String, tableName: String) -> String {
    var conditions: [String] = []
    for (index, char) in pattern.enumerated() {
        if char != "*" {
            conditions.append("char\(index + 1) = '\(char)'")
        }
    }
    let conditionString = conditions.isEmpty ? "1=1" : conditions.joined(separator: " AND ")
    return "SELECT word, score FROM \(tableName) WHERE \(conditionString) ORDER BY score DESC LIMIT 10;"
}

func closeDatabase() {
    if db != nil {
        sqlite3_close(db)
        db = nil
    }
}

func listTables() {
    let queryString = "SELECT name FROM sqlite_master WHERE type='table';"
    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        while(sqlite3_step(queryStatement) == SQLITE_ROW) {
            let tableName = String(cString: sqlite3_column_text(queryStatement, 0))
            print("Table name: \(tableName)")
        }
        sqlite3_finalize(queryStatement)
    } else {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("Error listing tables: \(errmsg)")
    }
}

// Debug function to check columns of a specific table
func listTableColumns(tableName: String) {
    let queryString = "PRAGMA table_info(\(tableName));"
    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        while(sqlite3_step(queryStatement) == SQLITE_ROW) {
            let columnName = String(cString: sqlite3_column_text(queryStatement, 1))
            print("Column name: \(columnName)")
        }
        sqlite3_finalize(queryStatement)
    } else {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("Error listing table columns: \(errmsg)")
    }
}

// Function to calculate MatchScore for a given word and position
func calculateMatchScore(word: String, row: Int, col: Int, direction: WordEntry.Direction, blockText: [[String]], gridSize: Int) -> Int {
    var matchScore = 0
    let intersectingClues = getIntersectingClues(word: word, row: row, col: col, direction: direction, blockText: blockText, gridSize: gridSize)
    
    for clue in intersectingClues {
        let candidateCount = getCandidateWordsCount(clue: clue, blockText: blockText, gridSize: gridSize)
        if candidateCount == 0 {
            return 0
        }
        matchScore += candidateCount
    }
    return matchScore
}

func getIntersectingClues(word: String, row: Int, col: Int, direction: WordEntry.Direction, blockText: [[String]], gridSize: Int) -> [(Int, Int, WordEntry.Direction)] {
    var intersectingClues: [(Int, Int, WordEntry.Direction)] = []
    
    for (index, char) in word.enumerated() {
        let currentRow = direction == .across ? row : row + index
        let currentCol = direction == .across ? col + index : col
        
        if currentRow >= gridSize || currentCol >= gridSize || blockText[currentRow][currentCol] == "." {
            continue
        }
        
        let intersectingDirection: WordEntry.Direction = direction == .across ? .down : .across
        intersectingClues.append((currentRow, currentCol, intersectingDirection))
    }
    
    return intersectingClues
}

func getCandidateWordsCount(clue: (Int, Int, WordEntry.Direction), blockText: [[String]], gridSize: Int) -> Int {
    let (row, col, direction) = clue
    var pattern = ""
    var currentRow = row
    var currentCol = col
    
    if direction == .across {
        while currentCol < gridSize && blockText[currentRow][currentCol] != "." {
            pattern.append(blockText[currentRow][currentCol] == " " ? "*" : blockText[currentRow][currentCol])
            currentCol += 1
        }
    } else {
        while currentRow < gridSize && blockText[currentRow][currentCol] != "." {
            pattern.append(blockText[currentRow][currentCol] == " " ? "*" : blockText[currentRow][currentCol])
            currentRow += 1
        }
    }
    
    let tableName = "word\(pattern.count)"
    let queryString = buildQueryString(from: pattern, tableName: tableName)
    var count = 0
    
    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        while(sqlite3_step(queryStatement) == SQLITE_ROW) {
            count += 1
        }
        sqlite3_finalize(queryStatement)
    } else {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("Error preparing select: \(errmsg)")
    }
    
    return count
}

func getWordCount(for pattern: String, tableName: String) -> Int {
    let queryString = buildQueryString(from: pattern, tableName: tableName)
    var count = 0

    if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
        while(sqlite3_step(queryStatement) == SQLITE_ROW) {
            count += 1
        }
        sqlite3_finalize(queryStatement)
    } else {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        print("Error preparing select: \(errmsg)")
    }

    return count
}
