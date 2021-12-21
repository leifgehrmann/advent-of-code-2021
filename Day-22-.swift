import Foundation

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-22-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
