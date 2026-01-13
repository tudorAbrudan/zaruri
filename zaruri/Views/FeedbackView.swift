//
//  FeedbackView.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import SwiftUI
import UIKit

/// UITextView wrapper for iOS 13 compatibility
struct MultilineTextView: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.delegate = context.coordinator
        textView.backgroundColor = UIColor.systemBackground
        textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextView
        
        init(_ parent: MultilineTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}

/// View for submitting feedback
struct FeedbackView: View {
    @ObservedObject var feedbackManager: FeedbackManager
    @Environment(\.presentationMode) var presentationMode
    @State private var feedbackText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .padding(.top, 30)
                
                // Title and message
                VStack(spacing: 12) {
                    Text("Feedback pentru ZARURI")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Ne-ar ajuta să știm părerea ta despre aplicație. Trimite-ne feedback-ul tău!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Text editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mesajul tău:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    MultilineTextView(text: $feedbackText)
                        .frame(minHeight: 150)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    // Submit button
                    Button(action: {
                        feedbackManager.submitFeedback(text: feedbackText)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Trimite Feedback")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? [Color.gray, Color.gray.opacity(0.8)]
                                        : [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    
                    // Postpone button
                    Button(action: {
                        feedbackManager.postponeFeedback()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Poate mai târziu")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                feedbackManager.showFeedbackView = false
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            })
        }
    }
}

