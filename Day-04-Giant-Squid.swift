import Foundation

enum ScriptError: Error {
    case FileCouldNotBeRead
    // NoBingo shouldn't happen because all draw numbers should exist in all boards,
    // but it is still a valid edge case.
    case NoBingo
}

func getCwd() -> String {
    if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
        return srcRoot
    }
    return FileManager.default.currentDirectoryPath
}

func readFileInCwd(file: String) throws -> String {
    let inputPath = URL(fileURLWithPath: getCwd() + file)
    do {
        return try String(contentsOf: inputPath, encoding: .utf8)
    } catch {
        throw ScriptError.FileCouldNotBeRead
    }
}

class Board {
    let numbers: [[Int]]
    var marked: [[Bool]]
    
    init(numbers: [[Int]]) {
        self.numbers = numbers
        self.marked = numbers.map { $0.map { _ in false }}
    }
    
    func check(drawNumber: Int) -> Bool {
        for (rowIndex, row) in self.numbers.enumerated() {
            for (colIndex, col) in row.enumerated() {
                if col == drawNumber {
                    self.marked[rowIndex][colIndex] = true
                    return true
                }
            }
        }
        return false
    }
    
    func checkBingo() -> Bool {
        // Check rows
        for row in self.marked {
            if (row.allSatisfy { $0 }) {
                return true
            }
        }
        
        // Check cols
        let colLength = self.marked[0].count
        for colIndex in 0..<colLength {
            let transposedCol = self.marked.map {$0[colIndex]}
            if (transposedCol.allSatisfy { $0 }) {
                return true
            }
        }
        return false
    }
}

func readBoard(from input: String) -> Board {
    let numbers = input
        // Get rid of redundant spaces
        .replacingOccurrences(of: " +", with: " ", options: [.regularExpression])
        .split(separator: "\n")
        .map {
            $0
                .split(separator: " ")
                .map {Int($0)}
                .compactMap {$0}
        }
    return Board(numbers: numbers)
}

func readPuzzle(from input: String) -> (drawNumbers: [Int], boards: [Board]) {
    let puzzleSplit = input.split(separator: "\n", maxSplits: 1)
    let drawNumbers = puzzleSplit[0]
        .split(separator: ",")
        .map {Int($0)}
        .compactMap {$0}
    let boards = puzzleSplit[1].components(separatedBy: "\n\n").map {readBoard(from: $0)}
    return (drawNumbers: drawNumbers, boards: boards)
}

func part1(_ puzzle: (drawNumbers: [Int], boards: [Board])) throws -> Int {
    for drawNumber in puzzle.drawNumbers {
        for board in puzzle.boards {
            let marked = board.check(drawNumber: drawNumber)
            
            if marked, board.checkBingo() {
                let unmarkedMarkerSum = zip(
                    board.numbers.flatMap({$0}),
                    board.marked.flatMap({$0})
                )
                    // Name the tuple, just for readability
                    .map {(number: $0.0, marked: $0.1)}
                    .reduce(0) { $0 + ($1.marked ? $1.number : 0) }
                return unmarkedMarkerSum * drawNumber
            }
            
        }
    }
    throw ScriptError.NoBingo
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-04-Input.txt")
        let puzzle = readPuzzle(from: input)
        
        print(try part1(puzzle))
    }
}
