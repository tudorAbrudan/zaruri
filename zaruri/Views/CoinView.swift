//
//  CoinView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// View for displaying a 50-bani coin with realistic thickness and 3D flip animation.
/// Uses the actual coin images (Cap = "romania-50-bani-2023-ban", Pajură = "romania-50-bani-2023-stema").
struct CoinView: View {
    let isHeads: Bool   // true = Cap (50 BANI text side), false = Pajură (Stema)
    let isRolling: Bool
    let size: CGFloat

    @State private var rotationAngle: Double = 0
    @State private var animationTimer: Timer?
    @State private var currentFace: Bool = true
    @State private var lastIsRolling: Bool = false
    @State private var lastIsHeads: Bool = true

    // 50 bani coin is brass-plated steel — warm golden/yellow tones
    private let edgeLightGold = Color(red: 0.87, green: 0.76, blue: 0.36)
    private let edgeMidGold   = Color(red: 0.76, green: 0.63, blue: 0.24)
    private let edgeDarkGold  = Color(red: 0.58, green: 0.46, blue: 0.14)

    /// Number of thin layers that simulate the coin's physical thickness.
    /// 12 layers at ~0.6% of diameter each → ~7% total, matching the real 50 bani ratio.
    private let edgeLayerCount = 12
    private var edgeLayerStep: CGFloat { (size * 0.075) / CGFloat(edgeLayerCount) }

    var body: some View {
        ZStack {
            // Ground shadow — stays flat, does NOT rotate with the coin
            Ellipse()
                .fill(Color.black.opacity(0.22))
                .frame(width: size * 0.78, height: size * 0.11)
                .blur(radius: size * 0.04)
                .offset(y: size * 0.52)

            coinBody
        }
        .frame(width: size, height: size)
        .onAppear {
            if !isRolling {
                rotationAngle = isHeads ? 0 : 180
                currentFace = isHeads
            }
            lastIsRolling = isRolling
            lastIsHeads = isHeads
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            if isRolling != lastIsRolling {
                lastIsRolling = isRolling
                if isRolling {
                    startRollingAnimation()
                } else {
                    stopRollingAnimation()
                }
            }
            if isHeads != lastIsHeads {
                lastIsHeads = isHeads
                if !isRolling {
                    rotationAngle = isHeads ? 0 : 180
                    currentFace = isHeads
                }
            }
        }
    }

    // MARK: - Coin Body

    private var coinBody: some View {
        ZStack {
            // Thickness layers — brass/gold edge rings, offset in Y.
            // When rotation3DEffect tilts the coin, these Y-offset layers create the
            // visible "grosime" (rim) that you see on a real coin viewed at an angle.
            ForEach((0..<edgeLayerCount).reversed(), id: \.self) { layer in
                let depth = Double(layer) / Double(edgeLayerCount - 1)  // 0 = front, 1 = back
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                edgeLightGold.opacity(0.95 - depth * 0.15),
                                edgeDarkGold.opacity(0.88 - depth * 0.10)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 0.996, height: size * 0.996)
                    // Each layer is shifted a little further "down" (positive Y in SwiftUI).
                    // The total stack depth equals edgeLayerCount × edgeLayerStep ≈ 7.5% of diameter.
                    .offset(y: CGFloat(layer + 1) * edgeLayerStep)
            }

            // Minted rim ring — a thin gold border around the face, like the coin's raised edge
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [edgeLightGold, edgeDarkGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.022
                )
                .frame(width: size * 0.994, height: size * 0.994)

            // Cap face — "50 BANI" text side
            Image("romania-50-bani-2023-ban")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.960, height: size * 0.960)
                .clipShape(Circle())
                .opacity(currentFace ? 1.0 : 0.0)

            // Pajură face — coat of arms (Stema) side
            Image("romania-50-bani-2023-stema")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.960, height: size * 0.960)
                .clipShape(Circle())
                .opacity(currentFace ? 0.0 : 1.0)

            // Gloss highlight — simulates the metallic sheen of the minted surface
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.06),
                            Color.clear
                        ]),
                        center: UnitPoint(x: 0.32, y: 0.25),
                        startRadius: size * 0.04,
                        endRadius: size * 0.52
                    )
                )
                .frame(width: size * 0.960, height: size * 0.960)
                .allowsHitTesting(false)
        }
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: cos(170 * .pi / 180), y: sin(170 * .pi / 180), z: 0),
            perspective: 0.5
        )
    }

    // MARK: - Animation

    private func startRollingAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil

        let startTime = Date()
        let duration: Double = 2.0

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < duration {
                let progress = (elapsed / duration).truncatingRemainder(dividingBy: 1.0)
                let angle = progress * 360 * 5   // 5 full rotations (1800°)
                self.rotationAngle = angle
                // Swap face at midpoint of each half-rotation (when edge-on at 90° / 270°)
                let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
                let positiveAngle = normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle
                self.currentFace = !(positiveAngle > 90 && positiveAngle < 270)
            } else {
                timer.invalidate()
                self.animationTimer = nil
            }
        }
    }

    private func stopRollingAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        currentFace = isHeads
        rotationAngle = isHeads ? 0.0 : 180.0
    }
}

#Preview {
    VStack(spacing: 40) {
        CoinView(isHeads: true, isRolling: false, size: 160)
        CoinView(isHeads: false, isRolling: false, size: 160)
    }
    .padding()
    .background(Color(.systemBackground))
}
