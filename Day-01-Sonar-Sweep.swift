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
    let inputPath = URL(fileURLWithPath: getCwd() + "/Day-01-Input.txt")
    do {
        return try String(contentsOf: inputPath, encoding: .utf8)
    } catch {
        throw ScriptError.FileCouldNotBeRead
    }
}

func countIncreasesInDepth(depths: [Int]) -> Int {
    var numberOfIncreases = 0
    var previousDepth: Int? = nil
    
    for depth in depths {
        if previousDepth != nil, depth > previousDepth! {
            numberOfIncreases += 1
        }
        previousDepth = depth
    }

    return numberOfIncreases
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-01-Input.txt")
        let depthStrings = input.split(separator: "\n")
        
        // flatMap will remove any Optional Integers
        let depths = depthStrings.map { Int($0) }.compactMap { $0 }

        print(countIncreasesInDepth(depths: depths))
    }
}
