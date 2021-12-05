import Foundation

enum ScriptError: Error {
    case DiagonalVentDetected
}

struct Point {
    let x: Int;
    let y: Int;
}

struct Vent {
    let start: Point;
    let end: Point;
}

func draw(_ vent: Vent, on ventMap: inout [[Int8]]) throws -> Void {
    if vent.start.x == vent.end.x {
        let minY = min(vent.start.y, vent.end.y)
        let maxY = max(vent.start.y, vent.end.y)
        for y in minY...maxY {
            ventMap[y][vent.start.x] += 1
        }
    } else if vent.start.y == vent.end.y {
        let minX = min(vent.start.x, vent.end.x)
        let maxX = max(vent.start.x, vent.end.x)
        for x in minX...maxX {
            ventMap[vent.start.y][x] += 1
        }
    } else {
        throw ScriptError.DiagonalVentDetected
    }
}

func part1(vents: [Vent]) throws -> Int {
    let ventMapWidth = 1000
    let ventMapHeight = 1000

    var ventMap = Array(
        repeating: Array(
            repeating: 0 as Int8,
            count: ventMapWidth
        ),
        count: ventMapHeight
    )
    
    // Filter out diagonal vents
    let nonDiagonalVents = vents.filter {
        $0.start.x == $0.end.x || $0.start.y == $0.end.y
    }
    for vent in nonDiagonalVents {
        try draw(vent, on: &ventMap)
    }
    
    // Count the number of places in the array where a vent appeared more than once
    return ventMap.reduce(0) {
        $0 + $1.reduce(0) { $0 + ($1 > 1 ? 1 : 0) }
    }
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-05-Input.txt")
        let ventAsStrings = input.split(separator: "\n")
            .map { $0.components(separatedBy: " -> ") }
            .map {(
                start: $0[0].split(separator: ","),
                end: $0[1].split(separator: ",")
            )}
        let vents = ventAsStrings
            .map {Vent(
                start: Point(x: Int($0.start[0])!, y: Int($0.start[1])!),
                end: Point(x: Int($0.end[0])!, y: Int($0.end[1])!)
            )}

        print("Part 1: ", try part1(vents: vents))
    }
}
