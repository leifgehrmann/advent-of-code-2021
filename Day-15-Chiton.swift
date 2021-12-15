import Foundation

struct Position: Hashable {
    let x: Int;
    let y: Int;
}

/// Returns the possible neighbors, either up down left or right, for a given
/// position in the map.
func neighbors(in map: [[Int]], at position: Position) -> [Position] {
    let mapHeight = map.count
    let mapWidth = map[0].count
    
    var neighbors: [Position] = []
    if position.x - 1 >= 0 {
        neighbors.append(Position(x: position.x - 1, y: position.y))
    }
    if position.x + 1 < mapWidth {
        neighbors.append(Position(x: position.x + 1, y: position.y))
    }
    if position.y - 1 >= 0 {
        neighbors.append(Position(x: position.x, y: position.y - 1))
    }
    if position.y + 1 < mapHeight {
        neighbors.append(Position(x: position.x, y: position.y + 1))
    }
    return neighbors
}

/// Returns the risk of traveling to a position.
func risk(in map: [[Int]], at position: Position) -> Int {
    return map[position.y][position.x]
}

/// Returns the correct index in the `toProcess` array, sorted by the netRisk.
func binarySearchIndex(
    _ toProcess: [(origin: Position?, position: Position, netRisk: Int)],
    _ newNetRisk: Int
) -> Array.Index {
    var low = toProcess.startIndex
    var high = toProcess.endIndex
    while low != high {
        let mid = toProcess.index(
            low,
            offsetBy: toProcess.distance(from: low, to: high) / 2
        )
        if toProcess[mid].netRisk < newNetRisk {
            low = toProcess.index(after: mid)
        } else {
            high = mid
        }
    }
    return low
}

func dijkstra(
    map: [[Int]],
    from start: Position,
    to end: Position
) -> Int? {
    /// To keep track of which positions have been traversed. The value
    /// represents the neighbor with the lowest risk to the `start` position.
    var parents: [Position: Position] = [:]
    /// To keep track of which position to evaluate next. The array is sorted
    /// by the `netRisk`.
    var toProcess: [(origin: Position?, position: Position, netRisk: Int)] = []
    
    /// Start at the start position, with a `netRisk`
    toProcess.append((origin: nil, position: start, netRisk: 0))
    
    /// Process each element in the queue of entries to process.
    while (toProcess.count > 0) {
        let itemToProcess = toProcess.removeFirst()

        let currentPosition = itemToProcess.position
        let currentNetRisk = itemToProcess.netRisk
        
        /// If `currentPosition` already exists in the parent array, just
        /// ignore it.
        if parents[currentPosition] != nil {
            continue
        }
        
        /// Mark the current position as traversed by saying that the
        /// position's neighbor with the lowest risk is the origin for
        /// this entry.
        parents[currentPosition] = itemToProcess.origin
        
        /// If the `currentPosition` is the end, then we implicitly have
        /// calculated the netRisk it takes to travel to the end. Therefore
        /// we can break the loop and stop the search.
        if currentPosition == end {
            return currentNetRisk
        }
        
        /// Add the neighbors to the `toProcess` queue.
        let neighbors = neighbors(in: map, at: currentPosition)
        for neighbor in neighbors {
            
            /// Skip neighbors that have already been processed.
            if parents[neighbor] != nil {
                continue
            }
            
            /// Create the next entry to process.
            let neighborRisk = currentNetRisk + risk(in: map, at: neighbor)
            let newEntryToProcess = (
                origin: currentPosition,
                position: neighbor,
                netRisk: neighborRisk
            )

            /// Find the correct index to insert the next entry. For
            /// efficiency, we use a binary search to identify the index,
            /// since the array will often be 1000s of entries long.
            let newEntryIndex = binarySearchIndex(toProcess, neighborRisk)
            toProcess.insert(newEntryToProcess, at: newEntryIndex)
        }
    }
    
    return nil
}

/// Takes in the existing map and applies the rules for the map in Part 2.
func expandMap(_ map: [[Int]]) -> [[Int]] {
    let mapHeight = map.count
    let mapWidth = map[0].count
    var newMap = Array(
        repeating: Array(repeating: 0, count: mapWidth * 5),
        count: mapHeight * 5
    )
    
    for my in 0..<5 {
        for mx in 0..<5 {
            for y in 0..<mapHeight {
                for x in 0..<mapHeight {
                    let newY = mapHeight * my + y
                    let newX = mapWidth * mx + x
                    let newRisk = (map[y][x] + mx + my - 1) % 9 + 1
                    newMap[newY][newX] = newRisk
                }
            }
        }
    }
    
    return newMap
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-15-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let map = input.split(separator: "\n")
            .map { $0.map {Int(String($0))}.compactMap {$0} }

        let mapHeight = map.count
        let mapWidth = map[0].count
        let start = Position(x: 0, y: 0)
        let end = Position(x: mapWidth - 1, y: mapHeight - 1)
        
        print(
            "Part 1: ",
            dijkstra(map: map, from: start, to: end) ?? "N/A"
        )
        
        let expandedMap = expandMap(map)
        let expandedEnd = Position(x: mapWidth * 5 - 1, y: mapHeight * 5 - 1)
        
        print(
            "Part 2: ",
            dijkstra(map: expandedMap, from: start, to: expandedEnd) ?? "N/A"
        )
    }
}
