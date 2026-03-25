//
//  DiceTextureGenerator.swift
//  zaruri
//

import UIKit
import RealityKit

/// Generates TextureResource objects for dice face labels or from asset images.
/// Uses 256×256 textures with a flat single-colour background (no gloss/shade effects)
/// for generated labels.
enum DiceTextureGenerator {

    private static var cache: [String: TextureResource] = [:]

    /// Returns a 256×256 TextureResource with `text` centred on `baseColor` background.
    /// Text colour is chosen automatically for contrast (black on light backgrounds, white otherwise).
    /// Pass `compact: true` for dice with small faces (e.g. d20) where a smaller font fits better.
    static func texture(text: String, baseColor: UIColor, compact: Bool = false) throws -> TextureResource {
        let key = "std|\(text)|\(baseColor.cgColor)|\(compact ? "c" : "n")"
        if let cached = cache[key] { return cached }

        let s: CGFloat = 256
        let size = CGSize(width: s, height: s)
        let renderer = UIGraphicsImageRenderer(size: size)

        let uiImage = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

            // Flat single-colour background
            baseColor.setFill()
            // Mai multă margine și colțuri puțin mai strânse, ca numerele să nu fie tăiate.
            UIBezierPath(roundedRect: rect.insetBy(dx: 12, dy: 12), cornerRadius: 30).fill()

            // Centred label — compact mode folosește font mai mic pentru fețele înguste (d10/d20).
            let isShort = text.count <= 2
            let fontSize: CGFloat = isShort ? (compact ? 100 : 138) : (text.count <= 4 ? 92 : 66)
            let font = UIFont.systemFont(ofSize: fontSize, weight: .black)
            let textColor: UIColor = isLight(color: baseColor) ? .black : .white
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]

            let nsText = text as NSString
            let textSize = nsText.size(withAttributes: attrs)
            let cx = (s - textSize.width) / 2
            let cy = (s - textSize.height) / 2
            nsText.draw(at: CGPoint(x: cx, y: cy), withAttributes: attrs)

            // Underline for 6 and 9 to distinguish them
            if text == "6" || text == "9" {
                let lineY = cy + textSize.height + 6
                let margin: CGFloat = 12
                textColor.setStroke()
                let line = UIBezierPath()
                line.move(to: CGPoint(x: cx - margin, y: lineY))
                line.addLine(to: CGPoint(x: cx + textSize.width + margin, y: lineY))
                line.lineWidth = 8
                line.stroke()
            }
        }

        guard let cgImage = uiImage.cgImage else { throw TextureError.cgImageFailed }
        let resource = try TextureResource(image: cgImage, options: .init(semantic: .color))
        cache[key] = resource
        return resource
    }

    /// Generates a 256×256 TextureResource for a standard d6 face using pips instead of numbers.
    /// Used to render classic casino-style dice. Pip colour is chosen for contrast.
    static func texturePips(number: Int, baseColor: UIColor) throws -> TextureResource {
        let key = "pips|\(number)|\(baseColor.cgColor)"
        if let cached = cache[key] { return cached }

        let s: CGFloat = 256
        let size = CGSize(width: s, height: s)
        let renderer = UIGraphicsImageRenderer(size: size)
        let pipColor: UIColor = isLight(color: baseColor) ? .black : .white

        let uiImage = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)

            // Flat rounded-rect background.
            baseColor.setFill()
            UIBezierPath(roundedRect: rect.insetBy(dx: 12, dy: 12), cornerRadius: 30).fill()

            let dotRadius: CGFloat = 22
            let spacing: CGFloat = 64
            let center = CGPoint(x: rect.midX, y: rect.midY)

            func drawDot(at point: CGPoint) {
                let dotRect = CGRect(
                    x: point.x - dotRadius,
                    y: point.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                )
                pipColor.setFill()
                UIBezierPath(ovalIn: dotRect).fill()
            }

            switch number {
            case 1:
                drawDot(at: center)
            case 2:
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y - spacing))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y + spacing))
            case 3:
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y - spacing))
                drawDot(at: center)
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y + spacing))
            case 4:
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y - spacing))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y - spacing))
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y + spacing))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y + spacing))
            case 5:
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y - spacing))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y - spacing))
                drawDot(at: center)
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y + spacing))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y + spacing))
            case 6:
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y - spacing))
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y))
                drawDot(at: CGPoint(x: center.x - spacing, y: center.y + spacing))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y - spacing))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y))
                drawDot(at: CGPoint(x: center.x + spacing, y: center.y + spacing))
            default:
                break
            }
        }

        guard let cgImage = uiImage.cgImage else { throw TextureError.cgImageFailed }
        let resource = try TextureResource(image: cgImage, options: .init(semantic: .color))
        cache[key] = resource
        return resource
    }

    /// Returns a TextureResource created directly from a named UIImage asset.
    /// The original image resolution is preserved.
    static func textureFromAsset(named name: String) throws -> TextureResource {
        let key = "asset|\(name)"
        if let cached = cache[key] { return cached }

        guard let image = UIImage(named: name) else {
            throw TextureError.cgImageFailed
        }
        guard let cgImage = image.cgImage else {
            throw TextureError.cgImageFailed
        }
        let resource = try TextureResource(image: cgImage, options: .init(semantic: .color))
        cache[key] = resource
        return resource
    }

    /// Convenience for numeric faces.
    static func texture(number: Int, baseColor: UIColor, compact: Bool = false) throws -> TextureResource {
        return try texture(text: "\(number)", baseColor: baseColor, compact: compact)
    }

    // MARK: - Helpers

    /// Simple perceived-lightness check to pick a contrasting foreground colour.
    private static func isLight(color: UIColor) -> Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.65
    }

    static func clearCache() { cache.removeAll() }

    enum TextureError: Error { case cgImageFailed }
}
