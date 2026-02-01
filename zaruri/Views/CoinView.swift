//
//  CoinView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// View for displaying a coin with 3D rotation animation
struct CoinView: View {
    let isHeads: Bool  // true = Cap (50 BANI), false = Pajură (Stema)
    let isRolling: Bool
    let size: CGFloat
    
    @State private var rotationAngle: Double = 0
    @State private var animationTimer: Timer?
    @State private var currentFace: Bool = true  // true = Cap, false = Pajură
    @State private var lastIsRolling: Bool = false
    @State private var lastIsHeads: Bool = true
    
    var body: some View {
        ZStack {
            // Drop shadow pentru efect 3D
            Circle()
                .fill(Color.black.opacity(0.2))
                .blur(radius: size * 0.1)
                .offset(x: 0, y: size * 0.05)
                .frame(width: size * 0.95, height: size * 0.95)
            
            // Coin with thickness effect
            ZStack {
                // Edge/rim pentru grosime (partea laterală a monedei)
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.5, green: 0.4, blue: 0.3),
                                Color(red: 0.4, green: 0.3, blue: 0.2),
                                Color(red: 0.3, green: 0.2, blue: 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.6, green: 0.5, blue: 0.3).opacity(0.8),
                                        Color(red: 0.4, green: 0.3, blue: 0.2).opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: size * 0.01  // Reduced by another 50%
                            )
                    )
                    .offset(x: 0, y: 0) // Edge rim for thickness
                
                // Ambele fețe ale monedei - alternăm între ele în timpul rotației
                ZStack {
                    // Fața 1 (Cap - 50 BANI)
                    Image("romania-50-bani-2023-ban")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size * 0.96, height: size * 0.96)
                        .clipShape(Circle())
                        .opacity(currentFace ? 1.0 : 0.0)
                    
                    // Fața 2 (Pajură - Stema)
                    Image("romania-50-bani-2023-stema")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: size * 0.96, height: size * 0.96)
                        .clipShape(Circle())
                        .opacity(currentFace ? 0.0 : 1.0)
                }
                .shadow(color: Color.black.opacity(0.4), radius: size * 0.1, x: 0, y: size * 0.05)
            }
        }
        .frame(width: size, height: size)
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: cos(170 * .pi / 180), y: sin(170 * .pi / 180), z: 0),
            perspective: 0.5
        )
        .onAppear {
            if !isRolling {
                rotationAngle = isHeads ? 0 : 180
                currentFace = isHeads
            }
            lastIsRolling = isRolling
            lastIsHeads = isHeads
        }
        .onReceive(Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()) { _ in
            // Check for changes in isRolling - check very frequently for immediate response
            if isRolling != lastIsRolling {
                lastIsRolling = isRolling
                if isRolling {
                    startRollingAnimation()
                } else {
                    // Stop immediately when isRolling becomes false
                    stopRollingAnimation()
                }
            }
            
            // Check for changes in isHeads
            if isHeads != lastIsHeads {
                lastIsHeads = isHeads
                if !isRolling {
                    rotationAngle = isHeads ? 0 : 180
                    currentFace = isHeads
                }
            }
        }
    }
    
    private func startRollingAnimation() {
        // Stop any existing animation first
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Start continuous rotation animation - slower
        let startTime = Date()
        let duration: Double = 2.0  // Slower rotation (was 1.56)
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            
            // Continue animation while elapsed time is less than duration
            // The onReceive timer will stop this if isRolling becomes false
            if elapsed < duration {
                let progress = (elapsed / duration).truncatingRemainder(dividingBy: 1.0)
                let angle = progress * 360 * 5  // 5 full rotations (1800 degrees)
                self.rotationAngle = angle
                
                // Update face based on rotation angle
                let normalizedAngle = angle.truncatingRemainder(dividingBy: 360)
                let positiveAngle = normalizedAngle < 0 ? normalizedAngle + 360 : normalizedAngle
                // Când unghiul este între 90° și 270°, arătăm spatele (Pajură)
                self.currentFace = !(positiveAngle > 90 && positiveAngle < 270)
            } else {
                // Animation finished naturally - stop timer
                timer.invalidate()
                self.animationTimer = nil
            }
        }
    }
    
    private func stopRollingAnimation() {
        // Stop timer immediately - this is critical
        animationTimer?.invalidate()
        animationTimer = nil
        
        // Set final state immediately - no delay, no animation
        currentFace = isHeads
        let finalAngle = isHeads ? 0.0 : 180.0
        
        // Set final angle immediately without any animation
        rotationAngle = finalAngle
    }
}

#Preview {
    VStack(spacing: 40) {
        CoinView(isHeads: true, isRolling: false, size: 150)
        CoinView(isHeads: false, isRolling: false, size: 150)
        CoinView(isHeads: true, isRolling: true, size: 150)
    }
    .padding()
}
