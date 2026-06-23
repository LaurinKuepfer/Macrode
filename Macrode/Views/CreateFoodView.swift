import SwiftUI
import SwiftData
import VisionKit
import WidgetKit

// MARK: - 4. Create Custom Food
struct CreateFoodView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    var prefilledData: (name: String, calories: Double, protein: Double, carbs: Double, fat: Double, barcode: String, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)?
    var editingFood: FoodItem? = nil
    var selectedDate: Date = Date()
    @Binding var mainTabSelection: Int
    
    @State private var name: String = ""
    @State private var calories: Double?
    @State private var protein: Double?
    @State private var carbs: Double?
    @State private var fat: Double?
    @State private var fiber: Double?
    @State private var sugar: Double?
    @State private var saturatedFat: Double?
    @State private var sodium: Double?
    @State private var householdUnitName: String = ""
    @State private var householdUnitWeightGrams: Double?
    @State private var isDrink: Bool = false
    @State private var selectedCategory: String = "Other"
    @FocusState private var isInputActive: Bool
    
    let categories = ["Drinks", "Fruits", "Vegetables", "Meat", "Carbs", "Dairy & Fats", "Fast Food", "Other"]
    
    var body: some View {
        Form {
            if let imageUrl = prefilledData?.imageUrl, let url = URL(string: imageUrl) {
                Section {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(maxWidth: .infinity, alignment: .center)
                        case .success(let image):
                            image.resizable().scaledToFit().frame(maxHeight: 200).cornerRadius(12).frame(maxWidth: .infinity, alignment: .center)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.bottom, 8)
                }
            }
            
            Section(header: Text("Food Info")) {
                TextField("Food Name (e.g. Greek Yogurt 2%)", text: $name)
                    .focused($isInputActive)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(LocalizedStringKey(cat)).tag(cat)
                    }
                }
            }
            Section(header: Text(isDrink ? "Nutrition per 100ml" : "Nutrition per 100g")) {
                HStack {
                    Text("Calories")
                    Spacer()
                    TextField("Required", value: $calories, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.green)
                }
                HStack {
                    Text("Protein (g)")
                    Spacer()
                    TextField("Optional", value: $protein, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.red)
                }
                HStack {
                    Text("Carbs (g)")
                    Spacer()
                    TextField("Optional", value: $carbs, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Fat (g)")
                    Spacer()
                    TextField("Optional", value: $fat, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.orange)
                }
                
                Toggle("Is this a drink? (ml)", isOn: $isDrink)
                    .onChange(of: isDrink) { _, newValue in
                        if newValue { selectedCategory = "Drinks" }
                    }
                    .padding(.top, 8)
            }
            if fiber != nil || sugar != nil || saturatedFat != nil || sodium != nil {
                Section(header: Text("Extended Nutrition")) {
                    if fiber != nil {
                        HStack {
                            Text("Fiber (g)")
                            Spacer()
                            TextField("—", value: $fiber, format: .number)
                                .keyboardType(.decimalPad).focused($isInputActive).multilineTextAlignment(.trailing).foregroundColor(.brown)
                        }
                    }
                    if sugar != nil {
                        HStack {
                            Text("Sugar (g)")
                            Spacer()
                            TextField("—", value: $sugar, format: .number)
                                .keyboardType(.decimalPad).focused($isInputActive).multilineTextAlignment(.trailing).foregroundColor(.pink)
                        }
                    }
                    if saturatedFat != nil {
                        HStack {
                            Text("Saturated Fat (g)")
                            Spacer()
                            TextField("—", value: $saturatedFat, format: .number)
                                .keyboardType(.decimalPad).focused($isInputActive).multilineTextAlignment(.trailing).foregroundColor(.orange)
                        }
                    }
                    if sodium != nil {
                        HStack {
                            Text("Sodium (g)")
                            Spacer()
                            TextField("—", value: $sodium, format: .number)
                                .keyboardType(.decimalPad).focused($isInputActive).multilineTextAlignment(.trailing).foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section(header: Text("Household Unit (Optional)"), footer: Text("Configure a custom unit (e.g., '1 Burger' = 150g) to log this item without entering its weight every time.")) {
                TextField("Unit Name (e.g., Slice, Burger)", text: $householdUnitName)
                    .focused($isInputActive)
                
                HStack {
                    Text("Weight of 1 \(householdUnitName.isEmpty ? "Unit" : householdUnitName)")
                    Spacer()
                    TextField("g/ml", value: $householdUnitWeightGrams, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            if prefilledData != nil {
                if let data = prefilledData, (data.nutriscore != nil || data.ecoscore != nil || data.novaGroup != nil) {
                    Section(header: Text("Scores (OpenFoodFacts)")) {
                        if let n = data.nutriscore {
                            HStack { Text("Nutri-Score"); Spacer(); Text(n.uppercased()).fontWeight(.bold) }
                        }
                        if let e = data.ecoscore {
                            HStack { Text("Eco-Score"); Spacer(); Text(e.uppercased()).fontWeight(.bold) }
                        }
                        if let nova = data.novaGroup {
                            HStack { Text("NOVA Group"); Spacer(); Text("\(nova)").fontWeight(.bold) }
                        }
                        if let b = data.brand {
                            HStack { Text("Brand"); Spacer(); Text(b).foregroundColor(.secondary) }
                        }
                    }
                }
                
                if let ingredients = prefilledData?.ingredients, !ingredients.isEmpty {
                    Section(header: Text("Ingredients")) {
                        Text(ingredients).font(.caption).foregroundColor(.secondary)
                    }
                }
                
                if let allergens = prefilledData?.allergens, !allergens.isEmpty {
                    Section(header: Text("Allergens")) {
                        Text(allergens).font(.caption).foregroundColor(.red)
                    }
                }
                
                Section(footer: Text("Data provided by Open Food Facts. Please verify the nutrition matches the package description.")) {
                    EmptyView()
                }
            }
            
            Section {
                Button(action: saveAndLog) {
                    HStack {
                        Spacer()
                        Text("Save & Log Today")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || calories == nil)
                .listRowBackground(Color.green)
            }
        }
        .navigationTitle("Save Food")
        .onAppear {
            if let data = prefilledData {
                name = data.name
                calories = data.calories
                protein = data.protein
                carbs = data.carbs
                fat = data.fat
                fiber = data.fiber
                sugar = data.sugar
                saturatedFat = data.saturatedFat
                sodium = data.sodium
                if categories.contains(data.category) {
                    selectedCategory = data.category
                }
            } else if let existing = editingFood {
                householdUnitName = existing.householdUnitName ?? ""
                householdUnitWeightGrams = existing.householdUnitWeightGrams
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    isInputActive = false
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveFood()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || calories == nil)
            }
        }
    }
    
    private func saveFood() -> FoodItem {
        let finalFood: FoodItem
        if let existing = editingFood {
            existing.name = name
            existing.calories = max(0, calories ?? 0)
            existing.protein = max(0, protein ?? 0)
            existing.carbs = max(0, carbs ?? 0)
            existing.fat = max(0, fat ?? 0)
            existing.category = selectedCategory
            existing.fiber = fiber
            existing.sugar = sugar
            existing.saturatedFat = saturatedFat
            existing.sodium = sodium
            existing.householdUnitName = householdUnitName.isEmpty ? nil : householdUnitName
            existing.householdUnitWeightGrams = householdUnitWeightGrams
            if let b = prefilledData?.barcode { existing.barcode = b }
            finalFood = existing
        } else {
            let newFood = FoodItem(
                name: name,
                calories: max(0, calories ?? 0),
                protein: max(0, protein ?? 0),
                carbs: max(0, carbs ?? 0),
                fat: max(0, fat ?? 0),
                barcode: prefilledData?.barcode,
                category: selectedCategory,
                fiber: fiber,
                sugar: sugar,
                saturatedFat: saturatedFat,
                sodium: sodium,
                imageUrl: prefilledData?.imageUrl,
                nutriscore: prefilledData?.nutriscore,
                ecoscore: prefilledData?.ecoscore,
                novaGroup: prefilledData?.novaGroup,
                ingredients: prefilledData?.ingredients,
                allergens: prefilledData?.allergens,
                brand: prefilledData?.brand,
                householdUnitName: householdUnitName.isEmpty ? nil : householdUnitName,
                householdUnitWeightGrams: householdUnitWeightGrams
            )
            context.insert(newFood)
            finalFood = newFood
        }
        try? context.save()
        HapticManager.shared.notification(.success)
        Task { WidgetCenter.shared.reloadAllTimelines() }
        return finalFood
    }
    
    private func saveAndLog() {
        let food = saveFood()
        
        let meal = ConsumedMeal(
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            weightGrams: 100, // Default to 100g on quick save & log
            consumedAt: selectedDate,
            mealCategory: autoMealCategory(for: selectedDate),
            fiber: food.fiber,
            sugar: food.sugar,
            saturatedFat: food.saturatedFat,
            sodium: food.sodium
        )
        context.insert(meal)
        HealthKitManager.shared.saveMeal(
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            date: selectedDate
        )
        try? context.save()
        Task { WidgetCenter.shared.reloadAllTimelines() }
        
        mainTabSelection = 0
        dismiss()
    }
}
