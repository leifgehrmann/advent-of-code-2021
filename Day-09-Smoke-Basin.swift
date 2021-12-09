import Foundation

func part1(_ map: [[Int]]) -> Int {
    let height = map.count
    let width = map[0].count
    var riskLevel = 0
    for y in 0..<height {
        for x in 0..<width {
            var adjacentToHigher = 0
            if x - 1 < 0 || map[y][x] < map[y][x - 1] {
                adjacentToHigher += 1
            }
            if x + 1 >= width || map[y][x] < map[y][x + 1] {
                adjacentToHigher += 1
            }
            if y - 1 < 0 || map[y][x] < map[y - 1][x] {
                adjacentToHigher += 1
            }
            if y + 1 >= height || map[y][x] < map[y + 1][x] {
                adjacentToHigher += 1
            }
            if adjacentToHigher == 4 {
                riskLevel += 1 + map[y][x]
            }
        }
    }
    
    return riskLevel
}

class Basin {
    var size: Int;
    
    init(size: Int) {
        self.size = size
    }
}

/// This extension allows us to use `.sorted()`.
extension Basin: Comparable {
    static func == (lhs: Basin, rhs: Basin) -> Bool {
        lhs.size == rhs.size
    }
    
    static func <(lhs: Basin, rhs: Basin) -> Bool {
        lhs.size < rhs.size
    }
}

/// This solution scans through each row of the map to accumulate the basin size.
///
/// Other Advent-of-Coders will probably have used recursion, but recursion is the
/// devils work, and this solution at least avoids stack overflow errors depending
/// on the input.
func part2(_ map: [[Int]]) -> Int {
    let width = map[0].count
    
    var basins: [Basin] = []
    var previousBasinRow = Array.init(repeating: nil as Basin?, count: width)
    
    for row in map {
        var currentBasinRow = Array.init(repeating: nil as Basin?, count: width)
        
        /// From the previous row find all the basins and if the height
        /// value is not `9`, pull down the basin and increase the count.
        /// Otherwise, we create a new basin from scratch.
        for (colIndex, col) in row.enumerated() {
            if col == 9 {
                continue
            }
            if previousBasinRow[colIndex] != nil {
                currentBasinRow[colIndex] = previousBasinRow[colIndex]
            } else {
                let newBasin = Basin(size: 0)
                currentBasinRow[colIndex] = newBasin
                basins.append(newBasin)
            }
            currentBasinRow[colIndex]?.size += 1
        }
        
        /// On the current row, iterate left-to-right, discovering and merging basins
        /// in the iteration when they are adjacent.
        for (colIndex, col) in row.enumerated() {
            /// Check that the current cell or the next cell is not a height of 9,
            /// because those do not count as being in any basin.
            if (
                col == 9 ||
                colIndex + 1 >= width ||
                row[colIndex + 1] == 9
            ) {
                continue
            }

            guard let currentBasin = currentBasinRow[colIndex] else {
                continue
            }
            guard let adjacentBasin = currentBasinRow[colIndex + 1] else {
                continue
            }
            
            /// If the adjacent cell's basin is the same as the current cell's basin, we
            /// don't need to do anything and can continue to the next cell.
            if currentBasin === adjacentBasin {
                continue
            }
            
            /// Otherwise, we need to merge the basins together. This is done by
            /// summing up the the size of both basins and just creating a new basin.
            currentBasin.size += adjacentBasin.size
            
            /// Replace all existing instances of `adjacentBasin` in the current
            /// row we are iterating with the merged basin.
            currentBasinRow = currentBasinRow.map {
                $0 === adjacentBasin ? currentBasin : $0
            }
            
            /// Remove any instances of the adjacent basin because it has been
            /// merged with the current basin.
            basins = basins.filter { $0 !== adjacentBasin }
        }
        
        previousBasinRow = currentBasinRow
    }
    
    /// Finally, find the largest 3 basins and multiply their sizes together.
    let sortedBasins = basins.sorted().reversed()
    let threeLargestBasins = sortedBasins.prefix(3)
    return threeLargestBasins.reduce(1) {$0 * $1.size}
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-09-Input.txt")
        
        let map = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map {$0.map {Int(String($0))}.compactMap{$0}}
        
        print("Part 1: ", part1(map))
        print("Part 2: ", part2(map))
    }
}
