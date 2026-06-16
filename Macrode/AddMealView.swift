import SwiftUI
import SwiftData
import VisionKit
import WidgetKit

func autoMealCategory(for date: Date = Date()) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    if hour < 10 { return "Breakfast" }
    if hour < 14 { return "Lunch" }
    if hour < 17 { return "Snack" }
    return "Dinner"
}

// MARK: - 1. THE MAIN LIBRARY TAB
struct AddMealView: View {
    @Binding var selectedDate: Date
    
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodItem.name) private var foodLibrary: [FoodItem]
    @Query(sort: \RecipeItem.name) private var recipeLibrary: [RecipeItem]
    
    @State private var searchText: String = ""
    @State private var selectedTab: Int = 0
    @State private var selectedCategory: String = "All"
    
    @State private var isShowingScanner = false
    @State private var scannedBarcode: String? = nil
    @State private var isFetchingAPI = false
    @State private var prefilledAPIResult: (name: String, calories: Double, protein: Double, carbs: Double, fat: Double, barcode: String, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)? = nil
    @State private var navigateToCreateFood = false
    @State private var selectedExistingFood: FoodItem? = nil
    
    @State private var navigateToQuickEstimate = false
    @State private var onlineSearchQuery: String? = nil
    
    let categories = ["All", "Drinks", "Fruits", "Vegetables", "Meat", "Carbs", "Dairy & Fats", "Fast Food", "Other"]
    
    var filteredFoods: [FoodItem] {
        var result = foodLibrary
        if selectedCategory != "All" {
            result = result.filter { $0.category == selectedCategory }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return result
    }
    
    var filteredRecipes: [RecipeItem] {
        if searchText.isEmpty { return recipeLibrary }
        return recipeLibrary.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !Calendar.current.isDateInToday(selectedDate) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Logging for: \(selectedDate.formatted(.dateTime.weekday(.wide).month().day()))")
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                }
                
                Picker("Library", selection: $selectedTab) {
                    Text("Foods").tag(0)
                    Text("Recipes").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                if selectedTab == 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: {
                                    withAnimation { selectedCategory = cat }
                                }) {
                                    Text(LocalizedStringKey(cat))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.green : Color.secondary.opacity(0.15))
                                        .foregroundColor(selectedCategory == cat ? .white : .primary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                
                ZStack {
                    List {
                        if selectedTab == 0 {
                            foodListContent
                        } else {
                            recipeListContent
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search...")
                    
                    if isFetchingAPI {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack {
                            ProgressView().scaleEffect(1.5).padding()
                            Text("Looking up product...").font(.headline).foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Food Library" : "Recipe Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if selectedTab == 0 {
                        HStack(spacing: 16) {
                            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                                Button(action: { isShowingScanner = true }) { Image(systemName: "barcode.viewfinder") }
                            }
                            Button(action: { prefilledAPIResult = nil; navigateToCreateFood = true }) { Image(systemName: "plus") }
                        }
                    } else {
                        NavigationLink(destination: CreateRecipeView()) { Image(systemName: "plus") }
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToCreateFood) { CreateFoodView(prefilledData: prefilledAPIResult) }
            .navigationDestination(isPresented: $navigateToQuickEstimate) { QuickEstimateView(selectedDate: selectedDate, isRootPresented: $navigateToQuickEstimate) }
            .navigationDestination(item: $selectedExistingFood) { food in LogFoodView(food: food, selectedDate: selectedDate) }
            .navigationDestination(item: Binding<String?>(
                get: { onlineSearchQuery },
                set: { onlineSearchQuery = $0 }
            )) { query in
                OnlineSearchResultsView(query: query)
            }
            .sheet(isPresented: $isShowingScanner) { ScannerView(scannedBarcode: $scannedBarcode).ignoresSafeArea() }
            .onChange(of: scannedBarcode) { _, newValue in if let barcode = newValue { fetchFromOpenFoodFacts(barcode: barcode) } }
        }
    }
    
    private var foodListContent: some View {
        Group {
            if !searchText.isEmpty {
                Section {
                    Button(action: {
                        onlineSearchQuery = searchText
                    }) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Search '\(searchText)' Globally")
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if filteredFoods.isEmpty {
                ContentUnavailableView("No Foods Locally", systemImage: "carrot", description: Text("Tap '+' to create food, or search globally above."))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filteredFoods) { food in
                    NavigationLink(destination: LogFoodView(food: food, selectedDate: selectedDate)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(food.name).font(.headline)
                            HStack(spacing: 8) {
                                Text("\(Int(food.calories)) kcal").foregroundColor(.green)
                                Text("•  \(Int(food.protein))g P | \(Int(food.carbs))g C | \(Int(food.fat))g F").foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    .swipeActions { Button(role: .destructive) { context.delete(food) } label: { Label("Delete", systemImage: "trash") } }
                }
            }
        }
    }
    
    private var recipeListContent: some View {
        Group {
            if filteredRecipes.isEmpty {
                ContentUnavailableView("No Recipes", systemImage: "frying.pan", description: Text("Tap '+' to combine foods into a recipe."))
                    .listRowBackground(Color.clear)
            } else {
                ScrollView {
                    let groupedRecipes = Dictionary(grouping: filteredRecipes, by: { $0.category })
                    let sortedCategories = groupedRecipes.keys.sorted()
                    
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(sortedCategories, id: \.self) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizedStringKey(category))
                                    .font(.title2.weight(.bold))
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(groupedRecipes[category] ?? []) { recipe in
                                            NavigationLink(destination: LogRecipeView(recipe: recipe, selectedDate: selectedDate)) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .fill(Color.green.opacity(0.1))
                                                            .frame(width: 140, height: 100)
                                                        Image(systemName: recipe.systemImage)
                                                            .font(.system(size: 40))
                                                            .foregroundColor(.green)
                                                    }
                                                    
                                                    Text(recipe.name)
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                        .lineLimit(2)
                                                        .frame(width: 140, alignment: .leading)
                                                    
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "clock")
                                                        Text("\(recipe.prepTimeMinutes) min")
                                                    }
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    
                                                    Text("\(Int(recipe.calories)) kcal")
                                                        .font(.subheadline.weight(.semibold))
                                                        .foregroundColor(.green)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    context.delete(recipe)
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
    }
    
    private func fetchFromOpenFoodFacts(barcode: String) {
        if let existingFood = foodLibrary.first(where: { $0.barcode == barcode }) {
            selectedExistingFood = existingFood
            return
        }
        
        isFetchingAPI = true
        Task {
            if let result = try? await OpenFoodFactsAPI.fetchProduct(barcode: barcode) {
                await MainActor.run { 
                    prefilledAPIResult = (name: result.name, calories: result.calories, protein: result.protein, carbs: result.carbs, fat: result.fat, barcode: barcode, category: result.category, fiber: result.fiber, sugar: result.sugar, saturatedFat: result.saturatedFat, sodium: result.sodium, imageUrl: result.imageUrl, nutriscore: result.nutriscore, ecoscore: result.ecoscore, novaGroup: result.novaGroup, ingredients: result.ingredients, allergens: result.allergens, brand: result.brand)
                    isFetchingAPI = false
                    navigateToCreateFood = true 
                }
            } else {
                await MainActor.run { isFetchingAPI = false; prefilledAPIResult = nil; navigateToCreateFood = true }
            }
        }
    }
}

// MARK: - 1. Quick Estimate
struct QuickEstimateView: View {
    var selectedDate: Date
    @Binding var isRootPresented: Bool
    @Environment(\.modelContext) private var context
    
    @State private var name: String = ""
    @State private var calories: Double?
    @State private var protein: Double?
    @State private var carbs: Double?
    @State private var fat: Double?
    @FocusState private var isInputActive: Bool
    
    var body: some View {
        Form {
            Section(
                header: Text("Restaurant or Quick Meal"),
                footer: Text("Don't know the exact macros? Just estimate the calories. Consistency is more important than perfect accuracy.")
            ) {
                TextField("e.g. Five Guys Cheeseburger", text: $name)
                    .focused($isInputActive)
                
                HStack {
                    Text("Estimated Calories")
                    Spacer()
                    TextField("Required", value: $calories, format: .number)
                        .keyboardType(.numberPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.green)
                        .font(.title3.weight(.bold))
                }
            }
            
            Section(
                header: Text("Optional Macros"),
                footer: Text("If you know the exact macros, you can enter them here. Otherwise, they will be logged as 0g.")
            ) {
                HStack {
                    Text("Protein")
                    Spacer()
                    TextField("Optional", value: $protein, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.red)
                }
                HStack {
                    Text("Carbs")
                    Spacer()
                    TextField("Optional", value: $carbs, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Fat")
                    Spacer()
                    TextField("Optional", value: $fat, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("Quick Estimate")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isRootPresented = false
                }
            }
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    isInputActive = false
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Log Meal") {
                    let finalCalories = max(0, calories ?? 0)
                    let finalProtein = max(0, protein ?? 0)
                    let finalCarbs = max(0, carbs ?? 0)
                    let finalFat = max(0, fat ?? 0)
                    
                    let meal = ConsumedMeal(
                        name: name,
                        calories: finalCalories,
                        protein: finalProtein,
                        carbs: finalCarbs,
                        fat: finalFat,
                        weightGrams: 0,
                        consumedAt: selectedDate,
                        mealCategory: autoMealCategory(for: selectedDate)
                    )
                    context.insert(meal)
                    try? context.save()
                    
                    HapticManager.shared.notification(.success)
                    HealthKitManager.shared.saveMeal(
                        name: name,
                        calories: finalCalories,
                        protein: finalProtein,
                        carbs: finalCarbs,
                        fat: finalFat,
                        date: selectedDate
                    )
                    Task { WidgetCenter.shared.reloadAllTimelines() }
                    isRootPresented = false
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || calories == nil)
            }
        }
        .onAppear {
            isInputActive = true
        }
    }
}

// MARK: - 2. Log Recipe
struct LogRecipeView: View {
    let recipe: RecipeItem
    var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var servings: Double = 1
    @FocusState private var isInputActive: Bool
    @State private var showingEditSheet = false
    
    private var validServings: Double {
        max(0, servings)
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
                        .disabled(servings <= 0)
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
        dismiss()
    }
}

struct StatBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.weight(.bold))
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - 3. Log Single Food
struct LogFoodView: View {
    let food: FoodItem
    var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var weight: Double = 100
    @FocusState private var isInputActive: Bool
    
    private var validWeight: Double {
        max(0, weight)
    }
    
    private var multiplier: Double {
        validWeight / 100.0
    }
    
    private var calcCalories: Double { food.calories * multiplier }
    private var calcProtein: Double { food.protein * multiplier }
    private var calcCarbs: Double { food.carbs * multiplier }
    private var calcFat: Double { food.fat * multiplier }
    
    private var isDrink: Bool {
        let cat = food.category.lowercased()
        return cat.contains("drink") || cat.contains("beverage") || cat.contains("liquid")
    }
    
    var body: some View {
        Form {
            Section(header: Text("How much did you eat?")) {
                HStack {
                    Text(isDrink ? "Volume (ml)" : "Weight (grams)")
                    Spacer()
                    TextField("100", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                        .focused($isInputActive)
                        .multilineTextAlignment(.trailing)
                        .font(.title3.weight(.bold))
                }
            }
            Section(header: Text("Calculated Nutrition")) {
                LabeledContent("Calories", value: "\(Int(calcCalories)) kcal").foregroundColor(.green)
                LabeledContent("Protein", value: "\(Int(calcProtein)) g").foregroundColor(.red)
                LabeledContent("Carbs", value: "\(Int(calcCarbs)) g").foregroundColor(.blue)
                LabeledContent("Fat", value: "\(Int(calcFat)) g").foregroundColor(.orange)
            }
        }
        .navigationTitle(food.name)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("Done") {
                    isInputActive = false
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Log Meal") {
                    let meal = ConsumedMeal(
                        name: food.name,
                        calories: calcCalories,
                        protein: calcProtein,
                        carbs: calcCarbs,
                        fat: calcFat,
                        weightGrams: validWeight,
                        consumedAt: selectedDate,
                        mealCategory: autoMealCategory(for: selectedDate),
                        fiber: food.fiber.map { $0 * validWeight / 100.0 },
                        sugar: food.sugar.map { $0 * validWeight / 100.0 },
                        saturatedFat: food.saturatedFat.map { $0 * validWeight / 100.0 },
                        sodium: food.sodium.map { $0 * validWeight / 100.0 }
                    )
                    context.insert(meal)
                    try? context.save()
                    
                    HapticManager.shared.notification(.success)
                    HealthKitManager.shared.saveMeal(
                        name: food.name,
                        calories: calcCalories,
                        protein: calcProtein,
                        carbs: calcCarbs,
                        fat: calcFat,
                        date: selectedDate
                    )
                    Task { WidgetCenter.shared.reloadAllTimelines() }
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(weight <= 0)
            }
        }
        .onAppear {
            isInputActive = true
        }
    }
}

// MARK: - 4. Create Custom Food
struct CreateFoodView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    var prefilledData: (name: String, calories: Double, protein: Double, carbs: Double, fat: Double, barcode: String, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)?
    
    @State private var name: String = ""
    @State private var calories: Double?
    @State private var protein: Double?
    @State private var carbs: Double?
    @State private var fat: Double?
    @State private var fiber: Double?
    @State private var sugar: Double?
    @State private var saturatedFat: Double?
    @State private var sodium: Double?
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
                        brand: prefilledData?.brand
                    )
                    context.insert(newFood)
                    try? context.save()
                    HapticManager.shared.notification(.success)
                    Task { WidgetCenter.shared.reloadAllTimelines() } 
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || calories == nil)
            }
        }
    }
}


// MARK: - 5. Edit Logged Meal
struct EditMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    var meal: ConsumedMeal
    
    @State private var weight: Double
    @State private var calories: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double
    @FocusState private var isInputActive: Bool
    
    let isWeightBased: Bool
    let originalMacrosPerGram: (cals: Double, pro: Double, carb: Double, fat: Double)?
    
    init(meal: ConsumedMeal) {
        self.meal = meal
        _weight = State(initialValue: meal.weightGrams)
        _calories = State(initialValue: meal.calories)
        _protein = State(initialValue: meal.protein)
        _carbs = State(initialValue: meal.carbs)
        _fat = State(initialValue: meal.fat)
        
        self.isWeightBased = meal.weightGrams > 0
        if meal.weightGrams > 0 {
            self.originalMacrosPerGram = (
                cals: meal.calories / meal.weightGrams,
                pro: meal.protein / meal.weightGrams,
                carb: meal.carbs / meal.weightGrams,
                fat: meal.fat / meal.weightGrams
            )
        } else {
            self.originalMacrosPerGram = nil
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if isWeightBased {
                    Section(header: Text("How much did you eat?"), footer: Text("Macros will auto-update based on the new weight.")) {
                        HStack {
                            Text("Weight (grams / ml)")
                            Spacer()
                            TextField("100", value: $weight, format: .number)
                                .keyboardType(.decimalPad)
                                .focused($isInputActive)
                                .multilineTextAlignment(.trailing)
                                .font(.title3.weight(.bold))
                                .onChange(of: weight) { _, newValue in
                                    if let original = originalMacrosPerGram {
                                        let validWeight = max(0, newValue)
                                        calories = validWeight * original.cals
                                        protein = validWeight * original.pro
                                        carbs = validWeight * original.carb
                                        fat = validWeight * original.fat
                                    }
                                }
                        }
                    }
                }
                
                Section(header: Text("Calculated Nutrition")) {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("Calories", value: $calories, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isInputActive)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.green)
                            .disabled(isWeightBased)
                    }
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("Protein", value: $protein, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isInputActive)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.red)
                            .disabled(isWeightBased)
                    }
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("Carbs", value: $carbs, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isInputActive)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.blue)
                            .disabled(isWeightBased)
                    }
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("Fat", value: $fat, format: .number)
                            .keyboardType(.decimalPad)
                            .focused($isInputActive)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.orange)
                            .disabled(isWeightBased)
                    }
                }
            }
            .navigationTitle("Edit \(meal.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { isInputActive = false }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        meal.weightGrams = weight
                        meal.calories = calories
                        meal.protein = protein
                        meal.carbs = carbs
                        meal.fat = fat
                        try? context.save()
                        HapticManager.shared.notification(.success)
                        Task { WidgetCenter.shared.reloadAllTimelines() } 
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            isInputActive = true
        }
    }
}

// MARK: - Online Search Results View
extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct OnlineSearchResultsView: View {
    let query: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var isSearching = true
    @State private var results: [(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)] = []
    
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                    Text("Community Data. Please verify with the product label if accuracy is critical.").font(.footnote).foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            if isSearching {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView().scaleEffect(1.5)
                        Text("Searching globally...").foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if results.isEmpty {
                ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Could not find anything for '\(query)'."))
                    .listRowBackground(Color.clear)
            } else {
                ForEach(results, id: \.name) { res in
                    Button(action: {
                        let newFood = FoodItem(name: res.name, calories: res.calories, protein: res.protein, carbs: res.carbs, fat: res.fat, barcode: nil, category: res.category, fiber: res.fiber, sugar: res.sugar, saturatedFat: res.saturatedFat, sodium: res.sodium, imageUrl: res.imageUrl, nutriscore: res.nutriscore, ecoscore: res.ecoscore, novaGroup: res.novaGroup, ingredients: res.ingredients, allergens: res.allergens, brand: res.brand)
                        context.insert(newFood)
                        try? context.save()
                        HapticManager.shared.impact(.light)
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(res.name).font(.headline).foregroundColor(.primary)
                                Spacer()
                                if let nutriscore = res.nutriscore {
                                    Text("N: \(nutriscore.uppercased())").font(.caption2).fontWeight(.bold).padding(.horizontal, 6).padding(.vertical, 2).background(Color.secondary.opacity(0.2)).cornerRadius(4).foregroundColor(.primary)
                                }
                            }
                            if let brand = res.brand {
                                Text(brand).font(.caption).foregroundColor(.secondary)
                            }
                            HStack(spacing: 8) {
                                Text("\(Int(res.calories)) kcal").foregroundColor(.green)
                                Text("•  \(Int(res.protein))g P | \(Int(res.carbs))g C | \(Int(res.fat))g F").foregroundColor(.secondary)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Global Results")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let res = try? await OpenFoodFactsAPI.searchProducts(query: query) {
                await MainActor.run {
                    self.results = res
                    self.isSearching = false
                }
            } else {
                await MainActor.run { self.isSearching = false }
            }
        }
    }
}
