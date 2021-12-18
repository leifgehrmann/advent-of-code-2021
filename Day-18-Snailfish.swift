import Foundation

enum Branch {
    case Left
    case Right
}

protocol Element {
    func magnitude() -> Int
    func isPair() -> Bool
    func isReduced() -> Bool
    func isReduced(depth: Int) -> Bool
    func wantsToExplode(depth: Int) -> Bool
    func wantsToSplit() -> Bool
    func toString() -> String
}

extension Int: Element {
    func magnitude() -> Int {
        return self
    }
    func isPair() -> Bool {
        return false
    }
    func isReduced() -> Bool {
        return self <= 9
    }
    func isReduced(depth: Int) -> Bool {
        return self.isReduced()
    }
    func wantsToExplode(depth: Int) -> Bool {
        return false
    }
    func wantsToSplit() -> Bool {
        return !self.isReduced()
    }
    func toString() -> String {
        return String(self)
    }
}

class Pair: Element {
    var left: Element;
    var right: Element;
    
    init (left: Element, right: Element) {
        self.left = left
        self.right = right
    }
    
    func magnitude() -> Int {
        return 3 * left.magnitude() + 2 * right.magnitude()
    }
    
    func isPair() -> Bool {
        return true
    }
    
    func isReduced() -> Bool {
        return self.isReduced(depth: 0)
    }
    
    func isReduced(depth: Int) -> Bool {
        return (
            !left.wantsToExplode(depth: depth + 1) &&
            !right.wantsToExplode(depth: depth + 1) &&
            !left.wantsToSplit() &&
            !right.wantsToSplit()
        )
    }
    
    func wantsToSplit() -> Bool {
        return left.wantsToSplit() ||
            right.wantsToSplit()
    }
    
    func wantsToExplode(depth: Int) -> Bool {
        if depth >= 4 {
            return true
        }
        return (
            left.wantsToExplode(depth: depth + 1) ||
            right.wantsToExplode(depth: depth + 1)
        )
    }
    
    func setElement(at path: [Branch], to element: Element) {
        var newPath = path
        let lastPathBranch = newPath.removeFirst()
        if newPath.count == 0 {
            if lastPathBranch == .Left {
                left = element
            } else {
                right = element
            }
        } else {
            if lastPathBranch == .Left {
                (left as! Pair).setElement(at: newPath, to: element)
            } else {
                (right as! Pair).setElement(at: newPath, to: element)
            }
        }
    }
    
    private func findLeftMostPairToExplode(
        depth: Int
    ) -> (pair: Pair, path: [Branch]) {
        var path: [Branch] = []
        var pairToExplode = self
        if left.isPair() && left.wantsToExplode(depth: depth + 1) {
            path.append(.Left)
            let (leftMostPairToExplode, pathToLeftMostPairToExplode) =
            (left as! Pair).findLeftMostPairToExplode(depth: depth + 1)
            pairToExplode = leftMostPairToExplode
            path.append(contentsOf: pathToLeftMostPairToExplode)
        } else if right.isPair() && right.wantsToExplode(depth: depth + 1) {
            path.append(.Right)
            let (leftMostPairToExplode, pathToLeftMostPairToExplode) =
            (right as! Pair).findLeftMostPairToExplode(depth: depth + 1)
            pairToExplode = leftMostPairToExplode
            path.append(contentsOf: pathToLeftMostPairToExplode)
        }
        return (
            pair: pairToExplode,
            path: path
        )
    }
    
    private func findLeftMostNumberToSplit() -> (number: Int, path: [Branch]) {
        var path: [Branch] = []
        var numberToSplit = 0
        if left.wantsToSplit() {
            path.append(.Left)
            if left.isPair() {
                let (leftMostElementToSplit, pathToLeftMostNumberToSplit) =
                    (left as! Pair).findLeftMostNumberToSplit()
                numberToSplit = leftMostElementToSplit
                path.append(contentsOf: pathToLeftMostNumberToSplit)
            } else {
                numberToSplit = left as! Int
            }
        } else if right.wantsToSplit() {
            path.append(.Right)
            if right.isPair() {
                let (leftMostNumberToSplit, pathToLeftMostNumberToSplit) =
                    (right as! Pair).findLeftMostNumberToSplit()
                numberToSplit = leftMostNumberToSplit
                path.append(contentsOf: pathToLeftMostNumberToSplit)
            } else {
                numberToSplit = right as! Int
            }
        }
        return (
            number: numberToSplit,
            path: path
        )
    }
    
    private func findLeftNeighborOfPairPath(
        path: [Branch]
    ) -> (pair: Pair, branch: Branch)? {
        /// Iterate through the path, from the end, looking first for a pair
        /// where the branch we were in was `Right`. Then we descend the `left`
        /// branch, looking for all the right-most elements.
        /// For example: In `LLRRLLRLL`, we "go up" the path to the pair
        /// `LLRRLL`, and then descend the `Left` branch for that pair, finding
        /// the right-most elements for that path. So it could look like:
        /// `LLRRLLLRRR`.
        /// If we go all the way up the tree that means there isn't a neighbor
        /// to the left of this path, so we return `nil`.
        /// For example: A path of `LLLLLLL` returns nil.
        var newPath = path
        while (true) {
            if newPath.count == 0 {
                return nil
            }
            let lastPathElement = newPath.removeLast()
            if lastPathElement == .Right {
                let parentPair = getPairFromPath(path: newPath)
                if parentPair.left.isPair() {
                    return (
                        pair: (parentPair.left as! Pair).findRightMostPair(),
                        branch: .Right
                    )
                } else {
                    return (pair: parentPair, branch: .Left)
                }
            }
        }
    }
    
    private func findRightNeighborOfPairPath(
        path: [Branch]
    ) -> (pair: Pair, branch: Branch)? {
        /// Iterate through the path, from the end, looking first for a pair
        /// where the branch we were in was `Left`. Then we descend the `Right`
        /// branch, looking for all the left-most elements.
        /// For example: In `LLRRLLRL`, we "go up" the path to the pair
        /// `LLRRLLRL`, and then descend the `Right` branch for that pair, finding
        /// the right-most elements for that path. So it could look like:
        /// `LLRRLLRLLLL`.
        /// If we go all the way up the tree that means there isn't a neighbor
        /// to the left of this path, so we return `nil`.
        /// For example: A path of `RRRRRRR` returns nil.
        var newPath = path
        while (true) {
            if newPath.count == 0 {
                return nil
            }
            let lastPathElement = newPath.removeLast()
            if lastPathElement == .Left {
                let parentPair = getPairFromPath(path: newPath)
                if parentPair.right.isPair() {
                    return (
                        pair: (parentPair.right as! Pair).findLeftMostPair(),
                        branch: .Left
                    )
                } else {
                    return (pair: parentPair, branch: .Right)
                }
            }
        }
    }
    
    func getPairFromPath(path: [Branch]) -> Pair {
        if path.count == 0 {
            return self
        }
        var newPath = path
        let dir = newPath.removeFirst()
        if dir == .Left {
            return (left as! Pair).getPairFromPath(path: newPath)
        } else {
            return (right as! Pair).getPairFromPath(path: newPath)
        }
    }
    
    func findLeftMostPair() -> Pair {
        if left.isPair() {
            return (left as! Pair).findLeftMostPair()
        } else {}
        return self
    }
    
    func findRightMostPair() -> Pair {
        if right.isPair() {
            return (right as! Pair).findRightMostPair()
        } else {}
        return self
    }
    
    func reduce() {
        /// Explode pairs that are deeper than 4 layers.
        if self.wantsToExplode(depth: 0) {
            let (pairToExplode, pathToPairToExplode) =
                self.findLeftMostPairToExplode(depth: 0)
            if let (leftNeighbor, leftNeighborBranch) =
                self.findLeftNeighborOfPairPath(path: pathToPairToExplode) {
                if leftNeighborBranch == .Left {
                    leftNeighbor.left = (
                        leftNeighbor.left.magnitude() +
                        pairToExplode.left.magnitude()
                    )
                } else {
                    leftNeighbor.right = (
                        leftNeighbor.right.magnitude() +
                        pairToExplode.left.magnitude()
                    )
                }
            }
            if let (rightNeighbor, rightNeighborBranch) =
                self.findRightNeighborOfPairPath(path: pathToPairToExplode) {
                if rightNeighborBranch == .Left {
                    rightNeighbor.left = (
                        rightNeighbor.left.magnitude() +
                        pairToExplode.right.magnitude()
                    )
                } else {
                    rightNeighbor.right = (
                        rightNeighbor.right.magnitude() +
                        pairToExplode.right.magnitude()
                    )
                }
            }
            setElement(at: pathToPairToExplode, to: 0)
            return
        }

        /// Split numbers larger than 9.
        if self.wantsToSplit() {
            let (elementToSplit, pathToElementToSplit) =
                self.findLeftMostNumberToSplit()
            let newPair = Pair(
                /// Regular number divided by two, rounded down.
                left: Int(floor(Float(elementToSplit) / 2.0)),
                /// Regular number divided by two, rounded up.
                right: Int(ceil(Float(elementToSplit) / 2.0))
            )
            setElement(at: pathToElementToSplit, to: newPair)
            return
        }
    }
    
    func add(_ rightPair: Pair) {
        let leftPair = Pair(
            left: left,
            right: right
        )
        left = leftPair
        right = rightPair
        while !self.isReduced() {
            self.reduce()
        }
    }
    
    func toString() -> String {
        return "[" + left.toString() + "," + right.toString() + "]"
    }
}

func parseSnailNumberAsElement(_ input: String) -> Element {
    var depth = 0
    var commaIndex: Int? = nil
    for (index, ch) in input.enumerated() {
        if depth == 0 && ch.isNumber {
            return Int(String(input))!
        }
        if ch == "[" {
            depth += 1
        }
        if ch == "]" {
            depth -= 1
        }
        if depth == 1 && ch == "," {
            commaIndex = index
            break
        }
    }
    let leftStart = input.index(input.startIndex, offsetBy: 1)
    let leftEnd = input.index(input.startIndex, offsetBy: commaIndex! - 1)
    let leftRange = leftStart...leftEnd

    let rightStart = input.index(input.startIndex, offsetBy: commaIndex! + 1)
    let rightEnd = input.index(input.endIndex, offsetBy: -2)
    let rightRange = rightStart...rightEnd
    
    return Pair(
        left: parseSnailNumberAsElement(String(input[leftRange])),
        right: parseSnailNumberAsElement(String(input[rightRange]))
    )
}

@main
enum Script {
    static func main() throws {
        let snailNumberStrings = try readFileInCwd(file: "/Day-18-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map { String($0) }
        
        var snailNumberSum: Pair? = nil
        for snailNumberString in snailNumberStrings {
            let snailNumber = parseSnailNumberAsElement(
                snailNumberString
            ) as! Pair
            if snailNumberSum == nil {
                snailNumberSum = snailNumber
            } else {
                snailNumberSum?.add(snailNumber)
            }
        }
        print("Part 1: ", snailNumberSum!.magnitude())
        
        var magnitudes: [Int] = []
        for aStr in snailNumberStrings {
            for bStr in snailNumberStrings {
                let leftSnailNumber = parseSnailNumberAsElement(aStr) as! Pair
                let rightSnailNumber = parseSnailNumberAsElement(bStr) as! Pair

                leftSnailNumber.add(rightSnailNumber)
                magnitudes.append(leftSnailNumber.magnitude())
            }
        }
        
        print("Part 2: ", magnitudes.max()!)
    }
}
