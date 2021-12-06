import Foundation

/// This is the lazy solution, which simply stores the state of each fish in an array.
/// This is inefficient because for a large number of days you'll run into time and
/// space issues.
func part1(_ initialState: [Int], days: Int) -> Int {
    let newInternalTimer = 8
    let renewedInternalTimer = 6

    var state = initialState

    for _ in 1...days {
        /// Spawn new fish and append them to the end of the array.
        let newLanternFishesCount = state.filter {$0 == 0}.count
        let newLanternFishes = Array.init(
            /// To account for the state change at the end of iteration,
            /// I've lazily added 1 to the initial internal timer...
            /// I know... it seems wrong. part2 is a much neater solution,
            /// but this is what I cam up with at the start.
            repeating: newInternalTimer + 1,
            count: newLanternFishesCount
        )
        state = state + newLanternFishes
        
        /// Adjust the life-cycle of each fish.
        state = state.map { $0 > 0 ? $0 - 1 : renewedInternalTimer }
    }
    return state.count
}

/// This is the optimized solution, where the count of each fish for their
/// respective state is kept track of, and a simple arithmetic calculation
/// is needed to proceed through each day.
func part2(_ initialState: [Int], days: Int) -> Int {
    let newInternalTimer = 8
    let renewedInternalTimer = 6
    
    /// Count the total number of fish in each state. This approach seems a lot
    /// simpler than using a `.reduce()`.
    var fishCountsInStates = Array.init(repeating: 0, count: newInternalTimer + 1)
    for fishState in initialState {
        fishCountsInStates[fishState] += 1
    }

    for _ in 1...days {
        var newFishCountsInState = Array.init(repeating: 0, count: newInternalTimer + 1)
        /// When the state of the fish is 0, we put all the counts into `renewedInternalTimer`,
        /// and add the same count to `newInternalTimer`.
        newFishCountsInState[renewedInternalTimer] += fishCountsInStates[0]
        newFishCountsInState[newInternalTimer] += fishCountsInStates[0]
        
        /// Shift the fish in the higher states into the next lower state.
        for fishState in 1...newInternalTimer {
            newFishCountsInState[fishState - 1] += fishCountsInStates[fishState]
        }
        
        fishCountsInStates = newFishCountsInState
    }

    /// Count the total number of fish in each state.
    return fishCountsInStates.reduce(0, +)
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-06-Input.txt")
        let state = input
            .replacingOccurrences(of: "\n", with: "") // Remove whitespace
            .split(separator: ",")
            .map { Int($0)! }.compactMap({ $0 })

        print("Part 1:", part1(state, days: 80))
        print("Part 2:", part2(state, days: 256))
    }
}
