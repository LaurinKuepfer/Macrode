import Foundation

enum DashboardBlock: String, Codable, CaseIterable, Identifiable {
    case energyOverview
    case macros
    case quickActions
    case water
    case fasting
    case frequentMeals
    case supplements
    case timeline
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .energyOverview: return "Energy Overview"
        case .macros: return "Macronutrients"
        case .quickActions: return "Quick Actions"
        case .water: return "Water Tracker"
        case .fasting: return "Fasting Timer"
        case .frequentMeals: return "Frequent Meals"
        case .supplements: return "Supplements"
        case .timeline: return "Meal Timeline"
        }
    }
    
    var systemImage: String {
        switch self {
        case .energyOverview: return "bolt.fill"
        case .macros: return "chart.bar.fill"
        case .quickActions: return "wand.and.stars"
        case .water: return "drop.fill"
        case .fasting: return "timer"
        case .frequentMeals: return "sparkles"
        case .supplements: return "pills.fill"
        case .timeline: return "clock.fill"
        }
    }
}
