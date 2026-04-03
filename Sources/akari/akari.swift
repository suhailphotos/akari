import Foundation
import CoreImage
import ImageIO
import CoreGraphics

enum AppError: Error, LocalizedError {
    case usage
    case cannotLoadImage(URL)
    case missingColorSpace(String)
    case cannotCreateOutputDirectory(URL)
    case unsupportedOSVersion
    case unsupportedOutputExtension(String)

    var errorDescription: String? {
        switch self {
        case .usage:
            return """
            Usage:
              akari <sdr.tif> <hdr.tif> <output.{heic|heif|jpg|jpeg}> [p3|srgb] [mono|rgb]

            Examples:
              akari myimage_sdr.tif myimage_hdr.tif out.heic p3 mono
              akari myimage_sdr.tif myimage_hdr.tif out.heic p3 rgb
              akari myimage_sdr.tif myimage_hdr.tif out.jpg p3 rgb
            """
        case .cannotLoadImage(let url):
            return "Could not load image: \(url.path)"
        case .missingColorSpace(let name):
            return "Could not create color space: \(name)"
        case .cannotCreateOutputDirectory(let url):
            return "Could not create output directory for: \(url.path)"
        case .unsupportedOSVersion:
            return "This tool requires macOS 15.0 or newer for Adaptive HDR export."
        case .unsupportedOutputExtension(let ext):
            return "Unsupported output extension: \(ext). Use .heic, .heif, .jpg, or .jpeg"
        }
    }
}

enum OutputKind: String {
    case heif
    case jpeg
}

enum GainMapKind: String {
    case mono
    case rgb
}

struct Config {
    let sdrURL: URL
    let hdrURL: URL
    let outputURL: URL
    let colorSpaceName: String
    let outputKind: OutputKind
    let gainMapKind: GainMapKind
}

func inferOutputKind(from outputURL: URL) throws -> OutputKind {
    let ext = outputURL.pathExtension.lowercased()
    switch ext {
    case "heic", "heif":
        return .heif
    case "jpg", "jpeg":
        return .jpeg
    default:
        throw AppError.unsupportedOutputExtension(ext)
    }
}

func parseArgs() throws -> Config {
    let args = CommandLine.arguments
    guard args.count >= 4 else {
        throw AppError.usage
    }

    let sdrURL = URL(fileURLWithPath: args[1]).standardizedFileURL
    let hdrURL = URL(fileURLWithPath: args[2]).standardizedFileURL
    let outputURL = URL(fileURLWithPath: args[3]).standardizedFileURL
    let colorSpaceName = args.count >= 5 ? args[4].lowercased() : "p3"
    let outputKind = try inferOutputKind(from: outputURL)

    let gainMapKind: GainMapKind
    if args.count >= 6 {
        gainMapKind = (args[5].lowercased() == "rgb") ? .rgb : .mono
    } else {
        gainMapKind = .mono
    }

    return Config(
        sdrURL: sdrURL,
        hdrURL: hdrURL,
        outputURL: outputURL,
        colorSpaceName: colorSpaceName,
        outputKind: outputKind,
        gainMapKind: gainMapKind
    )
}

func makeColorSpace(named name: String) throws -> CGColorSpace {
    switch name {
    case "p3":
        if let cs = CGColorSpace(name: CGColorSpace.displayP3) {
            return cs
        }
        throw AppError.missingColorSpace("Display P3")
    case "srgb":
        if let cs = CGColorSpace(name: CGColorSpace.sRGB) {
            return cs
        }
        throw AppError.missingColorSpace("sRGB")
    default:
        if let cs = CGColorSpace(name: CGColorSpace.displayP3) {
            return cs
        }
        throw AppError.missingColorSpace("Display P3")
    }
}

func loadCIImage(from url: URL) throws -> CIImage {
    guard let image = CIImage(contentsOf: url, options: [
        .applyOrientationProperty: true
    ]) else {
        throw AppError.cannotLoadImage(url)
    }
    return image
}

func ensureSameExtent(_ a: CIImage, _ b: CIImage) -> Bool {
    a.extent.integral.equalTo(b.extent.integral)
}

func resizeIfNeeded(source: CIImage, to match: CIImage) -> CIImage {
    let srcExtent = source.extent.integral
    let dstExtent = match.extent.integral

    guard !srcExtent.equalTo(dstExtent) else {
        return source
    }

    let scaleX = dstExtent.width / srcExtent.width
    let scaleY = dstExtent.height / srcExtent.height
    let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

    return source.transformed(by: transform)
}

func createOutputDirectoryIfNeeded(for outputURL: URL) throws {
    let dir = outputURL.deletingLastPathComponent()
    var isDir: ObjCBool = false

    if FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir) {
        return
    }

    do {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    } catch {
        throw AppError.cannotCreateOutputDirectory(outputURL)
    }
}

@available(macOS 15.0, *)
func adaptiveHDROptions(hdrImage: CIImage, gainMapKind: GainMapKind) -> [CIImageRepresentationOption: Any] {
    [
        .hdrImage: hdrImage,
        .hdrGainMapAsRGB: gainMapKind == .rgb
    ]
}

@available(macOS 15.0, *)
func writeAdaptiveHDRHEIF(
    sdrImage: CIImage,
    hdrImage: CIImage,
    outputURL: URL,
    colorSpace: CGColorSpace,
    gainMapKind: GainMapKind
) throws {
    let context = CIContext(options: nil)
    let options = adaptiveHDROptions(hdrImage: hdrImage, gainMapKind: gainMapKind)

    try context.writeHEIFRepresentation(
        of: sdrImage,
        to: outputURL,
        format: .RGBA8,
        colorSpace: colorSpace,
        options: options
    )
}

@available(macOS 15.0, *)
func writeAdaptiveHDRJPEG(
    sdrImage: CIImage,
    hdrImage: CIImage,
    outputURL: URL,
    colorSpace: CGColorSpace,
    gainMapKind: GainMapKind
) throws {
    let context = CIContext(options: nil)
    let options = adaptiveHDROptions(hdrImage: hdrImage, gainMapKind: gainMapKind)

    try context.writeJPEGRepresentation(
        of: sdrImage,
        to: outputURL,
        colorSpace: colorSpace,
        options: options
    )
}

@main
struct Akari {
    static func main() throws {
        let config = try parseArgs()

        guard #available(macOS 15.0, *) else {
            throw AppError.unsupportedOSVersion
        }

        let outputColorSpace = try makeColorSpace(named: config.colorSpaceName)

        let sdrImage = try loadCIImage(from: config.sdrURL)
        let hdrImageRaw = try loadCIImage(from: config.hdrURL)
        let hdrImage = resizeIfNeeded(source: hdrImageRaw, to: sdrImage)

        guard ensureSameExtent(sdrImage, hdrImage) else {
            fatalError("SDR and HDR images still do not match in size after attempted resize.")
        }

        try createOutputDirectoryIfNeeded(for: config.outputURL)

        if FileManager.default.fileExists(atPath: config.outputURL.path) {
            try FileManager.default.removeItem(at: config.outputURL)
        }

        switch config.outputKind {
        case .heif:
            try writeAdaptiveHDRHEIF(
                sdrImage: sdrImage,
                hdrImage: hdrImage,
                outputURL: config.outputURL,
                colorSpace: outputColorSpace,
                gainMapKind: config.gainMapKind
            )
            print("Wrote Adaptive HDR HEIF:")
        case .jpeg:
            try writeAdaptiveHDRJPEG(
                sdrImage: sdrImage,
                hdrImage: hdrImage,
                outputURL: config.outputURL,
                colorSpace: outputColorSpace,
                gainMapKind: config.gainMapKind
            )
            print("Wrote Adaptive HDR JPEG:")
        }

        print(config.outputURL.path)
        print("")
        print("SDR extent: \(sdrImage.extent.integral)")
        print("HDR extent: \(hdrImage.extent.integral)")
        print("Output color space: \(config.colorSpaceName)")
        print("Output kind: \(config.outputKind.rawValue)")
        print("Gain map kind: \(config.gainMapKind.rawValue)")
    }
}
