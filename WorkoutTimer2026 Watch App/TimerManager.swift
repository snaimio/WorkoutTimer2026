//
//  TimerManager.swift
//  WorkoutTimer2026 Watch App
//
//  Created by Sheikh Naim on 2026-06-15.
//

import Foundation
import Combine
import UserNotifications
import WatchKit

@MainActor
final class TimerManager: ObservableObject {
    
    // MARK: - Published for UI
    @Published private(set) var duration: TimeInterval
    @Published private(set) var remaining: TimeInterval
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var progress: Double = 0.0
    
    // MARK: - Private properties
    private var timerTask: Task<Void, Never>?
    private var startDate: Date?
    private var pausedRemaining: TimeInterval?
    
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
        
        // If we're resuming from pause
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
        updateProgress()
        removePendingCompletionNotification()
    }
    
    func toggle() {
        isRunning ? pause() : start()
    }
    
    // MARK: - Private timer loop
    
    private func runTimerLoop() async {
        guard let startDate = startDate else { return }
        
        while isRunning && remaining > 0 {
            let elapsed = Date().timeIntervalSince(startDate)
            let newRemaining = max(0, duration - elapsed)
            
            await MainActor.run {
                self.remaining = newRemaining
                self.updateProgress()
                
                // Last 10 seconds countdown haptic
                if newRemaining > 0 && newRemaining <= 10 && newRemaining.rounded() == newRemaining {
                    self.playCountdownHaptic()
                }
            }
            
            if newRemaining <= 0 {
                await timerCompleted()
                break
            }
            
            // Sleep for 0.1 seconds for smooth updates
            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                break // Task cancelled
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
            WKInterfaceDevice.current().play(.notification)
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
    
    private func playCountdownHaptic() {
        WKInterfaceDevice.current().play(.notification)
    }
    
    // MARK: - Notifications
    
    private func scheduleCompletionNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Workout Timer"
            content.body = "Timer finished! Great work! 💪"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, self.remaining), repeats: false)
            let request = UNNotificationRequest(identifier: "WorkoutTimerCompletion", content: content, trigger: trigger)
            center.add(request)
        }
    }
    
    private func removePendingCompletionNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["WorkoutTimerCompletion"])
    }
    
    private func sendImmediateNotification() async {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Workout Complete! 🎉"
        content.body = "Your workout timer has finished."
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
        let totalSeconds = Int(max(0, ceil(remaining)))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
