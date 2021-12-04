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
        let input = try readFileInCwd(file: "/Day-05-Input.txt")
    }
}
