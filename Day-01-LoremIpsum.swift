import Foundation

enum ScriptError: Error {
    case EnvironmentPathNotDefined
    case FileCouldNotBeRead
}

@main
enum Script {
    static func main() throws {
        print("Hello Xcode (Day 1)")
        guard let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] else {
            throw ScriptError.EnvironmentPathNotDefined
        }
        let inputPath = URL(fileURLWithPath: srcRoot + "/Day-01-Input.txt")
        var input = ""
        do {
            input = try String(contentsOf: inputPath, encoding: .utf8)
        } catch {
            throw ScriptError.FileCouldNotBeRead
        }
        print(input)
    }
}
