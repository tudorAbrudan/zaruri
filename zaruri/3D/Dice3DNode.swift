//
//  Dice3DNode.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SceneKit
import UIKit

/// 3D dice node using SceneKit with realistic materials and textures
class Dice3DNode: SCNNode {
    // MARK: - Properties
    
    var diceValue: Int = 1 {
        didSet {
            updateDiceFaces()
        }
    }
    
    var isRolling: Bool = false {
        didSet {
            if isRolling {
                startRollingAnimation()
            } else {
                stopRollingAnimation()
            }
        }
    }
    
    private let diceSize: CGFloat
    private var rollingAction: SCNAction?
    
    // MARK: - Initialization
    
    init(size: CGFloat = 1.0) {
        self.diceSize = size
        super.init()
        setupDice()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupDice() {
        // Create box geometry for dice
        let box = SCNBox(
            width: diceSize,
            height: diceSize,
            length: diceSize,
            chamferRadius: diceSize * 0.1
        )
        geometry = box
        
        // Setup materials for all 6 faces
        setupMaterials()
        
        // Add physics body for realistic rolling
        setupPhysics()
        
        // Initial face update
        updateDiceFaces()
    }
    
    private func setupMaterials() {
        guard let box = geometry as? SCNBox else {
            return
        }
        
        // Create base materials for all 6 faces
        var materials: [SCNMaterial] = []
        for _ in 0..<6 {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            material.specular.contents = UIColor(white: 0.8, alpha: 1.0)
            material.shininess = 0.5
            material.isDoubleSided = false
            material.lightingModel = .lambert
            materials.append(material)
        }
        
        box.materials = materials
        
        // Update faces with dots
        updateDiceFaces()
    }
    
    private func setupPhysics() {
        let physicsShape = SCNPhysicsShape(geometry: geometry!, options: nil)
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody?.mass = 1.0
        physicsBody?.friction = 0.8
        physicsBody?.restitution = 0.3  // Bounce
        physicsBody?.damping = 0.5
    }
    
    // MARK: - Face Updates
    
    private func updateDiceFaces() {
        guard let box = geometry as? SCNBox else {
            return
        }
        
        // Ensure we have materials
        if box.materials.isEmpty || box.materials.count != 6 {
            setupMaterials()
            return
        }
        
        // Create texture for each face based on dice value
        // Face mapping: 0=Right, 1=Left, 2=Top, 3=Bottom, 4=Front, 5=Back
        let dotMaterial = createDotMaterial()
        
        // Update each face
        for faceIndex in 0..<6 {
            let faceValue = getFaceValue(faceIndex: faceIndex)
            
            // Create texture on main thread
            let texture = createFaceTexture(value: faceValue, dotMaterial: dotMaterial)
            
            // Apply texture to material
            let material = box.materials[faceIndex]
            material.diffuse.contents = texture
            material.diffuse.wrapS = .repeat
            material.diffuse.wrapT = .repeat
            material.isDoubleSided = false
            material.lightingModel = .lambert
            material.locksAmbientWithDiffuse = true
        }
    }
    
    private func getFaceValue(faceIndex: Int) -> Int {
        // Standard dice: opposite faces sum to 7
        // When showing value 1, top face is 1, bottom is 6, etc.
        // This is a simplified mapping - in real dice, orientation matters
        // Opposite pairs: (0,1) Right-Left, (2,3) Top-Bottom, (4,5) Front-Back
        
        // For now, we'll show the dice value on the top face (index 2)
        // and distribute other values logically
        switch faceIndex {
        case 2:  // Top
            return diceValue
        case 3:  // Bottom
            return 7 - diceValue
        default:
            // Other faces get values 1-6 excluding top and bottom
            let otherValues = [1, 2, 3, 4, 5, 6].filter { $0 != diceValue && $0 != (7 - diceValue) }
            return otherValues[faceIndex % otherValues.count]
        }
    }
    
    private func createDotMaterial() -> UIColor {
        return UIColor.black
    }
    
    private func createFaceTexture(value: Int, dotMaterial: UIColor) -> UIImage {
        let size: CGFloat = 256  // Reasonable resolution
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        
        // White background
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        
        // Draw border
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(2)
        context.stroke(CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        
        // Draw dots based on value
        let dotRadius: CGFloat = size * 0.12
        let spacing: CGFloat = size * 0.25
        let center = CGPoint(x: size / 2, y: size / 2)
        
        context.setFillColor(dotMaterial.cgColor)
        
        switch value {
        case 1:
            // Center dot
            context.fillEllipse(in: CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            
        case 2:
            // Top-left and bottom-right
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            
        case 3:
            // Top-left, center, bottom-right
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            
        case 4:
            // Four corners
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            
        case 5:
            // Four corners + center
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            
        case 6:
            // Two columns of three
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fillEllipse(in: CGRect(
                x: size - spacing - dotRadius,
                y: size - spacing - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            
        default:
            break
        }
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return UIImage()
        }
        
        return image
    }
    
    
    // MARK: - Animation
    
    private func startRollingAnimation() {
        // Create continuous rotation animation
        let rotateAction = SCNAction.rotateBy(
            x: CGFloat.random(in: 0...2 * .pi),
            y: CGFloat.random(in: 0...2 * .pi),
            z: CGFloat.random(in: 0...2 * .pi),
            duration: 0.1
        )
        rollingAction = SCNAction.repeatForever(rotateAction)
        
        if let action = rollingAction {
            runAction(action, forKey: "rolling")
        }
    }
    
    private func stopRollingAnimation() {
        removeAction(forKey: "rolling")
        rollingAction = nil
    }
    
    // MARK: - Physics Roll
    
    /// Apply physics-based roll animation
    func applyRollImpulse() {
        guard let physicsBody = physicsBody else { return }
        
        // Random impulse for rolling
        let impulse = SCNVector3(
            Float.random(in: -2...2),
            Float.random(in: 3...5),  // Upward force
            Float.random(in: -2...2)
        )
        physicsBody.applyForce(impulse, asImpulse: true)
        
        // Random angular velocity
        let angularVelocity = SCNVector4(
            Float.random(in: -5...5),
            Float.random(in: -5...5),
            Float.random(in: -5...5),
            Float.random(in: 5...10)
        )
        physicsBody.angularVelocity = angularVelocity
    }
}

