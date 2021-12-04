import Foundation

func part1(signals: [String]) -> Int {
    let bitSequenceLength = 12
    var commonBitSequence = Array(repeating: 0, count: bitSequenceLength)
    
    // Iterate each signal bit and keep a count of how many "1"s appears
    // in each bit sequence versus how many "0"s.
    for signal in signals {
        for (index, char) in signal.enumerated() {
            commonBitSequence[index] += char == "1" ? 1 : -1
        }
    }

    // Convert the net values to an array of bits.
    let gammaBitSequence = commonBitSequence.map { $0 > 0 ? 1 : 0 }
    
    // Convert the bit sequence into an integer.
    let gamma = gammaBitSequence.reduce(0) { $0 << 1 + $1 }
    
    // Invert the gamma value to get the epsilon.
    let mask = (1 << bitSequenceLength) - 1
    let epsilon = ~gamma & mask
    
    print("Gamma: ", gamma)
    print("Epsilon: ", epsilon)
    return gamma * epsilon
}

enum MostCommonBit {
    case Zero // When "0" is the most common bit.
    case None // When there is an equal number of "0" and "1" bits.
    case One // When "1" is the most common bit.
}

func getMostCommonBit(in signals: [String], at bitPosition: Int) -> MostCommonBit {
    var bitCount = 0
    for signal in signals {
        let bitPositionIndex = signal.index(signal.startIndex, offsetBy: bitPosition)
        bitCount += signal[bitPositionIndex] == "1" ? 1 : -1
    }
    if bitCount == 0 {
        return .None
    }
    return bitCount > 0 ? .One : .Zero
}

func filter(signals: [String], for bit: Character, at bitPosition: Int) -> [String] {
    return signals.filter { signal -> Bool in
        let bitPositionIndex = signal.index(signal.startIndex, offsetBy: bitPosition)
        return signal[bitPositionIndex] == bit
    }
}

func convertSignalToInt(_ signal: String) -> Int {
    return signal.reduce(0) { $0 << 1 + (($1 == "1") ? 1 : 0) }
}

enum LifeSupportRatingType {
    case OxygenGeneratorRating
    case CO2ScrubberRating
}

func readLifeSupportRating(_ type: LifeSupportRatingType, for signals: [String]) -> Int {
    let bitSequenceLength = 12
    var filteredSignals = signals
    for bitPosition in 0...bitSequenceLength {
        var commonBit: Character
        switch getMostCommonBit(in: filteredSignals, at: bitPosition) {
            case .Zero: commonBit = "0"; break;
            // If "0" and "1" are equally common, keep values with a "1" in the position
            // being considered.
            case .None: commonBit = "1"; break;
            case .One: commonBit = "1"; break;
        }
        
        if type == .CO2ScrubberRating {
            // For the CO2 scrubber we want the least common value, so we flip the bit.
            // The same applies when "0" and "1" are equally common.
            commonBit = commonBit == "1" ? "0" : "1"
        }
        
        // Keep only numbers selected by the bit criteria for the type of rating value
        // for which we are searching. Discard numbers which do not match the bit criteria.
        filteredSignals = filter(signals: filteredSignals, for: commonBit, at: bitPosition)
        
        // If we only have one signal left, we break here;
        // This is the rating value for which we are searching.
        if filteredSignals.count == 1 {
            return convertSignalToInt(filteredSignals[0])
        }
    }

    // If we are at the end of processing all the bitPositions, in theory, this
    // means every leftover byte sequence should be identical. So we can just
    // return the first value in the array.
    return convertSignalToInt(filteredSignals[0])
}

func part2(signals: [String]) -> Int {
    let oxygenGeneratorRating = readLifeSupportRating(.OxygenGeneratorRating, for: signals)
    let co2ScrubberRating = readLifeSupportRating(.CO2ScrubberRating, for: signals)
    
    print("Oxygen generator rating: ", oxygenGeneratorRating)
    print("CO2 scrubber rating: ", co2ScrubberRating)
    
    return oxygenGeneratorRating * co2ScrubberRating
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-03-Input.txt")
        
        let signals = input
            .split(separator: "\n") // Split by line
            .map { String($0) } // Convert String SubSequence to String
        
        print("Part 1: ", part1(signals: signals))
        print("Part 2: ", part2(signals: signals))
    }
}
