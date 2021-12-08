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
    let segments = "abcdefg"
    var intersectedSignal = ""
    for segment in segments {
        if a.contains(segment) && b.contains(segment) {
            intersectedSignal.append(segment)
        }
    }
    return intersectedSignal
}

func subtract(_ a: String, from b: String) -> String {
    let segments = "abcdefg"
    var signalDifference = ""
    for segment in segments {
        if (b.contains(segment) && !a.contains(segment)) {
            signalDifference.append(segment)
        }
    }
    return signalDifference
}

func deduceThree(_ signals234: [String]) -> String {
    // Intersections of 2, 3, 5 can be used to deduce which
    // signal represents 3. Because only the intersection of
    // 2 and 5 result in an intersection of 3.
    let i1 = intersectSignals(signals234[0], signals234[1])
    let i2 = intersectSignals(signals234[0], signals234[2])
    if i1.count == 3 { return signals234[2] }
    if i2.count == 3 { return signals234[1] }
    return signals234[0]
}

func deduceTwoAndFive(_ three: String, _ four: String, _ signals25: [String]) -> (String, String) {
    // Intersection of 3 and 4 should result in a single segment b.
    // That can be used to deduce numbers 2 and 5.
    let difference = subtract(three, from: four)
    if (difference.count != 1) {
        print(three, four)
        print(difference)
        return ("ERROR", "ERROR")
    }
    if signals25[0].contains(difference) {
        return (signals25[1], signals25[0])
    }
    return (signals25[0], signals25[1])
}

func deduceSix(_ seven: String, _ signals069: [String]) -> String {
    if (subtract(seven, from: signals069[0]).count == 4) { return signals069[0] }
    if (subtract(seven, from: signals069[1]).count == 4) { return signals069[1] }
    return signals069[2]
}

func deduceZeroAndNine(_ three: String, _ signals09: [String]) -> (String, String) {
    if (subtract(three, from: signals09[0]).count == 2) {
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
    
    let three = deduceThree(signals235)
    let signals25 = signals235.filter { $0 != three }
    let (two, five) = deduceTwoAndFive(three, four, signals25)
    
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
