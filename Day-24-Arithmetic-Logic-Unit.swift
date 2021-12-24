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
                result = getValueAsInt(instruction.a) + getValueAsInt(instruction.b)
            case .Mul:
                result = getValueAsInt(instruction.a) * getValueAsInt(instruction.b)
            case .Div:
                let b = getValueAsInt(instruction.b)
                if (b == 0) {
                    throw ScriptError.DivideByZero
                }
                result = getValueAsInt(instruction.a) / getValueAsInt(instruction.b)
            case .Mod:
                let a = getValueAsInt(instruction.a)
                let b = getValueAsInt(instruction.b)
                if (a < 0 || b <= 0) {
                    throw ScriptError.ModuloNegative
                }
                result = getValueAsInt(instruction.a) % b
            case .Eql:
                result = getValueAsInt(instruction.a) == getValueAsInt(instruction.b) ? 1 : 0
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

func splitModelNumber(_ number: Int) -> [Int] {
    return String(number).map({Int(String($0))}).compactMap({$0})
}

@main
enum Script {
    static func main() throws {
        let instructions = try readFileInCwd(file: "/Day-24-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { try parseInstruction(String($0)) }
        
        print(instructions)
        
        let alu = Alu()
        
        
        let modelNumber = splitModelNumber(1)
        print(modelNumber)
        let output = try alu.process(instructions, with: modelNumber)
        print("W: ", output[.W]!)
        print("X: ", output[.X]!)
        print("Y: ", output[.Y]!)
        print("Z: ", output[.Z]!)
    }
}
