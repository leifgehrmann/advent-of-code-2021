import Foundation

struct Rule {
    let pair: String;
    let insertion: String;
}

typealias ElementCounts = [String.Element: Int]
typealias PairCounts = [String: Int]

extension String {
    func getElementPair(at index: Int) -> String {
        let pairRangeStart = self.index(self.startIndex, offsetBy: index)
        let pairRangeEnd = self.index(self.startIndex, offsetBy: index + 1)
        let pairRange = pairRangeStart...pairRangeEnd
        return String(self[pairRange])
    }
}

/// The solution I made for part 1. It is inefficient because we are manipulating a massive string for higher
/// iterations in the template growth.
func inefficientProcess(
    _ template: String,
    _ rules: [Rule]
) -> String {
    var index = 0
    var newString = String(template.first!)
    while index < template.count - 1 {
        let pair = template.getElementPair(at: index)
        index += 1
        
        if let rule = rules.filter({ $0.pair == pair }).first {
            newString += rule.insertion + String(pair.last!)
        } else {
            newString += String(pair.last!)
        }
    }
    
    return newString
}

/// The solution for part 2. It is more efficient because rather than handling a massive string, it is instead
/// dealing with the counts for each pair in the template sequence. The drawback with this solution of
/// course is we don't know where in the sequence the elements appear.
func efficientProcess(
    _ pairCounts: PairCounts,
    _ rules: [Rule]
) -> PairCounts {
    var newPairCounts: PairCounts = [:]
    for (pair, counts) in pairCounts {
        if let rule = rules.filter({ $0.pair == pair }).first {
            let newLeftPair = String(pair.first!) + rule.insertion
            let newRightPair = rule.insertion + String(pair.last!)
            newPairCounts[newLeftPair] = (newPairCounts[newLeftPair] ?? 0) + counts
            newPairCounts[newRightPair] = (newPairCounts[newRightPair] ?? 0) + counts
        } else {
            newPairCounts[pair] = (newPairCounts[pair] ?? 0) + counts
        }
    }
    return newPairCounts
}

/// Converts a template string into a dictionary of counts for each pair in the sequence.
func convertTemplateToPairCounts(_ template: String) -> PairCounts {
    var pairCounts: PairCounts = [:]
    var index = 0
    while index < template.count - 1 {
        let pair = template.getElementPair(at: index)
        pairCounts[pair] = (pairCounts[pair] ?? 0) + 1
        index += 1
    }
    return pairCounts
}

/// Returns the least and most common elements given the template string. This is as simple as count the
/// number of appearances for each character in the template.
func findLeastAndMostCommonElements(
    in template: String
) -> (least: Int, most: Int) {
    var elementCounts: ElementCounts = [:]
    for element in template {
        elementCounts[element] = (elementCounts[element] ?? 0) + 1
    }
    return (
        least: elementCounts.values.min()!,
        most: elementCounts.values.max()!
    )
}

/// Returns the least and most common elements given an initial template and list of pair counts.
///
/// 1. For each pair, we sum up the total counts for each element in the pair.
/// 2. We then divide it by two because we are effectively double-counting the elements.
/// 3. We finally need to account for the ends of the template string. Thankfully the initial template string
///   tells us which elements we have under-counted, so it is a trivial as adding one for each character at
///   the front and end.
func findLeastAndMostCommonElements(
    initialTemplate: String,
    pairCounts: PairCounts
) -> (least: Int, most: Int) {
    var elementCounts: ElementCounts = [:]
    for (pair, count) in pairCounts {
        for element in pair {
            elementCounts[element] = (elementCounts[element] ?? 0) + count
        }
    }
    
    for element in elementCounts.keys {
        elementCounts[element] = elementCounts[element]! / 2
    }
    
    elementCounts[initialTemplate.first!]! += 1
    elementCounts[initialTemplate.last!]! += 1

    return (
        least: elementCounts.values.min()!,
        most: elementCounts.values.max()!
    )
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-14-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let splitInput = input.components(separatedBy: "\n\n")
        
        var template = splitInput[0]
        let rules = splitInput[1].split(separator: "\n")
            .map { $0.components(separatedBy: " -> ") }
            .map { Rule(pair: String($0[0]), insertion: String($0[1])) }
        
        /// The first 10 steps use the algorithm I wrote for part 1, which is inefficient because we are
        /// manipulating a massive String.
        for _ in 1...10 {
            template = inefficientProcess(template, rules)
        }
        let (leastCountPart1, mostCountPart1) = findLeastAndMostCommonElements(
            in: template
        )
        print("Part 1: ", mostCountPart1 - leastCountPart1)
        
        /// For the next 30 steps, we need to do things more efficiently. Rather than keeping track of
        /// a massive string, we instead count the number of pairs within the string, and update the
        /// counts of each pairs depending on the rules.
        var pairCounts: PairCounts = convertTemplateToPairCounts(template)
        for _ in 11...40 {
            pairCounts = efficientProcess(pairCounts, rules)
        }
        let (leastCountPart2, mostCountPart2) = findLeastAndMostCommonElements(
            initialTemplate: template,
            pairCounts: pairCounts
        )
        print("Part 2: ", mostCountPart2 - leastCountPart2)
    }
}
