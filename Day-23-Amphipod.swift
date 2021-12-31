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
    
    var sideRoomPositionX: Int {
        switch (self) {
        case .A: return 3
        case .B: return 5
        case .C: return 7
        case .D: return 9
        }
    }

    var movementCost: Int {
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
        return distance * amphipod.movementCost
    }
    
    func isSolved() -> Bool {
        for (position, amphipod) in amphipods {
            if amphipod.sideRoomPositionX != position.x {
                return false
            }
        }
        return true
    }
    
    /// Determines whether or not the amphipod should move.
    func isSolved(for amphipod: Amphipod) -> Bool {
        var positionY = sideRoomY
        while positionY != sideRoomY + sideRoomDepths {
            let position = Position(x: amphipod.sideRoomPositionX, y: positionY)
            if amphipods[position] != amphipod {
                return false
            }
            positionY += 1
        }
        return true
    }

    func isHallwayAccessible(from position: Position) -> Bool {
        var positionY = sideRoomY
        while positionY < position.y {
            if amphipods[Position(x: position.x, y: positionY)] != nil {
                return false
            }
            positionY += 1
        }
        return true
    }
    
    func accessibleHallwayPositions(from: Position) -> [Position] {
        var positions: [Position] = []
        
        var leftPositionX = from.x - 1
        while leftPositionX >= hallwayMinX {
            let newPosition = Position(x: leftPositionX, y: hallwayY)
            if sideRoomXs.contains(leftPositionX) {
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
                rightPositionX += 1
                continue
            }
            if amphipods[newPosition] != nil {
                break
            }
            positions.append(newPosition)
            rightPositionX += 1
        }
        return positions
    }
    
    func accessibleSideRoom(for amphipod: Amphipod) -> Position? {
        var positionY = sideRoomY + sideRoomDepths - 1
        while positionY != hallwayY {
            let position = Position(x: amphipod.sideRoomPositionX, y: positionY)
            if amphipods[position] == nil {
                return position
            }
            if amphipods[position] != amphipod {
                return nil
            }
            positionY -= 1
        }
        return nil
    }
    
    func hallwayFreeBetween(from: Int, to: Int) -> Bool {
        let direction = from < to ? 1 : -1
        var positionX = from + direction
        while positionX != to {
            if amphipods[Position(x: positionX, y: hallwayY)] != nil {
                return false
            }
            positionX += direction
        }
        return true
    }
    
    func getProgressiveMovements(
        position: Position,
        amphipod: Amphipod
    ) -> [Position] {
        /// Amphipods in the hallway can only go into side-rooms they belong to.
        if position.y == hallwayY {
            guard let sideRoom = accessibleSideRoom(for: amphipod) else {
                return []
            }
            if hallwayFreeBetween(from: position.x, to: sideRoom.x) {
                return [sideRoom]
            }
            return []
        }
        if position.y > hallwayY {
            /// Don't recommend moving amphipods for rooms that are complete!
            if isSolved(for: amphipod) {
                return []
            }
            /// If we can't leave the side-room, there's not much we can do...
            if !isHallwayAccessible(from: position) {
                return []
            }
            
            if position.x == amphipod.sideRoomPositionX {
                var bottom = true
                for positionY in position.y..<(sideRoomY + sideRoomDepths) {
                    if amphipods[Position(x: position.x, y: positionY)] == nil {
                        print("It's halwayts up its room?")
                        exit(8)
                    }
                    if amphipods[Position(x: position.x, y: positionY)] != amphipod {
                        bottom = false
                    }
                }
                if bottom {
                    return []
                }
            }
            
            if let sideRoom = accessibleSideRoom(for: amphipod) {
                if hallwayFreeBetween(from: position.x, to: sideRoom.x) {
                    return [sideRoom]
                }
            }

            return accessibleHallwayPositions(from: position)
        }
        return []
    }
                                       
    func getProgressiveStates() -> [(newState: State, movementCost: Int)] {
        var newMovements: [(from: Position, to: Position)] = []
        for (position, amphipod) in amphipods {
            for newPosition in getProgressiveMovements(
                position: position,
                amphipod: amphipod
            ) {
                newMovements.append((from: position, to: newPosition))
            }
        }
        
        var newStates: [(newState: State, movementCost: Int)] = []
        for (oldPosition, newPosition) in newMovements {
            let amphipod = amphipods[oldPosition]!
            var newAmphipods = amphipods
            newAmphipods.removeValue(forKey: oldPosition)
            newAmphipods[newPosition] = amphipod
            let newState = State(
                amphipods: newAmphipods,
                sideRoomDepths: sideRoomDepths
            )
            let movementCost = distance(
                for: amphipod,
                from: oldPosition,
                to: newPosition
            )
            newStates.append((
                newState: newState,
                movementCost: movementCost
            ))
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
            printableMap[sideRoomY][amphipod.sideRoomPositionX] = "."
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
    minCostToSolvedStateCache: inout [State: Int?]
) -> Int? {
    if state.isSolved() {
        return 0
    }
    
    if minCostToSolvedStateCache[state] != nil {
        return minCostToSolvedStateCache[state]!
    }
    
    var minCostsToSolvedState: [Int] = []
    let progressiveStates = state.getProgressiveStates()
    for (newState, movementCost) in progressiveStates {
        let minCostToSolvedStateForNewState = findMinCostToSolvedState(
            for: newState,
            minCostToSolvedStateCache: &minCostToSolvedStateCache
        )
        
        if minCostToSolvedStateForNewState != nil {
            minCostsToSolvedState.append(movementCost + minCostToSolvedStateForNewState!)
        }
    }
    
    minCostToSolvedStateCache[state] = minCostsToSolvedState.min()
    return minCostsToSolvedState.min()
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-23-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let statePart1 = parseState(input: input, puzzle: .Part1)
        printState(statePart1)
        var minCostToSolvedStateCache: [State: Int?] = [:]
        let minCostPart1 = findMinCostToSolvedState(
            for: statePart1,
            minCostToSolvedStateCache: &minCostToSolvedStateCache
        )!
        print("Part 1: ", minCostPart1)
        
        let statePart2 = parseState(input: input, puzzle: .Part2)
        printState(statePart2)
        minCostToSolvedStateCache = [:]
        let minCostPart2 = findMinCostToSolvedState(
            for: statePart2,
            minCostToSolvedStateCache: &minCostToSolvedStateCache
        )!
        print("Part 2: ", minCostPart2)
    }
}
