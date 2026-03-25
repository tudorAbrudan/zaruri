//
//  DiceMaterialProvider.swift
//  zaruri
//

import RealityKit
import UIKit

/// Provides PBR materials for each DiceType.
/// `materials(for:)` returns one material per face with a number texture.
/// `material(for:)` returns a single solid-colour material for d3.
/// d2 uses 3 materials: [rim, topCap("1"), bottomCap("2")].
enum DiceMaterialProvider {

    // Per-type cache so textures are generated only once.
    private static var cache: [DiceType: [any Material]] = [:]

    /// Returns an array of materials with face-number textures.
    /// For d2: [rim, topCap, bottomCap]  (3 materials matching coinMesh slot order).
    /// For d4: uses corner-layout textures.
    /// Index i → face showing number (i+1) for all other types.
    /// - Parameter baseColorOverride: when provided, all numeric faces are generated using
    ///   this colour instead of the type's default. When nil, the colour comes from
    ///   `baseColor(for:)` and results are cached per-dice-type.
    static func materials(for type: DiceType, baseColorOverride: UIColor? = nil) -> [any Material] {
        if baseColorOverride == nil, let cached = cache[type] { return cached }

        let result: [any Material]
        switch type {
        case .d2:
            result = d2Materials(baseColorOverride: baseColorOverride)
        case .d3:
            result = d3Materials(baseColorOverride: baseColorOverride)
        case .d4:
            result = d4Materials(baseColorOverride: baseColorOverride)
        case .d6:
            // Standard d6 uses pips instead of numbers so it looks like a classic dice.
            let base = baseColorOverride ?? baseColor(for: .d6)
            result = (1...6).map { number in
                guard let texture = try? DiceTextureGenerator.texturePips(number: number, baseColor: base) else {
                    return fallback(color: base)
                }
                return faceMaterial(texture: texture)
            }
        default:
            let base = baseColorOverride ?? baseColor(for: type)
            // d10 și d20 folosesc texturi „compacte” (font mai mic, margini mai mari)
            // ca numerele să nu fie tăiate pe fețele triunghiulare înguste.
            let compact = (type == .d20 || type == .d10)
            result = (1...type.maxValue).map { number in
                guard let texture = try? DiceTextureGenerator.texture(number: number, baseColor: base, compact: compact) else {
                    return fallback(color: base)
                }
                return faceMaterial(texture: texture)
            }
        }
        if baseColorOverride == nil {
            cache[type] = result
        }
        return result
    }

    /// Single solid-colour material for d3.
    static func material(for type: DiceType) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: baseColor(for: type))
        mat.roughness = .init(floatLiteral: 0.30)
        mat.metallic = .init(floatLiteral: 0.05)
        return mat
    }

    /// Returns per-face materials using custom labels and a custom base color.
    static func customMaterials(labels: [String], baseColor: UIColor, type: DiceType) -> [any Material] {
        return labels.map { label in
            guard let texture = try? DiceTextureGenerator.texture(text: label, baseColor: baseColor) else {
                return fallback(color: baseColor)
            }
            return faceMaterial(texture: texture)
        }
    }

    static func clearCache() {
        cache.removeAll()
    }

    // MARK: - Private

    /// d4 tetrahedron: 4 materials — one per face, each showing the face value centred.
    /// Material index i → face that displays value (i+1), same convention as all other dice.
    private static func d4Materials(baseColorOverride: UIColor? = nil) -> [any Material] {
        let base = baseColorOverride ?? baseColor(for: .d4)
        return (1...4).map { number in
            guard let texture = try? DiceTextureGenerator.texture(number: number, baseColor: base) else {
                return fallback(color: base)
            }
            return faceMaterial(texture: texture)
        }
    }

    /// d2 numeric coin: 3 materials — slot 0 = rim, slot 1 = top cap "1", slot 2 = bottom cap "2".
    private static func d2Materials(baseColorOverride: UIColor? = nil) -> [any Material] {
        let base = baseColorOverride ?? baseColor(for: .d2)

        // Rim: slightly darker/more metallic to look like a coin edge
        var rim = PhysicallyBasedMaterial()
        rim.baseColor = .init(tint: base)
        rim.roughness = .init(floatLiteral: 0.45)
        rim.metallic  = .init(floatLiteral: 0.25)

        // Caps cu text numeric 1 / 2
        let top = (try? DiceTextureGenerator.texture(number: 1, baseColor: base)).map { faceMaterial(texture: $0) }
            ?? fallback(color: base)
        let bot = (try? DiceTextureGenerator.texture(number: 2, baseColor: base)).map { faceMaterial(texture: $0) }
            ?? fallback(color: base)

        return [rim, top, bot]
    }

    /// d2 „monedă 50 bani” — folosit doar în modul „Aruncă cu banul”.
    /// Slot 0 = rim, 1 = fața cu „50 BANI”, 2 = fața cu stema.
    static func coinMaterialsForD2() -> [any Material] {
        let base = baseColor(for: .d2)

        var rim = PhysicallyBasedMaterial()
        rim.baseColor = .init(tint: base)
        rim.roughness = .init(floatLiteral: 0.45)
        rim.metallic  = .init(floatLiteral: 0.25)

        let topTexture = try? DiceTextureGenerator.textureFromAsset(named: "romania-50-bani-2023-ban")
        let botTexture = try? DiceTextureGenerator.textureFromAsset(named: "romania-50-bani-2023-stema")

        let top: any Material = topTexture.map { faceMaterial(texture: $0) } ?? fallback(color: base)
        let bot: any Material = botTexture.map { faceMaterial(texture: $0) } ?? fallback(color: base)

        return [rim, top, bot]
    }

    /// d3 cube: 6 materials matching cubeMesh face order (top, front, right, left, back, bottom).
    /// Opposite faces share the same value: top/bottom=1, front/back=2, right/left=3.
    private static func d3Materials(baseColorOverride: UIColor? = nil) -> [any Material] {
        let base = baseColorOverride ?? baseColor(for: .d3)
        let faceValues = [1, 2, 3, 3, 2, 1]
        return faceValues.map { number in
            guard let texture = try? DiceTextureGenerator.texture(number: number, baseColor: base) else {
                return fallback(color: base)
            }
            return faceMaterial(texture: texture)
        }
    }

    private static func faceMaterial(texture: TextureResource) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(texture: .init(texture))
        mat.roughness = .init(floatLiteral: 0.25)
        mat.metallic  = .init(floatLiteral: 0.0)
        return mat
    }

    private static func fallback(color: UIColor) -> PhysicallyBasedMaterial {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: color)
        mat.roughness = .init(floatLiteral: 0.3)
        return mat
    }

    static func baseColor(for type: DiceType) -> UIColor {
        switch type {
        case .d2:  return UIColor(red: 0.75, green: 0.55, blue: 0.35, alpha: 1)  // Bronze
        case .d3:  return UIColor(red: 0.15, green: 0.65, blue: 0.60, alpha: 1)  // Teal
        case .d4:  return UIColor(red: 0.0,  green: 0.70, blue: 0.25, alpha: 1)  // Green
        // Darker navy for d6 so the white numerals pop even under strong lighting.
        case .d6:  return UIColor(red: 0.05, green: 0.20, blue: 0.55, alpha: 1)  // Navy blue
        case .d8:  return UIColor(red: 0.55, green: 0.0,  blue: 0.85, alpha: 1)  // Purple
        case .d10: return UIColor(red: 0.90, green: 0.20, blue: 0.40, alpha: 1)  // Crimson
        case .d12: return UIColor(red: 0.80, green: 0.0,  blue: 0.70, alpha: 1)  // Magenta
        case .d20: return UIColor(red: 0.95, green: 0.45, blue: 0.0,  alpha: 1)  // Orange
        }
    }
}
