// Manages all local notifications for the app.
// Handles daily reminders, spending milestones, and monthly analysis.

import UserNotifications
import CoreData

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting authorization: \(error.localizedDescription)")
            }
        }
    }
    
    // Daily reminder at 8 PM
    func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Expense Check"
        content.body = "Don't forget to log your expenses for today!"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 20 // 8 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Check inactivity
    func checkInactivity() {
        if let lastOpen = UserDefaults.standard.object(forKey: "lastAppOpenTime") as? Date {
            let hoursSinceLastOpen = Date().timeIntervalSince(lastOpen) / 3600
            if hoursSinceLastOpen >= 24 {
                let content = UNMutableNotificationContent()
                content.title = "Missing Your Expenses?"
                content.body = "You haven't tracked your expenses today. Don't forget to log them!"
                content.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: "inactivityReminder", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        } else {
            UserDefaults.standard.set(Date(), forKey: "lastAppOpenTime")
        }
    }
    
    // Smart reminders based on specific user rules
    func scheduleSmartReminders(viewContext: NSManagedObjectContext) {
        let calendar = Calendar.current
        let now = Date()
        
        // 1. Calculate Current Month Total
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let fetchRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startOfMonth as NSDate, now as NSDate)
        
        do {
            let expenses = try viewContext.fetch(fetchRequest)
            let currentMonthTotal = expenses.reduce(0) { $0 + $1.amount }
            let currentDay = calendar.component(.day, from: now)
            
            // Remove old alerts to avoid duplicates
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["milestone10k", "milestone15k", "endOfMonthAdvice", "monthlyComparison"])
            
            // 2. Milestone Alerts (10k & 15k)
            if currentMonthTotal >= 10000 && currentMonthTotal < 15000 {
                // Check if we haven't already alerted for 10k this month (using UserDefaults to track)
                if !hasAlertedFor(milestone: "10k", month: startOfMonth) {
                    scheduleNotification(
                        id: "milestone10k",
                        title: "Spending Alert",
                        body: "Today is day \(currentDay) & you have already spent ₹10,000. Spend the rest of the money wisely."
                    )
                    markAlertAsShown(milestone: "10k", month: startOfMonth)
                }
            } else if currentMonthTotal >= 15000 {
                if !hasAlertedFor(milestone: "15k", month: startOfMonth) {
                    scheduleNotification(
                        id: "milestone15k",
                        title: "Spending Alert",
                        body: "Today is day \(currentDay) & you have already spent ₹15,000. Please control your spendings."
                    )
                    markAlertAsShown(milestone: "15k", month: startOfMonth)
                }
            }
            
            // 3. End of Month Advice (7 days left)
            let range = calendar.range(of: .day, in: .month, for: now)!
            let daysRemaining = range.count - currentDay
            
            if daysRemaining <= 7 {
                var body = ""
                if currentMonthTotal <= 10000 {
                    body = "You have money left! You can spend it on something useful or entertainment."
                } else if currentMonthTotal <= 15000 {
                    body = "Money spent this month was calculated. You are within limits."
                } else {
                    body = "Control your spendings for the remaining days."
                }
                
                // Only show this once per month end period
                if !hasAlertedFor(milestone: "endOfMonth", month: startOfMonth) {
                    scheduleNotification(
                        id: "endOfMonthAdvice",
                        title: "End of Month Check",
                        body: body
                    )
                    markAlertAsShown(milestone: "endOfMonth", month: startOfMonth)
                }
            }
            
            // 4. Monthly Comparison (At the start of a new month)
            // Check if we need to show last month's comparison
            checkAndScheduleMonthlyComparison(viewContext: viewContext)
            
        } catch {
            print("Error in smart reminders: \(error)")
        }
    }
    
    private func checkAndScheduleMonthlyComparison(viewContext: NSManagedObjectContext) {
        let calendar = Calendar.current
        let now = Date()
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        // Only run this check if we haven't shown it for the current month
        if hasAlertedFor(milestone: "monthlyComparison", month: currentMonthStart) { return }
        
        // Calculate Previous Month Total
        let previousMonthDate = calendar.date(byAdding: .month, value: -1, to: now)!
        let previousMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonthDate))!
        let previousMonthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: previousMonthStart)!
        
        let prevRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        prevRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", previousMonthStart as NSDate, previousMonthEnd as NSDate)
        
        do {
            let prevExpenses = try viewContext.fetch(prevRequest)
            let prevTotal = prevExpenses.reduce(0) { $0 + $1.amount }
            
            // We can't know "this month's" total yet if it just started, 
            // so the requirement "your last month avg was X & u spent Y this month" 
            // implies comparing the *completed* last month to the *month before that* OR 
            // simply stating last month's total as the "average" baseline.
            // Let's interpret "last month avg" as the total of the previous month.
            
            if prevTotal > 0 {
                 scheduleNotification(
                    id: "monthlyComparison",
                    title: "New Month Started",
                    body: "Your last month total was ₹\(Int(prevTotal)). Try to beat that this month!"
                )
                markAlertAsShown(milestone: "monthlyComparison", month: currentMonthStart)
            }
            
        } catch {
            print("Error fetching previous month data: \(error)")
        }
    }
    
    // Helpers for tracking alerts
    private func hasAlertedFor(milestone: String, month: Date) -> Bool {
        let key = "alert_\(milestone)_\(Int(month.timeIntervalSince1970))"
        return UserDefaults.standard.bool(forKey: key)
    }
    
    private func markAlertAsShown(milestone: String, month: Date) {
        let key = "alert_\(milestone)_\(Int(month.timeIntervalSince1970))"
        UserDefaults.standard.set(true, forKey: key)
    }
    
    private func scheduleNotification(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Trigger immediately (1 second delay for system processing)
        // For testing during development, change to 5 seconds by uncommenting below:
        #if DEBUG
        // let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        #else
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        #endif
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
