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
    @State private var showingDurationPicker = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Timer display
            Text(timerManager.formattedRemaining())
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(timerManager.remaining <= 10 ? .red : .white)
            
            // Progress bar
            ProgressView(value: timerManager.progress)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(0.8)
            
            // Control buttons
            HStack(spacing: 15) {
                Button(action: { timerManager.toggle() }) {
                    Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                
                Button(action: { timerManager.reset() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                
                Button(action: { showingDurationPicker.toggle() }) {
                    Image(systemName: "clock")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .sheet(isPresented: $showingDurationPicker) {
            DurationPickerView(timerManager: timerManager)
        }
        .onAppear {
            requestNotificationPermissions()
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}

struct DurationPickerView: View {
    @ObservedObject var timerManager: TimerManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedMinutes = 1
    @State private var selectedSeconds = 0
    
    var body: some View {
        VStack {
            Text("Set Duration")
                .font(.headline)
                .padding(.top)
            
            HStack {
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(0...59, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
                
                Picker("Seconds", selection: $selectedSeconds) {
                    ForEach([0, 15, 30, 45], id: \.self) { second in
                        Text("\(second) sec").tag(second)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80)
            }
            
            Button("Set Timer") {
                let totalSeconds = TimeInterval(selectedMinutes * 60 + selectedSeconds)
                timerManager.setDuration(max(1, totalSeconds))
                dismiss()
            }
            .buttonStyle(.bordered)
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
