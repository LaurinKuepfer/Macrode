import Foundation
import SwiftData

struct MetabolismEngine {
    static func calculateTrueTDEE(dailyLogs: [DailyLogData], allMeals: [ConsumedMealData]) -> Double? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lookbackPeriod = calendar.date(byAdding: .day, value: -21, to: today) else { return nil }
        
        let recentLogs = dailyLogs
            .filter { $0.date >= lookbackPeriod && $0.date <= today && ($0.bodyWeight ?? 0) > 0 }
            .sorted { $0.date < $1.date }
        
        guard let firstLog = recentLogs.first, let lastLog = recentLogs.last else { return nil }
        
        let firstWeight = firstLog.bodyWeight ?? 0
        let lastWeight = lastLog.bodyWeight ?? 0
        guard firstWeight > 0, lastWeight > 0 else { return nil }
        
        let startDate = calendar.startOfDay(for: firstLog.date)
        let endDate = calendar.startOfDay(for: lastLog.date)
        
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        guard daysBetween >= 2 else { return nil }
        
        let weightDifferenceKG = lastWeight - firstWeight
        let dailyDeficitOrSurplus = (weightDifferenceKG * 7700.0) / Double(daysBetween)
        
        let mealsInPeriod = allMeals.filter { $0.consumedAt >= startDate && $0.consumedAt < endDate }
        
        let mealsByDay = Dictionary(grouping: mealsInPeriod) { calendar.startOfDay(for: $0.consumedAt) }
        let trackedDaysCount = mealsByDay.filter { $0.value.reduce(0, { sum, meal in sum + meal.calories }) > 500 }.count
        
        guard trackedDaysCount >= 2 else { return nil }
        
        let totalCaloriesEaten = mealsInPeriod.reduce(0) { $0 + $1.calories }
        let averageDailyCaloriesEaten = totalCaloriesEaten / Double(trackedDaysCount)
        
        let calculatedTDEE = averageDailyCaloriesEaten - dailyDeficitOrSurplus
        
        if calculatedTDEE > 1000 && calculatedTDEE < 5000 {
            return calculatedTDEE
        }
        
        return nil
    }
}
