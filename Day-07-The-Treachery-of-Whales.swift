import Foundation

enum ScriptError: Error {
    case NoPositionsFound
}

func linear(_ a: Int, _ b: Int) -> Int {
    return abs(a - b)
}

func triangular(_ a: Int, _ b: Int) -> Int {
    let d = linear(a, b)
    // Thanks OEIS for letting me be super lazy!
    // https://oeis.org/A000217
    return d * (d+1) / 2
}

func calculateMinimumFuel(
    for positions: [Int],
    costFunction: (Int, Int) -> Int
) throws -> Int {
    var minFuelUsed: Int?
    for index in 0..<positions.count {
        let positionPivot = positions[index]
        let fuelUsedAtPivot = positions
            .map {costFunction($0, positionPivot)}
            .reduce(0, +)
        if minFuelUsed == nil || fuelUsedAtPivot < minFuelUsed! {
            minFuelUsed = fuelUsedAtPivot
        }
    }
    
    // Check the solution is not nil. If it is, that means the array was empty.
    guard let solution = minFuelUsed else {
        throw ScriptError.NoPositionsFound
    }
    return solution
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-07-Input.txt")
        let positions = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: ",")
            .map { Int($0) }
            .compactMap {$0}

        print("Part 1: ", try calculateMinimumFuel(for: positions, costFunction: linear))
        print("Part 2: ", try calculateMinimumFuel(for: positions, costFunction: triangular))
    }
}
