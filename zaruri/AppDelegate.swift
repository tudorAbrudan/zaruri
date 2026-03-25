//
//  AppDelegate.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import UIKit

/// UIKit app delegate used only to control global behaviours such as orientation.
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Lock the app in portrait mode only.
        return .portrait
    }
}

