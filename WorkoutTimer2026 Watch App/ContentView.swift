//
//  ContentView.swift
//  WorkoutTimer2026 Watch App
//
//  Created by Douglas Jasper on 2026-06-15.
//

import SwiftUI
import UserNotifications
import WatchKit

struct ContentView: View {
    
    @StateObject private var timerManager = TimerManager()
    private let lastPresetKey = "lastSelectedPresetIndex"
    private let lastCustomTimeKey = "lastCustomTimeSeconds"
    
    // Presets
    let presets: [TimeInterval] = [60, 5*60, 10*60, 20*60, 30*60]
    let presetLabels: [String] = ["1m", "5m", "10m", "20m", "30m"]
    
    // Track selected preset index
    @State private var selectedPresetIndex: Int = {
        let saved = UserDefaults.standard.object(forKey: "lastSelectedPresetIndex") as? Int
        return saved ?? 1
    }()
    
    // Custom timer
    @State private var showingCustomTimeSheet = false
    @State private var customMinutes: Int = 1
    @State private var customSeconds: Int = 0
    
    var body: some View {
        VStack(spacing: 4) {
            // MARK: - Segmented Pills + Custom
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    // Preset pills
                    ForEach(0..<presetLabels.count, id: \.self) { idx in
                        Button(action: {
                            withAnimation {
                                selectedPresetIndex = idx
                                timerManager.setDuration(presets[idx])
                                UserDefaults.standard.set(idx, forKey: lastPresetKey)
                            }
                        }) {
                            Text(presetLabels[idx])
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .frame(minWidth: 30)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 6)
                                .background(segmentBackground(for: idx))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Custom pill
                    Button(action: {
                        let lastCustom = UserDefaults.standard.integer(forKey: lastCustomTimeKey)
                        customMinutes = lastCustom / 60
                        customSeconds = lastCustom % 60
                        selectedPresetIndex = presets.count
                        showingCustomTimeSheet = true
                    }) {
                        Text("Custom")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .frame(minWidth: 30)
                            .padding(.vertical, 3)
                            .padding(.horizontal, 6)
                            .background(selectedPresetIndex >= presets.count ? Color.accentColor : Color.clear)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 2)
            }
            .frame(height: 28)
            
            Spacer(minLength: 2)
            
            // MARK: - Timer display
            Text(timerManager.formattedRemaining())
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundColor(timerManager.remaining <= 10 ? .red : .white)
                .frame(height: 45)
            
            // MARK: - Progress ring
            ProgressView(value: timerManager.progress)
                .progressViewStyle(CircularProgressViewStyle(tint: timerManager.remaining <= 10 ? .red : .green))
                .scaleEffect(0.9)
                .frame(width: 55, height: 55)
            
            // MARK: - Controls (Fixed Button Sizing)
            HStack(spacing: 8) {
                Button(action: { timerManager.toggle() }) {
                    HStack {
                        Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 14))
                        Text(timerManager.isRunning ? "Pause" : "Start")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(minWidth: 60, maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: { timerManager.reset() }) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14))
                        Text("Reset")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(minWidth: 60, maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .sheet(isPresented: $showingCustomTimeSheet) {
            customTimerSheet
        }
        .onAppear {
            loadLastTimer()
            requestNotificationPermissionIfNeeded()
        }
    }
    
    // MARK: - Custom Timer Sheet
    
    private var customTimerSheet: some View {
        VStack(spacing: 12) {
            Text("Custom Timer")
                .font(.subheadline)
                .padding(.top, 4)
            
            HStack(spacing: 16) {
                // Minutes Picker
                VStack {
                    Text("Min")
                        .font(.caption2)
                    Picker("", selection: $customMinutes) {
                        ForEach(0..<121) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 45, height: 80)
                    .clipped()
                }
                VStack {
                    Text("Sec")
                        .font(.caption2)
                    Picker("", selection: $customSeconds) {
                        ForEach(0..<60) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 45, height: 80)
                    .clipped()
                }
            }
            
            HStack(spacing: 12) {
                Button("Set Timer") {
                    showingCustomTimeSheet = false
                    let totalSeconds = TimeInterval(customMinutes * 60 + customSeconds)
                    timerManager.setDuration(totalSeconds)
                    UserDefaults.standard.set(totalSeconds, forKey: lastCustomTimeKey)
                    selectedPresetIndex = presets.count
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    showingCustomTimeSheet = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func segmentBackground(for index: Int) -> some View {
        ZStack {
            if selectedPresetIndex == index {
                Capsule().fill(Color.accentColor)
            } else {
                Capsule()
                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                    .background(Capsule().fill(Color.clear))
            }
        }
    }
    
    private func loadLastTimer() {
        if selectedPresetIndex < presets.count {
            timerManager.setDuration(presets[selectedPresetIndex])
        } else {
            let lastCustom = UserDefaults.standard.double(forKey: lastCustomTimeKey)
            if lastCustom > 0 {
                timerManager.setDuration(lastCustom)
            } else {
                timerManager.setDuration(presets[1])
                selectedPresetIndex = 1
            }
        }
    }
    
    private func requestNotificationPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus != .authorized else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
