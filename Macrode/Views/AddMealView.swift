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
    @Binding var mainTabSelection: Int
    
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
    @State private var onlineSearchQuery: String?
    @State private var foodToEdit: FoodItem? = nil
    
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
            .navigationDestination(isPresented: $navigateToCreateFood) { 
                CreateFoodView(prefilledData: prefilledAPIResult, editingFood: foodToEdit, selectedDate: selectedDate, mainTabSelection: $mainTabSelection)
                    .onDisappear { foodToEdit = nil; prefilledAPIResult = nil }
            }
            .navigationDestination(isPresented: $navigateToQuickEstimate) { QuickEstimateView(selectedDate: selectedDate, isRootPresented: $navigateToQuickEstimate, mainTabSelection: $mainTabSelection) }
            .navigationDestination(item: $selectedExistingFood) { food in LogFoodView(food: food, selectedDate: selectedDate, mainTabSelection: $mainTabSelection) }
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
                    NavigationLink(destination: LogFoodView(food: food, selectedDate: selectedDate, mainTabSelection: $mainTabSelection)) {
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
                    .swipeActions { 
                        Button(role: .destructive) { context.delete(food) } label: { Label("Delete", systemImage: "trash") } 
                        Button {
                            foodToEdit = food
                            prefilledAPIResult = (name: food.name, calories: food.calories, protein: food.protein, carbs: food.carbs, fat: food.fat, barcode: food.barcode ?? "", category: food.category, fiber: food.fiber, sugar: food.sugar, saturatedFat: food.saturatedFat, sodium: food.sodium, imageUrl: food.imageUrl, nutriscore: food.nutriscore, ecoscore: food.ecoscore, novaGroup: food.novaGroup, ingredients: food.ingredients, allergens: food.allergens, brand: food.brand)
                            navigateToCreateFood = true
                        } label: { Label("Edit", systemImage: "pencil") }.tint(.blue)
                    }
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
                                            NavigationLink(destination: LogRecipeView(recipe: recipe, selectedDate: selectedDate, mainTabSelection: $mainTabSelection)) {
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

