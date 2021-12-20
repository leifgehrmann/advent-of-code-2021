import Foundation

typealias Algorithm = [Int]
typealias Image = [[Int]]

func enhance(
    image: Image,
    using algorithm: Algorithm,
    outOfBoundsValue: Int
) -> (image: Image, outOfBoundsValue: Int) {
    let height = image.count
    let width = image[0].count
    var newImage: Image = Array(
        repeating: Array(
            repeating: 0,
            count: width + 2
        ),
        count: height + 2
    )
    
    for y in 0..<width + 2 {
        for x in 0..<height + 2 {
            let algorithmIndex = getAlgorithmIndex(
                at: (x: x - 1, y: y - 1),
                from: image,
                outOfBoundsValue: outOfBoundsValue
            )
            let newPixelValue = algorithm[algorithmIndex]
            newImage[y][x] = newPixelValue
        }
    }
    
    /// After processing the image, we need to figure out what the new
    /// out-of-bounds value is, since it will be processed by the same
    /// algorithm. We can lazily get this by using the same function as above,
    /// but instead pass in an empty array.
    let newOutOfBoundsAlgorithmIndex = getAlgorithmIndex(
        at: (x: 0, y: 0),
        from: [[]],
        outOfBoundsValue: outOfBoundsValue
    )
    let newOutOfBoundsValue = algorithm[newOutOfBoundsAlgorithmIndex]
    
    return (
        image: newImage,
        outOfBoundsValue: newOutOfBoundsValue
    )
}

func getAlgorithmIndex(
    at pixel: (x: Int, y: Int),
    from image: Image,
    outOfBoundsValue: Int
) -> Int {
    let height = image.count
    let width = image[0].count
    var value = 0
    for dy in -1...1 {
        for dx in -1...1 {
            if (
                pixel.y + dy < 0 ||
                pixel.x + dx < 0 ||
                pixel.y + dy >= height ||
                pixel.x + dx >= width
            ) {
                value = value << 1 + outOfBoundsValue
            } else {
                value = value << 1 + image[pixel.y + dy][pixel.x + dx]
            }
        }
    }
    return value
}

func countLitPixels(in image: Image) -> Int {
    return image.flatMap({$0}).reduce(0) {$0 + $1}
}

@main
enum Script {
    static func main() throws {
        let inputSplit = try readFileInCwd(file: "/Day-20-Input.txt")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: "\n\n")
        let algorithm = String(inputSplit[0])
            .map { $0 == "#" ? 1 : 0}
        var image = inputSplit[1].split(separator: "\n")
            .map { $0.map { $0 == "#" ? 1 : 0 } }
        
        /// The out of bounds value initially starts off as unlit pixels.
        /// But for each enhancement, the out-of-bounds value
        /// could flip between lit and unlit depending on the algorithm.
        var outOfBoundsValue = 0

        for iteration in 1...50 {
            (image, outOfBoundsValue) = enhance(
                image: image,
                using: algorithm,
                outOfBoundsValue: outOfBoundsValue
            )
            if (iteration == 2) {
                print("Part 1: ", countLitPixels(in: image))
            }
        }
        print("Part 2: ", countLitPixels(in: image))
    }
}
