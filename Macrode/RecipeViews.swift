import SwiftUI
import SwiftData
import VisionKit

struct RecipeIngredientTemp: Identifiable {
    let id = UUID()
    let food: FoodItem
    var weightGrams: Double
}

struct CreateRecipeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FoodItem.name) private var foodLibrary: [FoodItem]
    
    @State private var recipeName: String = ""
    @State private var ingredients: [RecipeIngredientTemp] = []
    
    @State private var showingAddIngredient = false
    @State private var selectedFood: FoodItem?
    @State private var ingredientWeight: Double = 100
    @FocusState private var isNameFocused: Bool
    
    private var totalCalories: Double { ingredients.reduce(0) { $0 + ($1.food.calories * ($1.weightGrams / 100)) } }
    private var totalProtein: Double { ingredients.reduce(0) { $0 + ($1.food.protein * ($1.weightGrams / 100)) } }
    private var totalCarbs: Double { ingredients.reduce(0) { $0 + ($1.food.carbs * ($1.weightGrams / 100)) } }
    private var totalFat: Double { ingredients.reduce(0) { $0 + ($1.food.fat * ($1.weightGrams / 100)) } }
    
    var body: some View {
        Form {
            Section(header: Text("Recipe Name")) {
                TextField("e.g., Morning Protein Oats", text: $recipeName)
                    .focused($isNameFocused)
            }
            
            Section(header: Text("Ingredients"), footer: Text("Add foods from your library to build this recipe.")) {
                ForEach(ingredients) { ingredient in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(ingredient.food.name).font(.headline)
                            Text("\(Int(ingredient.weightGrams))g").font(.subheadline).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(Int(ingredient.food.calories * (ingredient.weightGrams / 100))) kcal")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .onDelete(perform: deleteIngredient)
                
                Button(action: { showingAddIngredient = true }) {
                    Label("Add Ingredient", systemImage: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.headline)
                }
            }
            
            if !ingredients.isEmpty {
                Section(header: Text("Total Nutrition (Per 1 Serving)")) {
                    LabeledContent("Calories", value: "\(Int(totalCalories)) kcal").foregroundColor(.green)
                    LabeledContent("Protein", value: "\(Int(totalProtein)) g").foregroundColor(.red)
                    LabeledContent("Carbs", value: "\(Int(totalCarbs)) g").foregroundColor(.blue)
                    LabeledContent("Fat", value: "\(Int(totalFat)) g").foregroundColor(.orange)
                }
            }
        }
        .navigationTitle("Create Recipe")
        .toolbar {
            ToolbarItem(placement: .keyboard) { Button("Done") { isNameFocused = false }.frame(maxWidth: .infinity, alignment: .trailing) }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save Recipe") {
                    saveRecipe()
                }
                .disabled(recipeName.isEmpty || ingredients.isEmpty)
            }
        }
        .sheet(isPresented: $showingAddIngredient) {
            IngredientPickerSheet(
                foodLibrary: foodLibrary,
                onFoodSelected: { food in
                    self.selectedFood = food
                }
            )
        }
        .alert("How many grams?", isPresented: Binding(
            get: { selectedFood != nil },
            set: { if !$0 { selectedFood = nil } }
        )) {
            TextField("Weight in grams", value: $ingredientWeight, format: .number).keyboardType(.decimalPad)
            Button("Add") {
                if let food = selectedFood {
                    ingredients.append(RecipeIngredientTemp(food: food, weightGrams: ingredientWeight))
                    selectedFood = nil
                    ingredientWeight = 100
                }
            }
            Button("Cancel", role: .cancel) { selectedFood = nil }
        }
    }
    
    private func deleteIngredient(at offsets: IndexSet) { ingredients.remove(atOffsets: offsets) }
    
    private func saveRecipe() {
        let newRecipe = RecipeItem(name: recipeName, calories: totalCalories, protein: totalProtein, carbs: totalCarbs, fat: totalFat)
        context.insert(newRecipe)
        dismiss()
    }
}

// MARK: - THE INGREDIENT PICKER SHEET
struct IngredientPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var foodLibrary: [FoodItem]
    var onFoodSelected: (FoodItem) -> Void
    
    @State private var searchText = ""
    @State private var isShowingScanner = false
    @State private var scannedBarcode: String? = nil
    
    @State private var isFetchingAPI = false
    @State private var navigateToCreateFood = false
    @State private var prefilledAPIResult: (name: String, calories: Double, protein: Double, carbs: Double, fat: Double, barcode: String, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)? = nil
    @State private var onlineSearchQuery: String? = nil
    
    var filteredFoods: [FoodItem] {
        if searchText.isEmpty { return foodLibrary }
        return foodLibrary.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
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
                        ContentUnavailableView("No Foods Locally", systemImage: "carrot", description: Text("Search globally above, or scan a barcode."))
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(filteredFoods) { food in
                            Button(action: {
                                onFoodSelected(food)
                                dismiss()
                            }) {
                                HStack {
                                    Text(food.name).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search ingredients...")
                
                if isFetchingAPI {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack {
                        ProgressView().scaleEffect(1.5).padding()
                        Text("Looking up product...").font(.headline).foregroundColor(.white)
                    }
                }
            }
            .navigationTitle("Pick Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                        Button(action: { isShowingScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                ScannerView(scannedBarcode: $scannedBarcode).ignoresSafeArea()
            }
            .onChange(of: scannedBarcode) { _, newValue in
                if let barcode = newValue {
                    isShowingScanner = false
                    fetchFromOpenFoodFacts(barcode: barcode)
                }
            }
            .navigationDestination(isPresented: $navigateToCreateFood) { 
                CreateFoodView(prefilledData: prefilledAPIResult) 
            }
            .navigationDestination(item: Binding<String?>(
                get: { onlineSearchQuery },
                set: { onlineSearchQuery = $0 }
            )) { query in
                OnlineSearchResultsView(query: query)
            }
        }
    }
    
    private func fetchFromOpenFoodFacts(barcode: String) {
        if let existingFood = foodLibrary.first(where: { $0.barcode == barcode }) {
            onFoodSelected(existingFood)
            dismiss()
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
                await MainActor.run { 
                    isFetchingAPI = false
                    prefilledAPIResult = nil
                    navigateToCreateFood = true 
                }
            }
        }
    }
}

// MARK: - Edit Recipe
struct EditRecipeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    var recipe: RecipeItem
    
    @State private var name: String
    @State private var calories: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double
    @State private var category: String
    @State private var prepTimeMinutes: Int
    @FocusState private var isInputActive: Bool
    
    let categories = ["Breakfast", "Lunch", "Dinner", "Snack", "Dessert", "Shake", "Other"]
    
    init(recipe: RecipeItem) {
        self.recipe = recipe
        _name = State(initialValue: recipe.name)
        _calories = State(initialValue: recipe.calories)
        _protein = State(initialValue: recipe.protein)
        _carbs = State(initialValue: recipe.carbs)
        _fat = State(initialValue: recipe.fat)
        _category = State(initialValue: recipe.category)
        _prepTimeMinutes = State(initialValue: recipe.prepTimeMinutes)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Recipe Details"), footer: Text("Note: Editing ingredients is not currently supported. You can manually adjust the total nutrition values here.")) {
                    TextField("Recipe Name", text: $name)
                        .focused($isInputActive)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    HStack {
                        Text("Prep Time (min)")
                        Spacer()
                        TextField("e.g. 15", value: $prepTimeMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .focused($isInputActive)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Total Nutrition (Per 1 Serving)")) {
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
                }
            }
            .navigationTitle("Edit \(recipe.name)")
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
                        recipe.name = name
                        recipe.calories = max(0, calories)
                        recipe.protein = max(0, protein)
                        recipe.carbs = max(0, carbs)
                        recipe.fat = max(0, fat)
                        recipe.category = category
                        recipe.prepTimeMinutes = max(0, prepTimeMinutes)
                        
                        try? context.save()
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || calories < 0)
                }
            }
        }
        .onAppear {
        }
    }
}
