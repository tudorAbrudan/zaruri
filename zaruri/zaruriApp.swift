//
//  zaruriApp.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import UIKit

@main
struct zaruriApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    FeedbackManager.shared.checkForUpdate()
                    ReviewRequestManager.shared.trackLaunch()
                }
        }
    }
}
