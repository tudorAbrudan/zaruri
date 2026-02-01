//
//  DiceSimpleView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI

/// Simple 2D dice view with dots
struct DiceSimpleView: View {
    let dice: Dice
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Drop shadow on background (projected shadow)
            if dice.type == .d6 {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(Color.black.opacity(0.2))
                    .blur(radius: size * 0.1)
                    .offset(x: 0, y: size * 0.05)
                    .frame(width: size * 0.95, height: size * 0.95)
            } else {
                diceBackgroundShape
                    .fill(Color.black.opacity(0.2))
                    .blur(radius: size * 0.1)
                    .offset(x: 0, y: size * 0.05)
                    .frame(width: size * 0.95, height: size * 0.95)
            }
            
            // Main dice shape with enhanced 3D effects
            Group {
                if dice.type == .d6 {
                    // Square for d6 (cube) - enhanced 3D
                    ZStack {
                        // Base shape with gradient
                        RoundedRectangle(cornerRadius: size * 0.15)
                            .fill(diceGradient)
                        
                        // Top highlight (light reflection)
                        RoundedRectangle(cornerRadius: size * 0.15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .frame(width: size * 0.7, height: size * 0.7)
                            .offset(x: -size * 0.1, y: -size * 0.1)
                        
                        // Bottom shadow (depth)
                        RoundedRectangle(cornerRadius: size * 0.15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.black.opacity(0.3)
                                    ]),
                                    startPoint: .center,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Border with highlight
                        RoundedRectangle(cornerRadius: size * 0.15)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.black.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: Color.black.opacity(0.4), radius: size * 0.15, x: 0, y: size * 0.08)
                    .shadow(color: Color.black.opacity(0.2), radius: size * 0.3, x: 0, y: size * 0.15)
                } else {
                    // Other shapes with enhanced 3D
                    ZStack {
                        // Base shape with gradient
                        diceBackgroundShape
                            .fill(diceGradient)
                        
                        // Top highlight
                        diceBackgroundShape
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .center
                                )
                            )
                            .frame(width: size * 0.7, height: size * 0.7)
                            .offset(x: -size * 0.1, y: -size * 0.1)
                        
                        // Bottom shadow
                        diceBackgroundShape
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.black.opacity(0.3)
                                    ]),
                                    startPoint: .center,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        // Border with highlight
                        diceBackgroundShape
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.black.opacity(0.3)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: Color.black.opacity(0.4), radius: size * 0.15, x: 0, y: size * 0.08)
                    .shadow(color: Color.black.opacity(0.2), radius: size * 0.3, x: 0, y: size * 0.15)
                }
            }
            
            // Content (dots for d6, numbers for others)
            diceContentView
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(dice.isRolling ? 360 : 0))
        .animation(dice.isRolling ? Animation.linear(duration: 0.3).repeatForever(autoreverses: false) : .default, value: dice.isRolling)
    }
    
    // Enhanced 3D gradient for each dice type with more contrast
    private var diceGradient: LinearGradient {
        let colors = diceTypeColors
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: colors.light, location: 0.0),
                .init(color: colors.base, location: 0.3),
                .init(color: colors.base, location: 0.7),
                .init(color: colors.dark, location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Colors for each dice type (matching the image)
    private var diceTypeColors: (base: Color, light: Color, dark: Color) {
        switch dice.type {
        case .d2:
            // Bronze/coin for d2
            return (Color(red: 0.8, green: 0.6, blue: 0.4), Color(red: 0.85, green: 0.68, blue: 0.45), Color(red: 0.6, green: 0.45, blue: 0.25))
        case .d3:
            // Teal for d3
            return (Color(red: 0.2, green: 0.7, blue: 0.65), Color(red: 0.3, green: 0.78, blue: 0.72), Color(red: 0.1, green: 0.55, blue: 0.5))
        case .d4:
            // Green for d4
            return (Color.green, Color.green.opacity(0.8), Color(red: 0.0, green: 0.6, blue: 0.0))
        case .d6:
            // Light blue for d6
            return (Color(red: 0.4, green: 0.7, blue: 1.0), Color(red: 0.5, green: 0.8, blue: 1.0), Color(red: 0.2, green: 0.5, blue: 0.9))
        case .d8:
            // Purple for d8
            return (Color.purple, Color.purple.opacity(0.8), Color(red: 0.5, green: 0.0, blue: 0.7))
        case .d10:
            // Red/pink for d10
            return (Color(red: 1.0, green: 0.3, blue: 0.5), Color(red: 1.0, green: 0.4, blue: 0.6), Color(red: 0.8, green: 0.1, blue: 0.3))
        case .d12:
            // Magenta/pink for d12
            return (Color(red: 1.0, green: 0.0, blue: 0.8), Color(red: 1.0, green: 0.2, blue: 0.9), Color(red: 0.7, green: 0.0, blue: 0.6))
        case .d20:
            // Orange for d20
            return (Color.orange, Color.orange.opacity(0.8), Color(red: 0.9, green: 0.5, blue: 0.0))
        }
    }
    
    private var diceBackgroundShape: AnyShape {
        switch dice.type {
        case .d2:
            // Circle for d2 (coin-like when multiple)
            return AnyShape(Circle())
        case .d3:
            // Triangle for d3
            return AnyShape(Triangle())
        case .d4:
            // Triangle for d4 (tetrahedron)
            return AnyShape(Triangle())
        case .d8:
            // Diamond/rhombus for d8 (octahedron)
            return AnyShape(Diamond())
        case .d10:
            // Pentagon for d10 (trapezohedron)
            return AnyShape(Pentagon())
        case .d12:
            // Pentagon for d12 (dodecahedron)
            return AnyShape(Pentagon())
        case .d20:
            // Triangle for d20 (icosahedron)
            return AnyShape(Triangle())
        default:
            // Fallback (shouldn't happen)
            return AnyShape(RoundedRectangle(cornerRadius: 0))
        }
    }
    
    @ViewBuilder
    private var diceContentView: some View {
        if dice.type == .d6 {
            // For d6, show dots pattern
            dotsView
        } else {
            // For other dice types, show number
            numberView
        }
    }
    
    private var numberView: some View {
        Text("\(dice.value)")
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.7), radius: 3, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 1)
            .overlay(
                Text("\(dice.value)")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.3))
                    .offset(x: -1, y: -1)
                    .blendMode(.overlay)
            )
    }
    
    private var dotsView: some View {
        GeometryReader { geometry in
            let dotSize = size * 0.15
            let spacing = size * 0.25
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                switch dice.value {
                case 1:
                    // Center dot
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(center)
                    
                case 2:
                    // Top-left and bottom-right
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 3:
                    // Top-left, center, bottom-right
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(center)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 4:
                    // Four corners
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: geometry.size.height - spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 5:
                    // Four corners + center
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(center)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: geometry.size.height - spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 6:
                    // Two columns of three
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: center.y)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: spacing, y: geometry.size.height - spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: spacing)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: center.y)
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.white.opacity(0.8)
                                ]),
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: dotSize
                            )
                        )
                        .frame(width: dotSize, height: dotSize)
                        .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 0)
                        .overlay(
                            Circle()
                                .fill(Color.white.opacity(0.4))
                                .frame(width: dotSize * 0.4, height: dotSize * 0.4)
                                .offset(x: -dotSize * 0.2, y: -dotSize * 0.2)
                        )
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                default:
                    EmptyView()
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom Shapes

/// Type-erased wrapper for Shape protocol
struct AnyShape: Shape, @unchecked Sendable {
    private let _path: (CGRect) -> Path
    
    init<S: Shape>(_ shape: S) {
        _path = shape.path(in:)
    }
    
    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }
}

/// Triangle shape for d4 and d20
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Diamond/rhombus shape for d8
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// Pentagon shape for d10 and d12
struct Pentagon: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        
        for i in 0..<5 {
            let angle = Double(i) * 2.0 * .pi / 5.0 - .pi / 2.0 // Start from top
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y + CGFloat(sin(angle)) * radius
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack {
        HStack {
            DiceSimpleView(dice: Dice(value: 1, type: .d6), size: 100)
            DiceSimpleView(dice: Dice(value: 3, type: .d6), size: 100)
            DiceSimpleView(dice: Dice(value: 6, type: .d6), size: 100)
        }
        .padding()
        
        HStack {
            DiceSimpleView(dice: Dice(value: 4, type: .d4), size: 100)
            DiceSimpleView(dice: Dice(value: 8, type: .d8), size: 100)
            DiceSimpleView(dice: Dice(value: 10, type: .d10), size: 100)
            DiceSimpleView(dice: Dice(value: 12, type: .d12), size: 100)
            DiceSimpleView(dice: Dice(value: 20, type: .d20), size: 100)
        }
        .padding()
    }
}










