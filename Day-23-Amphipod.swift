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
        /// We need to make sure the hasher sorts the positions of the
        /// amphipods in a particular order so that `amphipods` in an
        /// identical arrangement but a different order cannot be
        /// incorrectly hashed.
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
    
    /// Returns the distance from one position to another.
    func distance(
        for amphipod: Amphipod,
        from: Position,
        to: Position
    ) -> Int {
        var distance = 0
        /// Travel up, if we're not in the same side-room.
        if from.x != to.x && from.y != hallwayY {
            distance += from.y - hallwayY
        }
        /// Travel along the hallway.
        distance += abs(from.x - to.x)
        /// Travel down the side-room.
        distance += to.y - hallwayY
        return distance * amphipod.movementCost
    }
    
    /// Returns true if all the amphipods are in the right position.
    func isSolved() -> Bool {
        for (position, amphipod) in amphipods {
            if amphipod.sideRoomPositionX != position.x {
                return false
            }
        }
        return true
    }
    
    /// Returns true if the side-room for `amphipod` is complete. In other
    /// words, all the amphipods are in the correct side-room.
    func isSolved(for amphipod: Amphipod) -> Bool {
        let filteredAmphipods = amphipods.filter ({ $0.value == amphipod })
        for (position, amphipod) in filteredAmphipods {
            if amphipod.sideRoomPositionX != position.x {
                return false
            }
        }
        return true
    }
    
    /// Returns true if the amphipod is in the correct position, and all other
    /// amphipods beneath it in the side-room are all the same type.
    func isSolved(for amphipod: Amphipod, at position: Position) -> Bool {
        if position.x == amphipod.sideRoomPositionX {
            for positionY in position.y..<(sideRoomY + sideRoomDepths) {
                let sideRoomPosition = Position(x: position.x, y: positionY)
                if amphipods[sideRoomPosition] != amphipod {
                    return false
                }
            }
            return true
        }
        return false
    }

    /// Returns true if an amphipod in `position` can travel up the side-room.
    /// If there is an amphipod in the way, it cannot travel up.
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
    
    /// Returns all the positions in the hallway that can be accessed from
    /// `position`. Entrances to the side-rooms are excluded.
    func accessibleHallwayPositions(from position: Position) -> [Position] {
        var positions: [Position] = []
        
        var leftPositionX = position.x - 1
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
        
        var rightPositionX = position.x + 1
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
    
    /// Returns whether or not an amphipod enter the side room, ignoring
    /// whether or not the hallway is blocked. An amphipod can enter
    /// only if there are no other amphipod types, and there is at least one
    /// free space. The bottom most free space is returned first.
    func accessibleSideRoomPosition(for amphipod: Amphipod) -> Position? {
        /// If there is a different type of amphipod in the side-room,
        /// don't let any other amphipod enter.
        /// It's not obvious that this restriction is necessary, since
        /// technically it should be allowed for an amphipod to enter
        /// the side room, because it could be used as a strategy to
        /// minimise cost. But apparently if we don't have this
        /// restriction, we end up with too many recursive solutions!
        /// I have discovered a truly marvelous demonstration of this
        /// proposition that this margin is too narrow to contain.
        for positionY in sideRoomY..<sideRoomY + sideRoomDepths {
            let position = Position(
                x: amphipod.sideRoomPositionX,
                y: positionY
            )
            let sideRoomAmphipod = amphipods[position]
            if sideRoomAmphipod != amphipod && sideRoomAmphipod != nil {
                return nil
            }
        }
        
        /// Find the bottom most available side-room.
        var positionY = sideRoomY + sideRoomDepths - 1
        while positionY != hallwayY {
            let position = Position(
                x: amphipod.sideRoomPositionX,
                y: positionY
            )
            if amphipods[position] == nil {
                return position
            }
            positionY -= 1
        }
        return nil
    }
    
    /// Return `true` if the spaces in the hallway between `from` and `to` are
    /// all empty. The range is not inclusive.
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

    /// Returns all the possible movements for a single amphipod that could
    /// actually bring us closer to solving the amphipod's problem.
    func getProgressiveMovements(
        position: Position,
        amphipod: Amphipod
    ) -> [Position] {
        /// Amphipods in the hallway can only go into side-rooms they belong to.
        if position.y == hallwayY {
            /// Can the amphipod travel to the side-room?
            if !hallwayFreeBetween(
                from: position.x,
                to: amphipod.sideRoomPositionX
            ) {
                return []
            }
            /// Can the amphipod even enter the side-room?
            if let sideRoom = accessibleSideRoomPosition(for: amphipod) {
                return [sideRoom]
            }
            return []
        }
        /// Amphipods already in a side-room can go up into the hallway, or
        /// directly to their desired side-room.
        if position.y > hallwayY {
            /// We don't recommend moving amphipods for rooms that are
            /// already complete!
            if isSolved(for: amphipod) {
                return []
            }
            /// If we can't leave the side-room, there's not much we can do...
            if !isHallwayAccessible(from: position) {
                return []
            }
            
            /// If the amphipod is in the right room, and it sitting on top
            /// of other amphipods of the same type, then don't let
            /// the amphipod move!
            if isSolved(for: amphipod, at: position) {
                return []
            }
            
            /// If the amphipod is in a side-room and has access to the
            /// desired side-room, and the desired side-room doesn't have
            /// any other amphipods of a different type, then direct them
            /// to that destination without giving any other choice!
            if let sideRoom = accessibleSideRoomPosition(for: amphipod) {
                if hallwayFreeBetween(from: position.x, to: sideRoom.x) {
                    return [sideRoom]
                }
            }

            /// If the amphipod cannot enter their side-room, then just let
            /// them mull about in the hallway.
            return accessibleHallwayPositions(from: position)
        }
        return []
    }

    /// Returns all the states that make progress for the amphipods from the
    /// current state, along with the movement cost to perform the change.
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
            let totalCost = movementCost + minCostToSolvedStateForNewState!
            minCostsToSolvedState.append(totalCost)
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
