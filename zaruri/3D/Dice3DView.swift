//
//  Dice3DView.swift
//  zaruri
//

import SwiftUI
import RealityKit
import simd
import UIKit

/// 3D dice rendering area using RealityKit.
/// Numbers are baked into per-face textures on the dice geometry.
/// Camera sits at 45° above, looking down at the landing area.
struct Dice3DView: View {

    let dice: [Dice]
    let isRolling: Bool
    let rollForce: Float
    let theme: AppTheme
    var customConfig: CustomDiceConfig? = nil
    /// When true and the dice type is d2, uses the 50-bani coin look.
    var useCoinLookForD2: Bool = false
    /// Called after physics settles with the physics-determined value for each die.
    var onPhysicsSettled: (([Int]) -> Void)? = nil
    /// When true, the view expands to fill all available space (no fixed height, no rounded corners).
    var isFullScreen: Bool = false

    @State private var diceEntities: [DiceEntity] = []
    @State private var showValues: Bool = true
    /// Start positions folosite pentru a reseta zarurile înainte de fiecare aruncare.
    @State private var startPositionsCache: [SIMD3<Float>] = []
    /// Ultima stare de „isRolling” folosită ca să detectăm începutul unei noi aruncări.
    @State private var previousIsRolling: Bool = false
    /// Camera elevation angle in degrees (5° = almost horizontal, 85° = bird's eye). Default: 55°.
    @State private var cameraAngleDegrees: Double = 55
    /// Camera horizontal rotation in degrees (0° = front, 90° = right). Default: 0°.
    @State private var cameraYawDegrees: Double = 0
    /// Tracks previous drag translation to compute per-frame delta.
    @State private var lastDragTranslation: CGSize = .zero
    /// Camera distance from the look-at target. Adjusted by pinch-to-zoom.
    @State private var cameraRadius: Double = 5.85
    /// Previous magnification value, used to compute per-frame delta for pinch gesture.
    @State private var lastMagnification: CGFloat = 1.0
    /// Reference to the camera entity so it can be repositioned on drag.
    @State private var cameraEntity: PerspectiveCamera?
    /// One-time hint banner: true = show briefly, then fade out.
    @AppStorage("cameraHintDismissed") private var cameraHintDismissed: Bool = false
    @State private var showCameraHintBanner: Bool = false

    // Forces RealityView to rebuild when dice type, count, custom config, theme, or coin mode changes.
    private var sceneKey: String {
        var key = dice.map { $0.type.rawValue }.joined() + "\(dice.count)"
        key += "_t:\(theme.rawValue)"
        if useCoinLookForD2 { key += "coin" }
        if let config = customConfig {
            key += config.geometryType.rawValue + config.colorHex
                 + "\(config.useCustomLabels)" + config.faceLabels.joined(separator: ",")
        }
        return key
    }

    var body: some View {
        ZStack {
            // Themed table background (e.g. poker table, wooden table, etc.)
            ZStack {
                LinearGradient(
                    colors: theme.tableBackgroundColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if theme.showsTableLamp {
                    // Soft lamp-style glow above the table (only for selected themes).
                    RadialGradient(
                        colors: [
                            theme.tableLampHighlightColor.opacity(theme.tableLampIntensity),
                            theme.tableLampHighlightColor.opacity(0.0)
                        ],
                        center: .top,
                        startRadius: 8,
                        endRadius: 260
                    )
                    .blendMode(.screen)
                }
            }

            RealityView { content in
                buildScene(content: &content)
            } update: { _ in
                // Reposition camera whenever elevation or yaw sliders change.
                if let cam = cameraEntity {
                    let el = Float(cameraAngleDegrees * .pi / 180)
                    let yaw = Float(cameraYawDegrees * .pi / 180)
                    let radius = Float(cameraRadius)
                    let target = SIMD3<Float>(0, -1.0, 0)
                    cam.look(at: target, from: SIMD3(
                        radius * cos(el) * sin(yaw),
                        target.y + radius * sin(el),
                        radius * cos(el) * cos(yaw)
                    ), relativeTo: nil)
                }

                // La tranziția false -> true resetăm pozițiile, orientările și vitezele
                // astfel încât zarurile/moneda revin în „castronul” vizibil.
                if isRolling && !previousIsRolling {
                    for (i, entity) in diceEntities.enumerated() {
                        let basePos = startPositionsCache[safe: i] ?? SIMD3(0, 0.3, -0.4)
                        let baseScale = scale(for: dice.count)
                        let sizeMultiplier: Float
                        if useCoinLookForD2 {
                            sizeMultiplier = 1.50
                        } else if dice[safe: i]?.type == .d6 {
                            sizeMultiplier = 1.10
                        } else {
                            sizeMultiplier = 1.0
                        }
                        let s = baseScale * sizeMultiplier
                        entity.resetForNewRoll(to: basePos, scale: s)
                    }
                }
                previousIsRolling = isRolling

                if isRolling {
                    diceEntities.forEach { $0.applyRollImpulse(force: rollForce) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: isFullScreen ? .infinity : nil)
            .frame(height: isFullScreen ? nil : sceneHeight)
            .id(sceneKey)

            if showValues && !isRolling && !useCoinLookForD2 && !dice.allSatisfy({ $0.type == .d2 }) {
                DiceValuesOverlayView(dice: dice, theme: theme, customConfig: customConfig)
                    .transition(.opacity.animation(.easeIn(duration: 0.45)))
                    .allowsHitTesting(false)
            }

            // Brief one-time hint banner (top center, fades out after 3s)
            if showCameraHintBanner {
                VStack {
                    HStack(spacing: 6) {
                        Image(systemName: "rotate.3d")
                            .font(.system(size: 13, weight: .medium))
                        Text("Trage pentru a roti camera")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.top, 12)
                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            // Persistent subtle rotate icon (top-trailing corner)
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "rotate.3d")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.28))
                        .padding(10)
                }
                Spacer()
            }
            .allowsHitTesting(false)

        }
        .contentShape(Rectangle())
        .gesture(
            SimultaneousGesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        let dx = value.translation.width  - lastDragTranslation.width
                        let dy = value.translation.height - lastDragTranslation.height
                        cameraYawDegrees   = (cameraYawDegrees - Double(dx) * 0.45)
                            .truncatingRemainder(dividingBy: 360)
                        cameraAngleDegrees = min(85, max(5, cameraAngleDegrees + Double(dy) * 0.30))
                        lastDragTranslation = value.translation
                    }
                    .onEnded { _ in lastDragTranslation = .zero },
                MagnificationGesture()
                    .onChanged { scale in
                        let delta = Double(scale / lastMagnification)
                        lastMagnification = scale
                        // Pinch out (scale>1) → zoom in → smaller radius; pinch in → zoom out
                        cameraRadius = min(14.0, max(3.0, cameraRadius / delta))
                        repositionCamera()
                    }
                    .onEnded { _ in lastMagnification = 1.0 }
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: isFullScreen ? 0 : 24))
        .frame(height: isFullScreen ? nil : sceneHeight)
        .frame(maxHeight: isFullScreen ? .infinity : nil)
        .onChange(of: isRolling) { _, rolling in
            if rolling {
                showValues = false
            } else {
                Task { @MainActor in
                    // Timeout minim pentru ca animația de aruncare să fie vizibilă.
                    try? await Task.sleep(for: .milliseconds(2800))
                    guard !isRolling else { return }

                    // Așteptăm până când toate zarurile s-au oprit complet (până la 15 verificări × 300ms).
                    await waitUntilResting(maxChecks: 15)

                    // Pauză suplimentară după ce vitezele sunt sub prag, pentru micro-rotații reziduale.
                    // Citim valorile DUPĂ această pauză, nu înainte, ca să corespundă cu fața vizibilă.
                    try? await Task.sleep(for: .milliseconds(500))
                    guard !isRolling else { return }

                    // Un zar nu poate rămâne în echilibru pe muchie/colț: îl răsturnăm pe o față.
                    await settleDiceFlat()
                    guard !isRolling else { return }

                    var physicsValues: [Int] = []
                    for (i, entity) in diceEntities.enumerated() {
                        if let physicsValue = entity.currentTopFaceValue() {
                            physicsValues.append(physicsValue)
                        } else if let die = dice[safe: i] {
                            physicsValues.append(die.value)
                        }
                    }
                    if !physicsValues.isEmpty {
                        onPhysicsSettled?(physicsValues)
                    }

                    // Mică pauză pentru propagarea stării SwiftUI, apoi afișăm cercurile.
                    try? await Task.sleep(for: .milliseconds(80))
                    guard !isRolling else { return }
                    showValues = true
                }
            }
        }
        .onChange(of: sceneKey) { _, _ in
            showValues = true
        }
        .onAppear {
            // Set camera distance based on mode (fullscreen needs more zoom out)
            cameraRadius = isFullScreen ? 8.5 : 5.85
            repositionCamera()

            guard !cameraHintDismissed else { return }
            withAnimation(.easeIn(duration: 0.4)) {
                showCameraHintBanner = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeOut(duration: 0.8)) {
                    showCameraHintBanner = false
                }
                cameraHintDismissed = true
            }
        }
        .onChange(of: cameraAngleDegrees) { _, _ in repositionCamera() }
        .onChange(of: cameraYawDegrees)   { _, _ in repositionCamera() }
        .onChange(of: cameraRadius)       { _, _ in repositionCamera() }
    }

    // MARK: - Camera Reposition

    /// Directly repositions the camera entity — called immediately from drag gesture onChange,
    /// bypassing RealityView's update closure which may not fire reliably for camera-only changes.
    private func repositionCamera() {
        guard let cam = cameraEntity else { return }
        let el  = Float(cameraAngleDegrees * .pi / 180)
        let yaw = Float(cameraYawDegrees   * .pi / 180)
        let radius = Float(cameraRadius)
        let target = SIMD3<Float>(0, -1.0, 0)
        cam.look(at: target, from: SIMD3(
            radius * cos(el) * sin(yaw),
            target.y + radius * sin(el),
            radius * cos(el) * cos(yaw)
        ), relativeTo: nil)
    }

    // MARK: - Scene Construction

    private func buildScene(content: inout some RealityViewContentProtocol) {
        content.entities.removeAll()
        diceEntities = []

        addCamera(to: &content)
        addFloor(to: &content)
        addWalls(to: &content)
        addLighting(to: &content)

        let positions = startPositions(count: dice.count)
        startPositionsCache = positions
        let customLabels = customConfig?.resolvedLabels
        let customColor = customConfig?.uiColor
        var entities: [DiceEntity] = []
        for (i, die) in dice.enumerated() {
            // When no custom dice config is active, let the current theme drive the base dice colour
            // for all dice types. In classic mode this yields neutral white dice whose numbers/pips
            // are drawn with high-contrast black.
            let perDieBaseColorOverride: UIColor? = (customConfig == nil) ? theme.diceBaseUIColor : nil

            // In coin flip mode, always render as D2 (coin) regardless of selected dice type.
            let effectiveDiceType: DiceType = useCoinLookForD2 ? .d2 : die.type
            guard let entity = try? DiceEntity(
                diceType: effectiveDiceType,
                customLabels: useCoinLookForD2 ? nil : customLabels,
                customColor: useCoinLookForD2 ? nil : customColor,
                baseColorOverride: useCoinLookForD2 ? nil : perDieBaseColorOverride,
                useCoinLookForD2: useCoinLookForD2
            ) else { continue }
            entity.position = positions[safe: i] ?? SIMD3(0, 0.3, 0)
            entity.orientation = randomOrientation()
            let baseScale = scale(for: dice.count)
            // D6 este puțin mai mare, D10 ușor mai mare pentru lizibilitate,
            // iar moneda (în modul „Aruncă cu banul”) este cu ~50% mai mare.
            let sizeMultiplier: Float
            if useCoinLookForD2 {
                sizeMultiplier = 1.50
            } else if die.type == .d6 {
                sizeMultiplier = 1.10
            } else if die.type == .d10 {
                sizeMultiplier = 1.15
            } else {
                sizeMultiplier = 1.0
            }
            let s = baseScale * sizeMultiplier
            entity.scale = SIMD3(s, s, s)
            content.add(entity)
            entities.append(entity)
        }
        diceEntities = entities
    }

    // MARK: - Camera

    private func addCamera(to content: inout some RealityViewContentProtocol) {
        let cam = PerspectiveCamera()
        cam.camera.fieldOfViewInDegrees = 60
        let el = Float(cameraAngleDegrees * .pi / 180)
        let yaw = Float(cameraYawDegrees * .pi / 180)
        let radius = Float(cameraRadius)
        let target = SIMD3<Float>(0, -1.0, 0)
        cam.look(at: target, from: SIMD3(
            radius * cos(el) * sin(yaw),
            target.y + radius * sin(el),
            radius * cos(el) * cos(yaw)
        ), relativeTo: nil)
        content.add(cam)
        cameraEntity = cam
    }

    // MARK: - Physics Environment

    private func addFloor(to content: inout some RealityViewContentProtocol) {
        // Physical collision box
        let size = SIMD3<Float>(8, 0.16, 6.4)
        let shape = ShapeResource.generateBox(size: size)
        let floor = ModelEntity()
        floor.position = SIMD3(0, -2.0, -0.5)
        floor.components.set(CollisionComponent(shapes: [shape]))
        floor.components.set(PhysicsBodyComponent(
            shapes: [shape],
            mass: 0,
            material: .generate(friction: 0.90, restitution: 0.10),
            mode: .static
        ))

        // Vizualizăm clar „masa” ca un dreptunghi verde, ușor rotunjit.
        let tableMesh = MeshResource.generateBox(size: size)
        let tableColor = UIColor(red: 0.05, green: 0.35, blue: 0.19, alpha: 1.0)
        let edgeColor  = UIColor(red: 0.02, green: 0.18, blue: 0.10, alpha: 1.0)

        var mainMat = SimpleMaterial(color: tableColor, isMetallic: false)
        mainMat.roughness = 0.85

        var edgeMat = SimpleMaterial(color: edgeColor, isMetallic: false)
        edgeMat.roughness = 0.9

        // Folosim același mesh dar două materiale: partea de sus ușor mai deschisă decât marginea.
        floor.model = ModelComponent(mesh: tableMesh, materials: [mainMat, edgeMat])

        content.add(floor)
    }

    private func addWalls(to content: inout some RealityViewContentProtocol) {
        let physicsMat = PhysicsMaterialResource.generate(friction: 0.5, restitution: 0.25)

        var glassMat = PhysicallyBasedMaterial()
        glassMat.baseColor = .init(tint: UIColor(red: 0.55, green: 0.82, blue: 1.0, alpha: 1.0))
        glassMat.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: 0.05)
        glassMat.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: 0.0)
        glassMat.blending = .transparent(opacity: .init(floatLiteral: 0.01))

        func addWall(size: SIMD3<Float>, position: SIMD3<Float>) {
            let shape = ShapeResource.generateBox(size: size)
            let wall = ModelEntity()
            wall.position = position
            wall.components.set(CollisionComponent(shapes: [shape]))
            wall.components.set(PhysicsBodyComponent(
                shapes: [shape], mass: 0, material: physicsMat, mode: .static
            ))
            wall.model = ModelComponent(
                mesh: MeshResource.generateBox(size: size),
                materials: [glassMat]
            )
            content.add(wall)
        }

        // Floor footprint is 8 × 6.4 centered at (0, _, -0.5) → X edges ±4, Z edges -3.7 / 2.7.
        // Glass walls hug the floor's outer edge so the aquarium ends exactly at the corner,
        // never protruding past the base.
        let wt: Float = 0.1   // wall thickness
        let wh: Float = 7     // wall height
        // Side walls: span full floor depth, outer face flush with the floor's X edges.
        addWall(size: SIMD3(wt, wh, 6.4), position: SIMD3(-4 + wt / 2, 0.2, -0.5))
        addWall(size: SIMD3(wt, wh, 6.4), position: SIMD3( 4 - wt / 2, 0.2, -0.5))
        // Front/back walls: fit between the side walls so corners meet cleanly without overlap.
        addWall(size: SIMD3(8 - 2 * wt, wh, wt), position: SIMD3(0, 0.2, -3.7 + wt / 2))
        addWall(size: SIMD3(8 - 2 * wt, wh, wt), position: SIMD3(0, 0.2,  2.7 - wt / 2))
        // Ceiling matches the floor footprint exactly.
        addWall(size: SIMD3(8, 0.12, 6.4), position: SIMD3(0, 3.0, -0.5))
    }

    // MARK: - Lighting

    private func addLighting(to content: inout some RealityViewContentProtocol) {
        let key = DirectionalLight()
        key.light.intensity = 5000
        key.light.color = UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1)
        key.orientation = simd_quatf(angle: -.pi / 4, axis: SIMD3<Float>(1, 0, 0))
        content.add(key)

        let fill = DirectionalLight()
        fill.light.intensity = 900
        fill.light.color = UIColor(red: 0.60, green: 0.72, blue: 1.0, alpha: 1)
        fill.orientation = simd_quatf(angle: .pi / 6, axis: normalize(SIMD3<Float>(-1, 0.2, 0.3)))
        content.add(fill)
    }

    // MARK: - Layout

    private func startPositions(count: Int) -> [SIMD3<Float>] {
        let sp: Float = 1.6
        let y: Float = 0.3
        let z: Float = -0.4
        switch count {
        case 1: return [SIMD3(0, y, z)]
        case 2: return [SIMD3(-sp/2, y, z), SIMD3(sp/2, y, z)]
        case 3: return (0..<3).map { SIMD3(Float($0 - 1) * sp, y, z) }
        case 4: return [SIMD3(-sp/2, y, z + sp/3), SIMD3(sp/2, y, z + sp/3),
                        SIMD3(-sp/2, y, z - sp/3), SIMD3(sp/2, y, z - sp/3)]
        case 5: return [SIMD3(-sp, y, z + sp/3), SIMD3(0, y, z + sp/3), SIMD3(sp, y, z + sp/3),
                        SIMD3(-sp/2, y, z - sp/3), SIMD3(sp/2, y, z - sp/3)]
        default: return [SIMD3(-sp, y, z + sp/3), SIMD3(0, y, z + sp/3), SIMD3(sp, y, z + sp/3),
                         SIMD3(-sp, y, z - sp/3), SIMD3(0, y, z - sp/3), SIMD3(sp, y, z - sp/3)]
        }
    }

    private func scale(for count: Int) -> Float {
        [1: 1.20, 2: 1.04, 3: 0.88, 4: 0.76, 5: 0.68, 6: 0.60][count] ?? 0.60
    }

    private func randomOrientation() -> simd_quatf {
        let axis = normalize(SIMD3<Float>(
            Float.random(in: 0.1...1),
            Float.random(in: 0.1...1),
            Float.random(in: 0.1...1)
        ))
        return simd_quatf(angle: Float.random(in: 0...(2 * .pi)), axis: axis)
    }

    private var sceneHeight: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 580 : 400
    }

    private func waitUntilResting(maxChecks: Int) async {
        for _ in 0..<maxChecks {
            guard !isRolling else { return }
            if diceAreResting() { return }
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    /// Ensures every die ends lying flat on a face. First tips tilted dice physically with growing
    /// strength; on the last attempt aligns them exactly and lets them drop.
    private func settleDiceFlat() async {
        let attempts = 4
        for attempt in 0..<attempts {
            guard !isRolling else { return }
            let tilted = diceEntities.filter { !$0.isLyingFlat }
            if tilted.isEmpty { return }
            for entity in tilted {
                if attempt < attempts - 1 {
                    entity.tipTowardFlat(strength: 2.5 + Float(attempt) * 1.5)
                } else {
                    entity.snapFlatAndDrop()
                }
            }
            try? await Task.sleep(for: .milliseconds(900))
            await waitUntilResting(maxChecks: 10)
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    /// Considerăm că zarurile s-au „liniștit” când atât viteza liniară cât și cea
    /// unghiulară sunt sub praguri strict mici pentru toate entitățile.
    /// Prag angular strâns (0.08 rad/s ≈ 4.5°/s) evită citiri premature ale feței superioare.
    private func diceAreResting() -> Bool {
        let linearThreshold: Float = 0.05
        let angularThreshold: Float = 0.08
        for entity in diceEntities {
            if let motion = entity.components[PhysicsMotionComponent.self] {
                let lin = simd_length(motion.linearVelocity)
                let ang = simd_length(motion.angularVelocity)
                if lin > linearThreshold || ang > angularThreshold {
                    return false
                }
            }
        }
        return true
    }
}

// MARK: - Safe Array Subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Value Overlay

/// Glass-morphism chips showing each die's value — appears after physics settles.
struct DiceValuesOverlayView: View {
    let dice: [Dice]
    let theme: AppTheme
    var customConfig: CustomDiceConfig? = nil

    var body: some View {
        HStack(spacing: 10) {
            ForEach(dice) { die in
                Text(label(for: die))
                    .font(.system(size: chipFontSize, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.35)
                    .lineLimit(1)
                    .foregroundColor(.white)
                    .frame(width: chipSize, height: chipSize)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(theme.primaryColor.opacity(0.72)))
                            .shadow(color: theme.primaryColor.opacity(0.7), radius: 10)
                            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 18)
    }

    private func label(for die: Dice) -> String {
        if let config = customConfig, config.useCustomLabels,
           die.value >= 1, die.value <= config.faceLabels.count {
            return config.faceLabels[die.value - 1]
        }
        return "\(die.value)"
    }

    private var chipFontSize: CGFloat {
        switch dice.count {
        case 1: return 34
        case 2: return 28
        case 3: return 24
        default: return 20
        }
    }

    private var chipSize: CGFloat {
        switch dice.count {
        case 1: return 64
        case 2: return 54
        case 3: return 46
        default: return 40
        }
    }
}
