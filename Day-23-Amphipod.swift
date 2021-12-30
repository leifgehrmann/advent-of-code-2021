import Foundation

let hallwayY = 1
let hallwayMinX = 1
let hallwayMaxX = 11
let sideRoomY = 2
let sideRoomXs = [3, 5, 7, 9]

enum Amphipod: String, Hashable {
    case A = "A"
    case B = "B"
    case C = "C"
    case D = "D"
    
    var homeXPosition: Int {
        switch (self) {
        case .A: return 3
        case .B: return 5
        case .C: return 7
        case .D: return 9
        }
    }

    var moveCost: Int {
        switch (self) {
        case .A: return 1
        case .B: return 10
        case .C: return 100
        case .D: return 1000
        }
    }
    
    static let allTypes = [A, B, C, D]
}

struct Position: Hashable {
    let x: Int
    let y: Int
}

struct State: Hashable {
    let amphipods: [Position: Amphipod]
    let sideRoomDepths: Int
    
    static func == (lhs: State, rhs: State) -> Bool {
        if lhs.amphipods.count != lhs.amphipods.count {
            return false
        }
        for (position, amphipod) in lhs.amphipods {
            if rhs.amphipods[position] != amphipod {
                return false
            }
        }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        let sortedAmphipods = amphipods.sorted {
            if $0.key.y < $1.key.y {
                return false
            }
            if $0.key.y > $1.key.y {
                return true
            }
            if $0.key.x < $1.key.x {
                return false
            }
            return true
        }
        for (position, amphipod) in sortedAmphipods {
            hasher.combine(position.x)
            hasher.combine(position.y)
            hasher.combine(amphipod)
        }
    }
    
    func distance(
        for amphipod: Amphipod,
        from: Position,
        to: Position
    ) -> Int {
        var distance = 0
        /// Travel up, if we're not in the same hallway.
        if from.x != to.x && from.y != hallwayY {
            distance += from.y - hallwayY
        }
        /// Travel left-right.
        distance += abs(from.x - to.x)
        /// Travel down.
        distance += to.y - hallwayY
        return distance * amphipod.moveCost
    }
    
    func accessibleSideRooms(
        for amphipod: Amphipod,
        from position: Position
    ) -> [Position] {
        /// Is the entrance to the side-room accessible?
        var positionX = position.x + (position.x > amphipod.homeXPosition ? -1 : 1)
        while positionX != amphipod.homeXPosition {
            if amphipods[Position(x: positionX, y: hallwayY)] != nil {
                return []
            }
            positionX += position.x > amphipod.homeXPosition ? -1 : 1
        }
        
        /// Are all amphipods from bottom to top the correct type?
        /// If not, there is really no point for the amphipod to travel
        /// into it.
        var positionY = sideRoomY
        var accessibleRooms: [Position] = []
        var lastAccessibleRoom: Position? = nil
        while positionY <= sideRoomY + sideRoomDepths - 1 {
            let sideRoom = Position(x: positionX, y: positionY)
            positionY += 1
            if amphipods[sideRoom] == nil {
                lastAccessibleRoom = sideRoom
                accessibleRooms.append(sideRoom)
            } else if amphipods[sideRoom] != amphipod {
                return accessibleRooms
            }
            if isSolved(for: amphipod, at: sideRoom) {
                return lastAccessibleRoom != nil ? [lastAccessibleRoom!] : []
            }
        }
        
        if accessibleRooms.count == sideRoomDepths {
            return [lastAccessibleRoom!]
        } else {
            return accessibleRooms
        }
    }
    
    func isSolved() -> Bool {
        for (position, amphipod) in amphipods {
            if amphipod.homeXPosition != position.x {
                return false
            }
        }
        return true
    }
    
    /// Determines whether or not the amphipod should move.
    func isSolved(for amphipod: Amphipod, at position: Position) -> Bool {
        if position.x != amphipod.homeXPosition {
            return false
        }
        var positionY = position.y
        while positionY < sideRoomDepths + sideRoomY {
            if amphipods[Position(x: position.x, y: positionY)] != amphipod {
                return false
            }
            positionY += 1
        }
        return true
    }

    func hallwayAccessible(from: Position) -> Bool {
        var positionY = from.y - 1
        while positionY >= hallwayY {
            if amphipods[Position(x: from.x, y: positionY)] != nil {
                return false
            }
            positionY -= 1
        }
        return true
    }
    
    func hallwayPositionsAccessible(from: Position) -> (positions: [Position], intersections: [Position]) {
        var positions: [Position] = []
        var intersections: [Position] = []
        
        var leftPositionX = from.x - 1
        while leftPositionX >= hallwayMinX {
            let newPosition = Position(x: leftPositionX, y: hallwayY)
            if sideRoomXs.contains(leftPositionX) {
                intersections.append(newPosition)
                leftPositionX -= 1
                continue
            }
            if amphipods[newPosition] != nil {
                break
            }
            positions.append(newPosition)
            leftPositionX -= 1
        }
        
        var rightPositionX = from.x + 1
        while rightPositionX <= hallwayMaxX {
            let newPosition = Position(x: rightPositionX, y: hallwayY)
            if sideRoomXs.contains(rightPositionX) {
                intersections.append(newPosition)
                rightPositionX += 1
                continue
            }
            if amphipods[newPosition] != nil {
                break
            }
            positions.append(newPosition)
            rightPositionX += 1
        }
        return (positions: positions, intersections: positions)
    }
    
    func getProgressiveMovements(
        position: Position,
        amphipod: Amphipod
    ) -> [Position] {
        /// Amphipods in the hallway can only go into side-rooms they belong to.
        if position.y == hallwayY {
            return accessibleSideRooms(
                for: amphipod,
                from: position
            )
        }
        if position.y > hallwayY {
            /// Don't recommend moving if we are in the right spot!
            if isSolved(for: amphipod, at: position) {
                return []
            }
            /// If we can't leave the side-room, there's not much we can do...
            if !hallwayAccessible(from: position) {
                return []
            }
            
            var positions: [Position] = []
            let (hallwayPositions, hallwayIntersections) =
                hallwayPositionsAccessible(from: position)
            positions.append(contentsOf: hallwayPositions)
            
            for hallwayIntersection in hallwayIntersections {
                positions.append(contentsOf: accessibleSideRooms(
                    for: amphipod,
                    from: hallwayIntersection
                ))
            }
            
            return positions
        }
        return []
    }
                                       
    func getProgressiveStates() -> [(newState: State, movementCost: Int)] {
        var newStates: [(newState: State, movementCost: Int)] = []
        for (position, amphipod) in amphipods {
            for newPosition in getProgressiveMovements(
                position: position,
                amphipod: amphipod
            ) {
                var newAmphipods = amphipods
                newAmphipods.removeValue(forKey: position)
                newAmphipods[newPosition] = amphipod
                let newState = State(
                    amphipods: newAmphipods,
                    sideRoomDepths: sideRoomDepths
                )
                let movementCost = distance(
                    for: amphipod,
                    from: position,
                    to: newPosition
                )
                newStates.append((
                    newState: newState,
                    movementCost: movementCost
                ))
            }
        }
        
        return newStates
    }
}

func printState(_ state: State) {
    let width = hallwayMinX + hallwayMaxX
    let height = state.sideRoomDepths + sideRoomY
    var printableMap = Array(
        repeating: Array(
            repeating: "#",
            count: width + 1
        ),
        count: height + 1
    )
    for hallwayX in hallwayMinX...hallwayMaxX {
        printableMap[hallwayY][hallwayX] = "."
    }
    for amphipod in Amphipod.allTypes {
        for sideRoomY in sideRoomY..<(sideRoomY + state.sideRoomDepths) {
            printableMap[sideRoomY][amphipod.homeXPosition] = "."
        }
    }
    for (position, amphipod) in state.amphipods {
        printableMap[position.y][position.x] = amphipod.rawValue
    }
    print(
        printableMap.map { $0.reduce("") { $0 + String($1) } }
            .reduce("") { $0 + String($1) + "\n" }
    )
}

enum Puzzle {
    case Part1
    case Part2
}

func parseState(input: String, puzzle: Puzzle) -> State {
    var amphipods: [Position: Amphipod] = [:]
    for (yIndex, line) in input.split(separator: "\n").enumerated() {
        for (xIndex, char) in line.enumerated() {
            let yOffset = yIndex == 3 && puzzle == .Part2 ? 2 : 0
            let position = Position(x: xIndex, y: yIndex + yOffset)
            switch char {
            case "A": amphipods[position] = .A; break;
            case "B": amphipods[position] = .B; break;
            case "C": amphipods[position] = .C; break;
            case "D": amphipods[position] = .D; break;
            default: break;
            }
        }
    }
    
    if puzzle == .Part2 {
        amphipods[Position(x: 3, y: 3)] = .D
        amphipods[Position(x: 3, y: 4)] = .D
        amphipods[Position(x: 5, y: 3)] = .C
        amphipods[Position(x: 5, y: 4)] = .B
        amphipods[Position(x: 7, y: 3)] = .B
        amphipods[Position(x: 7, y: 4)] = .A
        amphipods[Position(x: 9, y: 3)] = .A
        amphipods[Position(x: 9, y: 4)] = .C
    }
    
    return State(
        amphipods: amphipods,
        sideRoomDepths: puzzle == .Part1 ? 2 : 4
    )
}

func findMinCostToSolvedState(
    for state: State,
    costToReachState: Int,
    minCostToReachStateCache: inout [State: Int],
    minCostToSolvedStateCache: inout [State: Int?],
    minCostToSolvedStateFound: inout Int
) -> Int? {
    if state.isSolved() {
        minCostToSolvedStateFound = costToReachState
        print("solution Found: ", minCostToSolvedStateFound)
        return costToReachState
    }
    
    if minCostToSolvedStateCache[state] != nil {
        return minCostToSolvedStateCache[state]!
    }
    
    if minCostToReachStateCache[state, default: Int.max] < costToReachState {
        return nil
    }

    minCostToReachStateCache[state] = costToReachState
    
    var minCostsToSolvedState: [Int] = []
    for (newState, movementCost) in state.getProgressiveStates() {
//        print("-------")
//        printState(state)
//        printState(newState)
//        print(costToReachState + movementCost, movementCost)
        
        if costToReachState + movementCost > minCostToSolvedStateFound {
            continue
        }
        
        let minCostToSolvedStateForNewState = findMinCostToSolvedState(
            for: newState,
            costToReachState: costToReachState + movementCost,
            minCostToReachStateCache: &minCostToReachStateCache,
            minCostToSolvedStateCache: &minCostToSolvedStateCache,
            minCostToSolvedStateFound: &minCostToSolvedStateFound
        )
        
        minCostToSolvedStateCache[state] = minCostToSolvedStateForNewState
        if minCostToSolvedStateForNewState != nil {
            minCostsToSolvedState.append(minCostToSolvedStateForNewState!)
        }
    }
    
    return minCostsToSolvedState.min()
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-23-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let state = parseState(input: input, puzzle: .Part1)
        
        printState(state)
        
        var minCostToReachStateCache: [State: Int] = [:]
        var minCostToSolvedStateCache: [State: Int?] = [:]
        var minCostToSolvedStateFound = Int.max
        print(findMinCostToSolvedState(
            for: state,
            costToReachState: 0,
            minCostToReachStateCache: &minCostToReachStateCache,
            minCostToSolvedStateCache: &minCostToSolvedStateCache,
            minCostToSolvedStateFound: &minCostToSolvedStateFound
        ))
        
        return
        
//        var costToCompleteState: [State: Cost] = [:]
//        var costToVisitState: [State: Cost] = [:]
//        print("Part 1: ", calculateMinCost(
//            state: state,
//            stateCost: 0,
//            map: map,
//            costToCompleteState: &costToCompleteState,
//            costToVisitState: &costToVisitState,
//            maxRecursions: 0
//        ))
        
//        let (map2, state2) = parseMapAndState(input, puzzle: .Part2)
//        printMap(map2, with: state2)
//
//        print("Part 2: ", findStateUntilSolved(initialState: state2, with: map2))
    }
}

//upper bound for part 2: 117596
