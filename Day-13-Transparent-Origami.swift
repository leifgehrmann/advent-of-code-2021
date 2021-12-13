import Foundation

struct Dot: Equatable {
    let x: Int;
    let y: Int;
}

struct Instruction {
    let axis: String;
    let position: Int;
}

func printDots(_ dots: [Dot]) {
    let maxX = dots.map { $0.x }.max()!
    let maxY = dots.map { $0.y }.max()!
    var map = Array(
        repeating: Array(repeating: "🟦", count: maxX + 1),
        count: maxY + 1
    )
    for dot in dots {
        map[dot.y][dot.x] = "🟨"
    }
    
    let rows = map.map { $0.reduce("") { $0 + String($1) } }
    print(rows.reduce("") { $0 + String($1) + "\n" })
}

func fold(_ dots: [Dot], _ instruction: Instruction) -> [Dot] {
    var filteredDots = dots
    
    if instruction.axis == "x" {
        filteredDots = filteredDots.filter { $0.x != instruction.position }
    } else {
        filteredDots = filteredDots.filter { $0.y != instruction.position }
    }

    var newDots: [Dot] = []
    for dot in filteredDots {
        var newDot = dot
        if instruction.axis == "x" {
            if dot.x > instruction.position {
                let newX = 2 * instruction.position - dot.x
                newDot = Dot(x: newX, y: dot.y)
            } else if dot.x == instruction.position {
                continue
            }
        } else if instruction.axis == "y" {
            if dot.y > instruction.position {
                let newY = 2 * instruction.position - dot.y
                newDot = Dot(x: dot.x, y: newY)
            } else if dot.y == instruction.position {
                continue
            }
        }
        
        if !newDots.contains(newDot) {
            newDots.append(newDot)
        }
    }
    
    return newDots
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-13-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let splitInput = input.components(separatedBy: "\n\n")
        
        var dots = splitInput[0]
            .split(separator: "\n")
            .map { $0.split(separator: ",").map {Int($0)}.compactMap { $0 } }
            .map { Dot(x: $0[0], y: $0[1]) }
        
        let foldInstructions = splitInput[1]
            .replacingOccurrences(of: "fold along ", with: "")
            .split(separator: "\n")
            .map { $0.split(separator: "=") }
            .map { Instruction(axis: String($0[0]), position: Int($0[1])!) }
        
        for (index, foldInstruction) in foldInstructions.enumerated() {
            dots = fold(dots, foldInstruction)
            if (index == 0) {
                print("Part 1: ", dots.count)
            }
        }
        
        print("Part 2:")
        printDots(dots)
    }
}
