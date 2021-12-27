import Foundation

struct Range: Hashable {
    let min: Int
    let max: Int
    
    func intersects(range: Range) -> Bool {
        return (
            self.contains(element: range.min) ||
            self.contains(element: range.max) ||
            (range.min < min && range.max > max)
        )
    }
    
    func contains(range: Range) -> Bool {
        return range.min >= min && range.max <= max
    }
    
    func contains(element: Int) -> Bool {
        return element >= min && element <= max
    }
    
    func length() -> Int {
        return max - min + 1
    }
    
    func split(range: Range) -> [Range] {
        let newSelf = self
        if self.intersects(range: range) {
            // identical
            if range == self {
                return [newSelf]
            }
            // envelopes
            if range.min < self.min && range.max > self.max {
                return [
                    Range(min: range.min, max: self.min - 1),
                    Range(min: self.min, max: self.max),
                    Range(min: self.max + 1, max: range.max)
                ]
            }
            // within
            if range.min > self.min && range.max < self.max {
                return [
                    Range(min: self.min, max: range.min - 1),
                    Range(min: range.min, max: range.max),
                    Range(min: range.max + 1, max: self.max)
                ]
            }
            // stretches right side
            if range.min > self.min && range.max > self.max {
                return [
                    Range(min: self.min, max: range.min - 1),
                    Range(min: range.min, max: self.max),
                    Range(min: self.max + 1, max: range.max)
                ]
            }
            // stretches left side
            if range.min < self.min && range.max < self.max {
                return [
                    Range(min: range.min, max: self.min - 1),
                    Range(min: self.min, max: range.max),
                    Range(min: range.max + 1, max: self.max)
                ]
            }
            // touches left edge
            if range.min == self.min && range.max < self.max {
                return [
                    Range(min: range.min, max: range.max),
                    Range(min: range.max + 1, max: self.max)
                ]
            }
            // touches left edge x2
            if range.min == self.min && range.max > self.max {
                return [
                    Range(min: range.min, max: self.max),
                    Range(min: self.max + 1, max: range.max)
                ]
            }
            // touches right edge
            if range.min > self.min && range.max == self.max {
                return [
                    Range(min: self.min, max: range.min - 1),
                    Range(min: range.min, max: self.max)
                ]
            }
            // touches right edge x2
            if range.min < self.min && range.max == self.max {
                return [
                    Range(min: range.min, max: self.min - 1),
                    Range(min: self.min, max: self.max)
                ]
            }
            // single unit length
            if self.min == self.max && range.min == self.min {
                return [
                    newSelf,
                    Range(min: range.min + 1, max: range.max)
                ]
            }
            // single unit length
            if self.min == self.max && range.max == self.max {
                return [
                    Range(min: range.min, max: range.max - 1),
                    newSelf
                ]
            }
        }
        return [newSelf, range]
    }
    
    func merge(range: Range) -> Range {
        return Range(min: Swift.min(self.min, range.min), max: Swift.max(self.max, range.max))
    }
    
    func subtract(range: Range) -> [Range] {
        self.split(range: range).filter {!$0.intersects(range: range)}
    }
}

struct Box: Equatable {
    let x: Range
    let y: Range
    let z: Range
    
    func intersects(box: Box) -> Bool {
        return (x.intersects(range: box.x) &&
            y.intersects(range: box.y) &&
            z.intersects(range: box.z)
        )
    }
    
    func contains(box: Box) -> Bool {
        return (
            x.contains(range: box.x) &&
            y.contains(range: box.y) &&
            z.contains(range: box.z)
        )
    }
    
    func volume() -> Int {
        return x.length() * y.length() * z.length()
    }
    
    func merge(_ box: Box) -> [Box] {
        if self.contains(box: box) {
            return [self]
        }
        if box.contains(box: self) {
            return [box]
        }
        
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
                        newBox.intersects(box: box)
                    ) {
                        newBoxes.append(newBox)
                    }
                }

            }
        }
        
        /// Simplify the problem by generalizing the merge to be the current
        /// box + all other boxes. This reduces the number of operations we
        /// need to do when merging in `getBoxesTurnedOn()`.
        newBoxes = newBoxes.filter { !self.intersects(box: $0) }
        newBoxes.append(self)
        
        return newBoxes
    }
    
    func subtract(_ box: Box) -> [Box] {
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
                        newBox.intersects(box: self) &&
                        !newBox.intersects(box: box)
                    ) {
                        newBoxes.append(newBox)
                    }
                }
            }
        }
        return newBoxes
    }
}

func getBoxesTurnedOn(steps: [Step]) -> [Box] {
    var boxes: [Box] = []
    var boxesToMerge: [Box] = []
    for (stepIndex, step) in steps.enumerated() {
        if stepIndex % 5 == 0 {
            print("\(stepIndex) / \(steps.count) Complete")
        }
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
                    let newBoxesToMerge = box.merge(boxToMerge)
                    boxesToMerge.append(contentsOf: newBoxesToMerge)
                    break
                }
            }
            if !intersected {
                boxes.append(boxToMerge)
            }
        }
    }
    return boxes
}

enum Action {
    case On
    case Off
}

struct Step {
    let action: Action
    let box: Box
}

func parseRange(line: String) -> (axis: String, range: Range) {
    let rangeSplit = line.split(separator: "=")
    let axis = String(rangeSplit[0])
    let range = rangeSplit[1].components(separatedBy: "..")
        .map {Int($0)}
        .compactMap {$0}
    return (
        axis: axis,
        range: Range(min: range[0], max: range[1])
    )
}

func parseStep(line: String) -> Step {
    let stepSplit = line.split(separator: " ")
    let action = stepSplit[0] == "on" ? Action.On : Action.Off
    let boxAxisRanges = stepSplit[1]
        .split(separator: ",", maxSplits: 3)
        .map { parseRange(line: String($0))}
    let boxXRange = boxAxisRanges.filter {$0.axis == "x"}.first!
    let boxYRange = boxAxisRanges.filter {$0.axis == "y"}.first!
    let boxZRange = boxAxisRanges.filter {$0.axis == "z"}.first!
    let box = Box(
        x: boxXRange.range,
        y: boxYRange.range,
        z: boxZRange.range
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
        
        let within50Range = Range(min: -50, max: 50)
        let within50Box = Box(x: within50Range, y: within50Range, z: within50Range)
        let stepsWithin50 = steps.filter { within50Box.contains(box: $0.box) }
        
        let boxesTurnedOnWithin50 = getBoxesTurnedOn(steps: stepsWithin50)
        print("Part 1: ",  boxesTurnedOnWithin50.reduce(0) {$0 + $1.volume()})

        let boxesTurnedOn = getBoxesTurnedOn(steps: steps)
        print("Part 2: ",  boxesTurnedOn.reduce(0) {$0 + $1.volume()})
    }
}
