import Foundation

func part1(commandTuples: [(direction: String, amount: Int)]) -> Int {
    let horizontalSum = commandTuples
        .filter { $0.direction == "forward" }
        .reduce(0) {$1.amount + $0 }
    let verticalSum = commandTuples
        .filter { $0.direction == "down" || $0.direction == "up" }
        .reduce(0) { ($1.amount) * ($1.direction == "up" ? -1 : 1) + $0}
    
    print("Vertical positiion: ", verticalSum)
    print("Horizontal position: ", horizontalSum)
    return verticalSum * horizontalSum
}

struct SubmarineState {
    var aim: Int;
    var horizontal: Int;
    var vertical: Int;
}

func part2(commandTuples: [(direction: String, amount: Int)]) -> Int {
    let submarineState = commandTuples.reduce(
        SubmarineState(aim: 0, horizontal: 0, vertical: 0)
    ) {
        (
            accumulation: SubmarineState,
            command: (direction: String, amount: Int)
        ) -> SubmarineState in

        if command.direction == "down" || command.direction == "up" {

            // Adjust the aim
            let directionScalar = (command.direction == "up" ? -1 : 1)
            return SubmarineState(
                aim: accumulation.aim + command.amount * directionScalar,
                horizontal: accumulation.horizontal,
                vertical: accumulation.vertical
            )

        } else {

            // We're going forward, so adjust the position
            return SubmarineState(
                aim: accumulation.aim,
                horizontal: accumulation.horizontal + command.amount,
                vertical: accumulation.vertical + accumulation.aim * command.amount
            )

        }

    }
    print(submarineState)
    return submarineState.horizontal * submarineState.vertical
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-02-Input.txt")
        
        let commandTuples = input
            .split(separator: "\n") // Split by line
            .map { $0.split(separator: " ") } // Split by space
            .map { (direction: String($0[0]), amount: Int($0[1])!) } // Typedef commands
        
        print("Part 1: ", part1(commandTuples: commandTuples))
        print("Part 2: ", part2(commandTuples: commandTuples))
    }
}
