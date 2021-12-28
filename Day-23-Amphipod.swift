import Foundation

enum AmphipodType: String, Hashable {
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"
}

struct Amphipod: Hashable {
    let type: AmphipodType
    
    func movementCost(steps: Int) -> Int {
        switch (type) {
        case .A: return 1 * steps
        case .B: return 10 * steps
        case .C: return 100 * steps
        case .D: return 1000 * steps
        }
    }
    
    func expectedXPosition() -> Int {
        switch (type) {
        case .A: return 3
        case .B: return 5
        case .C: return 7
        case .D: return 9
        }
    }
}

struct Room: Hashable {
    static func == (lhs: Room, rhs: Room) -> Bool {
        return (
            lhs.position.x == rhs.position.x &&
            lhs.position.y == rhs.position.y
        )
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(position.x)
        hasher.combine(position.y)
    }
    
    let position: (x: Int, y: Int)
}

struct Map {
    let rooms: [Room]
    let roomNeighbors: [Room: [(neighbor: Room, steps: Int)]]
    let distanceMatrix: [Room: [(destination: Room, steps: Int)]]

    func closestSideRoom(
        for amphipod: Amphipod,
        from room: Room
    ) -> (sideRoom: Room, steps: Int) {
        let result = distanceMatrix[room]!
            .filter { $0.destination.position.x == amphipod.expectedXPosition() }
            .sorted { $0.steps < $1.steps }
            .first!
        return (sideRoom: result.destination, steps: result.steps)
    }
}

struct State: Hashable {
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.occupancies.count != lhs.occupancies.count {
            return false
        }
        for (room, amphipod) in lhs.occupancies {
            if rhs.occupancies[room]?.type != amphipod.type {
                return false
            }
        }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        let sortedOccupancies = occupancies.sorted {
            if $0.key.position.y < $1.key.position.y {
                return false
            }
            if $0.key.position.y > $1.key.position.y {
                return true
            }
            if $0.key.position.x < $1.key.position.x {
                return false
            }
            return true
        }
        for (room, amphipod) in sortedOccupancies {
            hasher.combine(room.position.x)
            hasher.combine(room.position.y)
            hasher.combine(amphipod)
        }
    }
    
    let occupancies: [Room: Amphipod]
}

typealias Cost = Int

func printMap(_ map: Map, with state: State) {
    let width = map.rooms.map { $0.position.x }.max()!
    let height = map.rooms.map { $0.position.y }.max()!
    var printableMap = Array(
        repeating: Array(
            repeating: " ",
            count: width + 1
        ),
        count: height + 1
    )
    for room in map.rooms {
        printableMap[room.position.y][room.position.x] = "."
    }
    for (room, amphipod) in state.occupancies {
        printableMap[room.position.y][room.position.x] = amphipod.type.rawValue
    }
    print(
        printableMap.map { $0.reduce("") { $0 + String($1) } }
            .reduce("") { $0 + String($1) + "\n" }
    )
}

/// Amphipods will never move from the hallway into a room unless that room
/// is their destination room and that room contains no amphipods which do not
/// also have that room as their own destination. If an amphipod's starting
/// room is not its destination room, it can stay in that room until it
/// leaves the room. (For example, an Amber amphipod will not move from the
/// hallway into the right three rooms, and will only move into the leftmost
/// room if that room is empty or if it only contains other Amber amphipods.)
func movementAllowed(for amphipod: Amphipod, from: Room, to: Room) -> Bool {
    // Don't allow going up (Just for testing!)
//    if from.position.y > to.position.y {
//        return false
//    }
    
    /// Amphipods can move vertically in the room they are already in,
    /// and they can only move upwards.
    if from.position.y > to.position.y && from.position.x == to.position.x {
        return true
    }
    /// Amphipods can move horizontally along the hallway.
    if to.position.y == 1 {
        return true
    }
    /// Amphipods can enter side room that is their destination, and that
    /// they can only move downwards.
    return from.position.y < to.position.y &&
        to.position.x == amphipod.expectedXPosition()
}

func moveAmphipods(
    from initialState: State,
    with initialCost: Cost,
    using map: Map,
    skipping visitedStatesWithCost: [State: Cost]
) -> [State: Cost] {
    var newStatesWithCost: [State: Cost] = [:]

    for (room, amphipod) in initialState.occupancies {
        let roomNeighbor = map.roomNeighbors[room] ?? []
        for roomNeighbor in roomNeighbor {
            if !movementAllowed(
                for: amphipod,
                from: room,
                to: roomNeighbor.neighbor
            ) {
                continue
            }
            
            /// Check if the room is already occupied by another amphipod.
            if initialState.occupancies[roomNeighbor.neighbor] != nil {
                continue
            }
            
            /// Create the new state.
            var newOccupancies = initialState.occupancies
            newOccupancies.removeValue(forKey: room)
            newOccupancies[roomNeighbor.neighbor] = amphipod
            let newState = State(occupancies: newOccupancies)
            let newCost = initialCost + amphipod.movementCost(
                steps: roomNeighbor.steps
            )

            /// If we've already Skip states that have already been covered.
            if visitedStatesWithCost[newState, default: Int.max] < newCost {
                continue
            }
            
            /// If we've already found a similar step in this iteration, skip it if
            /// the score is less or perhaps greater.
            if newStatesWithCost[newState] != nil {
                continue
            }

            newStatesWithCost[newState] = newCost
        }
    }
    
    return newStatesWithCost
}

func isSolved(_ state: State) -> Bool {
    let amphipodsInCorrectPosition = state.occupancies.filter { $0.key.position.x == $0.value.expectedXPosition() }.count
    return amphipodsInCorrectPosition == state.occupancies.count
}

func lowerBoundCost(state: State, map: Map) -> Int {
    var score = 0
    for (room, amphipod) in state.occupancies {
        let distanceToSideRoom = map.closestSideRoom(for: amphipod, from: room).steps
        score += amphipod.movementCost(steps: distanceToSideRoom)
    }

    return score
}

func stateScore(state: State, cost: Cost, map: Map) -> Int {
    var score = 0
    for (room, amphipod) in state.occupancies {
        let distanceToSideRoom = map.closestSideRoom(for: amphipod, from: room).steps
        score += distanceToSideRoom * distanceToSideRoom
    }

    return score
}

/// Returns the correct index in the `toProcess` array, sorted by the netRisk.
func binarySearchIndex<Element: Hashable>(
    _ priorityQueue: [Element],
    _ priorityValueLookup: [Element: Int],
    _ newPriorityValue: Int
) -> Array.Index {
    var low = priorityQueue.startIndex
    var high = priorityQueue.endIndex
    while low != high {
        let mid = priorityQueue.index(
            low,
            offsetBy: priorityQueue.distance(from: low, to: high) / 2
        )
        if priorityValueLookup[priorityQueue[mid]]! < newPriorityValue {
            low = priorityQueue.index(after: mid)
        } else {
            high = mid
        }
    }
    return low
}

func generateRoomDistances(
    from: Room,
    using roomNeighbors: [Room: [(neighbor: Room, steps: Int)]]
) -> [(destination: Room, steps: Int)] {
    var roomsToProcess: [Room] = [from]
    var distanceToRoom: [Room: Int] = [from: 0]
    var visitedRooms: [Room] = [from]
    
    while roomsToProcess.count > 0 {
        let roomToProcess = roomsToProcess.removeFirst()
        for (neighbor, steps) in roomNeighbors[roomToProcess]! {
            if visitedRooms.contains(neighbor) {
                continue
            }
            distanceToRoom[neighbor] = distanceToRoom[roomToProcess]! + steps
            visitedRooms.append(neighbor)
            roomsToProcess.append(neighbor)
        }
    }
    
    var distanceMatrixForRoom: [(destination: Room, steps: Int)] = []
    for (room, steps) in distanceToRoom {
        distanceMatrixForRoom.append((destination: room, steps: steps))
    }
    return distanceMatrixForRoom
}

func parseMapAndState(_ input: String) -> (
    map: Map,
    state: State
) {
    /// I've hardcoded the problem because it simply isn't worth it to make
    /// it generic.
    let roomH01 = Room(position: (x: 1, y: 1))
    let roomH02 = Room(position: (x: 2, y: 1))
    let roomH04 = Room(position: (x: 4, y: 1))
    let roomH06 = Room(position: (x: 6, y: 1))
    let roomH08 = Room(position: (x: 8, y: 1))
    let roomH10 = Room(position: (x: 10, y: 1))
    let roomH11 = Room(position: (x: 11, y: 1))
    let roomS1A = Room(position: (x: 3, y: 2))
    let roomS1B = Room(position: (x: 3, y: 3))
    let roomS2A = Room(position: (x: 5, y: 2))
    let roomS2B = Room(position: (x: 5, y: 3))
    let roomS3A = Room(position: (x: 7, y: 2))
    let roomS3B = Room(position: (x: 7, y: 3))
    let roomS4A = Room(position: (x: 9, y: 2))
    let roomS4B = Room(position: (x: 9, y: 3))
    
    let rooms = [
        roomH01,
        roomH02,
        roomH04,
        roomH06,
        roomH08,
        roomH10,
        roomH11,
        roomS1A,
        roomS1B,
        roomS2A,
        roomS2B,
        roomS3A,
        roomS3B,
        roomS4A,
        roomS4B
    ]
    
    var occupancies: [Room: Amphipod] = [:]
    for (yIndex, line) in input.split(separator: "\n").enumerated() {
        for (xIndex, char) in line.enumerated() {
            let room = Room(position: (x: xIndex, y: yIndex))
            switch char {
            case "A": occupancies[room] = Amphipod(type: .A); break;
            case "B": occupancies[room] = Amphipod(type: .B); break;
            case "C": occupancies[room] = Amphipod(type: .C); break;
            case "D": occupancies[room] = Amphipod(type: .D); break;
            default: break;
            }
        }
    }
    
    /// Amphipods will never stop on the space immediately outside any
    /// room. They can move into that space so long as they immediately
    /// continue moving. (Specifically, this refers to the four open spaces
    /// in the hallway that are directly above an amphipod starting position.)
    ///
    /// For this reason, I've decided to model the hallway in such a way that
    /// these open spaces cannot be navigated to, and instead a step cost
    /// of 2 is required to get to the destination.
    var roomNeighbors: [Room: [(neighbor: Room, steps: Int)]] = [:]
    roomNeighbors[roomH01] = [(neighbor: roomH02, steps: 1)]
    roomNeighbors[roomH02] = [
        (neighbor: roomH04, steps: 2),
        (neighbor: roomH01, steps: 1),
        (neighbor: roomS1A, steps: 2)
    ]
    roomNeighbors[roomH04] = [
        (neighbor: roomH02, steps: 2),
        (neighbor: roomH06, steps: 2),
        (neighbor: roomS1A, steps: 2),
        (neighbor: roomS2A, steps: 2)
    ]
    roomNeighbors[roomH06] = [
        (neighbor: roomH04, steps: 2),
        (neighbor: roomH08, steps: 2),
        (neighbor: roomS2A, steps: 2),
        (neighbor: roomS3A, steps: 2)
    ]
    roomNeighbors[roomH08] = [
        (neighbor: roomH06, steps: 2),
        (neighbor: roomH10, steps: 2),
        (neighbor: roomS3A, steps: 2),
        (neighbor: roomS4A, steps: 2)
    ]
    roomNeighbors[roomH10] = [
        (neighbor: roomH08, steps: 2),
        (neighbor: roomH11, steps: 1),
        (neighbor: roomS4A, steps: 2)
    ]
    roomNeighbors[roomH11] = [(neighbor: roomH10, steps: 1)]
    roomNeighbors[roomS1A] = [
        (neighbor: roomH02, steps: 2),
        (neighbor: roomH04, steps: 2),
        (neighbor: roomS1B, steps: 1)
    ]
    roomNeighbors[roomS2A] = [
        (neighbor: roomH04, steps: 2),
        (neighbor: roomH06, steps: 2),
        (neighbor: roomS2B, steps: 1)
    ]
    roomNeighbors[roomS3A] = [
        (neighbor: roomH06, steps: 2),
        (neighbor: roomH08, steps: 2),
        (neighbor: roomS3B, steps: 1)
    ]
    roomNeighbors[roomS4A] = [
        (neighbor: roomH08, steps: 2),
        (neighbor: roomH10, steps: 2),
        (neighbor: roomS4B, steps: 1)
    ]
    roomNeighbors[roomS1B] = [(neighbor: roomS1A, steps: 1)]
    roomNeighbors[roomS2B] = [(neighbor: roomS2A, steps: 1)]
    roomNeighbors[roomS3B] = [(neighbor: roomS3A, steps: 1)]
    roomNeighbors[roomS4B] = [(neighbor: roomS4A, steps: 1)]
    
    var distanceMatrix: [Room: [(destination: Room, steps: Int)]] = [:]
    for room in rooms {
        distanceMatrix[room] = generateRoomDistances(
            from: room,
            using: roomNeighbors
        )
    }
    
    return (
        map: Map(
            rooms: rooms,
            roomNeighbors: roomNeighbors,
            distanceMatrix: distanceMatrix
        ),
        state: State(
            occupancies: occupancies
        )
    )
}

func findStateUntilSolved(initialState: State, with map: Map) -> Cost {
    var statesToProcess = [initialState]
    var statesToProcessIndexedByScore = [initialState]
    var visitedStatesWithCost: [State: Cost] = [:]
    var visitedStatesWithScore: [State: Int] = [:]
    var minimumStateCost = Int.max
    var foundUpperBound = false
    
    var iterations = 0
    while statesToProcess.count > 0 {

        let stateToProcess: State
        if foundUpperBound {
            stateToProcess = statesToProcess.removeFirst()
            if visitedStatesWithCost[stateToProcess] == nil {
                continue
            }
        } else {
            stateToProcess = statesToProcessIndexedByScore.removeFirst()
            statesToProcess.removeAll { $0 == stateToProcess }
        }
        
        let stateCost = visitedStatesWithCost[stateToProcess] ?? 0
        iterations += 1
        
        if statesToProcess.count % 100 == 0 {
            print("States to process, visited", statesToProcess.count, visitedStatesWithCost.count, stateCost, minimumStateCost)
        }
        
        // print("step to reach", visitedStatesWithStepsToRech[stateToProcess] ?? 0)
        
        // print("before: ")
        // printMap(map, with: stateToProcess)
        let newStatesWithCost = moveAmphipods(
            from: stateToProcess,
            with: stateCost,
            using: map,
            skipping: visitedStatesWithCost
        )
        
        for (state, cost) in newStatesWithCost {
            
            if foundUpperBound && cost >= minimumStateCost {
                continue
            }
            
            if foundUpperBound && (cost + lowerBoundCost(state: state, map: map)) >= minimumStateCost {
                continue
            }
            
            // print("after: ")
            // printMap(map, with: state)
            if isSolved(state) {
                // printMap(map, with: state)
                print("Found solution with cost: ", cost)
                minimumStateCost = cost
                
                // Remove all states that have a cost over the minimum cost
                var removedEntries = 0
                for (visitedState, visitedCost) in visitedStatesWithCost {
                    if (
                        visitedCost >= minimumStateCost ||
                        visitedCost + lowerBoundCost(state: visitedState, map: map) >= minimumStateCost
                    ) {
                        visitedStatesWithCost.removeValue(forKey: visitedState)
                        removedEntries += 1
                    }
                }
                print("Removed ", removedEntries, "entries after finding lower solution")

                foundUpperBound = true
            }
            
            if visitedStatesWithCost[state, default: Int.max] <= cost {
                continue
            }

            statesToProcess.append(state)
            visitedStatesWithCost[state] = cost
            if !foundUpperBound {
                let newScore = stateScore(state: state, cost: cost, map: map)
                let index = binarySearchIndex(
                    statesToProcessIndexedByScore,
                    visitedStatesWithScore,
                    newScore
                )
                visitedStatesWithScore[state] = newScore
                statesToProcessIndexedByScore.insert(state, at: index)
            }
        }
    }
    
    return minimumStateCost
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-23-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let (map, state) = parseMapAndState(input)
        
        return
        
        printMap(map, with: state)
        
        print("Part 1: ", findStateUntilSolved(initialState: state, with: map))
        
//        printMap(map, with: state)
//
//        print("Part 1: ", findStateUntilSolved(initialState: state, with: map))
    }
}
