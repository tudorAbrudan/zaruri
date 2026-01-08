//
//  DiceSceneKitView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import SceneKit

/// SwiftUI wrapper for SceneKit dice view
struct DiceSceneKitView: UIViewRepresentable {
    let dice: Dice
    let size: CGFloat
    var isRolling: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.allowsCameraControl = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.backgroundColor = UIColor.clear
        sceneView.antialiasingMode = .multisampling4X
        sceneView.isPlaying = true
        sceneView.preferredFramesPerSecond = 60
        
        // Create scene synchronously (SceneKit needs to be initialized on main thread)
        sceneView.scene = createScene()
        
        // Setup camera
        setupCamera(for: sceneView)
        
        // Setup lighting
        if let scene = sceneView.scene {
            setupLighting(for: scene)
        }
        
        // Add dice node
        let diceNode = Dice3DNode(size: size)
        diceNode.diceValue = dice.value
        diceNode.position = SCNVector3(0, 0, 0)
        sceneView.scene?.rootNode.addChildNode(diceNode)
        
        // Store dice node in coordinator
        context.coordinator.diceNode = diceNode
        context.coordinator.sceneView = sceneView
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update dice value
        context.coordinator.diceNode?.diceValue = dice.value
        context.coordinator.diceNode?.isRolling = isRolling
        
        // Apply roll impulse if just started rolling
        if isRolling && !context.coordinator.wasRolling {
            context.coordinator.diceNode?.applyRollImpulse()
        }
        
        context.coordinator.wasRolling = isRolling
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator {
        var diceNode: Dice3DNode?
        var sceneView: SCNView?
        var wasRolling: Bool = false
    }
    
    // MARK: - Scene Setup
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Configure physics world
        scene.physicsWorld.gravity = SCNVector3(0, -9.8, 0)
        scene.physicsWorld.timeStep = 1.0 / 60.0
        
        // Floor removed to avoid FloorPass warning
        // Physics will still work with dice collision
        
        return scene
    }
    
    private func setupCamera(for sceneView: SCNView) {
        let camera = SCNCamera()
        camera.fieldOfView = 60
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 2, 4)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        
        sceneView.scene?.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLighting(for scene: SCNScene) {
        // Ambient light - brighter for better visibility
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.8, alpha: 1.0)  // Increased from 0.6
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // Directional light - brighter
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor(white: 1.0, alpha: 1.0)  // Increased from 0.8
        directionalLight.shadowMode = .forward
        directionalLight.shadowColor = UIColor(white: 0, alpha: 0.3)
        let directionalLightNode = SCNNode()
        directionalLightNode.light = directionalLight
        directionalLightNode.position = SCNVector3(2, 5, 2)
        directionalLightNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalLightNode)
        
        // Additional omni light for better visibility
        let omniLight = SCNLight()
        omniLight.type = .omni
        omniLight.color = UIColor(white: 0.7, alpha: 1.0)
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(-2, 3, -2)
        scene.rootNode.addChildNode(omniLightNode)
    }
}

