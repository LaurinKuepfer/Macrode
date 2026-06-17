import SwiftUI
import SwiftData
import VisionKit
import WidgetKit

// MARK: - 2. Log Recipe
struct LogRecipeView: View {
    let recipe: RecipeItem
    var selectedDate: Date
    @Binding var mainTabSelection: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var servings: Double? = nil
    @FocusState private var isInputActive: Bool
    @State private var showingEditSheet = false
    
    private var validServings: Double {
        max(0, servings ?? 1) // default to 1 for calculations if empty
    }
    
    private var calcCalories: Double { recipe.calories * validServings }
    private var calcProtein: Double { recipe.protein * validServings }
    private var calcCarbs: Double { recipe.carbs * validServings }
    private var calcFat: Double { recipe.fat * validServings }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(gradient: Gradient(colors: [.green.opacity(0.8), .green]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 250)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: recipe.systemImage)
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                        
                        Text(recipe.name)
                            .font(.largeTitle.weight(.heavy))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    }
                    .padding()
                }
                
                HStack(spacing: 16) {
                    StatBadge(icon: "clock", text: "\(recipe.prepTimeMinutes) min")
                    StatBadge(icon: "flame.fill", text: "\(Int(recipe.calories)) kcal")
                    StatBadge(icon: "chart.bar.fill", text: recipe.difficulty)
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nutrition (per serving)")
                            .font(.title3.weight(.bold))
                        
                        HStack(spacing: 12) {
                            MacroPreviewCol(name: "Protein", amount: "\(Int(recipe.protein))g", color: .red)
                            MacroPreviewCol(name: "Carbs", amount: "\(Int(recipe.carbs))g", color: .blue)
                            MacroPreviewCol(name: "Fat", amount: "\(Int(recipe.fat))g", color: .orange)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    
                    if !recipe.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Instructions")
                                .font(.title3.weight(.bold))
                            
                            ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 16) {
                                    Circle()
                                        .fill(Color.green.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                        .overlay(Text("\(index + 1)").font(.caption.weight(.bold)).foregroundColor(.green))
                                    
                                    Text(instruction)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Log Meal")
                            .font(.title3.weight(.bold))
                        
                        HStack {
                            Text("Servings")
                                .font(.headline)
                            Spacer()
                            TextField("1", value: $servings, format: .number)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                                .multilineTextAlignment(.trailing)
                                .font(.title3.weight(.bold))
                                .frame(width: 80)
                                .padding(8)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: logMeal) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Log \(Int(calcCalories)) kcal")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(16)
                            .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled((servings ?? 0) <= 0)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .edgesIgnoringSafeArea(.top)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditSheet = true }
            }
            ToolbarItem(placement: .keyboard) {
                Button("Done") { isInputActive = false }
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecipeView(recipe: recipe)
        }
    }
    
    private func logMeal() {
        let meal = ConsumedMeal(
            name: recipe.name,
            calories: calcCalories,
            protein: calcProtein,
            carbs: calcCarbs,
            fat: calcFat,
            weightGrams: 0,
            consumedAt: selectedDate,
            mealCategory: autoMealCategory(for: selectedDate)
        )
        context.insert(meal)
        try? context.save()
        
        HapticManager.shared.notification(.success)
                    HealthKitManager.shared.saveMeal(
            name: recipe.name,
            calories: calcCalories,
            protein: calcProtein,
            carbs: calcCarbs,
            fat: calcFat,
            date: selectedDate
        )
        Task { WidgetCenter.shared.reloadAllTimelines() }
        mainTabSelection = 0
        dismiss()
    }
}
