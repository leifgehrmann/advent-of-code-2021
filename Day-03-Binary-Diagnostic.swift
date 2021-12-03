import Foundation

enum ScriptError: Error {
    case FileCouldNotBeRead
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

func part1(signals: [String]) -> Int {
    let bitLength = 12
    var commonBitSequence = Array(repeating: 0, count: bitLength)
    
    // Iterate each signal bit and keep a count of how many "1"s appears
    // in each bit sequence versus how many "0"s.
    for signal in signals {
        for (index, char) in signal.enumerated() {
            commonBitSequence[index] += char == "1" ? 1 : -1
        }
    }

    // Convert the net values to an array of bits
    let gammaBitSequence = commonBitSequence.map { $0 > 0 ? 1 : 0 }
    
    // Convert the bit sequence into an integer
    let gamma = gammaBitSequence.reduce(0) { $0 << 1 + $1 }
    
    // Invert the gamma value to get the epsilon
    let mask = (1 << bitLength) - 1
    let epsilon = ~gamma & mask
    
    print("Gamma: ", gamma)
    print("Epsilon: ", epsilon)
    return gamma * epsilon
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-03-Input.txt")
        
        let signals = input
            .split(separator: "\n") // Split by line
            .map { String($0) } // Convert String SubSequence to String
        
        print("Part 1: ", part1(signals: signals))
    }
}
