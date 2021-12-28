import Foundation

enum AmphipodType: String, Hashable {
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"
}

struct Amphipod: Hashable {
    let type: AmphipodType
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

func moveCost(amphipod: Amphipod, steps: Int) -> Int {
    switch (amphipod.type) {
    case .A: return 1 * steps
    case .B: return 10 * steps
    case .C: return 100 * steps
    case .D: return 1000 * steps
    }
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
    return from.position.y < to.position.y && (
        (amphipod.type == .A && to.position.x == 3) ||
        (amphipod.type == .B && to.position.x == 5) ||
        (amphipod.type == .C && to.position.x == 7) ||
        (amphipod.type == .D && to.position.x == 9)
    )
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
            let newCost = initialCost + moveCost(
                amphipod: amphipod,
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

func isSideRoomSolved(
    occupancies: [Amphipod],
    expectedAmphipodType: AmphipodType
) -> Bool {
    return occupancies.filter({ $0.type == expectedAmphipodType }).count == 2
}

func isSolved(_ state: State) -> Bool {
    let sideRoomPods = state.occupancies.filter { $0.key.position.y > 1 }
    let podsInA = Array(sideRoomPods.filter({ $0.key.position.x == 3 }).values)
    if !isSideRoomSolved(occupancies: podsInA, expectedAmphipodType: .A) {
        return false
    }
    let podsInB = Array(sideRoomPods.filter({ $0.key.position.x == 5 }).values)
    if !isSideRoomSolved(occupancies: podsInB, expectedAmphipodType: .B) {
        return false
    }
    let podsInC = Array(sideRoomPods.filter({ $0.key.position.x == 7 }).values)
    if !isSideRoomSolved(occupancies: podsInC, expectedAmphipodType: .C) {
        return false
    }
    let podsInD = Array(sideRoomPods.filter({ $0.key.position.x == 9 }).values)
    if !isSideRoomSolved(occupancies: podsInD, expectedAmphipodType: .D) {
        return false
    }
    return true
}

//func stateScore(state: State, cost: Cost) -> Int {
//    let room1A: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 3 && $0.key.position.x == 2 }.values)
//    let room2A: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 5 && $0.key.position.x == 2 }.values)
//    let room3A: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 7 && $0.key.position.x == 2 }.values)
//    let room4A: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 9 && $0.key.position.x == 2 }.values)
//    let room1B: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 3 && $0.key.position.x == 3 }.values)
//    let room2B: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 5 && $0.key.position.x == 3 }.values)
//    let room3B: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 7 && $0.key.position.x == 3 }.values)
//    let room4B: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 9 && $0.key.position.x == 3 }.values)
//    let room1AScore: Int = room1A.reduce(0) { $0 + (($1.type == .A) ? 1 : -2) }
//    let room2AScore: Int = room2A.reduce(0) { $0 + (($1.type == .B) ? 1 : -2) }
//    let room3AScore: Int = room3A.reduce(0) { $0 + (($1.type == .C) ? 1 : -2) }
//    let room4AScore: Int = room4A.reduce(0) { $0 + (($1.type == .D) ? 1 : -2) }
//    let room1BScore: Int = room1B.reduce(0) { $0 + (($1.type == .A) ? 1 : -2) }
//    let room2BScore: Int = room2B.reduce(0) { $0 + (($1.type == .B) ? 1 : -2) }
//    let room3BScore: Int = room3B.reduce(0) { $0 + (($1.type == .C) ? 1 : -2) }
//    let room4BScore: Int = room4B.reduce(0) { $0 + (($1.type == .D) ? 1 : -2) }
//    let bottomPodsScore: Int = (
//        room1BScore +
//        room2BScore +
//        room3BScore +
//        room4BScore
//    ) * 10 * 100 * 1000 * 10000
//    let middlePodsScore: Int = (
//        room1AScore +
//        room2AScore +
//        room3AScore +
//        room4AScore
//    ) * 10 * 100 * 1000
//    let hallwayA: [Int] = state.occupancies.filter { $0.key.position.y == 1 && $0.value.type == .A }.keys.reduce(0) { $0 + abs(3 - $1.position) }
//    let hallwayB: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 1 && $0.value.type == .A }.keys)
//    let hallwayC: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 1 && $0.value.type == .A }.keys)
//    let hallwayD: [Amphipod] = Array(state.occupancies.filter { $0.key.position.y == 1 && $0.value.type == .A }.keys)
//
//    return bottomPodsScore + middlePodsScore - hallway - cost
//}

/// Returns the correct index in the `toProcess` array, sorted by the netRisk.
//func binarySearchIndex(
//    _ states: [State],
//    _ stateCosts: [State: Int],
//    _ newStateScore: Int
//) -> Array.Index {
//    var low = states.startIndex
//    var high = states.endIndex
//    while low != high {
//        let mid = states.index(
//            low,
//            offsetBy: states.distance(from: low, to: high) / 2
//        )
//        let midStateCost = stateCosts[states[mid]]!
//        if stateScore(state: states[mid], cost: midStateCost) < newStateScore {
//            low = states.index(after: mid)
//        } else {
//            high = mid
//        }
//    }
//    return low
//}

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
    
    return (
        map: Map(
            rooms: rooms,
            roomNeighbors: roomNeighbors
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
    // var visitedStatesWithStepsToRech: [State: Int] = [:]
    var minimumStateCost = Int.max
    // var foundUpperBound = false
    
    var iterations = 0
    while statesToProcess.count > 0 {
        if statesToProcess.count % 100 == 0 {
            print("States to process, visited", statesToProcess.count, visitedStatesWithCost.count)
        }

        let stateToProcess: State
        //if foundUpperBound {
            stateToProcess = statesToProcess.removeFirst()
//        } else {
//            stateToProcess = statesToProcessIndexedByScore.removeLast()
//            statesToProcess.removeAll { $0 == stateToProcess }
//            printMap(map, with: stateToProcess)
//            print(stateScore(state: stateToProcess, cost: visitedStatesWithCost[stateToProcess] ?? 0))
//        }
        
        let stateCost = visitedStatesWithCost[stateToProcess] ?? 0
        iterations += 1
        
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
            
//            if foundUpperBound && cost >= minimumStateCost {
//                continue
//            }
            
            // print("after: ")
            // printMap(map, with: state)
            if isSolved(state) {
                //printMap(map, with: state)
                print("Found solution with cost: ", cost)
                minimumStateCost = cost
                
//                if !foundUpperBound {
//                    // Remove all states that have a cost over the minimum cost
//                    for (visitedState, visitedCost) in visitedStatesWithCost {
//                        if visitedCost > minimumStateCost {
//                            statesToProcess.removeAll { $0 == visitedState }
//                            visitedStatesWithCost.removeValue(forKey: visitedState)
//                        }
//                    }
//                }
//
//                foundUpperBound = true
            }
            
            if visitedStatesWithCost[state, default: Int.max] <= cost {
                continue
            }

            statesToProcess.append(state)
            visitedStatesWithCost[state] = cost
//            if !foundUpperBound {
//                let newScore = stateScore(state: state, cost: cost)
//                let index = binarySearchIndex(statesToProcessIndexedByScore, visitedStatesWithCost, newScore)
//                statesToProcessIndexedByScore.insert(state, at: index)
//            }
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
        
        printMap(map, with: state)
        // Because this script takes forever to run, I've added a return
        // statement to prevent it running in Github action.
        // Return
        print(findStateUntilSolved(initialState: state, with: map))
    }
}
