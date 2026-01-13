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
        
        // Initialize feedback system
        FeedbackManager.shared.requestNotificationPermissions()
        FeedbackManager.shared.checkForUpdate()
        
        // Check if should show feedback automatically
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if FeedbackManager.shared.shouldShowFeedbackAutomatically() {
                FeedbackManager.shared.showFeedback()
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // No action needed
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Cancel notification if app is opened
        FeedbackManager.shared.cancelScheduledNotifications()
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

