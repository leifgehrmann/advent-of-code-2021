import Foundation

struct Entry {
    /// 10 unique signal patterns.
    let signals: [String]
    /// 4-digit output value.
    let output: [String]
}

func parseLine(line: String) -> Entry {
    let splitLine = line.components(separatedBy: " | ")
    let signalsSplit = splitLine[0].split(separator: " ")
    let outputSplit = splitLine[1].split(separator: " ")
    return Entry(
        signals: signalsSplit.map {String($0)},
        output: outputSplit.map {String($0)}
    )
}

func part1(entries: [Entry]) -> Int {
    /// 1 = 2 segments.
    /// 4 = 4 segments.
    /// 7 = 3 segments.
    /// 8 = 7 segments.
    let uniquelySegmentedNumbers = [2, 4, 3, 7]
    return entries.reduce(0) {
        accumulator, entry in
        let appearences = entry.output
            .map {$0.count} // Count the length of the active segments.
            .filter {uniquelySegmentedNumbers.contains($0)}
            .count
        return accumulator + appearences
    }
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-08-Input.txt")
        let entries = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { parseLine(line: String($0)) }
        
        print("Part 1: ", part1(entries: entries))
    }
}
