import Foundation

/// A sequence of zeros and ones
typealias Bits = [UInt8]

struct Packet {
    let version: Int;
    let typeId: Int;
    let literalValue: Int?;
    let subPackets: [Packet]
}

func toInt(_ bits: Bits) -> Int {
    return bits.reduce(0) { $0 << 1 + Int($1) }
}

func toInt(_ bits: Bits.SubSequence) -> Int {
    return bits.reduce(0) { $0 << 1 + Int($1) }
}

func toBitsSubSequence(hexSequence: String) -> Bits.SubSequence {
    var bits: Bits = []
    for hex in hexSequence {
        /// If the asciiValue fails to unwrap, that means the input is incorrect.
        var fourBitInt = UInt8(String(hex), radix: 16)!
        /// Grab every bit in the sequence and append it to the `bits` array.
        for _ in 1...4 {
            let bit = (fourBitInt & 8) >> 3
            bits.append(bit)
            fourBitInt = fourBitInt << 1
        }
    }
    return bits[bits.startIndex..<bits.endIndex]
}

func getBit(in bits: Bits.SubSequence, at: Int) -> UInt8 {
    let index = bits.index(bits.startIndex, offsetBy: at)
    return bits[index]
}

func getBits(in bits: Bits.SubSequence, at: Int, length: Int) -> Bits.SubSequence {
    let indexStart = bits.index(bits.startIndex, offsetBy: at)
    let indexEnd = bits.index(bits.startIndex, offsetBy: at + length)
    return bits[indexStart..<indexEnd]
}

func getBits(in bits: Bits.SubSequence, from: Int) -> Bits.SubSequence {
    let indexStart = bits.index(bits.startIndex, offsetBy: from)
    return bits[indexStart..<bits.endIndex]
}

func printBits(_ bits: Bits.SubSequence) {
    print(bits.reduce("") { $0 + String($1) })
}

func printPacket(_ packet: Packet) {
    print("{")
    print("\"version\": \(packet.version),")
    if packet.literalValue != nil {
        print("\"literal\": \(packet.literalValue ?? -1)")
    } else {
        print("\"subPacket\": [")
        for (i, subPacket) in packet.subPackets.enumerated() {
            printPacket(subPacket)
            if i != packet.subPackets.count - 1 {
                print(",")
            }
        }
        print("]")
    }
    print("}")
}

func isPadding(bits: Bits.SubSequence) -> Bool {
    return !bits.contains(1)
}

func readLiteralValue(in bits: Bits.SubSequence) -> (literalValue: Int, endIndex: Int) {
    var index = 0
    var literalBits: Bits = []
    while (true) {
        literalBits.append(contentsOf: getBits(in: bits, at: index + 1, length: 4))
        
        let isLastGroup = getBit(in: bits, at: index) == 0
        if (isLastGroup) {
            break
        }
        index += 5
    }
    return (
        literalValue: toInt(literalBits),
        endIndex: index + 5
    )
}

func readOperator(in bits: Bits.SubSequence) -> (subPackets: [Packet], endIndex: Int) {
    let lengthTypeId = getBit(in: bits, at: 0)
    if (lengthTypeId == 0) {
        let totalBitLengthOfSubPackets = toInt(getBits(in: bits, at: 1, length: 15))
        var endIndex = 16
        let subPacketBits = getBits(in: bits, at: endIndex, length: totalBitLengthOfSubPackets)
        let (subPackets, subPacketsEndIndex) = readPackets(in: subPacketBits)
        endIndex += subPacketsEndIndex
        return (subPackets: subPackets, endIndex: endIndex)
    } else {
        let totalCountOfSubPackets = toInt(getBits(in: bits, at: 1, length: 11))
        var endIndex = 12
        var subPackets: [Packet] = []
        for _ in 1...totalCountOfSubPackets {
            let subPacketBits = getBits(in: bits, from: endIndex)
            let (packet, subPacketEndIndex) = readPacket(in: subPacketBits)
            subPackets.append(packet)
            endIndex += subPacketEndIndex
        }
        return (subPackets: subPackets, endIndex: endIndex)
    }
}

func readPacket(in bits: Bits.SubSequence) -> (packet: Packet, endIndex: Int) {
    let version = toInt(getBits(in: bits, at: 0, length: 3))
    let typeId = toInt(getBits(in: bits, at: 3, length: 3))
    var endIndex = 6
    
    if (typeId == 4) {
        /// Packet is a "literal value".
        let (literalValue, literalValueEndIndex) = readLiteralValue(in: getBits(in: bits, from: endIndex))
        endIndex += literalValueEndIndex
        return (
            packet: Packet(
                version: version,
                typeId: typeId,
                literalValue: literalValue,
                subPackets: []
            ),
            endIndex: endIndex
        )
    } else {
        let (subPackets, operatorEndIndex) = readOperator(in: getBits(in: bits, from: endIndex))
        endIndex += operatorEndIndex
        return (
            Packet(
                version: version,
                typeId: typeId,
                literalValue: nil,
                subPackets: subPackets
            ),
            endIndex: endIndex
        )
    }
}

func readPackets(in bits: Bits.SubSequence) -> (packets: [Packet], endIndex: Int) {
    var leftoverBits = bits
    var totalEndIndex = 0
    var packets: [Packet] = []
    while(true) {
        if (isPadding(bits: leftoverBits)) {
            break
        }
        let (packet, endIndex) = readPacket(in: leftoverBits)
        packets.append(packet)
        totalEndIndex += endIndex
        leftoverBits = getBits(in: leftoverBits, from: endIndex)
    }
    return (
        packets: packets,
        endIndex: totalEndIndex
    )
}

func versionSum(packet: Packet) -> Int {
    var totalSum = packet.version
    for subPacket in packet.subPackets {
        totalSum += versionSum(packet: subPacket)
    }
    return totalSum
}

func calculatePacket(packet: Packet) -> Int {
    if (packet.typeId == 0) {
        return packet.subPackets.map { calculatePacket(packet: $0)}.reduce(0, +)
    } else if (packet.typeId == 1) {
        return packet.subPackets.map { calculatePacket(packet: $0)}.reduce(1, *)
    } else if (packet.typeId == 2) {
        return packet.subPackets.map { calculatePacket(packet: $0)}.min()!
    } else if (packet.typeId == 3) {
        return packet.subPackets.map { calculatePacket(packet: $0)}.max()!
    } else if (packet.typeId == 4) {
        return packet.literalValue!
    } else if (packet.typeId == 5) {
        let calculatedPackets = packet.subPackets.map { calculatePacket(packet: $0)}
        return calculatedPackets.first! > calculatedPackets.last! ? 1 : 0
    } else if (packet.typeId == 6) {
        let calculatedPackets = packet.subPackets.map { calculatePacket(packet: $0)}
        return calculatedPackets.first! < calculatedPackets.last! ? 1 : 0
    } else if (packet.typeId == 7) {
        let calculatedPackets = packet.subPackets.map { calculatePacket(packet: $0)}
        return calculatedPackets.first! == calculatedPackets.last! ? 1 : 0
    }
    return 0
}

@main
enum Script {
    static func main() throws {
        let packetHex = try readFileInCwd(file: "/Day-16-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let packetBits = toBitsSubSequence(hexSequence: packetHex)
        let packet = readPacket(in: packetBits).packet
        
        print("Part 1: ", versionSum(packet: packet))
        
        print("Part 2: ", calculatePacket(packet: packet))
    }
}
