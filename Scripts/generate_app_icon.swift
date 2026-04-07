import AppKit
import Foundation

let fileManager = FileManager.default
let assetCatalogDirectory = URL(
    fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "UsageMonitorApp/Assets.xcassets/AppIcon.appiconset",
    isDirectory: true
)
let repositoryRoot = URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
let sourceIconURL = repositoryRoot.appendingPathComponent("icon.png")
let appRootDirectory = assetCatalogDirectory.deletingLastPathComponent().deletingLastPathComponent()
let standaloneIconURL = appRootDirectory.appendingPathComponent("AppIcon.icns")

let iconDefinitions: [(filename: String, points: Int, scale: Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

guard let sourceImage = NSImage(contentsOf: sourceIconURL) else {
    throw NSError(
        domain: "UsageMonitorIconGeneration",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Missing source icon at \(sourceIconURL.path)"]
    )
}

try fileManager.createDirectory(at: assetCatalogDirectory, withIntermediateDirectories: true)

let temporaryIconsetDirectory = fileManager.temporaryDirectory
    .appendingPathComponent("UsageMonitorApp-\(UUID().uuidString).iconset", isDirectory: true)
try fileManager.createDirectory(at: temporaryIconsetDirectory, withIntermediateDirectories: true)

for definition in iconDefinitions {
    let pixelSize = definition.points * definition.scale
    let pngData = try renderPNG(from: sourceImage, pixelSize: pixelSize)
    try pngData.write(to: assetCatalogDirectory.appendingPathComponent(definition.filename), options: .atomic)
    try pngData.write(
        to: temporaryIconsetDirectory.appendingPathComponent(iconsetFileName(points: definition.points, scale: definition.scale)),
        options: .atomic
    )
}

try buildStandaloneIcon(from: temporaryIconsetDirectory, to: standaloneIconURL)
try? fileManager.removeItem(at: temporaryIconsetDirectory)

func renderPNG(from sourceImage: NSImage, pixelSize: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(
            domain: "UsageMonitorIconGeneration",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Failed to allocate bitmap context."]
        )
    }

    bitmap.size = NSSize(width: pixelSize, height: pixelSize)

    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(
            domain: "UsageMonitorIconGeneration",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "Failed to create graphics context."]
        )
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let canvasRect = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    NSColor.clear.setFill()
    canvasRect.fill()

    let inset = CGFloat(pixelSize) * 0.04
    let targetRect = canvasRect.insetBy(dx: inset, dy: inset)
    let fittedRect = aspectFitRect(for: sourceImage.size, in: targetRect)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.12)
    shadow.shadowBlurRadius = CGFloat(pixelSize) * 0.05
    shadow.shadowOffset = NSSize(width: 0, height: -CGFloat(pixelSize) * 0.01)
    shadow.set()

    sourceImage.draw(
        in: fittedRect,
        from: CGRect(origin: .zero, size: sourceImage.size),
        operation: .sourceOver,
        fraction: 1
    )

    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(
            domain: "UsageMonitorIconGeneration",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG output."]
        )
    }

    return pngData
}

func aspectFitRect(for sourceSize: NSSize, in targetRect: CGRect) -> CGRect {
    guard sourceSize.width > 0, sourceSize.height > 0 else { return targetRect }
    let widthRatio = targetRect.width / sourceSize.width
    let heightRatio = targetRect.height / sourceSize.height
    let scale = min(widthRatio, heightRatio)
    let scaledSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
    return CGRect(
        x: targetRect.midX - scaledSize.width / 2,
        y: targetRect.midY - scaledSize.height / 2,
        width: scaledSize.width,
        height: scaledSize.height
    )
}

func iconsetFileName(points: Int, scale: Int) -> String {
    let suffix = scale == 2 ? "@2x" : ""
    return "icon_\(points)x\(points)\(suffix).png"
}

func buildStandaloneIcon(from iconsetDirectory: URL, to outputURL: URL) throws {
    try? fileManager.removeItem(at: outputURL)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = [
        "--convert", "icns",
        "--output", outputURL.path,
        iconsetDirectory.path
    ]

    let stderrPipe = Pipe()
    process.standardError = stderrPipe

    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown iconutil failure."
        throw NSError(
            domain: "UsageMonitorIconGeneration",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "Failed to generate standalone AppIcon.icns: \(errorMessage)"]
        )
    }
}
