import Foundation

class Player {
    var position: Int
    var score: Int
    
    init(position: Int) {
        self.position = position
        self.score = 0
    }
    
    func move(_ spaces: Int) {
        position = (position + spaces - 1) % 10 + 1
        score += position
    }
}

class DeterministicDie {
    var roles: Int = 0

    func rollThreeTimes() -> Int {
        let sum = [
            (roles) % 100 + 1,
            (roles + 1) % 100 + 1,
            (roles + 2) % 100 + 1
        ].reduce(0, +)
        roles += 3
        return sum
    }
}

func part1 (_ playerPositions: [Int]) {
    let players = playerPositions.map { Player(position: $0) }
    var playerTurnIndex = 0
    let deterministicDie = DeterministicDie()
    while players.filter({ $0.score >= 1000 }).count == 0 {
        /// Get the player who's turn it is.
        let player = players[playerTurnIndex]
        /// Move the player.
        let spacesToMove = deterministicDie.rollThreeTimes()
        player.move(spacesToMove)
        /// Move onto the next player.
        playerTurnIndex = (playerTurnIndex + 1) % players.count
    }

    let loser = players.filter { $0.score < 1000 }[0]
    print("Part 1: ", deterministicDie.roles * loser.score)
}

/// Returns a mapping of the the dice sums and the number of universes created
/// for three roles of the dice. In total 27 universes are created.
func diracDieStateCountAfterThreeRolls() -> [Int:Int] {
    var stateCount: [Int:Int] = [:]
    for d1 in 1...3 {
        for d2 in 1...3 {
            for d3 in 1...3 {
                let diceSum = d1 + d2 + d3
                stateCount[diceSum, default: 0] += 1
            }
        }
    }
    return stateCount
}

struct UniverseState: Hashable {
    let player1Score: Int;
    let player1Position: Int;
    let player2Score: Int;
    let player2Position: Int;
    let turn: Int;
}

func iterateUniverseStates (
    _ stateCounts: [UniverseState: Int],
    _ diracStateCount: [Int: Int]
) -> (
    newStateCounts: [UniverseState: Int],
    player1Wins: Int,
    player2Wins: Int
) {
    var newStateCounts: [UniverseState: Int] = [:]
    var player1Wins = 0
    var player2Wins = 0
    for (state, count) in stateCounts {
        for (diracSum, diracStateCount) in diracStateCount {
            let newState: UniverseState
            if state.turn == 0 {
                /// Player 1 is rolling.
                let newPosition = (state.player1Position + diracSum - 1) % 10 + 1
                let newScore = state.player1Score + newPosition
                newState = UniverseState(
                    player1Score: newScore,
                    player1Position: newPosition,
                    player2Score: state.player2Score,
                    player2Position: state.player2Position,
                    turn: 1
                )

                /// If the player has won, add it to the total list of
                /// universes won for the player.
                if (newScore >= 21) {
                    player1Wins += count * diracStateCount
                    continue
                }
            } else {
                /// Player 2 is rolling.
                let newPosition = (state.player2Position + diracSum - 1) % 10 + 1
                let newScore = state.player2Score + newPosition
                newState = UniverseState(
                    player1Score: state.player1Score,
                    player1Position: state.player1Position,
                    player2Score: newScore,
                    player2Position: newPosition,
                    turn: 0
                )

                /// If the player has won, add it to the total list of
                /// universes won for the player.
                if (newScore >= 21) {
                    player2Wins += count * diracStateCount
                    continue
                }
            }
            
            /// If no one has won, we shift the number of universes into
            /// the newState, multiplied by the number of universes created
            /// by rolling the dirac dice.
            newStateCounts[newState, default: 0] += count * diracStateCount
        }
    }
    
    return (
        newStateCounts: newStateCounts,
        player1Wins: player1Wins,
        player2Wins: player2Wins
    )
}

/// For part 2, instead of having an instance for every state, we
/// count the number of universes in each state.
func part2 (_ playerPositions: [Int]) {
    var stateCounts: [UniverseState:Int] = [:]
    var player1WinsCount = 0
    var player2WinsCount = 0

    /// The dice sums and number of universes created for three roles
    /// will always be the same, so we calculate it once.
    let diracStateCount = diracDieStateCountAfterThreeRolls()
    
    /// Setup the initial state of the universe.
    let initialState = UniverseState(
        player1Score: 0,
        player1Position: playerPositions[0],
        player2Score: 0,
        player2Position: playerPositions[1],
        turn: 0
    )
    stateCounts[initialState] = 1
    
    /// Iterate through the states of the universes until a winner has been
    /// reached in all of them.
    while stateCounts.values.reduce(0, +) > 0 {
        let (newStateCounts, player1Wins, player2Wins) = iterateUniverseStates(
            stateCounts,
            diracStateCount
        )
        player1WinsCount += player1Wins
        player2WinsCount += player2Wins
        stateCounts = newStateCounts
    }
    
    /// Print out the player that wins the most.
    print("Part 2: ", max(player1WinsCount, player2WinsCount))
}

@main
enum Script {
    static func main() throws {
        let playerPositions = try readFileInCwd(file: "/Day-21-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { Int($0.components(separatedBy: ": ")[1])! }

        part1(playerPositions)
        part2(playerPositions)
    }
}
