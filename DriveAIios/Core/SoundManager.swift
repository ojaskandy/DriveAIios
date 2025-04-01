//
//  SoundManager.swift
//  CruiseAIios
//
//  Created by Ojas Kandhare on 3/28/25.
//

import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    // Audio players for each sound type
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    // Cooldown tracking
    private var lastPlayedTimes: [String: Date] = [:]
    private let soundCooldown: TimeInterval = 3.0 // 3 seconds cooldown between sounds of the same type
    
    // Audio session
    private let audioSession = AVAudioSession.sharedInstance()
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            // Configure audio session for playback that overrides silent mode and Do Not Disturb
            try audioSession.setCategory(AVAudioSession.Category.playback, 
                                        mode: AVAudioSession.Mode.default, 
                                        options: [.duckOthers, .interruptSpokenAudioAndMixWithOthers])
            
            // Override silent switch
            try audioSession.setCategory(AVAudioSession.Category.playback, 
                                        options: [.mixWithOthers, .duckOthers, .interruptSpokenAudioAndMixWithOthers])
            
            // Override Do Not Disturb
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Make audio session active with high priority
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        // List of sound files to preload
        let soundFiles = [
            "traffic_light",
            "stop_sign",
            "person",
            "parking_meter"
        ]
        
        // Preload each sound file
        for soundFile in soundFiles {
            if let soundURL = Bundle.main.url(forResource: soundFile, withExtension: "wav", subdirectory: "Resources/Sounds") {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    audioPlayers[soundFile] = player
                    print("Preloaded sound: \(soundFile)")
                } catch {
                    print("Failed to preload sound \(soundFile): \(error)")
                }
            } else {
                print("Sound file not found: \(soundFile)")
            }
        }
    }
    
    // Play a sound by name with cooldown
    func playSound(named soundName: String, ignoreCooldown: Bool = false) {
        // Check if safety mode is enabled
        if !UserPreferencesService.shared.isSafetyModeEnabled {
            print("Safety mode disabled, not playing sound: \(soundName)")
            return
        }
        
        // Check if the sound is in cooldown
        if let lastPlayed = lastPlayedTimes[soundName] {
            let timeSinceLastPlayed = Date().timeIntervalSince(lastPlayed)
            if timeSinceLastPlayed < soundCooldown {
                // Sound is in cooldown, don't play it again yet
                print("Sound \(soundName) in cooldown (\(timeSinceLastPlayed) seconds since last played)")
                return
            }
        }
        
        // Update the last played time for this sound
        lastPlayedTimes[soundName] = Date()
        
        // Check if we have a preloaded player for this sound
        if let player = audioPlayers[soundName] {
            // Reset player to start
            player.currentTime = 0
            player.play()
            print("Playing sound: \(soundName)")
        } else {
            // Try to load and play the sound on demand
            if let soundURL = Bundle.main.url(forResource: soundName, withExtension: "wav", subdirectory: "Resources/Sounds") {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.prepareToPlay()
                    player.play()
                    
                    // Cache the player for future use
                    audioPlayers[soundName] = player
                    
                    print("Playing sound (on demand): \(soundName)")
                } catch {
                    print("Failed to play sound \(soundName): \(error)")
                    playSystemSound(for: soundName)
                }
            } else {
                print("Sound file not found: \(soundName)")
                playSystemSound(for: soundName)
            }
        }
    }
    
    // Play a system sound as fallback
    private func playSystemSound(for soundName: String) {
        // Map sound names to system sound IDs
        // Using more melodic and pleasant system sounds
        let systemSoundID: SystemSoundID
        
        switch soundName {
        case "traffic_light":
            systemSoundID = 1396 // Melodic ascending tone
        case "stop_sign":
            systemSoundID = 1394 // Gentle but attention-getting tone
        case "person":
            systemSoundID = 1375 // Warm, human-like tone
        case "parking_meter":
            systemSoundID = 1366 // Light, delicate tone
        default:
            systemSoundID = 1000 // Default system sound
        }
        
        // Update the last played time for this sound to maintain cooldown
        lastPlayedTimes[soundName] = Date()
        
        AudioServicesPlaySystemSound(systemSoundID)
    }
    
    // Play collision warning sound - extremely loud and annoying beep
    func playCollisionWarningSound() {
        // Always play collision warnings regardless of safety mode setting
        // This is a critical safety feature
        
        // Use system sound for urgent warning with strong haptic feedback
        AudioServicesPlaySystemSound(1521) // Strong haptic feedback
        
        // Play multiple urgent audio alerts in sequence for maximum attention
        DispatchQueue.global(qos: .userInteractive).async {
            // Play first alert
            AudioServicesPlaySystemSound(1005) // System sound ID for a loud alert
            Thread.sleep(forTimeInterval: 0.2)
            
            // Play second alert
            AudioServicesPlaySystemSound(1057) // Another attention-grabbing sound
            Thread.sleep(forTimeInterval: 0.2)
            
            // Play third alert
            AudioServicesPlaySystemSound(1005) // Repeat first alert
        }
        
        // Use speech synthesis for "BRAKE NOW" command with maximum volume and urgency
        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: "Brake now! Brake now!")
        utterance.rate = 0.5
        utterance.volume = 1.0
        utterance.pitchMultiplier = 0.7 // Lower pitch for more urgency
        utterance.postUtteranceDelay = 0.5 // Pause after speaking
        synthesizer.speak(utterance)
        
        // Schedule another utterance after a short delay for repetition
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let repeatUtterance = AVSpeechUtterance(string: "Danger! Brake immediately!")
            repeatUtterance.rate = 0.5
            repeatUtterance.volume = 1.0
            repeatUtterance.pitchMultiplier = 0.7
            synthesizer.speak(repeatUtterance)
        }
    }
    
    // Stop all sounds
    func stopAllSounds() {
        for player in audioPlayers.values {
            if player.isPlaying {
                player.stop()
            }
        }
    }
}
