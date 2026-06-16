import SwiftUI
import SwiftData

@main
struct MacrodeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([FoodItem.self, DailyLog.self, ConsumedMeal.self, RecipeItem.self, Supplement.self])
        
        let groupConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, groupContainer: .identifier("group.com.kuepferlaurin.macrode"))

        do {
            return try ModelContainer(for: schema, configurations: [groupConfig])
        } catch {
            print("Failed to initialize with App Group, falling back to local storage: \(error)")
            
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some Scene {
            WindowGroup {
                MainTabView()
                    .environment(\.locale, appLanguage == "system" ? .current : Locale(identifier: appLanguage))
            }
            .modelContainer(sharedModelContainer)
    }
}
