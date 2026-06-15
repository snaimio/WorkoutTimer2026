# WorkoutTimer2026 for watchOS

A clean, intuitive workout timer app for Apple Watch with haptic feedback and notification support.

## Features

- ⏱️ Customizable Timer - Set any duration from 1 second to 59 minutes
- 🎯 Circular Progress - Visual progress indicator showing remaining time
- 💪 Haptic Feedback - Gentle taps during the final 10 seconds
- 🔔 Completion Notifications - Alerts you when your workout interval ends
- 🎮 Simple Controls - Play/Pause/Reset buttons for easy control
- 📱 watchOS Optimized - Designed specifically for the Apple Watch interface

## Requirements

- watchOS 9.0 or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Installation

1. Clone the repository
2. Open WorkoutTimer2026.xcodeproj in Xcode
3. Select your Apple Watch as the build target
4. Build and run (⌘R)

## Usage

### Setting the Timer
1. Tap the clock icon button
2. Select minutes and seconds using the pickers
3. Tap "Set Timer"

### Controlling the Timer
- Play - Start the countdown
- Pause - Temporarily stop the timer
- Reset - Reset to the original duration

### During Countdown
- Timer displays minutes: seconds in large format
- Progress circle fills as time elapses
- Haptic feedback occurs every second during the last 10 seconds
- Timer turns red during final 10 seconds for visual warning

### When Timer Completes
- Haptic feedback plays
- Local notification appears on wrist
- Timer stops at 00:00

## Architecture

The app follows the MVVM pattern:
- ContentView - Main UI with timer display and controls
- TimerManager - Business logic for timer state management
- DurationPickerView - Modal view for setting custom durations

## Technical Details

- Uses Task and async/await for timer loop
- UNUserNotificationCenter for reliable background notifications
- WKInterfaceDevice for haptic feedback
- Published properties for SwiftUI reactive updates
- MainActor to ensure UI updates on main thread

## Known Limitations

- Timer may pause when wrist is lowered (watchOS power management)
- Completion notifications still fire accurately when app is suspended
- Maximum timer duration limited to 59 minutes (extendable if needed)

## Future Enhancements

- Multiple timer presets
- Custom haptic patterns
- Interval training (rounds)
- Sound effects option
- History/log of completed workouts
- iCloud sync across devices
- Complications support

## Troubleshooting

**Notifications not working?**
- Ensure notifications are enabled in Watch app settings
- First launch prompts for permission - tap "Allow"

**Timer seems inaccurate?**
- Timer is accurate when wrist is raised
- Background execution may pause, but notifications remain accurate

**No haptic feedback?**
- Check Silent Mode is disabled
- Ensure Wrist Detection is enabled in Watch settings

## Credits

Created by Sheikh Naim

---

Made with ❤️ for Apple Watch
