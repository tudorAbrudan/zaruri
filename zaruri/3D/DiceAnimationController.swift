//
//  DiceAnimationController.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SceneKit
import Foundation

/// Controller for managing dice rolling animations
class DiceAnimationController {
    // MARK: - Properties
    
    static let shared = DiceAnimationController()
    
    private let animationDuration: TimeInterval = 0.5
    private let bounceHeight: CGFloat = 0.5
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Animation Methods
    
    /// Create a rolling animation for a dice node
    func createRollAnimation(for node: SCNNode) -> SCNAction {
        // Combine rotation and bounce
        let rotate = SCNAction.rotateBy(
            x: CGFloat.random(in: 0...2 * .pi),
            y: CGFloat.random(in: 0...2 * .pi),
            z: CGFloat.random(in: 0...2 * .pi),
            duration: animationDuration
        )
        
        let bounce = SCNAction.sequence([
            SCNAction.moveBy(x: 0, y: bounceHeight, z: 0, duration: animationDuration / 2),
            SCNAction.moveBy(x: 0, y: -bounceHeight, z: 0, duration: animationDuration / 2),
        ])
        
        return SCNAction.group([rotate, bounce])
    }
    
    /// Create a physics-based roll with impulse
    func applyPhysicsRoll(to node: SCNNode) {
        guard let physicsBody = node.physicsBody else { return }
        
        // Random upward impulse
        let impulse = SCNVector3(
            Float.random(in: -1...1),
            Float.random(in: 2...4),
            Float.random(in: -1...1)
        )
        physicsBody.applyForce(impulse, asImpulse: true)
        
        // Random angular velocity for spinning
        let angularVelocity = SCNVector4(
            Float.random(in: -3...3),
            Float.random(in: -3...3),
            Float.random(in: -3...3),
            Float.random(in: 3...6)
        )
        physicsBody.angularVelocity = angularVelocity
    }
    
    /// Reset dice position and rotation
    func resetDice(_ node: SCNNode) {
        node.position = SCNVector3(0, 0, 0)
        node.rotation = SCNVector4(0, 0, 0, 0)
        
        if let physicsBody = node.physicsBody {
            physicsBody.velocity = SCNVector3(0, 0, 0)
            physicsBody.angularVelocity = SCNVector4(0, 0, 0, 0)
        }
    }
}

