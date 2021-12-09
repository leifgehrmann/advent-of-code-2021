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

extension Basin: Comparable {
    static func == (lhs: Basin, rhs: Basin) -> Bool {
        lhs.size == rhs.size
    }
    
    static func <(lhs: Basin, rhs: Basin) -> Bool {
        lhs.size < rhs.size
    }
}

func mergeBasins(_ a: Basin, _ b: Basin) -> Basin {
    return Basin(size: a.size + b.size)
}

func part2(_ map: [[Int]]) -> Int {
    let width = map[0].count
    
    var basins: [Basin] = []
    var previousBasinRow = Array.init(repeating: nil as Basin?, count: width)
    
    for row in map {
        var currentBasinRow = Array.init(repeating: nil as Basin?, count: width)
        
        // From the previous row find all the basins and if the height
        // value is not 9, pull down the basin and increase the count.
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
        
        // On the current row, iterate left-to-right, discovering and merging with basins
        // in the iteration.
        for (colIndex, col) in row.enumerated() {
            if col == 9 {
                continue
            }
            if colIndex + 1 >= width {
                continue
            }
            if row[colIndex + 1] == 9 {
                continue
            }
            guard let currentBasin = currentBasinRow[colIndex] else {
                continue
            }
            guard let adjacentBasin = currentBasinRow[colIndex + 1] else {
                continue
            }
            
            if currentBasin === adjacentBasin{
                continue
            }
            
            let newBasin = mergeBasins(currentBasin, adjacentBasin)
            
            // Replace all existing instacnes of currentBasin and nextBasin
            // with the newBasin.
            currentBasinRow = currentBasinRow
                .map {$0 === adjacentBasin ? newBasin : $0}
                .map {$0 === currentBasin ? newBasin : $0}
            
            // Remove the old basins.
            basins = basins.filter { $0 !== currentBasin }
            basins = basins.filter { $0 !== adjacentBasin }
            basins.append(newBasin)
        }
        
        previousBasinRow = currentBasinRow
    }
    
    // Finally, find the largest 3 basins and multiply their size together.
    let sortedBasins = basins.sorted()
    
    let firstLargest = sortedBasins[basins.count - 1].size
    let secondLargest = sortedBasins[basins.count - 2].size
    let thirdLargest = sortedBasins[basins.count - 3].size
    
    return firstLargest * secondLargest * thirdLargest
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
