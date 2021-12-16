import Foundation

/// A sequence of zeros and ones.
typealias Bits = [UInt8]

/// The final parsed result. Note that each packet contains a list of
/// sub-packets, or it optionally includes a literalValue. In practice
/// a packet can only have one or the other.
struct Packet {
    let version: Int;
    let typeId: Int;
    let literalValue: Int?;
    let subPackets: [Packet]
}

/// Converts a sequence of `1`s and `0`s to a number.
func toInt(_ bits: Bits) -> Int {
    return bits.reduce(0) { $0 << 1 + Int($1) }
}

/// Converts a sequence of `1`s and `0`s to a number.
func toInt(_ bits: Bits.SubSequence) -> Int {
    return bits.reduce(0) { $0 << 1 + Int($1) }
}

/// Converts a sequence of `0-9A-F` characters to a sequence of `1`s and `0`s.
func toBitsSubSequence(hexSequence: String) -> Bits.SubSequence {
    var bits: Bits = []
    for hex in hexSequence {
        var fourBitInt = UInt8(String(hex), radix: 16)!
        /// Grab every bit in the integer and append it to the `bits` array.
        for _ in 1...4 {
            let bit = (fourBitInt & 8) >> 3
            bits.append(bit)
            fourBitInt = fourBitInt << 1
        }
    }
    return bits[bits.startIndex..<bits.endIndex]
}

/// Returns an individual "bit" from a sequence of bits.
func getBit(in bits: Bits.SubSequence, at: Int) -> UInt8 {
    let index = bits.index(bits.startIndex, offsetBy: at)
    return bits[index]
}

/// Returns a subsequence of bits from a sequence of bits, starting from
/// `at` and finishing at `at + length`.
func getBits(
    in bits: Bits.SubSequence,
    at: Int,
    length: Int
) -> Bits.SubSequence {
    let indexStart = bits.index(bits.startIndex, offsetBy: at)
    let indexEnd = bits.index(bits.startIndex, offsetBy: at + length)
    return bits[indexStart..<indexEnd]
}

/// Returns a subsequence of bits from a sequence of bits, starting from
/// `from` and finishing at the end of the array.
func getBits(in bits: Bits.SubSequence, from: Int) -> Bits.SubSequence {
    let indexStart = bits.index(bits.startIndex, offsetBy: from)
    return bits[indexStart..<bits.endIndex]
}

/// Returns `true` if the sequence of bits all contain `0`s.
func isPadding(bits: Bits.SubSequence) -> Bool {
    return !bits.contains(1)
}

/// Returns the literal value and the number of bits it took to read
/// the value from a sequence of bits.
func readLiteralValue(
    in bits: Bits.SubSequence
) -> (literalValue: Int, bitLength: Int) {
    var index = 0
    var literalBits: Bits = []
    while (true) {
        let groupBits = getBits(in: bits, at: index + 1, length: 4)
        literalBits.append(contentsOf: groupBits)
        
        let isLastGroup = getBit(in: bits, at: index) == 0
        if (isLastGroup) {
            break
        }
        index += 5
    }
    return (
        literalValue: toInt(literalBits),
        bitLength: index + 5
    )
}

/// Returns a list of sub-packets from a sequence of bits, including
/// the number of bits it took to read all the sub-packets.
func readSubPackets(
    in bits: Bits.SubSequence
) -> (subPackets: [Packet], bitLength: Int) {
    let lengthTypeId = getBit(in: bits, at: 0)
    var totalSubPacketBitLength = 0
    var subPackets: [Packet] = []
    if (lengthTypeId == 0) {
        /// If the length-type-ID is 0, that means the next 15 bits in the
        /// sequence represents the total number of bits that the
        /// sub-packets consists of.
        let bitLengthOfSubPackets = toInt(getBits(in: bits, at: 1, length: 15))
        totalSubPacketBitLength = 1 + 15
        var subPacketBits = getBits(
            in: bits,
            at: 1 + 15,
            length: bitLengthOfSubPackets
        )
        while(true) {
            if (isPadding(bits: subPacketBits)) {
                break
            }
            let (subPacket, subPacketBitLength) = readPacket(in: subPacketBits)
            subPackets.append(subPacket)
            totalSubPacketBitLength += subPacketBitLength
            subPacketBits = getBits(in: subPacketBits, from: subPacketBitLength)
        }
    } else {
        /// If the length-type-ID is 1, that means the next 11 bits in the
        /// sequence represent the total number of sub-packets we
        /// expect to read next.
        let totalCountOfSubPackets = toInt(getBits(in: bits, at: 1, length: 11))
        totalSubPacketBitLength = 1 + 11
        var subPacketBits = getBits(in: bits, from: 1 + 11)
        for _ in 1...totalCountOfSubPackets {
            let (subPacket, subPacketBitLength) = readPacket(in: subPacketBits)
            subPackets.append(subPacket)
            totalSubPacketBitLength += subPacketBitLength
            subPacketBits = getBits(in: subPacketBits, from: subPacketBitLength)
        }
    }
    return (
        subPackets: subPackets,
        bitLength: totalSubPacketBitLength
    )
}

/// Returns a packet from a sequence of bits, including the number of
/// bits it took to read the entire packet, including sub-packets and
/// literal values.
func readPacket(in bits: Bits.SubSequence) -> (packet: Packet, bitLength: Int) {
    /// The first 6 bits of the packet are header values.
    let version = toInt(getBits(in: bits, at: 0, length: 3))
    let typeId = toInt(getBits(in: bits, at: 3, length: 3))
    /// The rest of the bits for the packet contains the content.
    let headerBitLength = 6
    
    /// If the typeId is `4`, that means the packet is a literal value.
    if (typeId == 4) {
        /// Packet is a "literal value".
        let literalValueBits = getBits(in: bits, from: headerBitLength)
        let (literalValue, literalValueBitLength) = readLiteralValue(
            in: literalValueBits
        )
        return (
            packet: Packet(
                version: version,
                typeId: typeId,
                literalValue: literalValue,
                subPackets: []
            ),
            bitLength: headerBitLength + literalValueBitLength
        )
    }
    
    /// Otherwise, if the typeId is something else, that means it has a
    /// sequence of sub-packets.
    let subPacketBits = getBits(in: bits, from: headerBitLength)
    let (subPackets, subPacketsBitLength) = readSubPackets(in: subPacketBits)
    return (
        Packet(
            version: version,
            typeId: typeId,
            literalValue: nil,
            subPackets: subPackets
        ),
        bitLength: headerBitLength + subPacketsBitLength
    )
}

/// Sums the versions for all the packets, including the sub-packets within
/// the packet.
func versionSumOfPacketAndSubPackets(_ packet: Packet) -> Int {
    var totalSum = packet.version
    for subPacket in packet.subPackets {
        totalSum += versionSumOfPacketAndSubPackets(subPacket)
    }
    return totalSum
}

/// Performs the operations within a packet and returns the value
/// of performing those operations.
func calculatePacket(_ packet: Packet) -> Int {
    if (packet.typeId == 0) {
        /// Operation to sum all the sub-packet values together.
        return packet.subPackets.map { calculatePacket($0)}.reduce(0, +)
    } else if (packet.typeId == 1) {
        /// Operation to multiply all the sub-packet values together.
        return packet.subPackets.map { calculatePacket($0)}.reduce(1, *)
    } else if (packet.typeId == 2) {
        /// Operation to get the minimum value of all the sub-packet values.
        return packet.subPackets.map { calculatePacket($0)}.min()!
    } else if (packet.typeId == 3) {
        /// Operation to get the maximum value of all the sub-packet values.
        return packet.subPackets.map { calculatePacket($0)}.max()!
    } else if (packet.typeId == 4) {
        /// If the typeId is a literalValue, then no operations are required.
        return packet.literalValue!
    } else if (packet.typeId == 5) {
        /// Returns `1` if the first sub-packet is larger than the second
        /// sub-packet, otherwise it returns `0`.
        let calculatedPackets = packet.subPackets.map { calculatePacket($0)}
        return calculatedPackets.first! > calculatedPackets.last! ? 1 : 0
    } else if (packet.typeId == 6) {
        /// Returns `1` if the first sub-packet is smaller than the second
        /// sub-packet, otherwise it returns `0`.
        let calculatedPackets = packet.subPackets.map { calculatePacket($0)}
        return calculatedPackets.first! < calculatedPackets.last! ? 1 : 0
    } else if (packet.typeId == 7) {
        /// Returns `1` if the first sub-packet is equal to the second
        /// sub-packet, otherwise it returns `0`.
        let calculatedPackets = packet.subPackets.map { calculatePacket($0)}
        return calculatedPackets.first! == calculatedPackets.last! ? 1 : 0
    }
    /// This should be an invalid state.
    return 0
}

@main
enum Script {
    static func main() throws {
        let packetHex = try readFileInCwd(file: "/Day-16-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        /// First we convert everything to ones and zeros, to make array slicing easier for us.
        let packetBits = toBitsSubSequence(hexSequence: packetHex)

        let packet = readPacket(in: packetBits).packet
        
        print("Part 1: ", versionSumOfPacketAndSubPackets(packet))
        print("Part 2: ", calculatePacket(packet))
    }
}
