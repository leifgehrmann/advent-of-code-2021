import Foundation

struct Target {
    let minX: Int;
    let maxX: Int;
    let minY: Int;
    let maxY: Int;
    
    func containsPosition(_ position: Position) -> Bool {
        return !(
            position.x > maxX || position.x < minX ||
            position.y > maxY || position.y < minY
        )
    }
    
    func closestX(to position: Position) -> Int? {
        if position.x > maxX {
            return maxX
        }
        if position.x < minX {
            return minX
        }
        return nil
    }
    
    func furthestX(to position: Position) -> Int? {
        if position.x > maxX {
            return minX
        }
        if position.x < minX {
            return maxX
        }
        return nil
    }
}

struct Position {
    let x: Int;
    let y: Int;
}

struct Velocity {
    let x: Int;
    let y: Int;
}

func parseTarget(input: String) -> Target {
    let rangeSplit = input.trimmingCharacters(in: .whitespacesAndNewlines)
    .split(separator: ",")
    let rangeX = rangeSplit[0]
        .split(separator: "=")[1].components(separatedBy: "..")
        .map {Int($0)}
        .compactMap {$0}
    let rangeY = rangeSplit[1]
        .split(separator: "=")[1].components(separatedBy: "..")
        .map {Int($0)}.compactMap {$0}
    return Target(
        minX: rangeX[0],
        maxX: rangeX[1],
        minY: rangeY[0],
        maxY: rangeY[1]
    )
}

func simulateShot(
    start: Position,
    velocity: Velocity,
    target: Target
) -> (hit: Bool, maxY: Int) {
    let velocityXDirection = velocity.x >= 0 ? 1 : -1
    var newVelocity = velocity
    var newPosition = start
    var maxY = start.y
    var hit = false
    while (true) {
        newPosition = Position(
            x: newPosition.x + newVelocity.x,
            y: newPosition.y + newVelocity.y
        )

        if maxY < newPosition.y {
            maxY = newPosition.y
        }
        
        /// Check if it has hit the target
        if (target.containsPosition(newPosition)) {
            hit = true
            break
        }
        
        /// Check if it is out-of-bounds, which means we can stop simulating.
        if newPosition.y < target.minY {
            break
        }
        
        newVelocity = Velocity(
            x: max(0, abs(newVelocity.x) - 1) * velocityXDirection,
            y: newVelocity.y - 1
        )
    }
    return (
        hit: hit,
        maxY: maxY
    )
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-17-Input.txt")
        let target = parseTarget(input: input)
        let startPosition = Position(x: 0, y: 0)
        
        /// To make the
        
        /// Make a  educated guess of what the upper and lower bounds of the
        /// problem will be.
        let closestXToStart = target.closestX(to: startPosition)!
        let direction = closestXToStart > startPosition.x ? 1 : -1
        
        /// Because drag will reduce the x-velocity to `0` in after
        /// `velocity.x`'s steps, we know that the lowest velocity
        /// (not accounting for the direction) will
        /// https://oeis.org/A002024
        let closestXDistance = abs(closestXToStart - startPosition.x)
        let lowestXVelocity = Int(floor(sqrt(Float(2 * closestXDistance)) + 1/2))
        /// Because the position is not interpolated, the highest velocity
        /// (not accounting for the direction) will be the furthest x position
        /// of the box.
        let highestXVelocity = abs(target.furthestX(to: startPosition)!)
        /// Accounting for the direction, we therefore know the lower and
        /// upper bounds of the x velocity.
        let minXVelocity = min(lowestXVelocity * direction, highestXVelocity * direction)
        let maxXVelocity = max(lowestXVelocity * direction, highestXVelocity * direction)
        
        /// We also know the minimum y velocity because we can fire downwards.
        /// This is the furthest y position of the box.
        let minYVelocity = target.minY
        /// Because the position is not interpolated, we also know
        /// the highest velocity, assuming the target is below
        /// the starting position.
        let maxYVelocity = abs(target.minY)
        
        var maxY: Int? = nil
        var hitVelocities: [Velocity] = []
        
        for vY in minYVelocity...maxYVelocity {
            for vX in minXVelocity...maxXVelocity {
                let velocity = Velocity(x: vX, y: vY)
                let (hit, simMaxY) = simulateShot(
                    start: startPosition,
                    velocity: velocity,
                    target: target
                )
                if hit {
                    hitVelocities.append(velocity)
                }
                if hit && simMaxY > maxY ?? (simMaxY - 1) {
                    maxY = simMaxY
                }
            }
        }
        
        print(maxY)
        print(hitVelocities.count)
        
    }
}
