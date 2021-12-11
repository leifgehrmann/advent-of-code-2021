import Foundation

/// Returns all the adjacent octopuses for a given map, including diagonal ones.
func getAdjacentOctopuses(
    for map: [[Int]],
    at cell: (x: Int, y: Int)
) -> [(x: Int, y: Int)] {
    var adjacentOctopuses: [(x: Int, y: Int)] = []
    for dy in -1...1  {
        for dx in -1...1 {
            /// Skip the center cell.
            if dx == 0 && dy == 0 {
                continue
            }
            /// Skip out-of-bounds cells.
            if (
                cell.y + dy < 0 ||
                cell.x + dx < 0 ||
                cell.y + dy >= map.count ||
                cell.x + dx >= map[0].count
            ) {
                continue
            }
            adjacentOctopuses.append((x: cell.x + dx, y: cell.y + dy))
        }
    }
    return adjacentOctopuses
}

/// Executes one step of the octopuses' bioluminescnet cycle.
func step(map: [[Int]]) -> (flashes: Int, newMap: [[Int]]) {
    let flashEnergyLevel = 10
    var newMap = map
    
    /// First, the energy level of each octopus increases by 1.
    newMap = newMap.map { $0.map { $0 + 1 }}
    
    /// We need to keep track of which octopus has flashed, so we create a map of
    /// all the flashes octopuses.
    var mapOfFlashed = newMap.map { $0.map { _ in false }}
    
    /// For each octopus that has the energy to flash, spread the energy to the adjacent
    /// octopuses. We iterate until all octopuses have flashed once.
    var octopusFlashedWhileCascading: Bool
    repeat {
        /// We keep track of any flashes so we know whether to iterate through the
        /// map again to cascade the energy levels. We reset it here for each
        /// cascade.
        octopusFlashedWhileCascading = false
        
        /// For each octopus that has the energy to flash, spread the energy to the
        /// adjacent octopuses. We iterate until all octopuses with the energy to flash
        /// have successfully flashed once.
        for (y, row) in newMap.enumerated() {
            for (x, col) in row.enumerated() {
                /// Skip octopuses that do not have the enegery to flash.
                if (col < flashEnergyLevel ) {
                    continue
                }
                
                /// Skip octopuses that have flashed.
                if (mapOfFlashed[y][x]) {
                    continue
                }
                
                /// Register the octopus as flashed.
                mapOfFlashed[y][x] = true
                octopusFlashedWhileCascading = true
                
                /// Get the adjacent octopuses and raise their
                /// energy level.
                let adjacentOctopuses = getAdjacentOctopuses(
                    for: newMap,
                    at: (x: x, y: y)
                )
                for point in adjacentOctopuses {
                    newMap[point.y][point.x] += 1
                }
            }
        }
    } while (octopusFlashedWhileCascading)
    
    /// Finally, any octopus that flashed during this step has its energy level set to 0,
    /// as it used all of its energy to flash.
    newMap = newMap.map { $0.map { $0 >= flashEnergyLevel ? 0 : $0 }}
    
    /// Count the number of flashes for this step.
    let flashes = mapOfFlashed.reduce(0) { $0 + $1.filter {$0}.count }
    
    return (flashes: flashes, newMap: newMap)
}

/// Prints the map of the octopuses' energy levels.
func printMap(_ map: [[Int]]) {
    let stringifiedRows = map.map { $0.reduce("") { $0 + String($1) } }
    print(stringifiedRows.reduce("") { $0 + String($1) + "\n" })
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-11-Input.txt")
        
        var map = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map {$0.map {Int(String($0))}.compactMap{$0}}

        printMap(map)
        
        /// To solve Part 2, we loop endlessly until all octopuses flash simulatneously.
        /// To solve Part 1, we wait until the 100th iteration and sum the total number of flashes.
        var steps = 0
        var totalFlashesAfter100Steps = 0
        var totalFlashesInLastStep = 0
        let maxNumberToFlashSimulaneously = map.count * map[0].count
        repeat {
            let stepResult = step(map: map)
            steps += 1
            
            map = stepResult.newMap
            totalFlashesInLastStep = stepResult.flashes
            if steps <= 100 {
                totalFlashesAfter100Steps += stepResult.flashes
            }
            
            printMap(map)
        } while (totalFlashesInLastStep != maxNumberToFlashSimulaneously)

        print("Part 1: ", totalFlashesAfter100Steps)
        print("Part 2: ", steps)
    }
}
