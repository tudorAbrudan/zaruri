//
//  ReviewPromptView.swift
//  zaruri
//

import SwiftUI
import UIKit

/// Sentiment-gating pre-prompt shown before the system App Store review dialog.
///
/// "Da" → triggers SKStoreReviewController via ReviewRequestManager.
/// "Am o sugestie" → opens email feedback, bypasses the App Store dialog.
struct ReviewPromptView: View {
    @ObservedObject var reviewManager: ReviewRequestManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Text("⭐️")
                        .font(.system(size: 40))
                }
                .padding(.top, 16)

                // Text
                VStack(spacing: 10) {
                    Text("Îți place Zaruri?")
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text("Ne-ar ajuta mult o recenzie scurtă pe App Store. Durează mai puțin de un minut.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                        // Small delay so the sheet dismiss animation finishes first.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            reviewManager.requestReviewFromSystem()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                            Text("Da, las o recenzie")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        dismiss()
                        openFeedbackEmail()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 15))
                            Text("Am o sugestie")
                                .font(.system(size: 15, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemBackground))
    }

    // MARK: - Feedback Email

    private func openFeedbackEmail() {
        let email = "apps.tudor@gmail.com"
        let subject = "[ZARURI] Sugestie"
        guard let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)"),
              UIApplication.shared.canOpenURL(url)
        else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ReviewPromptView(reviewManager: ReviewRequestManager.shared)
        .presentationDetents([.height(380)])
}
