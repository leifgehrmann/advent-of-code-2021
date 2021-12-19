import Foundation

typealias Matrix = [[Int]]

func getAllOrientations() -> [Matrix] {
    /// http://www.euclideanspace.com/maths/algebra/matrix/transforms/examples/
    let combinations = [
        (ch:  1, ca:  1, cb:  1, sh:  0, sa:  0, sb:  0),
        (ch:  0, ca:  1, cb:  1, sh:  1, sa:  0, sb:  0),
        (ch: -1, ca:  1, cb:  1, sh:  0, sa:  0, sb:  0),
        (ch:  0, ca:  1, cb:  1, sh: -1, sa:  0, sb:  0),
        
        (ch:  1, ca:  0, cb:  1, sh:  0, sa:  1, sb:  0),
        (ch:  0, ca:  0, cb:  1, sh:  1, sa:  1, sb:  0),
        (ch: -1, ca:  0, cb:  1, sh:  0, sa:  1, sb:  0),
        (ch:  0, ca:  0, cb:  1, sh: -1, sa:  1, sb:  0),
        
        (ch:  1, ca:  0, cb:  1, sh:  0, sa: -1, sb:  0),
        (ch:  0, ca:  0, cb:  1, sh:  1, sa: -1, sb:  0),
        (ch: -1, ca:  0, cb:  1, sh:  0, sa: -1, sb:  0),
        (ch:  0, ca:  0, cb:  1, sh: -1, sa: -1, sb:  0),
        
        (ch:  1, ca:  1, cb:  0, sh:  0, sa:  0, sb:  1),
        (ch:  0, ca:  1, cb:  0, sh:  1, sa:  0, sb:  1),
        (ch: -1, ca:  1, cb:  0, sh:  0, sa:  0, sb:  1),
        (ch:  0, ca:  1, cb:  0, sh: -1, sa:  0, sb:  1),
        
        (ch:  1, ca:  1, cb: -1, sh:  0, sa:  0, sb:  0),
        (ch:  0, ca:  1, cb: -1, sh:  1, sa:  0, sb:  0),
        (ch: -1, ca:  1, cb: -1, sh:  0, sa:  0, sb:  0),
        (ch:  0, ca:  1, cb: -1, sh: -1, sa:  0, sb:  0),
        
        (ch:  1, ca:  1, cb: 0, sh:  0, sa:  0, sb:  -1),
        (ch:  0, ca:  1, cb: 0, sh:  1, sa:  0, sb:  -1),
        (ch: -1, ca:  1, cb: 0, sh:  0, sa:  0, sb:  -1),
        (ch:  0, ca:  1, cb: 0, sh: -1, sa:  0, sb:  -1),
    ]
    var orientations: [Matrix] = []
    for combination in combinations {
        let ch = combination.ch
        let ca = combination.ca
        let cb = combination.cb
        let sh = combination.sh
        let sa = combination.sa
        let sb = combination.sb
        
        let r1 = [ch * ca, -ch * sa * cb + sh * sb, ch * sa * sb + sh * cb]
        let r2 = [sa, ca * cb, -ca * sb]
        let r3 = [-sh * ca, sh * sa * cb + ch * sb, -sh * sa * sb + ch * cb]
        let m = [r1, r2, r3]
        
        orientations.append(m)
    }
    return orientations
}

func printMatrix(_ matrix: Matrix) {
    let r1 =
        String(matrix[0][0]).padding(toLength: 3, withPad: " ", startingAt: 0) +
        String(matrix[0][1]).padding(toLength: 3, withPad: " ", startingAt: 0) +
        String(matrix[0][2]).padding(toLength: 3, withPad: " ", startingAt: 0)
    let r2 =
        String(matrix[1][0]).padding(toLength: 3, withPad: " ", startingAt: 0) +
        String(matrix[1][1]).padding(toLength: 3, withPad: " ", startingAt: 0) +
        String(matrix[1][2]).padding(toLength: 3, withPad: " ", startingAt: 0)
    let r3 =
        String(matrix[2][0]).padding(toLength: 3, withPad: " ", startingAt: 0) +
        String(matrix[2][1]).padding(toLength: 3, withPad: " ", startingAt: 0) +
        String(matrix[2][2]).padding(toLength: 3, withPad: " ", startingAt: 0)
    print(r1)
    print(r2)
    print(r3)
    
    print("")
}

struct Scanner {
    let beacons: [RelativePosition]
    
    func beacons(in orientation: Matrix) -> [RelativePosition] {
        return self.beacons.map {$0.rotate(orientation)}
    }
    
    
}

struct RelativePosition: Equatable {
    let x: Int;
    let y: Int;
    let z: Int;
    
    func inverse() -> RelativePosition {
        return RelativePosition(
            x: -x,
            y: -y,
            z: -z
        )
    }
    
    static func + (left: RelativePosition, right: RelativePosition) -> RelativePosition {
        return RelativePosition(
            x: left.x + right.x,
            y: left.y + right.y,
            z: left.z + right.z
        )
    }
    
    func rotate(_ m: Matrix) -> RelativePosition {
        return RelativePosition(
            x: self.x * m[0][0] + self.y * m[1][0] + self.z * m[2][0],
            y: self.x * m[0][1] + self.y * m[1][1] + self.z * m[2][1],
            z: self.x * m[0][2] + self.y * m[1][2] + self.z * m[2][2]
        )
    }
}

func parseInput (input: String) -> [Scanner] {
    return input.components(separatedBy: "\n\n")
        .map { $0.split(separator: "\n") }
        .map { $0.filter { !$0.contains("scanner") } }
        .map {
            $0.map {
                $0.split(separator: ",")
                .map { Int(String($0)) }
                .compactMap {$0}
            }
        }
        .map {
            $0.map { RelativePosition(
                x: $0[0],
                y: $0[1],
                z: $0[2]
            )}
        }
        .map { Scanner(beacons: $0) }
}

func match (_ ap: [RelativePosition] , _ bp: [RelativePosition]) -> [(matches: Int, offset: RelativePosition)] {
    var matchInfos: [(matches: Int, offset: RelativePosition)] = []
    for a in ap {
        let ai = a.inverse()
        let newAp = ap.map { $0 + ai }
        for b in bp {
            let bi = b.inverse()
            let newBp = bp.map { $0 + bi }
            
            var matches = 0
            for newA in newAp {
                if (newBp.contains(newA)) {
                    matches += 1
                }
            }
            
            if (matches >= 12) {
                matchInfos.append((
                    matches: matches,
                    offset: a + bi
                ))
            }
        }
    }
    return matchInfos
}

func manhattanDistance(_ a: RelativePosition, _ b: RelativePosition) -> Int {
    return abs(a.x - b.x) + abs(a.y - b.y) + abs(a.z - b.z)
}

func mergeBeacons(_ aArr: [RelativePosition], _ bArr: [RelativePosition]) -> [RelativePosition] {
    var newArr = aArr
    for b in bArr {
        if !newArr.contains(b) {
            newArr.append(b)
        }
    }
    return newArr
}

@main
enum Script {
    static func main() throws {
        let input = try readFileInCwd(file: "/Day-19-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var scanners = parseInput(input: input)
        
        var orientations = getAllOrientations()
        
        /// Use the first scanner as the true orientation.
        var allScanenrIdsToBla = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28]
        var scannerIdsToIgnore = [0, 6, 14, 24, 2, 13, 1, 5, 7, 9, 12, 26, 10, 15, 3, 16, 22, 28, 17, 18, 20, 23, 27, 8, 11, 19, 4, 21, 25]
        var scanner0 = scanners[0]
        print("Total beacons: \(scanner0.beacons.count)")
        var scanner0Beacons = scanner0.beacons
        
        // Done
        let scanner6 = scanners[6]
        let scanner6Rot = orientations[11]
        let scanner6Off = RelativePosition(x: 1259, y: -25, z: 96)
        let scanner6BeaconsRot = scanner6.beacons(in: scanner6Rot)
        let scanner6Beacons = scanner6BeaconsRot.map {$0 + scanner6Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner6Beacons))
        print("Total beacons: \(scanner0.beacons.count)")

        // Not done
        let scanner14 = scanners[14]
        let scanner14Rot = orientations[12]
        let scanner14Off = RelativePosition(x: 131, y: 1177, z: 119)
        let scanner14BeaconsRot = scanner14.beacons(in: scanner14Rot)
        let scanner14Beacons = scanner14BeaconsRot.map {$0 + scanner14Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner14Beacons))
        print("Total beacons: \(scanner0.beacons.count)")

        // Not done
        let scanner24 = scanners[24]
        let scanner24Rot = orientations[9]
        let scanner24Off = RelativePosition(x: 34, y: -1251, z: 105)
        let scanner24BeaconsRot = scanner24.beacons(in: scanner24Rot)
        let scanner24Beacons = scanner24BeaconsRot.map {$0 + scanner24Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner24Beacons))
        print("Total beacons: \(scanner0.beacons.count)")

        // Not done
        let scanner2 = scanners[2]
        let scanner2Rot = orientations[1]
        let scanner2Off = RelativePosition(x: 24, y: -1203, z: -1060)
        let scanner2BeaconsRot = scanner2.beacons(in: scanner2Rot)
        let scanner2Beacons = scanner2BeaconsRot.map {$0 + scanner2Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner2Beacons))
        print("Total beacons: \(scanner0.beacons.count)")

        // Not done
        let scanner13 = scanners[13]
        let scanner13Rot = orientations[4]
        let scanner13Off = RelativePosition(x: 42, y: -1129, z: 1156)
        let scanner13BeaconsRot = scanner13.beacons(in: scanner13Rot)
        let scanner13Beacons = scanner13BeaconsRot.map {$0 + scanner13Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner13Beacons))
        print("Total beacons: \(scanner0.beacons.count)")

        // Done
        let scanner1 = scanners[1]
        let scanner1Rot = orientations[10]
        let scanner1Off = RelativePosition(x: -1073, y: -1262, z: -1084)
        let scanner1BeaconsRot = scanner1.beacons(in: scanner1Rot)
        let scanner1Beacons = scanner1BeaconsRot.map {$0 + scanner1Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner1Beacons))
        print("Total beacons: \(scanner0.beacons.count)")

        // Done
        let scanner5 = scanners[5]
        let scanner5Rot = orientations[2]
        let scanner5Off = RelativePosition(x: 8, y: -2369, z: 1232)
        let scanner5BeaconsRot = scanner5.beacons(in: scanner5Rot)
        let scanner5Beacons = scanner5BeaconsRot.map {$0 + scanner5Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner5Beacons))
        print("Total beacons: \(scanner0.beacons.count)")

        // Done
        let scanner7 = scanners[7]
        let scanner7Rot = orientations[20]
        let scanner7Off = RelativePosition(x: -1222, y: -2464, z: 34)
        let scanner7BeaconsRot = scanner7.beacons(in: scanner7Rot)
        let scanner7Beacons = scanner7BeaconsRot.map {$0 + scanner7Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner7Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Done
        let scanner9 = scanners[9]
        let scanner9Rot = orientations[13]
        let scanner9Off = RelativePosition(x: -1136, y: -1251, z: 1226)
        let scanner9BeaconsRot = scanner9.beacons(in: scanner9Rot)
        let scanner9Beacons = scanner9BeaconsRot.map {$0 + scanner9Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner9Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Done
        let scanner12 = scanners[12]
        let scanner12Rot = orientations[3]
        let scanner12Off = RelativePosition(x: -2264, y: -1282, z: 1228)
        let scanner12BeaconsRot = scanner12.beacons(in: scanner12Rot)
        let scanner12Beacons = scanner12BeaconsRot.map {$0 + scanner12Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner12Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Done
        let scanner26 = scanners[26]
        let scanner26Rot = orientations[3]
        let scanner26Off = RelativePosition(x: -1170, y: -2479, z: 1245)
        let scanner26BeaconsRot = scanner26.beacons(in: scanner26Rot)
        let scanner26Beacons = scanner26BeaconsRot.map {$0 + scanner26Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner26Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Done
        let scanner10 = scanners[10]
        let scanner10Rot = orientations[19]
        let scanner10Off = RelativePosition(x: -1103, y: -3646, z: 1333)
        let scanner10BeaconsRot = scanner10.beacons(in: scanner10Rot)
        let scanner10Beacons = scanner10BeaconsRot.map {$0 + scanner10Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner10Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Done
        let scanner15 = scanners[15]
        let scanner15Rot = orientations[23]
        let scanner15Off = RelativePosition(x: -1229, y: -1121, z: -2263)
        let scanner15BeaconsRot = scanner15.beacons(in: scanner15Rot)
        let scanner15Beacons = scanner15BeaconsRot.map {$0 + scanner15Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner15Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Done
        let scanner3 = scanners[3]
        let scanner3Rot = orientations[15]
        let scanner3Off = RelativePosition(x: -1206, y: -1134, z: -3529)
        let scanner3BeaconsRot = scanner3.beacons(in: scanner3Rot)
        let scanner3Beacons = scanner3BeaconsRot.map {$0 + scanner3Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner3Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        // Done
        let scanner16 = scanners[16]
        let scanner16Rot = orientations[9]
        let scanner16Off = RelativePosition(x: 118, y: -2436, z: 2536)
        let scanner16BeaconsRot = scanner16.beacons(in: scanner16Rot)
        let scanner16Beacons = scanner16BeaconsRot.map {$0 + scanner16Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner16Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        // Done
        let scanner22 = scanners[22]
        let scanner22Rot = orientations[18]
        let scanner22Off = RelativePosition(x: 102, y: -1253, z: -2391)
        let scanner22BeaconsRot = scanner22.beacons(in: scanner22Rot)
        let scanner22Beacons = scanner22BeaconsRot.map {$0 + scanner22Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner22Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        // Done
        let scanner28 = scanners[28]
        let scanner28Rot = orientations[12]
        let scanner28Off = RelativePosition(x: 1242, y: -2451, z: 1335)
        let scanner28BeaconsRot = scanner28.beacons(in: scanner28Rot)
        let scanner28Beacons = scanner28BeaconsRot.map {$0 + scanner28Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner28Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Done
        let scanner17 = scanners[17]
        let scanner17Rot = orientations[16]
        let scanner17Off = RelativePosition(x: 5, y: -3612, z: 2371)
        let scanner17BeaconsRot = scanner17.beacons(in: scanner17Rot)
        let scanner17Beacons = scanner17BeaconsRot.map {$0 + scanner17Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner17Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        // Done
        let scanner18 = scanners[18]
        let scanner18Rot = orientations[21]
        let scanner18Off = RelativePosition(x: -8, y: -1141, z: 2420)
        let scanner18BeaconsRot = scanner18.beacons(in: scanner18Rot)
        let scanner18Beacons = scanner18BeaconsRot.map {$0 + scanner18Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner18Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        // Done
        let scanner20 = scanners[20]
        let scanner20Rot = orientations[7]
        let scanner20Off = RelativePosition(x: 1300, y: -3697, z: 1199)
        let scanner20BeaconsRot = scanner20.beacons(in: scanner20Rot)
        let scanner20Beacons = scanner20BeaconsRot.map {$0 + scanner20Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner20Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        // Done
        let scanner23 = scanners[23]
        let scanner23Rot = orientations[8]
        let scanner23Off = RelativePosition(x: 1207, y: -2384, z: 98)
        let scanner23BeaconsRot = scanner23.beacons(in: scanner23Rot)
        let scanner23Beacons = scanner23BeaconsRot.map {$0 + scanner23Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner23Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        // Done
        let scanner27 = scanners[27]
        let scanner27Rot = orientations[21]
        let scanner27Off = RelativePosition(x: 2422, y: -2319, z: 1314)
        let scanner27BeaconsRot = scanner27.beacons(in: scanner27Rot)
        let scanner27Beacons = scanner27BeaconsRot.map {$0 + scanner27Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner27Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        /// Done
        let scanner8 = scanners[8]
        let scanner8Rot = orientations[6]
        let scanner8Off = RelativePosition(x: 1185, y: -1172, z: 2461)
        let scanner8BeaconsRot = scanner8.beacons(in: scanner8Rot)
        let scanner8Beacons = scanner8BeaconsRot.map {$0 + scanner8Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner8Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        /// Done
        let scanner11 = scanners[11]
        let scanner11Rot = orientations[5]
        let scanner11Off = RelativePosition(x: 95, y: -1228, z: 3607)
        let scanner11BeaconsRot = scanner11.beacons(in: scanner11Rot)
        let scanner11Beacons = scanner11BeaconsRot.map {$0 + scanner11Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner11Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
//
//        /// Done
        let scanner19 = scanners[19]
        let scanner19Rot = orientations[14]
        let scanner19Off = RelativePosition(x: 2468, y: -2359, z: 2369)
        let scanner19BeaconsRot = scanner19.beacons(in: scanner19Rot)
        let scanner19Beacons = scanner19BeaconsRot.map {$0 + scanner19Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner19Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Not done
        let scanner4 = scanners[4]
        let scanner4Rot = orientations[22]
        let scanner4Off = RelativePosition(x: -1215, y: -1176, z: 3631)
        let scanner4BeaconsRot = scanner4.beacons(in: scanner4Rot)
        let scanner4Beacons = scanner4BeaconsRot.map {$0 + scanner4Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner4Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Not done
        let scanner21 = scanners[21]
        let scanner21Rot = orientations[17]
        let scanner21Off = RelativePosition(x: 1311, y: -1135, z: 3694)
        let scanner21BeaconsRot = scanner21.beacons(in: scanner21Rot)
        let scanner21Beacons = scanner21BeaconsRot.map {$0 + scanner21Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner21Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        // Not done
        let scanner25 = scanners[25]
        let scanner25Rot = orientations[10]
        let scanner25Off = RelativePosition(x: 2376, y: -2330, z: 3618)
        let scanner25BeaconsRot = scanner25.beacons(in: scanner25Rot)
        let scanner25Beacons = scanner25BeaconsRot.map {$0 + scanner25Off }
        scanner0 = Scanner(beacons: mergeBeacons(scanner0.beacons, scanner25Beacons))
        print("Total beacons: \(scanner0.beacons.count)")
        
        
        let beacons0 = scanner0.beacons
        for (scannerId, scanner) in scanners.enumerated() {
            print("----- \(scannerId) -----")
            if (scannerIdsToIgnore.contains(scannerId)) {
                continue
            }
            for (orientationIndex, orientation) in orientations.enumerated() {
                let newBeacons = scanner.beacons(in: orientation)
                
                let matches = match(beacons0, newBeacons)
                if (matches.count > 0) {
                    print("----- \(scannerId) -----")
                    print("orientation Index: \(orientationIndex)")
                    print("There was a match: \(matches.count)")
                    print(matches)
                }
            }
        }
        
        let offsets = [
            RelativePosition(x: 0, y: 0, z: 0),
            scanner1Off,
            scanner2Off,
            scanner3Off,
            scanner4Off,
            scanner5Off,
            scanner6Off,
            scanner7Off,
            scanner8Off,
            scanner9Off,
            scanner10Off,
            scanner11Off,
            scanner12Off,
            scanner13Off,
            scanner14Off,
            scanner15Off,
            scanner16Off,
            scanner17Off,
            scanner18Off,
            scanner19Off,
            scanner20Off,
            scanner2Off,
            scanner21Off,
            scanner22Off,
            scanner23Off,
            scanner24Off,
            scanner25Off,
            scanner26Off,
            scanner27Off,
            scanner28Off,
        ]
        var maxManhattan = 0
        for a in offsets {
            for b in offsets {
                let ab = manhattanDistance(a, b)
                if maxManhattan < ab {
                    print(a)
                    print(b)
                    maxManhattan = ab
                }
            }
        }
        
        
        // 14406
        print(maxManhattan)
    }
}
