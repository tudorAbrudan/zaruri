//
//  ReviewRequestManager.swift
//  zaruri
//

import Foundation
import StoreKit
import UIKit

/// Manages the App Store review request flow with sentiment gating.
///
/// Flow:
/// 1. `trackRoll()` is called after every classic dice roll.
/// 2. When all conditions are met, sets `showReviewPrompt = true`.
/// 3. `ReviewPromptView` shows a custom pre-prompt ("Îți place Zaruri?").
/// 4. If user taps "Da" → `requestReviewFromSystem()` → SKStoreReviewController.
/// 5. If user taps "Am o sugestie" → redirect to email feedback.
final class ReviewRequestManager: ObservableObject {

    static let shared = ReviewRequestManager()

    @Published var showReviewPrompt: Bool = false

    // MARK: - Thresholds

    private static let requiredActiveDays = 3
    private static let minimumTotalRolls  = 10
    private static let maxRequestsPerYear = 3
    private static let cooldownDays       = 120

    // MARK: - Private State

    private let stateKey = "reviewRequestState"
    /// Prevents showing the prompt more than once per app session.
    private var hasShownInCurrentSession = false

    private init() {}

    // MARK: - Public API

    /// Call once at app launch (hook for future version-reset logic).
    func trackLaunch() {}

    /// Call after every classic dice roll. Records the active day, increments roll
    /// counter, and shows the pre-prompt if all conditions are met.
    func trackRoll() {
        var state = loadState()
        let today = dayString(from: Date())
        state.activeDays.insert(today)
        state.totalRolls += 1
        saveState(state)

        guard canShowPrompt(state: state) else { return }
        hasShownInCurrentSession = true
        Task { @MainActor in
            // Small delay so the dice animation finishes before the prompt appears.
            try? await Task.sleep(for: .milliseconds(900))
            showReviewPrompt = true
        }
    }

    /// Called when user taps "Da, las o recenzie" in ReviewPromptView.
    /// Saves the request timestamp and calls the system review dialog.
    func requestReviewFromSystem() {
        var state = loadState()
        state.requestCount += 1
        state.lastRequestDate = Date()
        saveState(state)

        if #available(iOS 14.0, *) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            SKStoreReviewController.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview()
        }
    }

    // MARK: - Condition Check

    private func canShowPrompt(state: ReviewState) -> Bool {
        guard !hasShownInCurrentSession else { return false }
        guard state.activeDays.count >= Self.requiredActiveDays else { return false }
        guard state.totalRolls >= Self.minimumTotalRolls else { return false }
        guard state.requestCount < Self.maxRequestsPerYear else { return false }
        if let lastDate = state.lastRequestDate {
            let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard days >= Self.cooldownDays else { return false }
        }
        return true
    }

    // MARK: - Persistence

    private func dayString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func loadState() -> ReviewState {
        guard let data = UserDefaults.standard.data(forKey: stateKey),
              let state = try? JSONDecoder().decode(ReviewState.self, from: data)
        else { return ReviewState() }
        return state
    }

    private func saveState(_ state: ReviewState) {
        guard let encoded = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(encoded, forKey: stateKey)
    }
}
