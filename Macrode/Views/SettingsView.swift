import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    var dailyLog: DailyLog
    @Query private var allMeals: [ConsumedMeal]
    
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var csvDocument = CSVDocument()
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var showingResetConfirm = false

    @AppStorage("isProactiveCoachEnabled") private var isProactiveCoachEnabled = false
    @AppStorage("safetyFloorCalories") private var safetyFloorCalories: Double = 1500
    @AppStorage("hasCompletedTutorial") private var hasCompletedTutorial: Bool = true
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("userGoal") private var userGoal: GoalType = .maintain
    @AppStorage("hasDismissedWidgetPromo") private var hasDismissedWidgetPromo = false

    var body: some View {
        NavigationStack {
            List {
                
               
                Section {
                    HStack {
                        Label("Safety Floor", systemImage: "shield.fill")
                        Spacer()
                        Text("\(Int(safetyFloorCalories)) kcal")
                            .font(.subheadline).foregroundColor(.secondary)
                        Stepper("", value: $safetyFloorCalories, in: 1000...2500, step: 50)
                            .labelsHidden()
                    }
                } header: {
                    Label("Your Goal", systemImage: "flag.fill")
                } footer: {
                    Text("Energy Balance will never drop your daily target below the safety floor, even after higher-calorie days.")
                }
                
               
                Section {
                    Picker(selection: $appLanguage) {
                        Text("System").tag("system")
                        Text("English").tag("en")
                        Text("Deutsch").tag("de")
                        Text("Español").tag("es")
                        Text("Français").tag("fr")
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                } header: {
                    Label("General", systemImage: "gearshape.fill")
                }

               
                Section {
                    Toggle(isOn: $isProactiveCoachEnabled) {
                        Label("Daily Coach", systemImage: "bell.badge.fill")
                    }
                    .onChange(of: isProactiveCoachEnabled) { _, newValue in
                        HapticManager.shared.impact(.light)
                        if newValue {
                            NotificationManager.shared.requestPermission { success in
                                if success {
                                    NotificationManager.shared.scheduleDailyNotifications()
                                } else {
                                    isProactiveCoachEnabled = false
                                    showAlert(String(localized: "Permission Denied"), String(localized: "Please enable notifications for Macrode in your iPhone Settings."))
                                }
                            }
                        } else {
                            NotificationManager.shared.cancelNotifications()
                        }
                    }
                } header: {
                    Label("Notifications", systemImage: "bell.fill")
                } footer: {
                    Text("Receive offline daily reminders to take your supplements and hit your protein goals.")
                }
                
               
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Widgets").font(.caption).foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            widgetPreviewCard(icon: "flame.fill", title: "Calories", subtitle: "Remaining kcal", color: .green)
                            widgetPreviewCard(icon: "chart.bar.fill", title: "Macros", subtitle: "P / C / F split", color: .blue)
                            widgetPreviewCard(icon: "drop.fill", title: "Water", subtitle: "Daily intake", color: .cyan)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Text("Long-press your Home Screen → tap **+** in the top-left → search **Macrode** to add widgets.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Label("Widgets", systemImage: "rectangle.on.rectangle")
                }
                
               
                Section {
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        HealthKitManager.shared.requestAuthorization { success, error in
                            if success { showAlert(String(localized: "Connected!"), String(localized: "Macrode will now sync your meals directly to Apple Health.")) }
                            else { showAlert(String(localized: "Error"), error?.localizedDescription ?? String(localized: "Could not connect to Apple Health.")) }
                        }
                    }) {
                        Label("Connect Apple Health", systemImage: "heart.text.square.fill")
                            .foregroundColor(.primary)
                    }
                } header: {
                    Label("Health", systemImage: "heart.fill")
                } footer: {
                    Text("Sync meals, water, and weight to Apple Health automatically.")
                }
                
               
                Section {
                    Button(action: { prepareExport(); showingExporter = true }) {
                        Label("Export Backup (.csv)", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { showingImporter = true }) {
                        Label("Restore from Backup", systemImage: "square.and.arrow.down")
                    }
                    .foregroundColor(.orange)
                } header: {
                    Label("Data & Backup", systemImage: "externaldrive.fill")
                } footer: {
                    Text("Macrode is 100% offline. Use backups to transfer your data to a new device.")
                }
                
               
                Section {
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        hasCompletedTutorial = false
                        dismiss()
                    }) {
                        Label("Show Quick Guide", systemImage: "questionmark.circle.fill")
                            .foregroundColor(.primary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/LaurinKuepfer/Macrode")!) {
                        HStack {
                            Label("Source Code (GitHub)", systemImage: "curlybraces.square.fill")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.caption).foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Label("About & Help", systemImage: "info.circle.fill")
                }
                
               
                Section {
                    Button(role: .destructive, action: {
                        HapticManager.shared.impact(.light)
                        showingResetConfirm = true
                    }) {
                        Label("Reset All Data", systemImage: "trash.fill")
                    }
                } header: {
                    Label("Danger Zone", systemImage: "exclamationmark.triangle.fill")
                } footer: {
                    Text("This will permanently delete all your meals, logs, and settings. This cannot be undone.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .fileExporter(isPresented: $showingExporter, document: csvDocument, contentType: .commaSeparatedText, defaultFilename: "Macrode_Backup_\(Date().formatted(date: .numeric, time: .omitted))") { result in
                switch result {
                case .success(_): showAlert(String(localized: "Export Successful!"), String(localized: "Your data has been saved."))
                case .failure(let error): showAlert(String(localized: "Export Failed"), error.localizedDescription)
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importCSV(from: url)
                case .failure(let error): showAlert(String(localized: "Import Failed"), error.localizedDescription)
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) { Button("OK", role: .cancel) { } }
            .confirmationDialog("Are you sure?", isPresented: $showingResetConfirm, titleVisibility: .visible) {
                Button("Delete Everything", role: .destructive) { resetAllData() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all your logged meals, daily logs, food library, recipes, and supplements. Export a backup first!")
            }
            .onChange(of: appLanguage) { _, newLang in
                reseedStarterDatabase()
            }
        }
    }
    
   
    private func widgetPreviewCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption2).fontWeight(.bold)
            Text(subtitle)
                .font(.system(size: 9)).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(UIColor.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
   
    private func showAlert(_ title: String, _ message: String = "") {
        alertMessage = title + (message.isEmpty ? "" : "\n\(message)")
        showingAlert = true
    }
    
    private func resetAllData() {
        do {
            let mealDesc = FetchDescriptor<ConsumedMeal>()
            let logDesc = FetchDescriptor<DailyLog>()
            let foodDesc = FetchDescriptor<FoodItem>()
            let recipeDesc = FetchDescriptor<RecipeItem>()
            let suppDesc = FetchDescriptor<Supplement>()
            
            for item in (try? context.fetch(mealDesc)) ?? [] { context.delete(item) }
            for item in (try? context.fetch(logDesc)) ?? [] { context.delete(item) }
            for item in (try? context.fetch(foodDesc)) ?? [] { context.delete(item) }
            for item in (try? context.fetch(recipeDesc)) ?? [] { context.delete(item) }
            for item in (try? context.fetch(suppDesc)) ?? [] { context.delete(item) }
            
            try context.save()
            
            UserDefaults.standard.set(false, forKey: "hasLoadedStarterData")
            
            HapticManager.shared.notification(.success)
            showAlert(String(localized: "Data Reset"), String(localized: "All data has been deleted. Restart the app to begin fresh."))
        } catch {
            showAlert("Error", error.localizedDescription)
        }
    }
    
    private func reseedStarterDatabase() {
        do {
            let foodsDesc = FetchDescriptor<FoodItem>()
            let recipesDesc = FetchDescriptor<RecipeItem>()
            let existingFoods = try context.fetch(foodsDesc)
            let existingRecipes = try context.fetch(recipesDesc)
            
            let starterFoodNames = StarterDatabase.allStarterFoodNames
            let starterRecipeNames = StarterDatabase.allStarterRecipeNames
            
            for food in existingFoods where starterFoodNames.contains(food.name) {
                context.delete(food)
            }
            for recipe in existingRecipes where starterRecipeNames.contains(recipe.name) {
                context.delete(recipe)
            }
            
            for item in StarterDatabase.foods { 
                context.insert(FoodItem(name: item.name, calories: item.calories, protein: item.protein, carbs: item.carbs, fat: item.fat, category: item.category)) 
            }
            for recipe in StarterDatabase.recipes { 
                context.insert(RecipeItem(name: recipe.name, calories: recipe.calories, protein: recipe.protein, carbs: recipe.carbs, fat: recipe.fat, instructions: recipe.instructions, category: recipe.category, prepTimeMinutes: recipe.prepTimeMinutes, difficulty: recipe.difficulty, systemImage: recipe.systemImage)) 
            }
            try? context.save()
        } catch {
            print("Failed to update language database: \(error)")
        }
    }
    
   
    private func prepareExport() {
        var rows: [String] = ["Date,Meal Name,Calories,Protein,Carbs,Fat,Weight (g)"]
        let formatter = ISO8601DateFormatter()
        for meal in allMeals {
            let dateStr = formatter.string(from: meal.consumedAt)
            let safeName = meal.name.replacingOccurrences(of: ",", with: "")
            rows.append("\(dateStr),\(safeName),\(meal.calories),\(meal.protein),\(meal.carbs),\(meal.fat),\(meal.weightGrams)")
        }
        csvDocument = CSVDocument(initialText: rows.joined(separator: "\n"))
    }
    
    private func importCSV(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else { showAlert(String(localized: "Error"), String(localized: "Permission denied to read file.")); return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            guard let csvString = String(data: data, encoding: .utf8) else { return }
            let rows = csvString.components(separatedBy: "\n")
            guard rows.count > 1 else { return }
            
            let formatter = ISO8601DateFormatter()
            var importCount = 0
            
            for row in rows.dropFirst() {
                let columns = row.components(separatedBy: ",")
                if columns.count == 7 {
                    if let date = formatter.date(from: columns[0]), let cals = Double(columns[2]), let prot = Double(columns[3]), let carbs = Double(columns[4]), let fat = Double(columns[5]), let weight = Double(columns[6]) {
                        let newMeal = ConsumedMeal(name: columns[1], calories: cals, protein: prot, carbs: carbs, fat: fat, weightGrams: weight, consumedAt: date)
                        context.insert(newMeal)
                        importCount += 1
                    }
                }
            }
            try? context.save()
            showAlert(String(localized: "Import Successful!"), String(localized: "Restored \(importCount) meals to your diary."))
        } catch {
            showAlert(String(localized: "Import Error"), error.localizedDescription)
        }
    }
}
