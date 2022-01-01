import Foundation

enum ScriptError: Error {
    case DivideByZero
    case ModuloNegative
    case ParseValue
    case ParseInstruction
}

enum ValueType {
    case Variable
    case Number
}

protocol Value {
    func type() -> ValueType
}

enum Variable: Value {
    case W
    case X
    case Y
    case Z
    
    func type() -> ValueType {
        return .Variable
    }
}

extension Int: Value {
    func type() -> ValueType {
        return .Number
    }
}

enum InstructionType {
    case Input
    case Add
    case Mul
    case Div
    case Mod
    case Eql
}

struct Instruction {
    let type: InstructionType
    let a: Variable
    let b: Value
}

class Alu {
    var state: [Variable: Int]
    
    init() {
        state = [:]
        reset()
    }
    
    func reset() {
        state = [
            .W: 0,
            .X: 0,
            .Y: 0,
            .Z: 0,
        ]
    }
    
    func process(
        _ instructions: [Instruction],
        with modelNumber: [Int]
    ) throws -> [Variable: Int] {
        reset()
        var inputs = modelNumber
        
        for instruction in instructions {
            let result: Int
            switch instruction.type {
            case .Input:
                result = inputs.removeFirst()
                break;
            case .Add:
                result = getValueAsInt(instruction.a) +
                    getValueAsInt(instruction.b)
            case .Mul:
                result = getValueAsInt(instruction.a) *
                    getValueAsInt(instruction.b)
            case .Div:
                let b = getValueAsInt(instruction.b)
                if (b == 0) {
                    throw ScriptError.DivideByZero
                }
                result = getValueAsInt(instruction.a) /
                    getValueAsInt(instruction.b)
            case .Mod:
                let a = getValueAsInt(instruction.a)
                let b = getValueAsInt(instruction.b)
                if (a < 0 || b <= 0) {
                    throw ScriptError.ModuloNegative
                }
                result = getValueAsInt(instruction.a) % b
            case .Eql:
                result = getValueAsInt(instruction.a) ==
                    getValueAsInt(instruction.b) ? 1 : 0
            }
            
            state[instruction.a] = result
        }
        
        return state
    }
    
    private func getValueAsInt(_ value: Value) -> Int {
        if value.type() == .Variable {
            return state[value as! Variable, default: 0]
        } else {
            return value as! Int
        }
    }
}

func parseVariable(_ str: String) throws -> Variable {
    switch str {
    case "w":
        return .W
    case "x":
        return .X
    case "y":
        return .Y
    case "z":
        return .Z
    default:
        throw ScriptError.ParseValue
    }
}

func parseValue(_ str: String) throws -> Value {
    if str.rangeOfCharacter(from: .decimalDigits) != nil {
        return Int(str)!
    } else {
        return try parseVariable(str)
    }
}

func parseInstruction(_ instructionString: String) throws -> Instruction {
    let splitInstruction = instructionString.split(separator: " ")
    let type = String(splitInstruction[0])
    switch type {
    case "inp":
        return Instruction(
            type: .Input,
            a: try parseVariable(String(splitInstruction[1])),
            b: 0 /// A dummy value
        )
    case "add":
        return Instruction(
            type: .Add,
            a: try parseVariable(String(splitInstruction[1])),
            b: try parseValue(String(splitInstruction[2]))
        )
    case "mul":
        return Instruction(
            type: .Mul,
            a: try parseVariable(String(splitInstruction[1])),
            b: try parseValue(String(splitInstruction[2]))
        )
    case "div":
        return Instruction(
            type: .Div,
            a: try parseVariable(String(splitInstruction[1])),
            b: try parseValue(String(splitInstruction[2]))
        )
    case "mod":
        return Instruction(
            type: .Mod,
            a: try parseVariable(String(splitInstruction[1])),
            b: try parseValue(String(splitInstruction[2]))
        )
    case "eql":
        return Instruction(
            type: .Eql,
            a: try parseVariable(String(splitInstruction[1])),
            b: try parseValue(String(splitInstruction[2]))
        )
    default:
        throw ScriptError.ParseInstruction
    }
}

@main
enum Script {
    static func main() throws {
        let instructions = try readFileInCwd(file: "/Day-24-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { try parseInstruction(String($0)) }
        
        /// Welp, turns out the ALU was a waste of time. At least I had fun
        /// doing that part!
        let alu = Alu()
        
        let inputInstructions = try readFileInCwd(file: "/Day-24-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
        
        let pushPopInstructions = inputInstructions
            .filter { $0.contains("div z ") }
            .map {Int($0.split(separator: " ")[2])!}
        
        let compareDigits = inputInstructions
            .filter { $0.contains("add x ") }
            .map {Int($0.split(separator: " ")[2])}
            .compactMap {$0}
        
        let offsetDigits = inputInstructions
            .filter { $0.contains("add y ") }
            .map {Int($0.split(separator: " ")[2])}
            .compactMap {$0}
            .filter { $0 != 1 && $0 != 25 }
        
        print("Push or pop sequence: ", pushPopInstructions)
        print("compare digits: ", compareDigits)
        print("offset digits: ", offsetDigits)

        var stack: [Array.Index] = []
        var pushPopPairs: [(pushIndex: Int, popIndex: Int)] = []
        for (index, pushOrPopInstruction) in pushPopInstructions.enumerated() {
            if pushOrPopInstruction == 1 {
                /// 1 means we are "pushing" to the stack.
                stack.append(index)
            } else {
                /// 26 means we are "popping" from the stack.
                let pushIndex = stack.popLast()!
                pushPopPairs.append((
                    pushIndex: pushIndex,
                    popIndex: index
                ))
            }
        }
        
        func largestNumbers(
            for diff: Int
        ) -> (leftMostDigit: Int, rightMostDigit: Int) {
            /// Finds the largest compatible numbers by starting from 9
            /// and going down to 1.
            for leftMostDigit in (1...9).reversed() {
                let rightMostDigit = leftMostDigit + diff
                if rightMostDigit < 1 || rightMostDigit > 9 {
                    continue
                }
                return (
                    leftMostDigit: leftMostDigit,
                    rightMostDigit: rightMostDigit
                )
            }
            print("This... shouldn't happen")
            exit(1)
        }
        
        var part1Numbers: [Int] = Array(
            repeating: 0,
            count: pushPopInstructions.count
        )
        for pushPopPair in pushPopPairs {
            let diff = offsetDigits[pushPopPair.pushIndex] +
                compareDigits[pushPopPair.popIndex]
            let (leftMostDigit, rightMostDigit) = largestNumbers(for: diff)
            part1Numbers[pushPopPair.pushIndex] = leftMostDigit
            part1Numbers[pushPopPair.popIndex] = rightMostDigit
        }
        print("Part 1: ", part1Numbers.reduce("") {$0 + String($1)})
        let part1Output = try alu.process(instructions, with: part1Numbers)
        print("MONAD Z Output: ", part1Output[.Z]!)
        
        func smallestNumbers(
            for diff: Int
        ) -> (leftMostDigit: Int, rightMostDigit: Int) {
            /// Finds the smallest compatible numbers by starting from 1
            /// and going up to 9.
            for leftMostDigit in (1...9) {
                let rightMostDigit = leftMostDigit + diff
                if rightMostDigit < 1 || rightMostDigit > 9 {
                    continue
                }
                return (
                    leftMostDigit: leftMostDigit,
                    rightMostDigit: rightMostDigit
                )
            }
            print("This... shouldn't happen")
            exit(1)
        }
        
        var part2Numbers: [Int] = Array(
            repeating: 0,
            count: pushPopInstructions.count
        )
        for pushPopPair in pushPopPairs {
            let diff = offsetDigits[pushPopPair.pushIndex] +
                compareDigits[pushPopPair.popIndex]
            let (leftMostDigit, rightMostDigit) = smallestNumbers(for: diff)
            part2Numbers[pushPopPair.pushIndex] = leftMostDigit
            part2Numbers[pushPopPair.popIndex] = rightMostDigit
        }
        
        print("Part 2: ", part2Numbers.reduce("") {$0 + String($1)})
        let part2Output = try alu.process(instructions, with: part2Numbers)
        print("MONAD Z Output: ", part2Output[.Z]!)
    }
}
