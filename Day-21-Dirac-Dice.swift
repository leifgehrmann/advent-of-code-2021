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
    var roles: Int
    
    init() {
        self.roles = 0
    }

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

class DiracDie {
    
}

func hasAPlayerWon (players: [Player]) -> (winner: Player, losers: [Player])? {
    for player in players {
        if player.score >= 1000 {
            return (winner: player, losers: players.filter { $0 !== player })
        }
    }
    return nil
}

@main
enum Script {
    static func main() throws {
        let players = try readFileInCwd(file: "/Day-21-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { Int($0.components(separatedBy: ": ")[1])! }
            .map { Player(position: $0) }
        
        var playerTurnIndex = 0
        let deterministicDie = DeterministicDie()
        while hasAPlayerWon(players: players) == nil {
            /// Get the player who's turn it is.
            let player = players[playerTurnIndex]
            
            /// Move the player.
            let spacesToMove = deterministicDie.rollThreeTimes()
            player.move(spacesToMove)
            
            /// Move onto the next player.
            playerTurnIndex = (playerTurnIndex + 1) % players.count
            
            for player in players {
                print(player.score)
            }
        }
        
        guard let (_, losers) = hasAPlayerWon(players: players) else {
            return
        }
        let loser = losers.first!
        print("Part 1: ", deterministicDie.roles * loser.score)
    }
}
