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

    @AppStorage("appLanguage", store: UserDefaults(suiteName: "group.com.kuepferlaurin.macrode")) private var appLanguage: String = "system"
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
            WindowGroup {
                MainTabView()
                    .environment(\.locale, appLanguage == "system" ? .current : Locale(identifier: appLanguage))
                    .id(appLanguage)
                    .fontDesign(.rounded)
            }
            .modelContainer(sharedModelContainer)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    scheduleDynamicNotifications()
                }
            }
    }
    
    private func scheduleDynamicNotifications() {
        let context = sharedModelContainer.mainContext
        let meals = (try? context.fetch(FetchDescriptor<ConsumedMeal>())) ?? []
        let logs = (try? context.fetch(FetchDescriptor<DailyLog>())) ?? []
        let supplements = (try? context.fetch(FetchDescriptor<Supplement>())) ?? []
        
        let today = Calendar.current.startOfDay(for: Date())
        let todayLog = logs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
        
        NotificationManager.shared.scheduleDynamicNotifications(meals: meals, log: todayLog, supplements: supplements)
    }
}
