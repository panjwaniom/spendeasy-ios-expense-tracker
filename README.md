# SpendEasy 💰

A beautiful, intuitive iOS expense tracker that helps you manage your daily spending with smart notifications and insightful visualisations. Built with SwiftUI and Core Data for a seamless, privacy-first experience.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Xcode](https://img.shields.io/badge/Xcode-15.0+-orange.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-red.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Features

- **Quick Expense Tracking:** Add expenses in seconds with predefined categories
- **Interactive Donut Chart:** Tap to select and view category breakdowns with smooth animations
- **Daily & Monthly Views:** Swipe left/right to navigate between days or months
- **Smart Notifications:**
  - Daily reminders at 8 PM to log your expenses
  - Spending milestone alerts (₹10,000 and ₹15,000)
  - End-of-month budget advice based on your spending patterns
  - Monthly comparison to track your progress
- **Clean, Modern UI:** Dark mode optimised with a "Midnight Professional" aesthetic
- **100% Private:** All data stored locally on your device with Core Data
- **Swipe Gestures:** Intuitive navigation to review past expenses

## 📱 Screenshots

_Screenshots will be added here showcasing:_

- Main expense tracking screen with donut chart
- Add expense view with category selection
- Monthly overview with spending trends

### Home Screen
### Add Expense
### Monthly Overview

<p align="center">
  <img src="screenshots/home-screen.png" width="250"/>
  <img src="screenshots/add-expense.png" width="250"/>
  <img src="screenshots/monthly-view.png" width="250"/>
</p>

## 🛠 Tech Stack

- **SwiftUI** - Modern, declarative UI framework
- **Core Data** - Local persistence and data management
- **Swift Charts** - Native charting framework for beautiful visualizations
- **UserNotifications** - Smart spending alerts and reminders

## 📋 Requirements

- **iOS 17.0+** (required for Swift Charts framework)
- **Xcode 15.0+**
- **macOS Ventura or later** (for Xcode 15)

## 🚀 How to Build & Run

### 1. Clone the Repository
```bash
git clone https://github.com/panjwaniom/SpendEasy.git
cd SpendEasy
```

### 2. Open in Xcode
```bash
open SwiftExpenseTracker.xcodeproj
```

### 3. Select Target Device
- In Xcode, select a simulator (e.g., **iPhone 16 Pro**) or connect a physical device
- Ensure the deployment target is set to iOS 17.0 or later

### 4. Build and Run
- Press `Cmd + R` or click the Play button in Xcode
- The app will compile and launch on your selected device/simulator

### 5. Enable Notifications (Important for Testing)
- When the app first launches, allow notifications when prompted
- On simulator: Go to **Settings > Notifications > SpendEasy** and ensure notifications are enabled
- On device: Notifications should work immediately after granting permission

## 🧪 Testing Notes

### Testing Notifications (Developer Guide)

The app includes several types of notifications that trigger based on spending behavior:

#### 1. Daily Reminder (8 PM)
- **Trigger:** Scheduled for 8 PM daily
- **Test:** Change the hour in `NotificationManager.swift` line 26 to the current hour + 1 minute
- **Reset:** Uninstall and reinstall the app to reschedule

#### 2. Spending Milestone Alerts
- **₹10,000 Milestone:** Add expenses totalling ₹10,000+ in the current month
- **₹15,000 Milestone:** Add expenses totalling ₹15,000+ in the current month
- **Test:** Use the "Add Expense" feature to quickly add large amounts
- **Note:** Alerts fire only once per milestone per month (tracked via UserDefaults)

#### 3. End-of-Month Advice
- **Trigger:** Automatically fires when 7 or fewer days remain in the month
- **Test:** Modify the condition in `NotificationManager.swift` line 100 to `daysRemaining <= 30` for immediate testing
- **Content:** Message varies based on spending (under ₹10k, ₹10k-15k, or over ₹15k)

#### 4. Monthly Comparison
- **Trigger:** Fires at the start of a new month
- **Test:** Add expenses in a previous month, then change device date to the 1st of next month
- **Content:** Compares current month to previous month's total

#### Debug Mode for Faster Testing
In `NotificationManager.swift`, line 190, there's a DEBUG flag:
```swift
#if DEBUG
// let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
```
Uncomment the 5-second line to see notifications fire 5 seconds after triggering (useful for rapid testing).

### Testing the Donut Chart
- Add expenses across multiple categories
- Tap individual slices to select/deselect categories
- Tap multiple slices to see combined totals
- The center displays the selected category name(s) and total amount

### Testing Swipe Navigation
- **Daily View:** Swipe left/right on the date header to change days
- **Monthly View:** Swipe left/right on the month header to change months
- Expenses update automatically based on the selected period

## 🏗 Project Structure

```
SwiftExpenseTracker/
├── SpendEasyApp.swift    # App entry point
├── ContentView.swift                # Main expense tracking screen
├── AddExpenseView.swift             # (Legacy - minimal usage)
├── EditExpenseView.swift            # Edit existing expenses
├── DonutChartView.swift             # Interactive category chart
├── NotificationManager.swift        # Smart notification logic
├── CategoryHelper.swift             # Category colors and utilities
├── Persistence.swift                # Core Data stack
└── SwiftExpenseTracker.xcdatamodeld # Core Data model
```

## 🎨 Design Philosophy

SpendEasy follows a **"Midnight Professional"** design aesthetic:
- Deep, rich dark backgrounds (#0A0A0F, #1A1A2E)
- Vibrant accent colors for categories
- Smooth animations and micro-interactions
- Golden ratio (0.618) used in chart design
- Clean typography with SF Pro system font

## 🔒 Privacy

- **No account required** - Start tracking immediately
- **No internet connection needed** - Works 100% offline
- **No data collection** - All data stays on your device
- **No third-party analytics** - Your spending is your business

## 🤝 Contributing

This is a personal portfolio project, but suggestions and feedback are welcome! Feel free to:
- Open an issue for bugs or feature requests
- Fork the repo and submit a pull request
- Share your experience using the app

## 📄 License

This project is available under the MIT License. See LICENSE file for details.

## 👨‍💻 Author

Created by **Om Panjwani** as a portfolio project demonstrating:
- SwiftUI best practices
- Core Data integration
- Local notifications
- Interactive data visualizations
- Clean architecture and code organization

---

**Built with ❤️ using Swift and SwiftUI**

