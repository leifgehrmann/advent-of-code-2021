import Foundation

enum Branch {
    case Left
    case Right
}

protocol PairElement {
    func magnitude() -> Int
    func isPair() -> Bool
    func isReduced() -> Bool
    func isReduced(depth: Int) -> Bool
    func wantsToExplode(depth: Int) -> Bool
    func wantsToSplit() -> Bool
    func reduceLoop()
}

extension Int: PairElement {
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
    func reduceLoop() {}
}

class Pair: PairElement {
    var left: PairElement;
    var right: PairElement;
    
    init (left: PairElement, right: PairElement) {
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
        return left.wantsToExplode(depth: depth + 1) || right.wantsToExplode(depth: depth + 1)
    }
    
    func setPairElement(at path: [Branch], to pairElement: PairElement) {
        var newPath = path
        let lastPathBranch = newPath.removeFirst()
        if newPath.count == 0 {
            if lastPathBranch == .Left {
                left = pairElement
            } else {
                right = pairElement
            }
        } else {
            if lastPathBranch == .Left {
                (left as! Pair).setPairElement(at: newPath, to: pairElement)
            } else {
                (right as! Pair).setPairElement(at: newPath, to: pairElement)
            }
        }
    }
    
    func findLeftMostPairToExplode(depth: Int) -> (pair: Pair, path: [Branch]) {
        var path: [Branch] = []
        var pairToExplode = self
        if left.wantsToExplode(depth: depth + 1) {
            path.append(.Left)
            if left.isPair() {
                let (leftPairToExplode, pathToLeftPairToExplode) = (left as! Pair).findLeftMostPairToExplode(depth: depth + 1)
                pairToExplode = leftPairToExplode
                path.append(contentsOf: pathToLeftPairToExplode)
            }
        } else if right.wantsToExplode(depth: depth + 1) {
            path.append(.Right)
            if right.isPair() {
                let (rightPairToExplode, pathToRightPairToExplode) = (right as! Pair).findLeftMostPairToExplode(depth: depth + 1)
                pairToExplode = rightPairToExplode
                path.append(contentsOf: pathToRightPairToExplode)
            }
        }
        return (
            pair: pairToExplode,
            path: path
        )
    }
    
    func findLeftMostPairElementToSplit() -> (pairElement: Int, path: [Branch]) {
        var path: [Branch] = []
        var pairElementToSplit = 0
        if left.wantsToSplit() {
            path.append(.Left)
            if left.isPair() {
                let (leftPairElementToSplit, pathToLeftPairElementToSplit) = (left as! Pair).findLeftMostPairElementToSplit()
                pairElementToSplit = leftPairElementToSplit
                path.append(contentsOf: pathToLeftPairElementToSplit)
            } else {
                pairElementToSplit = left as! Int
            }
        } else if right.wantsToSplit() {
            path.append(.Right)
            if right.isPair() {
                let (leftPairElementToSplit, pathToLeftPairElementToSplit) = (right as! Pair).findLeftMostPairElementToSplit()
                pairElementToSplit = leftPairElementToSplit
                path.append(contentsOf: pathToLeftPairElementToSplit)
            } else {
                pairElementToSplit = right as! Int
            }
        }
        return (
            pairElement: pairElementToSplit,
            path: path
        )
    }
    
    func findLeftNeighborOfPairPath(path: [Branch]) -> (pair: Pair, branch: Branch)? {
        // If we have a sequence 001100100, we start from the end,
        // and iterate backwards until we reach a 1. When there is a one, we
        // then try to find the right most pair from 0011000.
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
    
    func findRightNeighborOfPairPath(path: [Branch]) -> (pair: Pair, branch: Branch)? {
        // If we have a sequence 001100100, we start from the end,
        // and iterate backwards until we reach a 1. When there is a one, we
        // then try to find the right most pair from 0011000.
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
        /// Prioritize explosions
        if self.wantsToExplode(depth: 0) {
            let (pairToExplode, pathToPairToExplode) = self.findLeftMostPairToExplode(depth: 0)
            if var (leftNeighbor, leftNeighborBranch) = self.findLeftNeighborOfPairPath(path: pathToPairToExplode) {
                if leftNeighborBranch == .Left {
                    print("ghuyhu")
                    leftNeighbor.left = leftNeighbor.left.magnitude() + pairToExplode.left.magnitude()
                } else {
                    print("wat")
                    leftNeighbor.right = leftNeighbor.right.magnitude() + pairToExplode.left.magnitude()
                }
            }
            if var (rightNeighbor, rightNeighborBranch) = self.findRightNeighborOfPairPath(path: pathToPairToExplode) {
                if rightNeighborBranch == .Left {
                    print("hmm")
                    rightNeighbor.left = rightNeighbor.left.magnitude() + pairToExplode.right.magnitude()
                } else {
                    print("hagh", rightNeighbor.right)
                    rightNeighbor.right = rightNeighbor.right.magnitude() + pairToExplode.right.magnitude()
                }
            }
            setPairElement(at: pathToPairToExplode, to: 0)
            return
        }
        /// Now lets split big numbers
        if self.wantsToSplit() {
            let (pairElementToSplit, pathToPairElementToSplit) = self.findLeftMostPairElementToSplit()
            let newPair = Pair(
                left: Int(floor(Float(pairElementToSplit) / 2.0)),
                right: Int(ceil(Float(pairElementToSplit) / 2.0))
            )
            printSnailNumber(newPair)
            setPairElement(at: pathToPairElementToSplit, to: newPair)
            return
        }
    }
    
    func reduceLoop() {
        while !self.isReduced() {
            self.reduce()
        }
    }
    
    static func + (left: Pair, right: Pair) -> Pair {
        return Pair(
            left: left,
            right: right
        )
    }
}

func parseSnailNumberAsPairElement(_ input: String) -> PairElement {
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
    let leftRangeStart = input.index(input.startIndex, offsetBy: 1)
    let leftRangeEnd = input.index(input.startIndex, offsetBy: commaIndex! - 1)
    let rightRangeStart = input.index(input.startIndex, offsetBy: commaIndex! + 1)
    let rightRangeEnd = input.index(input.endIndex, offsetBy: -2)
    let leftRange = leftRangeStart...leftRangeEnd
    let rightRange = rightRangeStart...rightRangeEnd
    return Pair(
        left: parseSnailNumberAsPairElement(String(input[leftRange])),
        right: parseSnailNumberAsPairElement(String(input[rightRange]))
    )
}

func toString(_ pairElement: PairElement) -> String {
    if pairElement.isPair() {
        let pair = pairElement as! Pair
        return "[" + toString(pair.left) + "," + toString(pair.right) + "]"
    }
    return String(pairElement.magnitude())
}

func printSnailNumber(_ pairElement: PairElement) {
    print(toString(pairElement))
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-18-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var lastSnailNumber: PairElement? = nil
        for snailNumberString in input.split(separator: "\n") {
            print(snailNumberString)
            let snailNumber = parseSnailNumberAsPairElement(String(snailNumberString))
            if lastSnailNumber == nil {
                lastSnailNumber = snailNumber
            } else {
                lastSnailNumber = (lastSnailNumber as! Pair) + (snailNumber as! Pair)
            }
            (lastSnailNumber as! Pair).reduceLoop()
            printSnailNumber(lastSnailNumber as! PairElement)
            print("----")
        }
        print(lastSnailNumber?.magnitude())
        
        var magnitudes: [Int] = []
        for (ai, a) in input.split(separator: "\n").enumerated() {
            for (bi, b) in input.split(separator: "\n").enumerated() {
                let aNumber = parseSnailNumberAsPairElement(String(a))
                let bNumber = parseSnailNumberAsPairElement(String(b))
                
                if ai == bi {
                    continue
                }
                
                let cNumber = (aNumber as! Pair) + (bNumber as! Pair)
                cNumber.reduceLoop()
                
                printSnailNumber(aNumber)
                printSnailNumber(bNumber)
                printSnailNumber(cNumber)
                print("-----")
                magnitudes.append(cNumber.magnitude())
            }
        }
        
        print(magnitudes.max())
    }
}
