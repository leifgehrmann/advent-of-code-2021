import Foundation

/// Define the graph system based on Strings, Tuples, and Arrays.
/// Wouldn't really recommend this in production environments, but it seemed convinient here!
typealias Node = String
typealias Edge = (Node, Node)
typealias Path = [Node]

extension Node {
    /// Returns `true` if the node is a small cave.
    ///
    /// Caves names that are uppercase are considered large caves.
    /// Otherwise, if they have a lowercase name, they are small caves.
    func isSmallCave() -> Bool {
        return self.rangeOfCharacter(from: .lowercaseLetters) != nil
    }
    
    /// Returns `true` if the node can be visited for a given path.
    func hasVisitedTooManyTimes(
        in path: Path,
        maxVisitsToSmallCaves: Int
    ) -> Bool {
        /// The `start` and `end` caves cannot be visited more than once.
        if self == "start" || self == "end" {
            return path.contains(self)
        }
        /// Small caves can be visited only a certain number of times, so it if appears
        /// in the path more than the `maxVisits`, we cannot visit it.
        if isSmallCave() {
            return path.filter {$0 == self}.count >= maxVisitsToSmallCaves
        }
        
        /// Large caves can be visited multiple times.
        return false
    }
}

extension Path {
    /// Returns a new path that adds `node` to the end of the sequence.
    func extend(to node: Node) -> Path {
        var newPath = self
        newPath.append(node)
        return newPath
    }
    
    /// Returns `true` if a small cave has appeared more than once in the path.
    func hasVisitedSmallCavesMoreThanOnce() -> Bool {
        let smallCavesInPath = self.filter { $0.isSmallCave() }
        let smallCavesInPathSet = Set(smallCavesInPath)
        return smallCavesInPathSet.count != smallCavesInPath.count
    }
    
    /// Finds the next nodes we can travel to given a sequence of `edges`.
    func findNextNodes(
        in edges: [Edge],
        which hasVisitConstraint: VisitConstraint
    ) -> [Node] {
        var potentialNodes: [Node] = []

        /// If there is no starting point, there are no next nodes to follow!
        guard let currentNode = self.last else {
            return potentialNodes
        }
        
        /// Depending on the puzzle part, we want to control how many times a
        /// certain node can be visited.
        /// * For Part 1, small caves could only be visited once.
        /// * For Part 2, small caves could be visited more than once, but only
        ///   if another small cave hasn't been visited more than once.
        let maxVisitsToSmallCaves: Int
        switch hasVisitConstraint {
        case .CannotVisitSmallCavesMoreThanOnce:
            maxVisitsToSmallCaves = 1
            break
        case .CanVisitOneSmallCaveMoreThanOnce:
            maxVisitsToSmallCaves = hasVisitedSmallCavesMoreThanOnce() ? 1 : 2
            break
        }
        
        /// Iterate all the edges, looking for the next potential nodes.
        for edge in edges {
            /// Handle `[0]` to `[1]`.
            if currentNode == edge.0 {
                if !edge.1.hasVisitedTooManyTimes(
                    in: self,
                    maxVisitsToSmallCaves: maxVisitsToSmallCaves
                ) {
                    potentialNodes.append(edge.1)
                }
            }
            /// Handle `[1]` to `[0]`.
            if currentNode == edge.1 {
                if !edge.0.hasVisitedTooManyTimes(
                    in: self,
                    maxVisitsToSmallCaves: maxVisitsToSmallCaves
                ) {
                    potentialNodes.append(edge.0)
                }
            }
        }
        
        return potentialNodes
    }
}

/// Returns all the paths that reach the end, with a given visit constraint.
func generateAllPathsToEnd (
    from path: Path,
    using edges: [Edge],
    which hasVisitConstraint: VisitConstraint
) -> [Path] {
    var pathsToEnd: [Path] = []
    let nextNodes = path.findNextNodes(
        in: edges,
        which: hasVisitConstraint
    )
    for nextNode in nextNodes {
        let extendedPath = path.extend(to: nextNode)
        if nextNode == "end" {
            pathsToEnd.append(extendedPath)
            continue
        }
        
        let extendedPathsToEnd = generateAllPathsToEnd(
            from: extendedPath,
            using: edges,
            which: hasVisitConstraint
        )
        pathsToEnd.append(contentsOf: extendedPathsToEnd)
    }
    
    return pathsToEnd
}

enum VisitConstraint {
    /// Visitation constraint for Part 1.
    case CannotVisitSmallCavesMoreThanOnce
    /// Visitation constraint for Part 2.
    case CanVisitOneSmallCaveMoreThanOnce
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-12-Input.txt")
        
        let edges = input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .map {$0.components(separatedBy: "-")}
            .map {Edge($0[0], $0[1])}

        let pathsToEndForPart1 = generateAllPathsToEnd(
            from: ["start"],
            using: edges,
            which: .CannotVisitSmallCavesMoreThanOnce
        )
        print("Part 1: ", pathsToEndForPart1.count)
        
        let pathsToEndForPart2 = generateAllPathsToEnd(
            from: ["start"],
            using: edges,
            which: .CanVisitOneSmallCaveMoreThanOnce
        )
        print("Part 2: ", pathsToEndForPart2.count)
    }
}
