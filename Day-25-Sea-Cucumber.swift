import Foundation

typealias Map = [[String]]

let empty = "."
let east = ">"
let south = "v"
let justMoved = "#"

func normalisePosition(x: Int, y: Int, map: Map) -> (x: Int, y: Int) {
    let height = map.count
    let width = map[0].count
    return (x: (x + width * 2) % width, y: (y + height * 2) % height)
}

func getElement(x: Int, y: Int, in map: Map) -> String {
    let (normalisedX, normalisedY) = normalisePosition(x: x, y: y, map: map)
    return map[normalisedY][normalisedX]
}

func setElement(x: Int, y: Int, in map: inout Map, to value: String) {
    let (normalisedX, normalisedY) = normalisePosition(x: x, y: y, map: map)
    map[normalisedY][normalisedX] = value
}

func moveEastHerd(_ map: Map) -> Map {
    let height = map.count
    let width = map[0].count
    var newMap = map
    for y in 0..<height {
        guard let indexOfFirstEmpty: Array<String>.Index = map[y].firstIndex(of: empty) else {
            continue
        }
        for x in ((indexOfFirstEmpty - width + 2)...(indexOfFirstEmpty)).reversed() {
            if getElement(x: x, y: y, in: newMap) == empty {
                if getElement(x: x - 1, y: y, in: newMap) == east {
                    setElement(x: x, y: y, in: &newMap, to: east)
                    setElement(x: x - 1, y: y, in: &newMap, to: justMoved)
                }
            }
        }
    }
    return replaceJustMovedWithEmpty(newMap)
}

func moveSouthHerd(_ map: Map) -> Map {
    let height = map.count
    let width = map[0].count
    var newMap = map
    for x in 0..<width {
        let column = map.map { $0[x] }
        guard let indexOfFirstEmpty: Array<String>.Index = column.firstIndex(of: empty) else {
            continue
        }
        for y in ((indexOfFirstEmpty - height + 2)...(indexOfFirstEmpty)).reversed() {
            if getElement(x: x, y: y, in: newMap) == empty {
                if getElement(x: x, y: y - 1, in: newMap) == south {
                    setElement(x: x, y: y, in: &newMap, to: south)
                    setElement(x: x, y: y - 1, in: &newMap, to: justMoved)
                }
            }
        }
    }
    return replaceJustMovedWithEmpty(newMap)
}

func replaceJustMovedWithEmpty(_ map: Map) -> Map {
    return map.map {$0.map{ $0 == justMoved ? empty : $0 }}
}

func printMap(_ map: Map) {
    let stringifiedRows = map.map { $0.reduce("") { $0 + String($1) } }
    print(stringifiedRows.reduce("") { $0 + String($1) + "\n" })
}

@main
enum Script {
    static func main() throws {
        let map = try readFileInCwd(file: "/Day-25-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { $0.map { String($0) } }
        
        var previous: Map? = nil
        var current = map
        
        printMap(map)
        
        var steps = 0
        while previous != current {
            previous = current
            current = moveEastHerd(current)
            current = moveSouthHerd(current)
            steps += 1
            printMap(current)
        }
        print(steps)
    }
}
