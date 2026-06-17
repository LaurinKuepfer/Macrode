import Foundation
import SwiftData

struct ReviewData {
    let days: Int
    let averageCalorieTarget: Double
    let averageCalorieIntake: Double
    let daysGoalMet: Int
    let bestMacroName: String
    let bestMacroPercentage: Double
    let weightChange: Double? // Positive means gained, negative means lost
    let motivationalMessage: String
}

class ReviewEngine {
    static func generateReview(days: Int, logs: [DailyLog], meals: [ConsumedMeal]) -> ReviewData {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -days, to: todayStart)!
        
        var validLogs = [DailyLog]()
        var logDict = [Date: DailyLog]()
        for log in logs {
            let logStart = calendar.startOfDay(for: log.date)
            if logStart >= startDate && logStart < todayStart {
                validLogs.append(log)
                logDict[logStart] = log
            }
        }
        
        var dailyMeals = [Date: [ConsumedMeal]]()
        for meal in meals {
            let mealStart = calendar.startOfDay(for: meal.consumedAt)
            if mealStart >= startDate && mealStart < todayStart {
                dailyMeals[mealStart, default: []].append(meal)
            }
        }
        
        var totalTargetCals: Double = 0
        var totalIntakeCals: Double = 0
        
        var totalProTarget: Double = 0
        var totalProIntake: Double = 0
        var totalCarbTarget: Double = 0
        var totalCarbIntake: Double = 0
        var totalFatTarget: Double = 0
        var totalFatIntake: Double = 0
        
        var successfulDays = 0
        let daysToCount = max(1, validLogs.count)
        
        for log in validLogs {
            let logStart = calendar.startOfDay(for: log.date)
            let dayMeals = dailyMeals[logStart] ?? []
            
            let dayCals = dayMeals.reduce(0) { $0 + $1.calories }
            let dayPro = dayMeals.reduce(0) { $0 + $1.protein }
            let dayCarb = dayMeals.reduce(0) { $0 + $1.carbs }
            let dayFat = dayMeals.reduce(0) { $0 + $1.fat }
            
            totalTargetCals += log.calorieTarget
            totalIntakeCals += dayCals
            
            totalProTarget += log.proteinTarget
            totalProIntake += dayPro
            totalCarbTarget += log.carbsTarget
            totalCarbIntake += dayCarb
            totalFatTarget += log.fatTarget
            totalFatIntake += dayFat
            
            if dayCals > 0 && dayCals <= log.calorieTarget {
                successfulDays += 1
            }
        }
        
        let avgTarget = totalTargetCals / Double(daysToCount)
        let avgIntake = totalIntakeCals / Double(daysToCount)
        
        let proRatio = totalProTarget > 0 ? (totalProIntake / totalProTarget) : 0
        let carbRatio = totalCarbTarget > 0 ? (totalCarbIntake / totalCarbTarget) : 0
        let fatRatio = totalFatTarget > 0 ? (totalFatIntake / totalFatTarget) : 0
        
        var bestMacro = "Protein"
        var bestRatio = proRatio
        
        if carbRatio > bestRatio && carbRatio <= 1.1 { // Try to find highest completion without massive overshoot
            bestMacro = "Carbs"
            bestRatio = carbRatio
        }
        if fatRatio > bestRatio && fatRatio <= 1.1 {
            bestMacro = "Fat"
            bestRatio = fatRatio
        }
        
        // Weight Change
        var weightChange: Double? = nil
        let sortedLogs = validLogs.sorted { $0.date < $1.date }
        if let firstLog = sortedLogs.first(where: { $0.bodyWeight != nil }), let lastLog = sortedLogs.last(where: { $0.bodyWeight != nil }) {
            if let w1 = firstLog.bodyWeight, let w2 = lastLog.bodyWeight {
                if firstLog.date != lastLog.date {
                    weightChange = w2 - w1
                }
            }
        }
        
        // Motivational Message
        let successRate = Double(successfulDays) / Double(daysToCount)
        let message: String
        if validLogs.isEmpty {
            message = "You don't have enough data yet. Keep logging your meals to see your review!"
        } else if successRate >= 0.8 {
            message = "Absolutely stellar work! You are building unbreakable habits. Keep this momentum going!"
        } else if successRate >= 0.5 {
            message = "Great effort! You had some fantastic days. Let's aim to turn those few slip-ups into wins next time."
        } else {
            message = "Progress isn't always linear. What matters is that you're here and tracking. Let's focus on winning tomorrow."
        }
        
        return ReviewData(
            days: days,
            averageCalorieTarget: avgTarget,
            averageCalorieIntake: avgIntake,
            daysGoalMet: successfulDays,
            bestMacroName: bestMacro,
            bestMacroPercentage: bestRatio * 100,
            weightChange: weightChange,
            motivationalMessage: message
        )
    }
}
