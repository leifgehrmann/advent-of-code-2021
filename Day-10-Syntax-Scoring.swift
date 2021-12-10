import Foundation

func solve(_ chunks: [String]) -> (part1: Int, part2: Int) {
    let openingChars: [String.Element] = ["(", "[", "{", "<"]
    let closingCharsMap: [String.Element:String.Element] = [
        "(": ")",
        "[": "]",
        "{": "}",
        "<": ">"
    ]

    /// For part 1 we keep track of the first illegal character for each chunk.
    /// For part 2 we keep track of the incomplete chunks and the sequence of opening characters.
    var firstIllegalCharacters: [String.Element] = []
    var incompleteChunkCharStacks: [[String.Element]] = []

    chunkLoop: for chunk in chunks {
        var charStack: [String.Element] = []
        for char in chunk {
            /// If we discover an opening character, add it to the stack.
            if (openingChars.contains(char)) {
                charStack.append(char)
                continue
            }
            
            /// If we discover a closing character that matches the opening character
            /// in the stack, pop the opening character from the stack.
            /// If it does not match, it is an illegal chunk.
            let lastOpeningChar = charStack.last!
            if closingCharsMap[lastOpeningChar] == char {
                _ = charStack.popLast()
                continue
            }

            /// If we discover an illegal chunk, append the character we've discovered
            /// and continue onto the next chunk in the array.
            firstIllegalCharacters.append(char)
            continue chunkLoop
        }

        /// According to the puzzle, the leftover chunks will always be
        /// incomplete chunks.
        incompleteChunkCharStacks.append(charStack)
    }
    
    /// Calculate the solution for the first part.
    let roundScore = firstIllegalCharacters.filter {$0 == ")"}.count * 3
    let squareScore = firstIllegalCharacters.filter {$0 == "]"}.count * 57
    let curlyScore = firstIllegalCharacters.filter {$0 == "}"}.count * 1197
    let angleScore = firstIllegalCharacters.filter {$0 == ">"}.count * 25137
    let part1 = roundScore + squareScore + curlyScore + angleScore
    
    /// Calculate the solution for the second part.
    var chunkScores: [Int] = []
    let closingCharPoints: [String.Element:Int] = [
        ")": 1,
        "]": 2,
        "}": 3,
        ">": 4
    ]
    for charStack in incompleteChunkCharStacks {
        /// Converts the char stack into a completion seqeunce. For example: `[(<{{`  -> `}}>)]`.
        let completionSequence = charStack.reversed().map({closingCharsMap[$0]!})
        /// Converts the completion sequence into an array of points. For example: `}}>)]` -> `33412`.
        let completionSequenceAsPoints = completionSequence.map({closingCharPoints[$0]!})
        /// Calculate the total score for the incomplete chunk.
        let chunkScore = completionSequenceAsPoints.reduce(0) {$0 * 5 + $1}
        chunkScores.append(chunkScore)
    }
    /// Get the middle score of all the scores.
    let part2 = chunkScores.sorted()[chunkScores.count / 2]
    
    return (part1: part1, part2: part2)
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-10-Input.txt")
        
        let chunks = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map {String($0)}
        
        let (part1: part1, part2: part2) = solve(chunks)
        print("Part 1: ", part1)
        print("Part 2: ", part2)
    }
}
