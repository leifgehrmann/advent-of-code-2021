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

func countIncreasesInDepth(depths: [Int], withSlidingWindow: Int) -> Int {
    let slidingWindow = withSlidingWindow
    var numberOfIncreases = 0
    var previousDepthSum: Int? = nil

    for i in slidingWindow...depths.count-1-slidingWindow {
        let currentDepths = depths[i-slidingWindow...i+slidingWindow]
        let currentDepthSum = currentDepths.reduce(0, +)
        if previousDepthSum != nil, currentDepthSum > previousDepthSum! {
            numberOfIncreases += 1
        }
        previousDepthSum = currentDepthSum
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

        print("Part 1: ", countIncreasesInDepth(depths: depths))
        print("Part 2: ", countIncreasesInDepth(depths: depths, withSlidingWindow: 1))
    }
}
