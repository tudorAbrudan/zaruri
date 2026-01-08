//
//  SoundManager.swift
//  zaruri
//
//  Created by ax on 06.01.2026.
//

import AVFoundation
import UIKit

/// Manager for playing sounds
class SoundManager {
    // MARK: - Properties
    
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isEnabled: Bool = true
    
    // MARK: - Initialization
    
    private init() {
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session setup failed, continue without sound
        }
    }
    
    // MARK: - Sound Control
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    func isSoundEnabled() -> Bool {
        return isEnabled
    }
    
    // MARK: - Sound Playback
    
    /// Play dice roll sound
    func playRollSound() {
        guard isEnabled else { return }
        
        // Use system sound for simplicity (works offline, no file needed)
        AudioServicesPlaySystemSound(1104)  // System sound ID for dice roll effect
    }
    
    /// Play success sound
    func playSuccessSound() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1057)  // Success sound
    }
    
    /// Play error sound
    func playErrorSound() {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(1053)  // Error sound
    }
    
    /// Play custom sound from file
    func playSound(named fileName: String, ofType fileType: String = "caf") {
        guard isEnabled else { return }
        
        let cacheKey = "\(fileName).\(fileType)"
        
        // Check cache
        if let player = audioPlayers[cacheKey] {
            player.currentTime = 0
            player.play()
            return
        }
        
        // Load sound file
        guard let path = Bundle.main.path(forResource: fileName, ofType: fileType) else {
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayers[cacheKey] = player
            player.play()
        } catch {
            // Failed to play sound, continue silently
        }
    }
    
    /// Stop all sounds
    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
    }
}

