import Foundation
import SwiftData

@ModelActor
actor MealRepository {
    func getMeals(for date: Date) -> [ConsumedMeal] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let descriptor = FetchDescriptor<ConsumedMeal>(predicate: #Predicate { $0.consumedAt >= startOfDay && $0.consumedAt < endOfDay })
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    func saveMeal(_ meal: ConsumedMeal) {
        modelContext.insert(meal)
        try? modelContext.save()
    }
    
    func deleteMeal(_ meal: ConsumedMeal) {
        modelContext.delete(meal)
        try? modelContext.save()
    }
}
