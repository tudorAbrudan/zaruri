//
//  SpeechManager.swift
//  zaruri
//

import AVFoundation
import UIKit

/// Manager for speaking text aloud (e.g. current player name in turn-based mode)
final class SpeechManager {
    static let shared = SpeechManager()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    /// Speak the given text in Romanian (or system language fallback)
    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.95
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        // Prefer Romanian for player names
        utterance.voice = AVSpeechSynthesisVoice(language: "ro-RO") ?? AVSpeechSynthesisVoice(language: "ro") ?? AVSpeechSynthesisVoice()
        
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }
    
    /// Stop any current speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
