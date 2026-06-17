import Foundation
import SwiftData

@ModelActor
actor DailyLogRepository {
    func getLog(for date: Date) -> DailyLog? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyLog>(predicate: #Predicate { $0.date == startOfDay })
        return try? modelContext.fetch(descriptor).first
    }
    
    func saveLog(_ log: DailyLog) {
        modelContext.insert(log)
        try? modelContext.save()
    }
}
