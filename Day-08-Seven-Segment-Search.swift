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
        /// Convert String.SubString to String.
        /// We also sort the characters into alphabetical order, since
        /// I believe it'll make comparisons easier later on.
        signals: signalsSplit.map {String($0.sorted())},
        output: outputSplit.map {String($0.sorted())}
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

func intersectSignals(_ a: String, _ b: String) -> String {
    /// Returns the intersecting segments for a signal.
    /// For example, the intersection of `acg` and `abcg`, the return will be `cg`.
    var intersectedSignal = ""
    for aElement in a {
        if b.contains(aElement) {
            intersectedSignal.append(aElement)
        }
    }
    return intersectedSignal
}

func deduceThree(_ one: String, _ signals235: [String]) -> String {
    /// Intersection of 1 and 2 should result in 1 segments.
    /// Intersection of 1 and 3 should result in 2 segments.
    /// Intersection of 1 and 5 should result in 1 segments.
    if intersectSignals(one, signals235[0]).count == 2 { return signals235[0] }
    if intersectSignals(one, signals235[1]).count == 2 { return signals235[1] }
    return signals235[2]
}

func deduceTwoAndFive(_ four: String, _ signals25: [String]) -> (String, String) {
    /// Intersection 4 and 2 should result in 2 segments.
    /// Intersection 4 and 5 should result in 3 segments.
    if intersectSignals(four, signals25[0]).count == 2 {
        return (signals25[0], signals25[1])
    }
    return (signals25[1], signals25[0])
}

func deduceSix(_ seven: String, _ signals069: [String]) -> String {
    /// Intersection of 7 and 0 should result in 3 segments.
    /// Intersection of 7 and 9 should result in 3 segments.
    /// Intersection of 7 and 6 should result in 2 segments.
    /// Therefore we can deduce 6 because of the unique number of intersections.
    if (intersectSignals(seven, signals069[0]).count == 2) { return signals069[0] }
    if (intersectSignals(seven, signals069[1]).count == 2) { return signals069[1] }
    return signals069[2]
}

func deduceZeroAndNine(_ three: String, _ signals09: [String]) -> (String, String) {
    /// Intersection of 3 and 0 should result in 2 segments.
    /// Intersection of 3 and 9 should result in 1 segments.
    if (intersectSignals(three, signals09[0]).count == 4) {
        return (signals09[0], signals09[1])
    }
    return (signals09[1], signals09[0])
}

func deduceSignals(_ signals: [String]) -> [String] {
    let one = signals.filter { $0.count == 2 }[0]
    let four = signals.filter { $0.count == 4 }[0]
    let seven = signals.filter { $0.count == 3 }[0]
    let eight = signals.filter { $0.count == 7 }[0]
    
    let signals235 = signals.filter { $0.count == 5 }
    let signals069 = signals.filter { $0.count == 6 }
    
    let three = deduceThree(one, signals235)
    let signals25 = signals235.filter { $0 != three }
    let (two, five) = deduceTwoAndFive(four, signals25)
    
    let six = deduceSix(seven, signals069)
    let signals09 = signals069.filter { $0 != six }
    let (zero, nine) = deduceZeroAndNine(three, signals09)
    
    return [zero, one, two, three, four, five, six, seven, eight, nine]
}

func part2(entries: [Entry]) -> Int {
    var sum = 0
    for entry in entries {
        let signalMap = deduceSignals(entry.signals)
        var translatedOutput = 0
        for digit in entry.output {
            translatedOutput *= 10
            let number = signalMap.firstIndex {$0 == digit}!
            translatedOutput += number
        }
        sum += translatedOutput
    }
    return sum
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
        print("Part 2: ", part2(entries: entries))
    }
}
