//
//  DiceMaterialManager.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SceneKit
import UIKit

/// Manager for dice materials and textures
class DiceMaterialManager {
    // MARK: - Properties
    
    static let shared = DiceMaterialManager()
    
    private var materialCache: [String: SCNMaterial] = [:]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Material Creation
    
    /// Get or create material for dice face
    func getDiceMaterial(theme: AppTheme = .standard) -> SCNMaterial {
        let cacheKey = theme.rawValue
        
        if let cached = materialCache[cacheKey] {
            return cached
        }
        
        let material = createMaterial(for: theme)
        materialCache[cacheKey] = material
        return material
    }
    
    private func createMaterial(for theme: AppTheme) -> SCNMaterial {
        let material = SCNMaterial()
        
        switch theme {
        case .standard:
            material.diffuse.contents = UIColor.white
            material.specular.contents = UIColor(white: 0.8, alpha: 1.0)
            material.shininess = 0.5
            
        case .dark:
            material.diffuse.contents = UIColor.darkGray
            material.specular.contents = UIColor(white: 0.6, alpha: 1.0)
            material.shininess = 0.3
            
        case .colorful:
            material.diffuse.contents = UIColor.systemPurple.withAlphaComponent(0.3)
            material.specular.contents = UIColor.systemPurple
            material.shininess = 0.7
            
        case .classic:
            material.diffuse.contents = UIColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0)
            material.specular.contents = UIColor(white: 0.7, alpha: 1.0)
            material.shininess = 0.4
        }
        
        return material
    }
    
    /// Clear material cache
    func clearCache() {
        materialCache.removeAll()
    }
}



