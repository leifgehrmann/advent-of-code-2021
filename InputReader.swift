import Foundation

enum InputReaderError: Error {
    case FileCouldNotBeRead
}

private func getCwd() -> String {
    if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
        return srcRoot
    }
    return FileManager.default.currentDirectoryPath
}

/// Every puzzle reads from an input file, so every puzzle will be using this function
/// to read from the input.
func readFileInCwd(file: String) throws -> String {
    let inputPath = URL(fileURLWithPath: getCwd() + file)
    do {
        return try String(contentsOf: inputPath, encoding: .utf8)
    } catch {
        throw InputReaderError.FileCouldNotBeRead
    }
}
