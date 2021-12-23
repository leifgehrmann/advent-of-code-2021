import Foundation

struct Box {
    let x: Range
    let y: Range
    let z: Range
    
    func intersects(box: Box) -> Bool {
        return box.x.intersects(range: box.x) &&
        box.y.intersects(range: box.y) &&
        box.z.intersects(range: box.z)
    }
    
    func volume() -> Int {
        return x.length() * y.length() * z.length()
    }
    
    func merge(_ box: Box) -> [Box] {
        var newBoxes: [Box] = []
        for xRange in x.split(range: box.x) {
            for yRange in y.split(range: box.y) {
                for zRange in z.split(range: box.z) {
                    let newBox = Box(
                        x: xRange,
                        y: yRange,
                        z: zRange
                    )
                    if (
                        newBox.intersects(box: self) ||
                        newBox.intersects(box: self)
                    ) {
                        newBoxes.append(newBox)
                    }
                }
            }
        }
        return newBoxes
    }
    
    func subtract(_ box: Box) -> [Box] {
        var newBoxes: [Box] = []
        for xRange in x.subtract(range: box.x) {
            for yRange in y.subtract(range: box.y) {
                for zRange in z.subtract(range: box.z) {
                    newBoxes.append(Box(
                        x: xRange,
                        y: yRange,
                        z: zRange
                    ))
                }
            }
        }
        return []
    }
}

struct Range {
    let min: Int
    let max: Int
    
    func intersects(range: Range) -> Bool {
        return !(
            (min < range.min && max < range.max) ||
            (min > range.min && max > range.max)
        )
    }
    
    func length() -> Int {
        return max - min + 1
    }
    
    func split(range: Range) -> [Range] {
        let rangeBits = [min, max, range.min, range.max].sorted()
        let ab = Range(min: rangeBits[0], max: rangeBits[1])
        let bc = Range(min: rangeBits[1], max: rangeBits[2])
        let cd = Range(min: rangeBits[2], max: rangeBits[3])
        return [ab,bc,cd]
    }
    
    func subtract(range: Range) -> [Range] {
        var newRanges: [Range] = []
        if min < range.min && max > range.min {
            newRanges.append(Range(min: min, max: range.min - 1))
        }
        if max > range.max && min < range.max {
            newRanges.append(Range(min: range.max + 1, max: max))
        }
        return newRanges
    }
}

enum Action {
    case On
    case Off
}

struct Step {
    let action: Action
    let box: Box
}

func parseRange(line: String) -> (axis: String, min: Int, max: Int) {
    let rangeSplit = line.split(separator: "=")
    let axis = String(rangeSplit[0])
    let range = rangeSplit[1].components(separatedBy: "..")
        .map {Int($0)}
        .compactMap {$0}
    return (
        axis: axis,
        min: range[0],
        max: range[1]
    )
}

func parseStep(line: String) -> Step {
    let stepSplit = line.split(separator: " ")
    let action = stepSplit[0] == "on" ? Action.On : Action.Off
    let boxAxisRanges = stepSplit[1]
        .split(separator: ",")
        .map { parseRange(line: String($0))}
    let boxXRange = boxAxisRanges.filter {$0.axis == "x"}.first!
    let boxYRange = boxAxisRanges.filter {$0.axis == "y"}.first!
    let boxZRange = boxAxisRanges.filter {$0.axis == "z"}.first!
    let box = Box(
        x: Range(min: boxXRange.min, max: boxXRange.max),
        y: Range(min: boxYRange.min, max: boxYRange.max),
        z: Range(min: boxZRange.min, max: boxZRange.max)
    )
    
    return Step(
        action: action,
        box: box
    )
}

@main
enum Script {
    static func main() throws {
        let steps = try readFileInCwd(file: "/Day-22-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { parseStep(line: String($0)) }
        
        var boxes: [Box] = []
        var boxesToMerge: [Box] = []
        for step in steps {
            if step.action == .Off {
                let boxToSubtract = step.box
                var newBoxes: [Box]  = []
                for (boxIndex, box) in boxes.enumerated().reversed() {
                    if box.intersects(box: boxToSubtract) {
                        boxes.remove(at: boxIndex)
                        newBoxes.append(contentsOf: box.subtract(boxToSubtract))
                    }
                }
                boxes.append(contentsOf: newBoxes)
            } else {
                boxesToMerge.append(step.box)
            }
            while boxesToMerge.count > 0 {
                let boxToMerge = boxesToMerge.removeFirst()
                var intersected = false
                for (boxIndex, box) in boxes.enumerated().reversed() {
                    if box.intersects(box: boxToMerge) {
                        intersected = true
                        boxes.remove(at: boxIndex)
                        boxesToMerge.append(contentsOf: box.merge(boxToMerge))
                        break
                    }
                }
                if !intersected {
                    boxes.append(boxToMerge)
                }
            }
        }
        
        print(boxes)
    }
}
