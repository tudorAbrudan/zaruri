//
//  SceneDelegate.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import UIKit
import SwiftUI

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        let window = UIWindow(windowScene: windowScene)
        let contentView = ContentView()
        window.rootViewController = UIHostingController(rootView: contentView)
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // No action needed
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // No action needed
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // No action needed
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // No action needed
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // No action needed
    }
}

