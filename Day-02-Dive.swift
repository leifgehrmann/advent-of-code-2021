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

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-02-Input.txt")
        
        let commandStrings = input.split(separator: "\n")
        let commandTupleStrings = commandStrings.map { $0.split(separator: " ") }
        let commandTuples = commandTupleStrings.map { ($0[0], Int($0[1])!) }
        
        let horizontalSum = commandTuples
            .filter { $0.0 == "forward" }
            .reduce(0) {$1.1 + $0 }
        let verticalSum = commandTuples
            .filter { $0.0 == "down" || $0.0 == "up" }
            .reduce(0) { ($1.1) * ($1.0 == "up" ? -1 : 1) + $0}
        
        print("Vertical positiion: ", verticalSum)
        print("Horizontal position: ", horizontalSum)
        print("Puzzle solution: ", horizontalSum * verticalSum)
    }
}
