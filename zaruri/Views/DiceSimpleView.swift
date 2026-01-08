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
            // White background with shadow
            RoundedRectangle(cornerRadius: size * 0.15)
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // Border
            RoundedRectangle(cornerRadius: size * 0.15)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: size, height: size)
            
            // Dots
            dotsView
        }
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
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(center)
                    
                case 2:
                    // Top-left and bottom-right
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 3:
                    // Top-left, center, bottom-right
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(center)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 4:
                    // Four corners
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: geometry.size.height - spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 5:
                    // Four corners + center
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(center)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: geometry.size.height - spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                case 6:
                    // Two columns of three
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: center.y)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: spacing, y: geometry.size.height - spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: spacing)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: center.y)
                    Circle()
                        .fill(Color.black)
                        .frame(width: dotSize, height: dotSize)
                        .position(x: geometry.size.width - spacing, y: geometry.size.height - spacing)
                    
                default:
                    EmptyView()
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack {
        DiceSimpleView(dice: Dice(value: 1), size: 100)
        DiceSimpleView(dice: Dice(value: 3), size: 100)
        DiceSimpleView(dice: Dice(value: 6), size: 100)
    }
    .padding()
}



