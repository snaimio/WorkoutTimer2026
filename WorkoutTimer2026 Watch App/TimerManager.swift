//  TimerManager.swift
//  WorkoutTimer2026 Watch App

//  Created by Sheikh Naim on 2026-06-15.

import Foundation
import Combine
import UserNotifications
import WatchKit
import AVFoundation

@preconcurrency import UserNotifications

@MainActor
final class TimerManager: ObservableObject {
    
    // MARK: - Published for UI
    @Published private(set) var duration: TimeInterval
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var progress: Double = 0.0
    
    // MARK: - Private
    private var timerTask: Task<Void, Never>?
    private var startDate: Date?
    private var pausedRemaining: TimeInterval?
    private var lastPlayedSecond: Int = -1
    
    init(duration: TimeInterval = 60) {
        self.duration = duration
        self.remaining = duration
        self.updateProgress()
    }
    
    // MARK: - Public API
    
    func setDuration(_ seconds: TimeInterval) {
        guard !isRunning else { return }
        duration = max(1, seconds)
        remaining = duration
        updateProgress()
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        lastPlayedSecond = -1
        
        if let pausedRemaining = pausedRemaining {
            remaining = pausedRemaining
            self.pausedRemaining = nil
        }
        
        startDate = Date()
        scheduleCompletionNotification()
        
        timerTask = Task { [weak self] in
            await self?.runTimerLoop()
        }
    }
    
    func pause() {
        guard isRunning else { return }
        isRunning = false
        pausedRemaining = remaining
        timerTask?.cancel()
        timerTask = nil
        removePendingCompletionNotification()
    }
    
    func reset() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
        remaining = duration
        pausedRemaining = nil
        lastPlayedSecond = -1
        updateProgress()
        removePendingCompletionNotification()
    }
    
    func toggle() {
        isRunning ? pause() : start()
    }
    
    // MARK: - Private Timer Loop
    
    private func runTimerLoop() async {
        guard let startDate = startDate else { return }
        
        while isRunning && remaining > 0 {
            let elapsed = Date().timeIntervalSince(startDate)
            let newRemaining = max(0, duration - elapsed)
            
            await MainActor.run {
                self.remaining = newRemaining
                self.updateProgress()
                
                // LAST 10 SECONDS COUNTDOWN - SOUND + HAPTICS
                if newRemaining > 0 && newRemaining <= 10 {
                    let currentSecond = Int(ceil(newRemaining))
                    if currentSecond != self.lastPlayedSecond {
                        self.lastPlayedSecond = currentSecond
                        self.playCountdownAlert()  // SOUND + HAPTIC every second
                    }
                }
            }
            
            if newRemaining <= 0 {
                await timerCompleted()
                break
            }
            
            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                break
            }
        }
        
        await MainActor.run {
            self.isRunning = false
            self.timerTask = nil
        }
    }
    
    private func timerCompleted() async {
        await MainActor.run {
            self.remaining = 0
            self.updateProgress()
            self.playCompletionAlert()  // SOUND + HAPTICS at completion
        }
        await sendImmediateNotification()
    }
    
    private func updateProgress() {
        if duration <= 0 {
            progress = 0
        } else {
            progress = max(0, min(1.0, 1.0 - (remaining / duration)))
        }
    }
    
    // MARK: - Sound + Haptic Feedback
    
    private func playCountdownAlert() {
        // HAPTICS (vibration)
        WKInterfaceDevice.current().play(.notification)
        
        // SOUND using notification (works on simulator and device)
        playSoundViaNotification()
    }
    
    private func playCompletionAlert() {
        // HAPTICS (vibration)
        WKInterfaceDevice.current().play(.notification)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            WKInterfaceDevice.current().play(.notification)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            WKInterfaceDevice.current().play(.success)
        }
        
        // SOUND (completion)
        playSoundViaNotification()
        
        // Play second sound after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.playSoundViaNotification()
        }
    }
    
    private func playSoundViaNotification() {
        // Use notification sound - works on both simulator and real device
        let content = UNMutableNotificationContent()
        content.sound = .default
        content.title = ""
        content.body = ""
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "beep-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to play sound: \(error)")
            }
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleCompletionNotification() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Workout Timer"
            content.body = "Timer finished! 💪"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, self.remaining), repeats: false)
            let request = UNNotificationRequest(identifier: "WorkoutTimerCompletion", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
    
    private func removePendingCompletionNotification() {
        Task { @MainActor in
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["WorkoutTimerCompletion"])
        }
    }
    
    private func sendImmediateNotification() async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Workout Complete! 🎉"
        content.body = "Your timer has completed."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "WorkoutTimerImmediate-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
    
    // MARK: - Helpers
    
    func formattedRemaining() -> String {
        let sec = Int(max(0, ceil(remaining)))
        let minutes = sec / 60
        let seconds = sec % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
