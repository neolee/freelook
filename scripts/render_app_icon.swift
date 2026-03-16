import AppKit

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let masterURL = outputDirectory.appendingPathComponent("appicon_1024.png")

let masterSize = CGSize(width: 1024, height: 1024)
let canvas = CGRect(origin: .zero, size: masterSize)

func color(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    NSColor(
        calibratedRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
        green: CGFloat((hex >> 8) & 0xFF) / 255.0,
        blue: CGFloat(hex & 0xFF) / 255.0,
        alpha: alpha
    )
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(masterSize.width),
    pixelsHigh: Int(masterSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Unable to create bitmap representation.")
}

bitmap.size = NSSize(width: masterSize.width, height: masterSize.height)

guard let graphicsContext = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to create graphics context.")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = graphicsContext

let context = graphicsContext.cgContext

context.setShouldAntialias(true)
context.clear(canvas)

let tileRect = canvas.insetBy(dx: 56, dy: 56)
let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: 228, yRadius: 228)

context.saveGState()
let tileShadow = NSShadow()
tileShadow.shadowColor = color(0x1A2230, alpha: 0.18)
tileShadow.shadowBlurRadius = 54
tileShadow.shadowOffset = NSSize(width: 0, height: -24)
tileShadow.set()
color(0xE7EEE8).setFill()
tilePath.fill()
context.restoreGState()

context.saveGState()
tilePath.addClip()
NSGradient(colors: [color(0xF7F1E8), color(0xDFEBE4)])?.draw(in: tilePath, angle: -90)

let glowRect = tileRect.insetBy(dx: -120, dy: -180).offsetBy(dx: -24, dy: 120)
NSGradient(colors: [
    color(0xFFFFFF, alpha: 0.34),
    color(0xFFFFFF, alpha: 0.0)
])?.draw(in: NSBezierPath(ovalIn: glowRect), relativeCenterPosition: .zero)
context.restoreGState()

color(0xFFFFFF, alpha: 0.5).setStroke()
tilePath.lineWidth = 6
tilePath.stroke()

let pageRect = CGRect(x: 266, y: 176, width: 492, height: 672)
let pagePath = NSBezierPath(roundedRect: pageRect, xRadius: 92, yRadius: 92)

context.saveGState()
let pageShadow = NSShadow()
pageShadow.shadowColor = color(0x243240, alpha: 0.16)
pageShadow.shadowBlurRadius = 34
pageShadow.shadowOffset = NSSize(width: 0, height: -18)
pageShadow.set()
color(0xFFFDF9).setFill()
pagePath.fill()
context.restoreGState()

color(0xDDE4E6).setStroke()
pagePath.lineWidth = 4
pagePath.stroke()

let foldPath = NSBezierPath()
foldPath.move(to: CGPoint(x: 610, y: 848))
foldPath.line(to: CGPoint(x: 758, y: 848))
foldPath.line(to: CGPoint(x: 758, y: 694))
foldPath.close()
color(0xE7F0F5).setFill()
foldPath.fill()

let foldDivider = NSBezierPath()
foldDivider.move(to: CGPoint(x: 616, y: 848))
foldDivider.line(to: CGPoint(x: 758, y: 706))
color(0xD0DAE0).setStroke()
foldDivider.lineWidth = 4
foldDivider.lineCapStyle = .round
foldDivider.stroke()

let accentLine = NSBezierPath(roundedRect: CGRect(x: 330, y: 748, width: 208, height: 28), xRadius: 14, yRadius: 14)
color(0x2E6CF6).setFill()
accentLine.fill()

let secondaryLine = NSBezierPath(roundedRect: CGRect(x: 330, y: 694, width: 140, height: 24), xRadius: 12, yRadius: 12)
color(0x24B77F).setFill()
secondaryLine.fill()

let tertiaryLine = NSBezierPath(roundedRect: CGRect(x: 330, y: 646, width: 176, height: 24), xRadius: 12, yRadius: 12)
color(0xD9822B).setFill()
tertiaryLine.fill()

let bracketFont = NSFont(name: "Menlo-Bold", size: 208) ?? NSFont.monospacedSystemFont(ofSize: 208, weight: .bold)
let slashFont = NSFont(name: "Menlo-Bold", size: 224) ?? NSFont.monospacedSystemFont(ofSize: 224, weight: .bold)

let leftAttributes: [NSAttributedString.Key: Any] = [
    .font: bracketFont,
    .foregroundColor: color(0x233447)
]
let rightAttributes: [NSAttributedString.Key: Any] = [
    .font: bracketFont,
    .foregroundColor: color(0x233447)
]
let slashAttributes: [NSAttributedString.Key: Any] = [
    .font: slashFont,
    .foregroundColor: color(0x2E6CF6)
]

NSAttributedString(string: "<", attributes: leftAttributes).draw(at: CGPoint(x: 334, y: 352))
NSAttributedString(string: "/", attributes: slashAttributes).draw(at: CGPoint(x: 468, y: 336))
NSAttributedString(string: ">", attributes: rightAttributes).draw(at: CGPoint(x: 614, y: 352))

let bottomLine = NSBezierPath(roundedRect: CGRect(x: 330, y: 252, width: 248, height: 26), xRadius: 13, yRadius: 13)
color(0xC8D2D8).setFill()
bottomLine.fill()

NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode PNG.")
}

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
try data.write(to: masterURL)
