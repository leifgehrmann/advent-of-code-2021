import Foundation

struct Position: Hashable {
    let x: Int;
    let y: Int;
}

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

func cost(in map: [[Int]], at position: Position) -> Int {
    return map[position.y][position.x]
}

func dijkstra(
    map: [[Int]],
    from start: Position,
    to end: Position
) -> (riskSum: Int, path: [Position]) {
    var parents: [Position: Position] = [:]
    // toProcess is an array sorted by the cost it takes to travel to
    // that destination.
    var toProcess: [(origin: Position?, position: Position, netCost: Int)] = []
    
    toProcess.append((origin: nil, position: start, netCost: 0))
    
    var netCostToEnd = 0
    var iterations = 0
    
    while (toProcess.count > 0) {
        if iterations % 1000 == 0 {
            print(toProcess.count)
        }
        iterations += 1
        let itemToProcess = toProcess.removeFirst()

        let currentPosition = itemToProcess.position
        let currentNetCost = itemToProcess.netCost
        
        // If the current position already exists in the parent array, just
        // ignore it.
        if parents[currentPosition] != nil {
            continue
        }
        
        parents[currentPosition] = itemToProcess.origin
        
        if currentPosition == end {
            netCostToEnd = currentNetCost
            break
        }
        
        let neighbors = neighbors(in: map, at: currentPosition)
        for neighbor in neighbors {
            
            // Skip neighbors that have already been calculated
            if parents[neighbor] != nil {
                continue
            }
            
            let neighborCost = currentNetCost + cost(in: map, at: neighbor)
            let newEntryToProcess = (
                origin: currentPosition,
                position: neighbor,
                netCost: neighborCost
            )
            if let index = toProcess.firstIndex(where: { $0.netCost > neighborCost }) {
                toProcess.insert(newEntryToProcess, at: index)
            } else {
                toProcess.append(newEntryToProcess)
            }
        }
    }
    
    return (riskSum: netCostToEnd, path: [])
}

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
        
        print(dijkstra(map: map, from: start, to: end))
        
        let expandedMap = expandMap(map)
        let expandedEnd = Position(x: mapWidth * 5 - 1, y: mapHeight * 5 - 1)
        
        print(dijkstra(map: expandedMap, from: start, to: expandedEnd))
    }
}
