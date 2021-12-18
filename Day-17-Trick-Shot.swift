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
}

struct Position {
    let x: Int;
    let y: Int;
}

struct Velocity {
    let dx: Int;
    let dy: Int;
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
        minX: min(rangeX[0], rangeX[1]),
        maxX: max(rangeX[0], rangeX[1]),
        minY: min(rangeY[0], rangeY[1]),
        maxY: max(rangeY[0], rangeY[1])
    )
}

/// Returns the minimum velocity to reach `xPosition`. This takes drag
/// into account.
func getMinimumXVelocityToHitViaDrag(xPosition: Int) -> Int {
    /// For each step the drag will subtract `1` from the velocity. This means
    /// a velocity of `4` will travel `4 + 3 + 2 + 1 = 10` in 4 steps. We
    /// want a function that does the inverse of this calculation, where
    /// `f(10) = 4`. Thankfully the OEIS has us covered:
    /// https://oeis.org/A002024
    let scalar = Int(floor(sqrt(Float(2 * abs(xPosition))) + 1/2))
    /// The above function doesn't take direction into account, so we need to
    /// apply the direction to scalar to derive the velocity.
    let direction = xPosition >= 0 ? 1 : -1
    return scalar * direction
}

/// Returns the maximum velocity to yeet it to the `xPosition`.
func getMaximumXVelocityToHitDirectly(xPosition: Int) -> Int {
    return xPosition
}

/// Returns the minimum velocity to reach `yPosition`. This takes gravity
/// into account.
func getMinimumYVelocityToHitViaGravity(yPosition: Int) -> Int {
    if (yPosition > 0) {
        /// It just to happens that the function to calculate this is the
        /// same as the function that we use to calculate drag, because
        /// drag has the same dx as gravity.
        return getMinimumXVelocityToHitViaDrag(xPosition: yPosition)
    } else {
        /// Otherwise, if the yPosition is below the start position, we can
        /// just yeet it downwards at the same velocity as the `yPosition`.
        return yPosition
    }
}

/// Returns the maximum velocity to reach `yPosition`.
func getMaximumYVelocityToHitViaGravity(target: Target) -> Int {
    return max(
        /// Because gravity is 1 for each step, when the probe is fired
        /// upwards it will always return to the start position with the
        /// same velocity but inverted.
        abs(target.minY),
        abs(target.maxY)
    )
}

/// Returns the minimum and maximum values for a list of numbers.
func minMax(_ values: Int...) -> (min: Int?, max: Int?) {
    return (
        min: values.min(),
        max: values.max()
    )
}

func simulateShot(
    start: Position,
    velocity: Velocity,
    target: Target
) -> (hit: Bool, maxY: Int) {
    let velocityXDirection = velocity.dx >= 0 ? 1 : -1
    var newVelocity = velocity
    var newPosition = start
    var maxY = start.y
    var hit = false

    while (true) {
        /// Derive the new target.
        newPosition = Position(
            x: newPosition.x + newVelocity.dx,
            y: newPosition.y + newVelocity.dy
        )

        /// Record whether we hit a maxY.
        if maxY < newPosition.y {
            maxY = newPosition.y
        }
        
        /// Check if it has hit the target.
        if (target.containsPosition(newPosition)) {
            hit = true
            break
        }
        
        /// Check if it is out-of-bounds, which means we can stop simulating.
        if newPosition.y < target.minY {
            break
        }
        
        /// Apply drag and gravity to the velocity.
        newVelocity = Velocity(
            dx: max(0, abs(newVelocity.dx) - 1) * velocityXDirection,
            dy: newVelocity.dy - 1
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
        
        /// If the target cross the 0 y-position, there are infinitely many
        /// solutions because the probe will always reach the 0 position
        /// due to gravity being 1.
        if (target.minX <= 0 && target.maxX >= 0) {
            print("Part 1: Infinity")
            print("Part 2: Infinite")
        }
        
        let startPosition = Position(x: 0, y: 0)
        
        /// Calculate the upper and lower bounds of what the X velocities will
        /// be. Since the target could be behind the `startPosition`, we
        /// want to handle negative velocities as well.
        let (minXVelocity, maxXVelocity) = minMax(
            getMinimumXVelocityToHitViaDrag(xPosition: target.minX),
            getMinimumXVelocityToHitViaDrag(xPosition: target.maxX),
            getMaximumXVelocityToHitDirectly(xPosition: target.minX),
            getMaximumXVelocityToHitDirectly(xPosition: target.maxX)
        )
        
        /// We know the minimum y velocity because we can fire directly
        /// towards the target. This is the furthest y position of the box
        /// from the start position.
        let minYVelocity = getMinimumYVelocityToHitViaGravity(yPosition: target.minY)
        /// Because the position is not interpolated, we know the highest
        /// velocity is equal to the max step that can be taken.
        let maxYVelocity = getMaximumYVelocityToHitViaGravity(target: target)
        
        var maxY: Int = startPosition.y
        var hitVelocities: [Velocity] = []
        
        /// Simulate the shorts for all velocities we know have a chance of
        /// hitting the target. If it hits, keep track of the velocities that
        /// hit the target and record the maxY.
        for vY in minYVelocity...maxYVelocity {
            for vX in minXVelocity!...maxXVelocity! {
                let velocity = Velocity(dx: vX, dy: vY)
                let (hit, simMaxY) = simulateShot(
                    start: startPosition,
                    velocity: velocity,
                    target: target
                )
                if hit {
                    hitVelocities.append(velocity)
                    if simMaxY > maxY {
                        maxY = simMaxY
                    }
                }
            }
        }
        
        print("Part 1: ", maxY)
        print("Part 2: ", hitVelocities.count)
    }
}
