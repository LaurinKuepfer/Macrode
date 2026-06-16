import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // 1. Request permission from the user
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    // 2. Schedule ALL Daily Coach messages (with optional parameters for dynamic progress tracking)
    func scheduleDailyNotifications(meals: [ConsumedMeal] = [], log: DailyLog? = nil) {
        // Clear any old notifications first to avoid overlaps
        cancelNotifications()
        
        // MORNING REMINDER (7:00 AM) - Repeats daily
        scheduleNotification(
            id: "morning_motivation",
            title: String(localized: "💊 Don't forget your breakfast and supplements! 🍳"),
            body: String(localized: "Don't forget to log your breakfast and take your supplements."),
            hour: 7,
            minute: 0,
            repeats: true
        )
        
        // WATER REMINDERS (Every 2 hours) - Repeats daily
        let waterHours = [10, 12, 14, 16, 18]
        let waterMessages = [
            String(localized: "Hydration Check 💧 Grab a glass of water!"),
            String(localized: "Stay sharp! 🧠 Time for some water."),
            String(localized: "Midday thirst? 🚰 Keep that water target in mind."),
            String(localized: "Almost evening! 💧 Don't forget to hydrate."),
            String(localized: "Last water check! 🚰 Finish strong.")
        ]
        
        for (index, hour) in waterHours.enumerated() {
            scheduleNotification(
                id: "water_reminder_\(hour)",
                title: String(localized: "Hydration Coach"),
                body: waterMessages[index],
                hour: hour,
                minute: 0,
                repeats: true
            )
        }
        
        // EVENING CHECK-IN (8:00 PM) - Dynamic scheduling
        scheduleEveningCheckIns(meals: meals, log: log)
    }
    
    // Dynamic scheduler for the evening check-ins
    private func scheduleEveningCheckIns(meals: [ConsumedMeal], log: DailyLog?) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let now = Date()
        
        // Schedules rolling check-ins for the next 7 days.
        // Today (day 0) is dynamic; future days (1 to 6) serve as fallbacks.
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let eveningDate = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: targetDate) else {
                continue
            }
            
            // If 8:00 PM today has already passed, skip scheduling day 0
            guard eveningDate > now else { continue }
            
            let content = UNMutableNotificationContent()
            content.sound = .default
            
            if dayOffset == 0, let log = log {
                // Determine today's current metrics
                let todayMeals = meals.filter { calendar.isDate($0.consumedAt, inSameDayAs: now) }
                let totalCals = todayMeals.reduce(0) { $0 + $1.calories }
                let totalProtein = todayMeals.reduce(0) { $0 + $1.protein }
                
                let isCalGoalHit = totalCals >= log.calorieTarget
                let isProteinGoalHit = totalProtein >= log.proteinTarget
                
                if isCalGoalHit && isProteinGoalHit {
                    content.title = String(localized: "Goal Achieved! 🎉")
                    content.body = String(localized: "You've successfully hit both your protein and calorie goals today! Keep up the consistency.")
                } else {
                    content.title = String(localized: "Evening Check-in 🌙")
                    content.body = String(localized: "Have you hit your protein goal for today? Log your dinner to keep your streak alive!")
                }
            } else {
                // Future fallback reminders
                content.title = String(localized: "Evening Check-in 🌙")
                content.body = String(localized: "Have you hit your protein goal for today? Log your dinner to keep your streak alive!")
            }
            
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: eveningDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "evening_protein_day_\(dayOffset)", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling evening check-in for day \(dayOffset): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper function to build repeating/non-repeating daily notifications
    private func scheduleNotification(id: String, title: String, body: String, hour: Int, minute: Int, repeats: Bool = true) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // 3. Turn off the coach
    func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}