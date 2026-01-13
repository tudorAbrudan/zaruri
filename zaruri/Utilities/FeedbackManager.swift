//
//  FeedbackManager.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import Foundation
import UserNotifications
import UIKit

/// Manager for feedback system and notifications
class FeedbackManager: ObservableObject {
    // MARK: - Properties
    
    static let shared = FeedbackManager()
    
    @Published var showFeedbackView: Bool = false
    
    private let feedbackStateKey = "feedbackState"
    private let feedbackNotificationIdentifier = "zaruri.feedback.reminder"
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Feedback State Management
    
    /// Load feedback state from UserDefaults
    private func loadFeedbackState() -> FeedbackState {
        guard let data = UserDefaults.standard.data(forKey: feedbackStateKey),
              let state = try? JSONDecoder().decode(FeedbackState.self, from: data) else {
            return FeedbackState()
        }
        return state
    }
    
    /// Save feedback state to UserDefaults
    private func saveFeedbackState(_ state: FeedbackState) {
        guard let encoded = try? JSONEncoder().encode(state) else {
            return
        }
        UserDefaults.standard.set(encoded, forKey: feedbackStateKey)
    }
    
    // MARK: - App Version Detection
    
    /// Check if this is a new installation or update
    func checkForUpdate() {
        var state = loadFeedbackState()
        
        let currentVersion = getAppVersion()
        let currentBuild = getBuildNumber()
        
        // Check if first launch
        if state.firstLaunchDate == nil {
            state.firstLaunchDate = Date()
            state.lastAppVersion = currentVersion
            state.lastBuildNumber = currentBuild
            saveFeedbackState(state)
            
            // Schedule notification for 3 days
            scheduleFeedbackNotification()
            return
        }
        
        // Check if version changed (update)
        if state.lastAppVersion != currentVersion || state.lastBuildNumber != currentBuild {
            // This is an update
            state.lastAppVersion = currentVersion
            state.lastBuildNumber = currentBuild
            saveFeedbackState(state)
            
            // Schedule notification for 3 days after update
            scheduleFeedbackNotification()
        }
    }
    
    // MARK: - Feedback Display Logic
    
    /// Check if feedback should be shown automatically
    func shouldShowFeedbackAutomatically() -> Bool {
        let state = loadFeedbackState()
        
        // Don't show if already submitted
        if state.feedbackSubmitted {
            return false
        }
        
        // Don't show if postponed 3 times
        if state.feedbackPostponedCount >= 3 {
            return false
        }
        
        // Check if 3 days have passed since first launch or last shown
        guard let firstLaunch = state.firstLaunchDate else {
            return false
        }
        
        let daysSinceFirstLaunch = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
        
        if daysSinceFirstLaunch < 3 {
            return false
        }
        
        // Check if 3 days have passed since last shown
        if let lastShown = state.lastFeedbackShownDate {
            let daysSinceLastShown = Calendar.current.dateComponents([.day], from: lastShown, to: Date()).day ?? 0
            if daysSinceLastShown < 3 {
                return false
            }
        }
        
        return true
    }
    
    /// Show feedback view
    func showFeedback() {
        var state = loadFeedbackState()
        state.lastFeedbackShownDate = Date()
        saveFeedbackState(state)
        
        showFeedbackView = true
    }
    
    /// Postpone feedback (max 3 times)
    func postponeFeedback() {
        var state = loadFeedbackState()
        
        if state.feedbackPostponedCount < 3 {
            state.feedbackPostponedCount += 1
            state.lastFeedbackShownDate = Date()
            saveFeedbackState(state)
        }
        
        showFeedbackView = false
    }
    
    /// Submit feedback
    func submitFeedback(text: String) {
        var state = loadFeedbackState()
        state.feedbackSubmitted = true
        state.lastFeedbackShownDate = Date()
        saveFeedbackState(state)
        
        // Cancel any scheduled notifications
        cancelScheduledNotifications()
        
        // Open email with feedback
        openFeedbackEmail(feedbackText: text)
        
        showFeedbackView = false
    }
    
    // MARK: - Email
    
    /// Open email client with feedback
    private func openFeedbackEmail(feedbackText: String) {
        let email = "apps.tudor@gmail.com"
        let subject = "[ZARURI] Feedback"
        let deviceInfo = getDeviceInfo()
        let body = """
        \(feedbackText)
        
        ---
        Device Info:
        \(deviceInfo)
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // MARK: - Device Info
    
    /// Get device information string
    func getDeviceInfo() -> String {
        let device = UIDevice.current
        let model = device.model
        let systemVersion = device.systemVersion
        let appVersion = getAppVersion()
        let buildNumber = getBuildNumber()
        
        return """
        Model: \(model)
        iOS Version: \(systemVersion)
        App Version: \(appVersion)
        Build: \(buildNumber)
        """
    }
    
    /// Get app version
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Get build number
    private func getBuildNumber() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    // MARK: - Notifications
    
    /// Request notification permissions
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule feedback notification for 3 days
    func scheduleFeedbackNotification() {
        // Cancel existing notification
        cancelScheduledNotifications()
        
        // Check if feedback already submitted
        let state = loadFeedbackState()
        if state.feedbackSubmitted {
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "ZARURI"
        content.body = "Ai ceva feedback pentru aplicație? Ne-ar ajuta să știm părerea ta!"
        content.sound = .default
        content.userInfo = ["type": "feedback"]
        
        // Schedule for 3 days from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3 * 24 * 60 * 60, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: feedbackNotificationIdentifier,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancel scheduled notifications
    func cancelScheduledNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [feedbackNotificationIdentifier]
        )
    }
    
    /// Handle notification tap
    func handleNotificationTap() {
        // Cancel notification if app is opened
        cancelScheduledNotifications()
        
        // Show feedback view
        showFeedback()
    }
}

