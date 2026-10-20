// Draws the background of the disk image window: assets/dmg/background.tiff (1x and 2x).
// Run it again after changing it: swift scripts/dmg-background.swift
import AppKit

// 60 points taller than the content: room for the path and status bars, when Finder shows them.
let size = NSSize(width: 660, height: 460)
/// Where Finder shows the two icons (centres, from the top-left), as in scripts/dmg-settings.py.
let app = NSPoint(x: 180, y: 200), apps = NSPoint(x: 480, y: 200)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

func serif(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    return base.fontDescriptor.withDesign(.serif).flatMap { NSFont(descriptor: $0, size: size) } ?? base
}

func draw(scale: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width * scale), pixelsHigh: Int(size.height * scale),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = size
    NSGraphicsContext.saveGraphicsState()
    // Flipped, for a top-left origin like Finder's icon positions (and text drawn the right way up).
    NSGraphicsContext.current = NSGraphicsContext(cgContext: NSGraphicsContext(bitmapImageRep: rep)!.cgContext, flipped: true)
    let flip = NSAffineTransform()
    flip.translateX(by: 0, yBy: size.height)
    flip.scaleX(by: 1, yBy: -1)
    flip.concat()

    // A hotel lobby: striped wallpaper, a floor, and a red carpet the porter walks the app along.
    for i in stride(from: 0, to: Int(size.width), by: 22) {
        (i / 22 % 2 == 0 ? color(0xF5F0E8) : color(0xF1EADF)).setFill()
        NSRect(x: CGFloat(i), y: 0, width: 22, height: size.height).fill()
    }
    NSGradient(colors: [color(0xFFFDF9, 0.75), color(0xFFFDF9, 0)])!
        .draw(fromCenter: NSPoint(x: 330, y: 190), radius: 0, toCenter: NSPoint(x: 330, y: 190), radius: 320, options: [])
    // Brass picture rail along the top.
    color(0xE8B866, 0.55).setFill()
    NSRect(x: 0, y: 96, width: size.width, height: 1.5).fill()

    // The carpet, from the app to Applications.
    // Its ends go under the two icons, so it joins them; the names below stay on the floor.
    let carpet = NSRect(x: app.x + 30, y: app.y - 21, width: apps.x - app.x - 60, height: 42)
    let runner = NSBezierPath(roundedRect: carpet, xRadius: 6, yRadius: 6)
    NSGradient(colors: [color(0xC85E3B), color(0xB2502F)])!.draw(in: runner, angle: 90)
    color(0xE8B866).setStroke()
    for inset in [CGFloat(4)] {
        let edge = NSBezierPath(roundedRect: carpet.insetBy(dx: inset, dy: inset), xRadius: 4, yRadius: 4)
        edge.lineWidth = 1.5
        edge.stroke()
    }
    // Chevrons woven into it, pointing the way.
    let mid = carpet.midY
    for x in stride(from: app.x + 92, through: apps.x - 100, by: 24) {
        let chevron = NSBezierPath()
        chevron.move(to: NSPoint(x: x, y: mid - 8))
        chevron.line(to: NSPoint(x: x + 9, y: mid))
        chevron.line(to: NSPoint(x: x, y: mid + 8))
        chevron.lineWidth = 2.5
        chevron.lineCapStyle = .round
        chevron.lineJoinStyle = .round
        color(0xF6E4DA, 0.85).setStroke()
        chevron.stroke()
    }
    // Title and hint.
    func text(_ s: String, _ font: NSFont, _ c: NSColor, y: CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: c]
        let w = (s as NSString).size(withAttributes: attrs).width
        (s as NSString).draw(at: NSPoint(x: (size.width - w) / 2, y: y), withAttributes: attrs)
    }
    text("Porter for Claude Desktop", serif(26, .semibold), color(0x2B2522), y: 30)
    text("A T   Y O U R   S E R V I C E", NSFont.systemFont(ofSize: 10, weight: .semibold), color(0xA8875A), y: 68)
    text("Drag Porter onto Applications to check it in", NSFont.systemFont(ofSize: 13, weight: .medium), color(0x857A70), y: 340)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = "assets/dmg"
for (scale, name) in [(1.0, "background.png"), (2.0, "background@2x.png")] {
    try! draw(scale: scale).representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(out)/\(name)"))
}
let tiff = Process()
tiff.executableURL = URL(fileURLWithPath: "/usr/bin/tiffutil")
tiff.arguments = ["-cathidpicheck", "\(out)/background.png", "\(out)/background@2x.png", "-out", "\(out)/background.tiff"]
try! tiff.run()
tiff.waitUntilExit()
try? FileManager.default.removeItem(atPath: "\(out)/background.png")
try? FileManager.default.removeItem(atPath: "\(out)/background@2x.png")
print("Wrote \(out)/background.tiff")
