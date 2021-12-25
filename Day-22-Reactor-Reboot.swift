import Foundation

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
    
    func volume() -> Int {
        return x.length() * y.length() * z.length()
    }
    
    func merge(_ box: Box) -> [Box] {
        var allIntersectX = true
        var newXBoxes: [Box] = []
        for xRange in x.split(range: box.x) {
            var allIntersectY = true
            var newYBoxes: [Box] = []
            for yRange in y.split(range: box.y) {
                var allIntersectZ = true
                var newZBoxes: [Box] = []
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
                        newZBoxes.append(newBox)
                    } else {
                        allIntersectZ = false
                        allIntersectY = false
                        allIntersectX = false
                    }
                }
                
                if (allIntersectZ) {
                    newZBoxes = [
                        Box(x: xRange, y: yRange, z: box.z.merge(range: self.z))
                    ]
                }
                
                newYBoxes.append(contentsOf: newZBoxes)
            }
            
            if (allIntersectY) {
                newYBoxes = [
                    Box(x: xRange, y: box.y.merge(range: self.y), z: box.z.merge(range: self.z))
                ]
            }
            
            newXBoxes.append(contentsOf: newYBoxes)
        }
        
        if (allIntersectX) {
            return [
                Box(x: box.x.merge(range: self.x), y: box.y.merge(range: self.y), z: box.z.merge(range: self.z))
            ]
        }
        
        return newXBoxes
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
    
    func contains(element: Int) -> Bool {
        return element >= min && element <= max
    }
    
    func length() -> Int {
        return max - min + 1
    }
    
    func split(range: Range) -> [Range] {
        if self.intersects(range: range) {
            // identical
            if range == self {
                return [self]
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
                    Range(min: range.min, max: range.max),
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
                    self,
                    Range(min: range.min + 1, max: range.max)
                ]
            }
            // single unit length
            if self.min == self.max && range.max == self.max {
                return [
                    Range(min: range.min, max: range.max - 1),
                    self
                ]
            }
        }
        return [self, range]
    }
    
    func merge(range: Range) -> Range {
        return Range(min: Swift.min(self.min, range.min), max: Swift.max(self.max, range.max))
    }
    
    func subtract(range: Range) -> [Range] {
        self.split(range: range).filter {!$0.intersects(range: range)}
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
        
        // Test that intersects works correctly
//        print(Range(min: 2, max: 4).contains(element: 1)) // return false
//        print(Range(min: 2, max: 4).contains(element: 2)) // return true
//        print(Range(min: 2, max: 4).contains(element: 3)) // return true
//        print(Range(min: 2, max: 4).contains(element: 4)) // return true
//        print(Range(min: 2, max: 4).contains(element: 5)) // return false
//        print(Range(min: 2, max: 2).contains(element: 1)) // return false
//        print(Range(min: 2, max: 2).contains(element: 2)) // return true
//        print(Range(min: 2, max: 2).contains(element: 3)) // return false
        
        // Test that intersects works correctly
//        print(Range(min: 2, max: 4).intersects(range: Range(min: 3, max: 4))) // return true
//        print(Range(min: 2, max: 4).intersects(range: Range(min: 4, max: 4))) // return true
//        print(Range(min: 2, max: 4).intersects(range: Range(min: 5, max: 5))) // return false
//        print(Range(min: 2, max: 2).intersects(range: Range(min: 1, max: 5))) // return true
//        print(Range(min: 2, max: 2).intersects(range: Range(min: 1, max: 1))) // return false
//        print(Range(min: 2, max: 2).intersects(range: Range(min: 1, max: 2))) // return true
//        print(Range(min: 2, max: 4).intersects(range: Range(min: 1, max: 3))) // return true
//
//        // Test that length works correctly
//        print(Range(min: 2, max: 2).length()) // return 1
//        print(Range(min: 2, max: 3).length()) // return 1
//
//        // Test that split works correctly
//        print(Range(min: 2, max: 4).split(range: Range(min: 3, max: 4))) // 2 ranges, 2-2, 3-4
//        print(Range(min: 2, max: 4).split(range: Range(min: 4, max: 4))) // 2 ranges, 2-2, 4-4
//        print(Range(min: 1, max: 3).split(range: Range(min: 5, max: 7))) // 2 ranges, 1-3, 5-7
//        print(Range(min: 1, max: 7).split(range: Range(min: 3, max: 5))) // 3 ranges, 1-2, 3-5, 6-7
//        print(Range(min: 1, max: 3).split(range: Range(min: 1, max: 2))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 1, max: 3).split(range: Range(min: 3, max: 3))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 1, max: 3).split(range: Range(min: 1, max: 3))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 3, max: 3).split(range: Range(min: 1, max: 3))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 1, max: 1).split(range: Range(min: 1, max: 3))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 1, max: 4).split(range: Range(min: 2, max: 3))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 1, max: 2).split(range: Range(min: 3, max: 3))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 1, max: 2).split(range: Range(min: 3, max: 4))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 1, max: 3).split(range: Range(min: 2, max: 4))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 2, max: 4).split(range: Range(min: 1, max: 3))) // 3 ranges, 1-2, 3-3
//        print(Range(min: -21, max: 9).split(range: Range(min: -35, max: 9))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 9, max: 21).split(range: Range(min: 9, max: 35))) // 3 ranges, 1-2, 3-3
//        print(Range(min: 8, max: 21).split(range: Range(min: 9, max: 35))) // 3 ranges, 1-2, 3-3
//        return
        
//        print(Range(min: 2, max: 4).subtract(range: Range(min: 1, max: 3))) // 4-4
//        print(Range(min: 2, max: 4).subtract(range: Range(min: 3, max: 3))) // 2-2, 4-4
//        print(Range(min: 2, max: 4).subtract(range: Range(min: 4, max: 4))) // 2-3
//
//        print(Box(x: Range(min: 1, max: 3), y: Range(min: 1, max: 3), z: Range(min: 1, max: 3)).subtract(
//            Box(x: Range(min: 2, max: 2), y: Range(min: 2, max: 2), z: Range(min: 2, max: 2))
//        ))
        
        var boxes: [Box] = []
        var boxesToMerge: [Box] = []
        for step in steps {
            print(step)
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
                        print(box)
                        print(boxToMerge)
                        boxes.remove(at: boxIndex)
                        let newBoxesToMerge = box.merge(boxToMerge)
                        print(newBoxesToMerge)
                        print(boxes.count)
                        boxesToMerge.append(contentsOf: newBoxesToMerge)
                        break
                    }
                }
                if !intersected {
                    boxes.append(boxToMerge)
                }
            }
        }
        
        print(boxes)
        print(boxes.reduce(0) {$0 + $1.volume()}) // Expect 26
    }
}
