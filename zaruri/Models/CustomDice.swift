//
//  CustomDice.swift
//  zaruri
//

import UIKit
import SwiftUI

/// Configuration for a user-defined custom die.
/// Supports any polygon shape (d4-d20), custom color, and optional per-face labels.
struct CustomDiceConfig: Codable, Equatable {

    /// The geometric shape (d4-d20; d2/d3 not supported for per-face labels).
    var geometryType: DiceType

    /// Die color encoded as "#RRGGBB".
    var colorHex: String

    /// When true each face shows the corresponding entry in `faceLabels`.
    /// When false faces show the standard numbers 1…geometryType.maxValue.
    var useCustomLabels: Bool

    /// One label per face. Count must equal `geometryType.maxValue`.
    var faceLabels: [String]

    /// User-visible name shown in Settings.
    var name: String

    /// Default numeric-label config for the given geometry.
    init(geometryType: DiceType = .d6, colorHex: String = "#3A7BFF") {
        self.geometryType = geometryType
        self.colorHex = colorHex
        self.useCustomLabels = false
        self.faceLabels = (1...geometryType.maxValue).map { "\($0)" }
        self.name = "Custom \(geometryType.displayName)"
    }

    /// The UIColor derived from `colorHex`, or a default blue on parse failure.
    var uiColor: UIColor {
        UIColor(hexString: colorHex) ?? UIColor(red: 0.23, green: 0.48, blue: 1.0, alpha: 1)
    }

    var color: Color { Color(uiColor) }

    /// Effective labels: custom text if enabled and correctly sized, otherwise numbers.
    var resolvedLabels: [String] {
        guard useCustomLabels && faceLabels.count == geometryType.maxValue else {
            return (1...geometryType.maxValue).map { "\($0)" }
        }
        return faceLabels
    }
}

// MARK: - UIColor Hex Helpers

extension UIColor {

    /// Parses "#RRGGBB" or "#RRGGBBAA" strings.
    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex = String(hex.dropFirst()) }
        guard hex.count == 6 || hex.count == 8,
              let value = UInt64(hex, radix: 16) else { return nil }
        let r, g, b, a: CGFloat
        if hex.count == 6 {
            r = CGFloat((value >> 16) & 0xFF) / 255
            g = CGFloat((value >>  8) & 0xFF) / 255
            b = CGFloat( value        & 0xFF) / 255
            a = 1
        } else {
            r = CGFloat((value >> 24) & 0xFF) / 255
            g = CGFloat((value >> 16) & 0xFF) / 255
            b = CGFloat((value >>  8) & 0xFF) / 255
            a = CGFloat( value        & 0xFF) / 255
        }
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    /// Returns a "#RRGGBB" hex string.
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
