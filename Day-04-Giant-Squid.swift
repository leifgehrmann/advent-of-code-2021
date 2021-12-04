import Foundation

enum ScriptError: Error {
    case NoBingo
}

class Board {
    let numbers: [[Int]]
    var marked: [[Bool]]
    
    init(numbers: [[Int]]) {
        self.numbers = numbers
        self.marked = numbers.map { $0.map { _ in false }}
    }
    
    func mark(drawNumber: Int) -> Bool {
        for (rowIndex, row) in numbers.enumerated() {
            for (colIndex, col) in row.enumerated() {
                if col == drawNumber {
                    marked[rowIndex][colIndex] = true
                    return true
                }
            }
        }
        return false
    }
    
    func hasBingo() -> Bool {
        // Check rows
        for row in marked {
            if (row.allSatisfy { $0 }) {
                return true
            }
        }
        
        // Check cols
        let colLength = marked[0].count
        for colIndex in 0..<colLength {
            let transposedCol = marked.map {$0[colIndex]}
            if (transposedCol.allSatisfy { $0 }) {
                return true
            }
        }
        return false
    }
    
    func printBoardNumbers() {
        let stringifiedNumbers = numbers.map { $0.map {
            String($0).padding(toLength: 3, withPad: " ", startingAt: 0)
        }}
        let stringifiedRows = stringifiedNumbers.map {
            $0.reduce("") { $0 + $1 }
        }
        print(stringifiedRows.reduce("") { $0 + String($1) + "\n" })
    }

    func printBoardMarked() {
        let stringifiedMarked = marked.map { $0.map {
            $0 ? "☑️ " : "⬜️ "
        }}
        let stringifiedRows = stringifiedMarked.map {
            $0.reduce("") { $0 + $1 }
        }
        print(stringifiedRows.reduce("") { $0 + String($1) + "\n" })
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

func getSolution(lastDrawNumber: Int, board: Board) -> Int {
    let unmarkedMarkerSum = zip(
        board.numbers.flatMap({$0}),
        board.marked.flatMap({$0})
    )
        // Name the tuple, just for readability
        .map {(number: $0.0, marked: $0.1)}
        // Sum up all the unmarked numbers
        .reduce(0) { $0 + (!$1.marked ? $1.number : 0) }
    board.printBoardNumbers()
    board.printBoardMarked()
    print("Marked Sum: ", unmarkedMarkerSum)
    print("Last Draw Number: ", lastDrawNumber)
    return unmarkedMarkerSum * lastDrawNumber
}

func part1(_ puzzle: (drawNumbers: [Int], boards: [Board])) throws -> Int {
    for drawNumber in puzzle.drawNumbers {
        for board in puzzle.boards {
            let marked = board.mark(drawNumber: drawNumber)
            if marked, board.hasBingo() {
                return getSolution(lastDrawNumber: drawNumber, board: board)
            }
            
        }
    }
    throw ScriptError.NoBingo
}

func part2(_ puzzle: (drawNumbers: [Int], boards: [Board])) throws -> Int {
    let numberOfBoards = puzzle.boards.count
    var numberOfBingos = 0
    for drawNumber in puzzle.drawNumbers {
        for board in puzzle.boards {
            if board.hasBingo() {
                continue
            }
            
            let marked = board.mark(drawNumber: drawNumber)
            if marked, board.hasBingo() {
                numberOfBingos += 1
                if numberOfBingos == numberOfBoards {
                    return getSolution(lastDrawNumber: drawNumber, board: board)
                }
            }
        }
    }
    
    throw ScriptError.NoBingo
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-04-Input.txt")

        print("Part 1: ", try part1(readPuzzle(from: input)), "\n")
        print("Part 2: ", try part2(readPuzzle(from: input)))
    }
}
