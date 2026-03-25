//
//  DiceEntity.swift
//  zaruri
//

import RealityKit
import UIKit
import simd

/// A RealityKit Entity representing a single physical die.
@MainActor
final class DiceEntity: Entity {

    let diceType: DiceType
    private let modelEntity: ModelEntity

    required init() {
        fatalError("Use init(diceType:) instead")
    }

    /// Creates a die entity.
    /// - Parameters:
    ///   - diceType: The geometry of the die.
    ///   - customLabels: When provided, these per-face labels are used instead of numbers.
    ///   - customColor: When provided, overrides the default color for this dice type.
    ///   - useCoinLookForD2: When true and `diceType == .d2`, uses the 50-bani coin textures.
    init(
        diceType: DiceType,
        customLabels: [String]? = nil,
        customColor: UIColor? = nil,
        baseColorOverride: UIColor? = nil,
        useCoinLookForD2: Bool = false
    ) throws {
        self.diceType = diceType
        let mesh = try DiceMeshProvider.mesh(for: diceType)

        let materials: [any Material]
        if let labels = customLabels {
            let color = customColor ?? baseColorOverride ?? DiceMaterialProvider.baseColor(for: diceType)
            materials = DiceMaterialProvider.customMaterials(labels: labels, baseColor: color, type: diceType)
        } else if diceType == .d2 && useCoinLookForD2 {
            materials = DiceMaterialProvider.coinMaterialsForD2()
        } else {
            materials = DiceMaterialProvider.materials(for: diceType, baseColorOverride: baseColorOverride)
        }

        self.modelEntity = ModelEntity(mesh: mesh, materials: materials)
        super.init()
        addChild(modelEntity)
        setupPhysics()
    }

    // MARK: - Roll

    /// Applies a random impulse — call once when a new roll begins.
    /// - Parameter force: multiplier (1.0 = normal, up to ~6.0 pentru aruncări foarte puternice).
    func applyRollImpulse(force: Float = 1.0) {
        // Permitem până la ~6× pentru aruncări foarte puternice,
        // dar ajustăm distribuția în funcție de tipul de zar.
        let f = min(max(force, 1.0), 6.0)
        var motion = components[PhysicsMotionComponent.self] ?? PhysicsMotionComponent()

        let calmFactor: Float = 0.8  // ~20% mai puțină agitație pentru toate zarurile

        if diceType == .d2 {
            // Pentru monedă: mai mult flip (rotație pe axele X/Z) și puțin mai mult „arc”.
            let baseAng: ClosedRange<Float> = -22...22
            motion.angularVelocity = SIMD3<Float>(
                Float.random(in: baseAng) * f * 1.4 * calmFactor,
                Float.random(in: -6...6) * calmFactor,
                Float.random(in: baseAng) * f * 1.4 * calmFactor
            )
            motion.linearVelocity = SIMD3<Float>(
                Float.random(in: -0.4...0.4) * f * calmFactor,
                Float.random(in: 1.8...3.0)  * f * calmFactor,
                Float.random(in: -0.2...0.2) * f * calmFactor
            )
        } else {
            motion.angularVelocity = SIMD3<Float>(
                Float.random(in: -14...14) * f * calmFactor,
                Float.random(in: -14...14) * f * calmFactor,
                Float.random(in: -14...14) * f * calmFactor
            )
            motion.linearVelocity = SIMD3<Float>(
                Float.random(in: -0.7...0.7) * f * calmFactor,
                Float.random(in: 1.6...2.6)  * f * calmFactor,
                Float.random(in: -0.2...0.2) * f * calmFactor
            )
        }
        components.set(motion)
    }

    /// Resets transform & motion before a new roll so dice that au zburat departe revin în zona vizibilă.
    func resetForNewRoll(to position: SIMD3<Float>, scale: Float) {
        self.position = position
        // Orientare aleatorie de start, ca să nu pară „lipite”.
        let axis = normalize(SIMD3<Float>(
            Float.random(in: -1...1),
            Float.random(in: -1...1),
            Float.random(in: -1...1)
        ))
        self.orientation = simd_quatf(angle: Float.random(in: 0...(2 * .pi)), axis: axis)
        self.scale = SIMD3(repeating: scale)
        // Resetăm complet vitezele fizice.
        components.set(PhysicsMotionComponent())
    }

    // MARK: - Physics-Determined Face Value

    /// Returns the value of the face currently pointing most directly upward (+Y world),
    /// determined from the entity's current orientation after physics has settled.
    func currentTopFaceValue() -> Int? {
        if diceType == .d3 { return d3TopFaceValue() }

        let worldUp = SIMD3<Float>(0, 1, 0)
        var bestDot: Float = -2
        var bestValue = 1

        for v in 1...diceType.maxValue {
            let localNormal = DiceFaceNormals.faceUpNormal(for: diceType, value: v)
            let worldNormal = orientation.act(localNormal)
            let dot = simd_dot(worldNormal, worldUp)
            if dot > bestDot {
                bestDot = dot
                bestValue = v
            }
        }
        return bestValue
    }

    /// d3 uses a cube with opposite faces sharing the same value (top/bottom=1, front/back=2, right/left=3).
    /// Must check all 6 face normals to correctly identify the top face.
    private func d3TopFaceValue() -> Int {
        let faceNormals: [(SIMD3<Float>, Int)] = [
            (SIMD3( 0,  1,  0), 1),  // top
            (SIMD3( 0,  0,  1), 2),  // front
            (SIMD3( 1,  0,  0), 3),  // right
            (SIMD3(-1,  0,  0), 3),  // left
            (SIMD3( 0,  0, -1), 2),  // back
            (SIMD3( 0, -1,  0), 1),  // bottom
        ]
        let worldUp = SIMD3<Float>(0, 1, 0)
        var bestDot: Float = -2
        var bestValue = 1
        for (localNormal, value) in faceNormals {
            let dot = simd_dot(orientation.act(localNormal), worldUp)
            if dot > bestDot { bestDot = dot; bestValue = value }
        }
        return bestValue
    }

    // MARK: - Physics Setup

    private func setupPhysics() {
        let meshResource = modelEntity.model?.mesh ?? MeshResource.generateBox(size: 0.9)
        let convex = ShapeResource.generateConvex(from: meshResource)

        components.set(CollisionComponent(shapes: [convex]))
        components.set(PhysicsBodyComponent(
            shapes: [convex],
            mass: 0.09,
            material: .generate(friction: 0.65, restitution: 0.30),
            mode: .dynamic
        ))
        components.set(PhysicsMotionComponent())
    }
}
