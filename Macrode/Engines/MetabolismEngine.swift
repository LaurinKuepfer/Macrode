import Foundation
import SwiftData

struct TDEEResult: Sendable {
    let tdee: Double?
    let validDaysLogged: Int
    let requiredDays: Int = 21
}

struct MetabolismEngine {
    static func calculateTrueTDEE(dailyLogs: [DailyLogData], allMeals: [ConsumedMealData]) -> TDEEResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        guard let lookbackPeriod = calendar.date(byAdding: .day, value: -21, to: today) else { 
            return TDEEResult(tdee: nil, validDaysLogged: 0) 
        }
        
        // Calculate valid tracked days overall in the last 21 days
        let allRecentMeals = allMeals.filter { $0.consumedAt >= lookbackPeriod && $0.consumedAt <= Date() }
        let allMealsByDay = Dictionary(grouping: allRecentMeals) { calendar.startOfDay(for: $0.consumedAt) }
        let validDaysLogged = allMealsByDay.filter { $0.value.reduce(0, { sum, meal in sum + meal.calories }) > 500 }.count
        
        let recentLogs = dailyLogs
            .filter { $0.date >= lookbackPeriod && $0.date <= today && ($0.bodyWeight ?? 0) > 0 }
            .sorted { $0.date < $1.date }
        
        guard let firstLog = recentLogs.first, let lastLog = recentLogs.last else { 
            return TDEEResult(tdee: nil, validDaysLogged: validDaysLogged) 
        }
        
        let firstWeight = firstLog.bodyWeight ?? 0
        let lastWeight = lastLog.bodyWeight ?? 0
        guard firstWeight > 0, lastWeight > 0 else { 
            return TDEEResult(tdee: nil, validDaysLogged: validDaysLogged) 
        }
        
        let startDate = calendar.startOfDay(for: firstLog.date)
        let endDate = calendar.startOfDay(for: lastLog.date)
        
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        
        guard daysBetween >= 2 else { 
            return TDEEResult(tdee: nil, validDaysLogged: validDaysLogged) 
        }
        
        let weightDifferenceKG = lastWeight - firstWeight
        let dailyDeficitOrSurplus = (weightDifferenceKG * 7700.0) / Double(daysBetween)
        
        let mealsInPeriod = allMeals.filter { $0.consumedAt >= startDate && $0.consumedAt < endDate }
        
        let mealsByDay = Dictionary(grouping: mealsInPeriod) { calendar.startOfDay(for: $0.consumedAt) }
        let trackedDaysCount = mealsByDay.filter { $0.value.reduce(0, { sum, meal in sum + meal.calories }) > 500 }.count
        
        let complianceRate = Double(trackedDaysCount) / Double(max(1, daysBetween))
        guard complianceRate >= 0.8 else { 
            return TDEEResult(tdee: nil, validDaysLogged: validDaysLogged) 
        }
        
        let totalCaloriesEaten = mealsInPeriod.reduce(0) { $0 + $1.calories }
        let averageDailyCaloriesEaten = totalCaloriesEaten / Double(max(1, trackedDaysCount))
        
        let calculatedTDEE = averageDailyCaloriesEaten - dailyDeficitOrSurplus
        
        if calculatedTDEE > 1000 && calculatedTDEE < 5000 {
            return TDEEResult(tdee: calculatedTDEE, validDaysLogged: validDaysLogged)
        }
        
        return TDEEResult(tdee: nil, validDaysLogged: validDaysLogged)
    }
}
