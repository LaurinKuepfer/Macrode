import Foundation
import SwiftData
import SwiftUI

@Observable
class DashboardViewModel {
    var cachedTDEE: TDEEResult?
    var cachedBalance: BalanceEngine.BalanceResult?
    
    var showingSmartSuggester = false
    var showingQuickAddSheet = false
    var editingMeal: ConsumedMeal? = nil
    var mealToDelete: ConsumedMeal? = nil
    
    var goalsMetCache: [Date: Bool] = [:]
    var logsDictionary: [Date: DailyLog] = [:]
    
    func recalculateEngines(allDailyLogs: [DailyLog], allConsumedMeals: [ConsumedMeal], userGoal: GoalType, selectedDate: Date) {
        let logsData = allDailyLogs.map { DailyLogData(from: $0) }
        let mealsData = allConsumedMeals.map { ConsumedMealData(from: $0) }
        
        let tdee = MetabolismEngine.calculateTrueTDEE(dailyLogs: logsData, allMeals: mealsData)
        let f = BalanceEngine.calculateBalance(for: selectedDate, allLogs: logsData, allMeals: mealsData, userGoal: userGoal)
        
        self.cachedTDEE = tdee
        self.cachedBalance = f
    }
    
    var frequentMeals: [ConsumedMeal] = []
    
    func updateFrequentMeals(allConsumedMeals: [ConsumedMeal]) {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let startOfToday = calendar.startOfDay(for: now)
        
        let todayMealNames = Set(allConsumedMeals.filter { $0.consumedAt >= startOfToday }.map { $0.name })
        
        let recentMeals = allConsumedMeals.filter {
            guard $0.consumedAt < startOfToday else { return false }
            
            let daysAgo = calendar.dateComponents([.day], from: $0.consumedAt, to: now).day ?? 0
            guard daysAgo <= 30 else { return false }
            
            let mealHour = calendar.component(.hour, from: $0.consumedAt)
            let diff = abs(mealHour - currentHour)
            return diff <= 2 || diff >= 22
        }
        
        let grouped = Dictionary(grouping: recentMeals, by: { $0.name })
        let frequent = grouped.filter { !todayMealNames.contains($0.key) && $0.value.count >= 2 }
        
        let sorted = frequent.sorted { $0.value.count > $1.value.count }
        let result = sorted.prefix(3).compactMap { $0.value.first }
        
        self.frequentMeals = result
    }
    
    func updateLogsDictionary(dailyLogs: [DailyLog]) {
        var dict = [Date: DailyLog]()
        for log in dailyLogs { dict[Calendar.current.startOfDay(for: log.date)] = log }
        self.logsDictionary = dict
    }
}
