import AppKit

/// The app's artwork, drawn in code so it stays crisp at any size: a faceless porter in a plum
/// uniform and tilted cap, on a terracotta squircle. `assets/brand/porter-app-icon.svg` (256 grid)
/// and `assets/brand/porter-menubar.svg` (180 grid) are the sources this geometry mirrors.
enum Icon {
    private static let badgeCenter = CGPoint(x: 15.2, y: 2.8)
    private static let badgeRadius: CGFloat = 2.5

    // MARK: - Menu bar

    /// Template image for the status item; `badge` adds a dot for sessions stopped by a limit,
    /// `busy` dims the figure while a move runs.
    static func menuBar(badge: Bool, busy: Bool = false) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: true) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            drawMenuBar(in: ctx, badge: badge, alpha: busy ? 0.4 : 1)
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Porter for Claude Desktop"
        return image
    }

    /// The silhouette on the 18-point grid, in a flipped (top-left origin) context. Shapes are
    /// filled even-odd, so where the cap overlaps the head a thin gap separates them.
    private static func drawMenuBar(in ctx: CGContext, badge: Bool, alpha: CGFloat) {
        ctx.saveGState()
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        ctx.saveGState()
        ctx.setAlpha(alpha)
        ctx.scaleBy(x: 0.1, y: 0.1)
        let path = CGMutablePath()
        // Shoulders with a V-neck cut.
        path.move(to: CGPoint(x: 18, y: 180))
        path.addLine(to: CGPoint(x: 18, y: 158))
        path.addQuadCurve(to: CGPoint(x: 52, y: 127), control: CGPoint(x: 18, y: 132))
        path.addLine(to: CGPoint(x: 74, y: 124))
        path.addLine(to: CGPoint(x: 90, y: 150))
        path.addLine(to: CGPoint(x: 106, y: 124))
        path.addLine(to: CGPoint(x: 128, y: 127))
        path.addQuadCurve(to: CGPoint(x: 162, y: 158), control: CGPoint(x: 162, y: 132))
        path.addLine(to: CGPoint(x: 162, y: 180))
        path.closeSubpath()
        // Head.
        path.addEllipse(in: CGRect(x: 63, y: 59, width: 54, height: 54))
        // Cap, tilted.
        let tilt = rotation(-8, around: CGPoint(x: 90, y: 52))
        let crown = CGMutablePath()
        crown.move(to: CGPoint(x: 68, y: 40))
        crown.addQuadCurve(to: CGPoint(x: 80, y: 28), control: CGPoint(x: 68, y: 28))
        crown.addLine(to: CGPoint(x: 100, y: 28))
        crown.addQuadCurve(to: CGPoint(x: 112, y: 40), control: CGPoint(x: 112, y: 28))
        crown.addLine(to: CGPoint(x: 115, y: 56))
        crown.addLine(to: CGPoint(x: 65, y: 56))
        crown.closeSubpath()
        path.addPath(crown, transform: tilt)
        path.addPath(CGPath(roundedRect: CGRect(x: 58, y: 58, width: 64, height: 11), cornerWidth: 5.5, cornerHeight: 5.5,
                            transform: nil), transform: tilt)
        ctx.addPath(path)
        ctx.setFillColor(.black)
        ctx.fillPath(using: .evenOdd)
        ctx.restoreGState()

        // Badge: a dot in the free top-right corner, separated from the cap by a clear ring.
        if badge {
            ctx.setBlendMode(.clear)
            ctx.fillEllipse(in: circle(badgeCenter, badgeRadius + 1.3))
            ctx.setBlendMode(.normal)
            ctx.setFillColor(.black)
            ctx.fillEllipse(in: circle(badgeCenter, badgeRadius))
        }
        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }

    // MARK: - App icon

    /// The Finder/Dock icon, on the macOS icon grid (an 824-point body centred in 1024), drawn in
    /// a y-up context such as a bitmap or an NSImage.
    static func drawAppIcon(in ctx: CGContext, size: CGFloat) {
        // The artwork's squircle spans 16…240 of its 256 grid; fit it to the body and flip to y-down.
        let k = size * 824 / 1024 / 224
        ctx.saveGState()
        ctx.translateBy(x: 0, y: size)
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: size * 100 / 1024 - 16 * k, y: size * 100 / 1024 - 16 * k)
        ctx.scaleBy(x: k, y: k)
        drawArtwork(in: ctx)
        ctx.restoreGState()
    }

    /// `porter-app-icon.svg`, element by element, on its 256 grid in a y-down context.
    private static func drawArtwork(in ctx: CGContext) {
        let squircle = CGPath(roundedRect: CGRect(x: 16, y: 16, width: 224, height: 224), cornerWidth: 52, cornerHeight: 52,
                              transform: nil)

        // Background, with a soft shadow under it like other Dock icons.
        ctx.saveGState()
        // Shadow offset and blur are in device space, untouched by the flip and scale above:
        // scale them by hand and point the offset down on the y-up device.
        let scale = abs(ctx.ctm.d)
        ctx.setShadow(offset: CGSize(width: 0, height: -3 * scale), blur: 7 * scale, color: CGColor(gray: 0, alpha: 0.28))
        ctx.addPath(squircle)
        ctx.setFillColor(hex(0xC85E3B))
        ctx.fillPath()
        ctx.restoreGState()
        fill(ctx, squircle, gradient: [hex(0xE8906A), hex(0xC85E3B)], from: 16, to: 240)

        // Uniform, shirt, lapels and button, clipped to the squircle.
        ctx.saveGState()
        ctx.addPath(squircle)
        ctx.clip()
        let uniform = CGMutablePath()
        uniform.move(to: CGPoint(x: 40, y: 256))
        uniform.addLine(to: CGPoint(x: 40, y: 224))
        uniform.addQuadCurve(to: CGPoint(x: 82, y: 181), control: CGPoint(x: 40, y: 188))
        uniform.addLine(to: CGPoint(x: 111, y: 177))
        uniform.addLine(to: CGPoint(x: 145, y: 177))
        uniform.addLine(to: CGPoint(x: 174, y: 181))
        uniform.addQuadCurve(to: CGPoint(x: 216, y: 224), control: CGPoint(x: 216, y: 188))
        uniform.addLine(to: CGPoint(x: 216, y: 256))
        uniform.closeSubpath()
        fill(ctx, uniform, gradient: [hex(0x433053), hex(0x2F2039)], from: 177, to: 256)
        fill(ctx, polygon([(111, 177), (128, 212), (145, 177)]), hex(0xFFF4EA))
        fill(ctx, polygon([(111, 177), (96, 183), (119, 226), (128, 212)]), hex(0x57406B))
        fill(ctx, polygon([(145, 177), (160, 183), (137, 226), (128, 212)]), hex(0x57406B))
        ctx.setFillColor(hex(0xE8B866))
        ctx.fillEllipse(in: CGRect(x: 123.5, y: 233.5, width: 9, height: 9))
        ctx.restoreGState()

        // Neck, with the shadow the head casts on it.
        let neck = CGMutablePath()
        neck.move(to: CGPoint(x: 115, y: 148))
        neck.addLine(to: CGPoint(x: 141, y: 148))
        neck.addLine(to: CGPoint(x: 141, y: 172))
        neck.addQuadCurve(to: CGPoint(x: 128, y: 182), control: CGPoint(x: 141, y: 180))
        neck.addQuadCurve(to: CGPoint(x: 115, y: 172), control: CGPoint(x: 115, y: 180))
        neck.closeSubpath()
        fill(ctx, neck, hex(0xF2D3C0))
        let shade = CGMutablePath()
        shade.move(to: CGPoint(x: 115, y: 152))
        shade.addLine(to: CGPoint(x: 141, y: 152))
        shade.addLine(to: CGPoint(x: 141, y: 162))
        shade.addQuadCurve(to: CGPoint(x: 115, y: 162), control: CGPoint(x: 128, y: 170))
        shade.closeSubpath()
        fill(ctx, shade, hex(0xE2B9A3))

        // Head.
        ctx.setFillColor(hex(0xFFF4EA))
        ctx.fillEllipse(in: CGRect(x: 95, y: 93, width: 66, height: 66))

        // Cap, tilted: crown with a highlight, brass band, brim.
        ctx.saveGState()
        ctx.concatenate(rotation(-8, around: CGPoint(x: 128, y: 98)))
        let crown = CGMutablePath()
        crown.move(to: CGPoint(x: 102, y: 84))
        crown.addQuadCurve(to: CGPoint(x: 114, y: 72), control: CGPoint(x: 102, y: 72))
        crown.addLine(to: CGPoint(x: 142, y: 72))
        crown.addQuadCurve(to: CGPoint(x: 154, y: 84), control: CGPoint(x: 154, y: 72))
        crown.addLine(to: CGPoint(x: 157, y: 104))
        crown.addLine(to: CGPoint(x: 99, y: 104))
        crown.closeSubpath()
        fill(ctx, crown, gradient: [hex(0x4E3560), hex(0x382643)], from: 72, to: 104)
        let shine = CGMutablePath()
        shine.move(to: CGPoint(x: 106, y: 80))
        shine.addQuadCurve(to: CGPoint(x: 112, y: 76), control: CGPoint(x: 107, y: 76))
        shine.addLine(to: CGPoint(x: 128, y: 76))
        ctx.addPath(shine)
        ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.25))
        ctx.setLineWidth(3)
        ctx.setLineCap(.round)
        ctx.strokePath()
        fill(ctx, CGPath(roundedRect: CGRect(x: 100, y: 92, width: 56, height: 5), cornerWidth: 2.5, cornerHeight: 2.5,
                         transform: nil), hex(0xE8B866))
        fill(ctx, CGPath(roundedRect: CGRect(x: 93, y: 101, width: 70, height: 10), cornerWidth: 5, cornerHeight: 5,
                         transform: nil), hex(0x2A1C33))
        ctx.restoreGState()

        // Pin: brass rim, cream face, generic six-ray asterisk.
        ctx.setFillColor(hex(0xE8B866))
        ctx.fillEllipse(in: CGRect(x: 152.5, y: 193.5, width: 29, height: 29))
        ctx.setFillColor(hex(0xFFF4EA))
        ctx.fillEllipse(in: CGRect(x: 155, y: 196, width: 24, height: 24))
        ctx.setStrokeColor(hex(0xD97757))
        ctx.setLineWidth(3.4)
        ctx.setLineCap(.round)
        for i in 0..<6 {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / 3
            ctx.move(to: CGPoint(x: 167, y: 208))
            ctx.addLine(to: CGPoint(x: 167 + cos(angle) * 7.5, y: 208 + sin(angle) * 7.5))
        }
        ctx.strokePath()

        // A thread of light along the top edge.
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: CGRect(x: 17, y: 17, width: 222, height: 222), cornerWidth: 51, cornerHeight: 51,
                           transform: nil))
        ctx.setLineWidth(2)
        ctx.replacePathWithStrokedPath()
        ctx.clip()
        if let edge = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                 colors: [CGColor(gray: 1, alpha: 0.45), CGColor(gray: 1, alpha: 0)] as CFArray,
                                 locations: [0, 1]) {
            ctx.drawLinearGradient(edge, start: CGPoint(x: 0, y: 17), end: CGPoint(x: 0, y: 128), options: [])
        }
        ctx.restoreGState()
    }

    /// The app icon as an image, for the app's own windows (the bundle icon is missing when run unbundled).
    static func appImage(size: CGFloat) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            drawAppIcon(in: ctx, size: size)
            return true
        }
    }

    /// Writes the PNG sizes an .iconset needs (`iconutil -c icns` turns the folder into an .icns).
    static func writeIconset(to folder: String) throws {
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
        for base in [16, 32, 128, 256, 512] {
            for factor in [1, 2] {
                let px = base * factor
                guard let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { continue }
                drawAppIcon(in: ctx, size: CGFloat(px))
                guard let image = ctx.makeImage(),
                      let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { continue }
                let name = factor == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
                try png.write(to: URL(fileURLWithPath: "\(folder)/\(name)"))
            }
        }
    }

    // MARK: - Helpers

    private static func circle(_ c: CGPoint, _ r: CGFloat) -> CGRect {
        CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
    }

    private static func hex(_ value: UInt32) -> CGColor {
        CGColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }

    private static func rotation(_ degrees: CGFloat, around p: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: p.x, y: p.y).rotated(by: degrees * .pi / 180).translatedBy(x: -p.x, y: -p.y)
    }

    private static func polygon(_ points: [(CGFloat, CGFloat)]) -> CGPath {
        let path = CGMutablePath()
        path.addLines(between: points.map { CGPoint(x: $0.0, y: $0.1) })
        path.closeSubpath()
        return path
    }

    private static func fill(_ ctx: CGContext, _ path: CGPath, _ color: CGColor) {
        ctx.addPath(path)
        ctx.setFillColor(color)
        ctx.fillPath()
    }

    /// Fills `path` with a vertical gradient running from y `from` to y `to`.
    private static func fill(_ ctx: CGContext, _ path: CGPath, gradient colors: [CGColor], from: CGFloat, to: CGFloat) {
        guard let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                                        colors: colors as CFArray, locations: [0, 1]) else { return }
        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: from), end: CGPoint(x: 0, y: to), options: [])
        ctx.restoreGState()
    }
}
