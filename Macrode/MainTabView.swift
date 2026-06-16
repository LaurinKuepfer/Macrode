import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var context
    @Query private var dailyLogs: [DailyLog]
    
    @State private var selectedTab = 0
    @State private var globalSelectedDate: Date = Date()
    @State private var dummyIsPresented: Bool = false 
    
    
    private var todayLog: DailyLog {
        let startOfDay = Calendar.current.startOfDay(for: globalSelectedDate)
        if let log = dailyLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDay) }) {
            return log
        } else {
            let previousLogs = dailyLogs.filter { $0.date < startOfDay }.sorted { $0.date > $1.date }
            if let lastLog = previousLogs.first {
                let newLog = DailyLog(date: startOfDay, calorieTarget: lastLog.calorieTarget, proteinTarget: lastLog.proteinTarget, carbsTarget: lastLog.carbsTarget, fatTarget: lastLog.fatTarget, waterTargetML: lastLog.waterTargetML, bodyWeight: lastLog.bodyWeight)
                context.insert(newLog)
                try? context.save()
                return newLog
            } else {
                let newLog = DailyLog(date: startOfDay)
                context.insert(newLog)
                try? context.save()
                return newLog
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // TAB 1: TODAY
            DashboardView(selectedDate: $globalSelectedDate, selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
                .tag(0)
            
            // TAB 2: INSIGHTS
            InsightsView(selectedDate: $globalSelectedDate)
                .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }
                .tag(1)
            
            // TAB 3: LIBRARY
            AddMealView(selectedDate: $globalSelectedDate)
                .tabItem { Label("Library", systemImage: "book.pages.fill") }
                .tag(2)
            
            // TAB 4: SETTINGS
            NavigationStack {
                SettingsView(dailyLog: todayLog)
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(3)
            
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .tint(.green)
        .onAppear {
            syncToWidget()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            let calendar = Calendar.current
            if !calendar.isDate(globalSelectedDate, inSameDayAs: Date()) {
                globalSelectedDate = Date()
                _ = todayLog // Force creation if it doesn't exist
            }
            syncToWidget()
        }
        .onChange(of: UserDefaults.standard.string(forKey: "userGoal")) { _, _ in syncToWidget() }
        .onChange(of: UserDefaults.standard.double(forKey: "safetyFloorCalories")) { _, _ in syncToWidget() }
        .onOpenURL { url in
            if url.scheme == "macrode" && url.host == "addMeal" {
                selectedTab = 2
            }
        }
    }
    
    private func syncToWidget() {
        let standard = UserDefaults.standard
        let shared = UserDefaults(suiteName: "group.com.kuepferlaurin.macrode")
        
        if let goal = standard.string(forKey: "userGoal") {
            shared?.set(goal, forKey: "userGoal")
        }
        
        let floor = standard.double(forKey: "safetyFloorCalories")
        if floor > 0 {
            shared?.set(floor, forKey: "safetyFloorCalories")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}
