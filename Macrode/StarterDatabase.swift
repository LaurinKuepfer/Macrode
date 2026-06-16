import Foundation

struct StarterFood {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let category: String
}

struct StarterRecipe {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let instructions: [String]
    let category: String
    let prepTimeMinutes: Int
    let difficulty: String
    let systemImage: String
}

struct StarterDatabase {
    
    static var currentLanguage: String {
        return UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
    }
    
    static var foods: [StarterFood] {
        let lang = currentLanguage == "system" ? (Locale.current.language.languageCode?.identifier ?? "en") : currentLanguage
        if lang.hasPrefix("de") { return foodsDE }
        if lang.hasPrefix("es") { return foodsES }
        if lang.hasPrefix("fr") { return foodsFR }
        return foodsEN
    }
    
    static var recipes: [StarterRecipe] {
        let lang = currentLanguage == "system" ? (Locale.current.language.languageCode?.identifier ?? "en") : currentLanguage
        if lang.hasPrefix("de") { return recipesDE }
        if lang.hasPrefix("es") { return recipesES }
        if lang.hasPrefix("fr") { return recipesFR }
        return recipesEN
    }
    
    static var allStarterFoodNames: Set<String> {
        let all = foodsEN + foodsDE + foodsES + foodsFR
        return Set(all.map { $0.name })
    }
    
    static var allStarterRecipeNames: Set<String> {
        let all = recipesEN + recipesDE + recipesES + recipesFR
        return Set(all.map { $0.name })
    }
    
    // MARK: - ENGLISH DATABASE
    private static let foodsEN: [StarterFood] = [
        StarterFood(name: "Quinoa (Cooked)", calories: 120, protein: 4.4, carbs: 21.3, fat: 1.9, category: "Carbs"),
        StarterFood(name: "Brown Rice (Cooked)", calories: 112, protein: 2.6, carbs: 23.5, fat: 0.9, category: "Carbs"),
        StarterFood(name: "Whole Wheat Bread", calories: 247, protein: 13.0, carbs: 41.0, fat: 3.4, category: "Carbs"),
        StarterFood(name: "Potato (Baked)", calories: 93, protein: 2.5, carbs: 21.0, fat: 0.1, category: "Carbs"),
        StarterFood(name: "Lentils (Cooked)", calories: 116, protein: 9.0, carbs: 20.0, fat: 0.4, category: "Carbs"),
        StarterFood(name: "Black Beans (Cooked)", calories: 132, protein: 8.9, carbs: 23.7, fat: 0.5, category: "Carbs"),
        StarterFood(name: "Pork Chop (Lean)", calories: 197, protein: 25.0, carbs: 0.0, fat: 10.0, category: "Meat"),
        StarterFood(name: "Turkey Breast", calories: 147, protein: 30.0, carbs: 0.0, fat: 2.0, category: "Meat"),
        StarterFood(name: "Tuna (Canned)", calories: 86, protein: 19.4, carbs: 0.0, fat: 1.0, category: "Meat"),
        StarterFood(name: "Shrimp", calories: 99, protein: 24.0, carbs: 0.2, fat: 0.3, category: "Meat"),
        StarterFood(name: "Tofu", calories: 144, protein: 15.8, carbs: 2.8, fat: 8.7, category: "Other"),
        StarterFood(name: "Cottage Cheese", calories: 72, protein: 12.4, carbs: 2.7, fat: 1.0, category: "Dairy & Fats"),
        StarterFood(name: "Cheddar Cheese", calories: 402, protein: 25.0, carbs: 1.3, fat: 33.0, category: "Dairy & Fats"),
        StarterFood(name: "Mozzarella", calories: 254, protein: 24.3, carbs: 2.8, fat: 15.9, category: "Dairy & Fats"),
        StarterFood(name: "Walnuts", calories: 654, protein: 15.2, carbs: 13.7, fat: 65.2, category: "Dairy & Fats"),
        StarterFood(name: "Chia Seeds", calories: 486, protein: 16.5, carbs: 42.1, fat: 30.7, category: "Dairy & Fats"),
        StarterFood(name: "Orange", calories: 47, protein: 0.9, carbs: 11.8, fat: 0.1, category: "Fruits"),
        StarterFood(name: "Strawberries", calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Blueberries", calories: 57, protein: 0.7, carbs: 14.5, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Watermelon", calories: 30, protein: 0.6, carbs: 7.6, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Tomato", calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Carrot", calories: 41, protein: 0.9, carbs: 9.6, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Cucumber", calories: 15, protein: 0.6, carbs: 3.6, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Bell Pepper", calories: 20, protein: 0.9, carbs: 4.6, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Onion", calories: 40, protein: 1.1, carbs: 9.3, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Garlic", calories: 149, protein: 6.4, carbs: 33.1, fat: 0.5, category: "Vegetables"),
        StarterFood(name: "Protein Bar", calories: 350, protein: 20.0, carbs: 35.0, fat: 10.0, category: "Fast Food"),
        StarterFood(name: "Orange Juice", calories: 45, protein: 0.7, carbs: 10.4, fat: 0.2, category: "Drinks"),
        StarterFood(name: "Coffee (Black)", calories: 2, protein: 0.3, carbs: 0.0, fat: 0.0, category: "Drinks"),
        StarterFood(name: "Chicken Breast (Raw)", calories: 120, protein: 22.5, carbs: 0.0, fat: 2.6, category: "Meat"),
        StarterFood(name: "Ground Beef (95% Lean, Raw)", calories: 137, protein: 21.4, carbs: 0.0, fat: 5.0, category: "Meat"),
        StarterFood(name: "Atlantic Salmon (Raw)", calories: 208, protein: 20.0, carbs: 0.0, fat: 13.0, category: "Meat"),
        StarterFood(name: "Jasmine Rice (Dry)", calories: 356, protein: 7.1, carbs: 78.9, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Oats (Rolled)", calories: 379, protein: 13.1, carbs: 67.7, fat: 6.5, category: "Carbs"),
        StarterFood(name: "Sweet Potato (Raw)", calories: 86, protein: 1.6, carbs: 20.1, fat: 0.1, category: "Carbs"),
        StarterFood(name: "Olive Oil", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Butter", calories: 717, protein: 0.8, carbs: 0.1, fat: 81.0, category: "Dairy & Fats"),
        StarterFood(name: "Avocado", calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7, category: "Dairy & Fats"),
        StarterFood(name: "Almonds", calories: 579, protein: 21.1, carbs: 21.6, fat: 49.9, category: "Dairy & Fats"),
        StarterFood(name: "Greek Yogurt (0% Fat)", calories: 59, protein: 10.3, carbs: 3.6, fat: 0.4, category: "Dairy & Fats"),
        StarterFood(name: "Whole Milk (3.25%)", calories: 61, protein: 3.1, carbs: 4.8, fat: 3.2, category: "Drinks"),
        StarterFood(name: "Whey Protein Powder", calories: 379, protein: 78.0, carbs: 6.0, fat: 5.0, category: "Other"),
        StarterFood(name: "Banana", calories: 89, protein: 1.1, carbs: 22.8, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Apple", calories: 52, protein: 0.3, carbs: 13.8, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Broccoli (Raw)", calories: 34, protein: 2.8, carbs: 6.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Spinach (Raw)", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Egg (Whole, Raw)", calories: 143, protein: 12.6, carbs: 0.7, fat: 9.5, category: "Dairy & Fats"),
        StarterFood(name: "Peanut Butter", calories: 588, protein: 25.0, carbs: 20.0, fat: 50.0, category: "Dairy & Fats"),
        StarterFood(name: "Honey", calories: 304, protein: 0.3, carbs: 82.4, fat: 0.0, category: "Other")
    ]
    
    private static let recipesEN: [StarterRecipe] = [
        StarterRecipe(name: "Classic Protein Pancakes", calories: 350, protein: 30.0, carbs: 35.0, fat: 8.0, instructions: ["Blend 50g oats, 1 scoop whey, 1 egg, and 50ml milk.", "Cook on a non-stick pan until bubbly, then flip.", "Top with zero-calorie syrup or berries."], category: "Breakfast", prepTimeMinutes: 15, difficulty: "Medium", systemImage: "circle.grid.2x2"),
        StarterRecipe(name: "Tuna Salad Wrap", calories: 400, protein: 35.0, carbs: 30.0, fat: 12.0, instructions: ["Mix 1 can of drained tuna with 2 tbsp light mayo and diced onions.", "Spread on a whole wheat tortilla.", "Add spinach and wrap tightly."], category: "Lunch", prepTimeMinutes: 5, difficulty: "Easy", systemImage: "leaf"),
        StarterRecipe(name: "Lean Beef Chili", calories: 500, protein: 45.0, carbs: 40.0, fat: 15.0, instructions: ["Brown 150g lean ground beef.", "Add 100g kidney beans, 100g canned tomatoes, and chili spices.", "Simmer for 15 minutes."], category: "Dinner", prepTimeMinutes: 20, difficulty: "Medium", systemImage: "flame"),
        StarterRecipe(name: "Vegan Tofu Stir-fry", calories: 380, protein: 25.0, carbs: 30.0, fat: 18.0, instructions: ["Cube 150g firm tofu and pan-fry in 1 tbsp sesame oil.", "Add 150g mixed veggies (broccoli, bell peppers).", "Stir in 2 tbsp soy sauce and serve over quinoa."], category: "Dinner", prepTimeMinutes: 15, difficulty: "Medium", systemImage: "leaf.arrow.triangle.circlepath"),
        StarterRecipe(name: "Cottage Cheese & Pineapple", calories: 200, protein: 20.0, carbs: 20.0, fat: 4.0, instructions: ["Spoon 150g low-fat cottage cheese into a bowl.", "Top with 100g diced pineapple chunks.", "Sprinkle with a pinch of cinnamon."], category: "Snack", prepTimeMinutes: 2, difficulty: "Easy", systemImage: "sun.max"),
        StarterRecipe(name: "High-Protein Scrambled Eggs", calories: 300, protein: 25.0, carbs: 2.0, fat: 20.0, instructions: ["Whisk 2 whole eggs and 100g egg whites.", "Scramble in a hot pan.", "Top with a pinch of salt and chives."], category: "Breakfast", prepTimeMinutes: 5, difficulty: "Easy", systemImage: "frying.pan"),
        StarterRecipe(name: "Grilled Salmon & Asparagus", calories: 450, protein: 35.0, carbs: 5.0, fat: 25.0, instructions: ["Season a 150g salmon fillet with lemon and pepper.", "Grill salmon and 100g asparagus for 10-12 minutes.", "Serve with a slice of lemon."], category: "Dinner", prepTimeMinutes: 15, difficulty: "Medium", systemImage: "fish"),
        StarterRecipe(name: "Chocolate Protein Mousse", calories: 250, protein: 30.0, carbs: 10.0, fat: 5.0, instructions: ["Mix 200g greek yogurt with 1 scoop chocolate whey.", "Stir until perfectly smooth.", "Chill in fridge for 10 minutes before eating."], category: "Dessert", prepTimeMinutes: 5, difficulty: "Easy", systemImage: "star"),
        StarterRecipe(name: "Turkey & Cheese Roll-ups", calories: 220, protein: 24.0, carbs: 4.0, fat: 12.0, instructions: ["Take 4 slices of deli turkey breast.", "Place 1 slice of cheddar cheese inside each.", "Roll them up and eat as a quick snack."], category: "Snack", prepTimeMinutes: 2, difficulty: "Easy", systemImage: "cylinder"),
        StarterRecipe(name: "Berry Protein Smoothie", calories: 300, protein: 25.0, carbs: 35.0, fat: 5.0, instructions: ["Blend 1 cup almond milk, 1 scoop vanilla whey, 100g mixed berries, and a handful of spinach.", "Blend until smooth."], category: "Snack", prepTimeMinutes: 5, difficulty: "Easy", systemImage: "drop"),
        StarterRecipe(name: "Protein Oats & Peanut Butter", calories: 450, protein: 35.0, carbs: 45.0, fat: 15.0, instructions: ["Boil 200ml of water or milk.", "Stir in 50g of oats and simmer for 5 minutes.", "Mix in 1 scoop of whey protein off the heat.", "Top with 1 tbsp of peanut butter and enjoy!"], category: "Breakfast", prepTimeMinutes: 10, difficulty: "Easy", systemImage: "bowl"),
        StarterRecipe(name: "Chicken, Rice & Broccoli", calories: 550, protein: 45.0, carbs: 65.0, fat: 10.0, instructions: ["Cook 70g of dry jasmine rice according to package instructions.", "Season 150g chicken breast and pan-fry until golden brown and cooked through.", "Steam 100g of broccoli for 4 minutes.", "Serve everything together with a dash of soy sauce."], category: "Lunch", prepTimeMinutes: 25, difficulty: "Medium", systemImage: "frying.pan"),
        StarterRecipe(name: "Avocado Egg Toast", calories: 480, protein: 20.0, carbs: 35.0, fat: 28.0, instructions: ["Toast 2 slices of whole wheat bread.", "Mash half an avocado and spread evenly over the toast.", "Fry or poach 2 eggs to your liking.", "Place eggs on the avocado toast and sprinkle with salt, pepper, and chili flakes."], category: "Breakfast", prepTimeMinutes: 10, difficulty: "Easy", systemImage: "carrot"),
        StarterRecipe(name: "Greek Yogurt Berry Parfait", calories: 250, protein: 22.0, carbs: 30.0, fat: 4.0, instructions: ["Add 200g of Greek Yogurt into a bowl.", "Mix in a few drops of liquid sweetener or honey.", "Top with 100g of mixed berries and a small handful of granola."], category: "Snack", prepTimeMinutes: 5, difficulty: "Easy", systemImage: "cup.and.saucer"),
        StarterRecipe(name: "Quick Protein Shake", calories: 150, protein: 25.0, carbs: 5.0, fat: 2.0, instructions: ["Add 300ml of cold water or milk to a shaker.", "Add 1 scoop (30g) of whey protein powder.", "Shake vigorously for 15 seconds until smooth."], category: "Snack", prepTimeMinutes: 2, difficulty: "Easy", systemImage: "waterbottle")
    ]
    
    // MARK: - GERMAN DATABASE
    private static let foodsDE: [StarterFood] = [
        StarterFood(name: "Quinoa (Gekocht)", calories: 120, protein: 4.4, carbs: 21.3, fat: 1.9, category: "Carbs"),
        StarterFood(name: "Vollkornbrot", calories: 247, protein: 13.0, carbs: 41.0, fat: 3.4, category: "Carbs"),
        StarterFood(name: "Kartoffel (Gekocht)", calories: 93, protein: 2.5, carbs: 21.0, fat: 0.1, category: "Carbs"),
        StarterFood(name: "Linsen (Gekocht)", calories: 116, protein: 9.0, carbs: 20.0, fat: 0.4, category: "Carbs"),
        StarterFood(name: "Putenbrust", calories: 147, protein: 30.0, carbs: 0.0, fat: 2.0, category: "Meat"),
        StarterFood(name: "Thunfisch (Dose)", calories: 86, protein: 19.4, carbs: 0.0, fat: 1.0, category: "Meat"),
        StarterFood(name: "Tofu", calories: 144, protein: 15.8, carbs: 2.8, fat: 8.7, category: "Other"),
        StarterFood(name: "Hüttenkäse", calories: 72, protein: 12.4, carbs: 2.7, fat: 1.0, category: "Dairy & Fats"),
        StarterFood(name: "Walnüsse", calories: 654, protein: 15.2, carbs: 13.7, fat: 65.2, category: "Dairy & Fats"),
        StarterFood(name: "Erdbeeren", calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Tomate", calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, category: "Vegetables"),
        StarterFood(name: "Gurke", calories: 15, protein: 0.6, carbs: 3.6, fat: 0.1, category: "Vegetables"),
        StarterFood(name: "Kaffee (Schwarz)", calories: 2, protein: 0.3, carbs: 0.0, fat: 0.0, category: "Drinks"),
        StarterFood(name: "Hähnchenbrust (Roh)", calories: 120, protein: 22.5, carbs: 0.0, fat: 2.6, category: "Meat"),
        StarterFood(name: "Rinderhackfleisch (Mager, Roh)", calories: 137, protein: 21.4, carbs: 0.0, fat: 5.0, category: "Meat"),
        StarterFood(name: "Lachs (Roh)", calories: 208, protein: 20.0, carbs: 0.0, fat: 13.0, category: "Meat"),
        StarterFood(name: "Basmati Reis (Trocken)", calories: 356, protein: 7.1, carbs: 78.9, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Haferflocken (Zart)", calories: 379, protein: 13.1, carbs: 67.7, fat: 6.5, category: "Carbs"),
        StarterFood(name: "Süßkartoffel (Roh)", calories: 86, protein: 1.6, carbs: 20.1, fat: 0.1, category: "Carbs"),
        StarterFood(name: "Olivenöl", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Butter", calories: 717, protein: 0.8, carbs: 0.1, fat: 81.0, category: "Dairy & Fats"),
        StarterFood(name: "Avocado", calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7, category: "Dairy & Fats"),
        StarterFood(name: "Mandeln", calories: 579, protein: 21.1, carbs: 21.6, fat: 49.9, category: "Dairy & Fats"),
        StarterFood(name: "Magerquark", calories: 68, protein: 12.0, carbs: 4.1, fat: 0.2, category: "Dairy & Fats"),
        StarterFood(name: "Vollmilch (3,5%)", calories: 64, protein: 3.3, carbs: 4.8, fat: 3.6, category: "Drinks"),
        StarterFood(name: "Whey Protein Pulver", calories: 379, protein: 78.0, carbs: 6.0, fat: 5.0, category: "Other"),
        StarterFood(name: "Banane", calories: 89, protein: 1.1, carbs: 22.8, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Apfel", calories: 52, protein: 0.3, carbs: 13.8, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Brokkoli (Roh)", calories: 34, protein: 2.8, carbs: 6.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Spinat (Roh)", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Ei (Roh)", calories: 143, protein: 12.6, carbs: 0.7, fat: 9.5, category: "Dairy & Fats"),
        StarterFood(name: "Erdnussbutter", calories: 588, protein: 25.0, carbs: 20.0, fat: 50.0, category: "Dairy & Fats"),
        StarterFood(name: "Honig", calories: 304, protein: 0.3, carbs: 82.4, fat: 0.0, category: "Other")
    ]
    
    private static let recipesDE: [StarterRecipe] = [
        StarterRecipe(name: "Klassische Protein Pancakes", calories: 350, protein: 30.0, carbs: 35.0, fat: 8.0, instructions: ["50g Haferflocken, 1 Scoop Whey, 1 Ei und 50ml Milch mixen.", "In einer beschichteten Pfanne von beiden Seiten braten.", "Mit Beeren oder kalorienfreiem Sirup toppen."], category: "Frühstück", prepTimeMinutes: 15, difficulty: "Mittel", systemImage: "circle.grid.2x2"),
        StarterRecipe(name: "Thunfisch Salat Wrap", calories: 400, protein: 35.0, carbs: 30.0, fat: 12.0, instructions: ["1 Dose Thunfisch mit etwas Joghurt und Zwiebeln mischen.", "Auf einem Vollkorn-Wrap verteilen.", "Mit Spinat belegen und fest aufrollen."], category: "Mittagessen", prepTimeMinutes: 5, difficulty: "Leicht", systemImage: "leaf"),
        StarterRecipe(name: "Magerquark Schoko Mousse", calories: 250, protein: 30.0, carbs: 10.0, fat: 5.0, instructions: ["200g Magerquark mit 1 Scoop Schoko Whey vermischen.", "Glatt rühren bis es cremig ist.", "Vor dem Verzehr 10 Minuten kalt stellen."], category: "Dessert", prepTimeMinutes: 5, difficulty: "Leicht", systemImage: "star"),
        StarterRecipe(name: "Protein Smoothie", calories: 300, protein: 25.0, carbs: 35.0, fat: 5.0, instructions: ["Mandelmilch, Whey, Beeren und Spinat im Mixer pürieren."], category: "Snack", prepTimeMinutes: 5, difficulty: "Leicht", systemImage: "drop"),
        StarterRecipe(name: "Protein Oats & Erdnussmus", calories: 450, protein: 35.0, carbs: 45.0, fat: 15.0, instructions: ["200ml Wasser oder Milch in einem Topf aufkochen.", "50g Haferflocken einrühren und 5 Minuten köcheln lassen.", "Vom Herd nehmen und 1 Scoop Whey Protein unterrühren.", "Mit 1 EL Erdnussmus toppen und genießen!"], category: "Frühstück", prepTimeMinutes: 10, difficulty: "Leicht", systemImage: "bowl"),
        StarterRecipe(name: "Hähnchen, Reis & Brokkoli", calories: 550, protein: 45.0, carbs: 65.0, fat: 10.0, instructions: ["70g trockenen Basmatireis nach Packungsbeilage kochen.", "150g Hähnchenbrust würzen und in einer Pfanne goldbraun braten.", "100g Brokkoli für 4 Minuten dampfgaren.", "Alles zusammen mit einem Schuss Sojasauce servieren."], category: "Mittagessen", prepTimeMinutes: 25, difficulty: "Mittel", systemImage: "frying.pan"),
        StarterRecipe(name: "Avocado-Brot mit Spiegelei", calories: 480, protein: 20.0, carbs: 35.0, fat: 28.0, instructions: ["2 Scheiben Vollkornbrot toasten.", "Eine halbe Avocado zerdrücken und gleichmäßig auf dem Brot verteilen.", "2 Eier nach Belieben als Spiegelei oder pochiert zubereiten.", "Die Eier auf dem Avocado-Brot platzieren und mit Salz, Pfeffer und Chiliflocken würzen."], category: "Frühstück", prepTimeMinutes: 10, difficulty: "Leicht", systemImage: "carrot"),
        StarterRecipe(name: "Magerquark mit Beeren", calories: 250, protein: 30.0, carbs: 25.0, fat: 2.0, instructions: ["250g Magerquark in eine Schüssel geben und mit etwas Wasser cremig rühren.", "Nach Belieben mit FlavDrops oder Honig süßen.", "Mit 100g gemischten Beeren (z.B. Himbeeren, Blaubeeren) toppen."], category: "Snack", prepTimeMinutes: 5, difficulty: "Leicht", systemImage: "cup.and.saucer"),
        StarterRecipe(name: "Quick Protein Shake", calories: 150, protein: 25.0, carbs: 5.0, fat: 2.0, instructions: ["300ml kaltes Wasser oder Milch in einen Shaker füllen.", "1 Scoop (30g) Whey Protein Pulver hinzufügen.", "Für 15 Sekunden kräftig schütteln."], category: "Snack", prepTimeMinutes: 2, difficulty: "Leicht", systemImage: "waterbottle")
    ]
    
    // MARK: - SPANISH DATABASE
    private static let foodsES: [StarterFood] = [
        StarterFood(name: "Pechuga de Pollo (Cruda)", calories: 120, protein: 22.5, carbs: 0.0, fat: 2.6, category: "Meat"),
        StarterFood(name: "Carne Picada (Magra, Cruda)", calories: 137, protein: 21.4, carbs: 0.0, fat: 5.0, category: "Meat"),
        StarterFood(name: "Salmón (Crudo)", calories: 208, protein: 20.0, carbs: 0.0, fat: 13.0, category: "Meat"),
        StarterFood(name: "Arroz Jazmín (Seco)", calories: 356, protein: 7.1, carbs: 78.9, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Copos de Avena", calories: 379, protein: 13.1, carbs: 67.7, fat: 6.5, category: "Carbs"),
        StarterFood(name: "Boniato (Crudo)", calories: 86, protein: 1.6, carbs: 20.1, fat: 0.1, category: "Carbs"),
        StarterFood(name: "Aceite de Oliva", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Mantequilla", calories: 717, protein: 0.8, carbs: 0.1, fat: 81.0, category: "Dairy & Fats"),
        StarterFood(name: "Aguacate", calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7, category: "Dairy & Fats"),
        StarterFood(name: "Almendras", calories: 579, protein: 21.1, carbs: 21.6, fat: 49.9, category: "Dairy & Fats"),
        StarterFood(name: "Yogur Griego (0%)", calories: 59, protein: 10.3, carbs: 3.6, fat: 0.4, category: "Dairy & Fats"),
        StarterFood(name: "Leche Entera", calories: 61, protein: 3.1, carbs: 4.8, fat: 3.2, category: "Drinks"),
        StarterFood(name: "Proteína Whey", calories: 379, protein: 78.0, carbs: 6.0, fat: 5.0, category: "Other"),
        StarterFood(name: "Plátano", calories: 89, protein: 1.1, carbs: 22.8, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Manzana", calories: 52, protein: 0.3, carbs: 13.8, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Brócoli (Crudo)", calories: 34, protein: 2.8, carbs: 6.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Espinacas (Crudas)", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Huevo (Crudo)", calories: 143, protein: 12.6, carbs: 0.7, fat: 9.5, category: "Dairy & Fats"),
        StarterFood(name: "Crema de Cacahuete", calories: 588, protein: 25.0, carbs: 20.0, fat: 50.0, category: "Dairy & Fats"),
        StarterFood(name: "Miel", calories: 304, protein: 0.3, carbs: 82.4, fat: 0.0, category: "Other")
    ]
    
    private static let recipesES: [StarterRecipe] = [
        StarterRecipe(name: "Avena Proteica y Cacahuete", calories: 450, protein: 35.0, carbs: 45.0, fat: 15.0, instructions: ["Hierve 200ml de agua o leche.", "Añade 50g de avena y cocina a fuego lento 5 minutos.", "Retira del fuego y mezcla 1 cazo de proteína whey.", "Añade 1 cucharada de crema de cacahuete y disfruta."], category: "Breakfast", prepTimeMinutes: 10, difficulty: "Fácil", systemImage: "bowl"),
        StarterRecipe(name: "Pollo, Arroz y Brócoli", calories: 550, protein: 45.0, carbs: 65.0, fat: 10.0, instructions: ["Cuece 70g de arroz jazmín seco según el envase.", "Sazona 150g de pollo y dóralo en una sartén.", "Haz 100g de brócoli al vapor 4 minutos.", "Sírvelo todo con un chorrito de salsa de soja."], category: "Lunch", prepTimeMinutes: 25, difficulty: "Medio", systemImage: "frying.pan"),
        StarterRecipe(name: "Tostada de Aguacate y Huevo", calories: 480, protein: 20.0, carbs: 35.0, fat: 28.0, instructions: ["Tuesta 2 rebanadas de pan integral.", "Machaca medio aguacate y úntalo en las tostadas.", "Fríe o escalfa 2 huevos a tu gusto.", "Pon los huevos sobre el aguacate y añade sal, pimienta y chile."], category: "Breakfast", prepTimeMinutes: 10, difficulty: "Fácil", systemImage: "carrot"),
        StarterRecipe(name: "Yogur Griego con Frutas", calories: 250, protein: 22.0, carbs: 30.0, fat: 4.0, instructions: ["Pon 200g de Yogur Griego en un bol.", "Mezcla con un poco de edulcorante o miel.", "Añade 100g de frutos rojos y un puñado de granola."], category: "Snack", prepTimeMinutes: 5, difficulty: "Fácil", systemImage: "cup.and.saucer"),
        StarterRecipe(name: "Batido de Proteína Rápido", calories: 150, protein: 25.0, carbs: 5.0, fat: 2.0, instructions: ["Añade 300ml de agua fría o leche a un mezclador.", "Añade 1 cazo (30g) de proteína whey.", "Agita vigorosamente 15 segundos."], category: "Snack", prepTimeMinutes: 2, difficulty: "Fácil", systemImage: "waterbottle")
    ]
    
    // MARK: - FRENCH DATABASE
    private static let foodsFR: [StarterFood] = [
        StarterFood(name: "Blanc de Poulet (Cru)", calories: 120, protein: 22.5, carbs: 0.0, fat: 2.6, category: "Meat"),
        StarterFood(name: "Viande Hachée (Maigre, Crue)", calories: 137, protein: 21.4, carbs: 0.0, fat: 5.0, category: "Meat"),
        StarterFood(name: "Saumon (Cru)", calories: 208, protein: 20.0, carbs: 0.0, fat: 13.0, category: "Meat"),
        StarterFood(name: "Riz Jasmin (Sec)", calories: 356, protein: 7.1, carbs: 78.9, fat: 0.6, category: "Carbs"),
        StarterFood(name: "Flocons d'Avoine", calories: 379, protein: 13.1, carbs: 67.7, fat: 6.5, category: "Carbs"),
        StarterFood(name: "Patate Douce (Crue)", calories: 86, protein: 1.6, carbs: 20.1, fat: 0.1, category: "Carbs"),
        StarterFood(name: "Huile d'Olive", calories: 884, protein: 0.0, carbs: 0.0, fat: 100.0, category: "Dairy & Fats"),
        StarterFood(name: "Beurre", calories: 717, protein: 0.8, carbs: 0.1, fat: 81.0, category: "Dairy & Fats"),
        StarterFood(name: "Avocat", calories: 160, protein: 2.0, carbs: 8.5, fat: 14.7, category: "Dairy & Fats"),
        StarterFood(name: "Amandes", calories: 579, protein: 21.1, carbs: 21.6, fat: 49.9, category: "Dairy & Fats"),
        StarterFood(name: "Yaourt Grec (0%)", calories: 59, protein: 10.3, carbs: 3.6, fat: 0.4, category: "Dairy & Fats"),
        StarterFood(name: "Lait Entier", calories: 61, protein: 3.1, carbs: 4.8, fat: 3.2, category: "Drinks"),
        StarterFood(name: "Protéine Whey", calories: 379, protein: 78.0, carbs: 6.0, fat: 5.0, category: "Other"),
        StarterFood(name: "Banane", calories: 89, protein: 1.1, carbs: 22.8, fat: 0.3, category: "Fruits"),
        StarterFood(name: "Pomme", calories: 52, protein: 0.3, carbs: 13.8, fat: 0.2, category: "Fruits"),
        StarterFood(name: "Brocoli (Cru)", calories: 34, protein: 2.8, carbs: 6.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Épinards (Crus)", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, category: "Vegetables"),
        StarterFood(name: "Œuf (Cru)", calories: 143, protein: 12.6, carbs: 0.7, fat: 9.5, category: "Dairy & Fats"),
        StarterFood(name: "Beurre de Cacahuète", calories: 588, protein: 25.0, carbs: 20.0, fat: 50.0, category: "Dairy & Fats"),
        StarterFood(name: "Miel", calories: 304, protein: 0.3, carbs: 82.4, fat: 0.0, category: "Other")
    ]
    
    private static let recipesFR: [StarterRecipe] = [
        StarterRecipe(name: "Avoine Protéinée & Cacahuète", calories: 450, protein: 35.0, carbs: 45.0, fat: 15.0, instructions: ["Faites bouillir 200 ml d'eau ou de lait.", "Ajoutez 50g d'avoine et laissez mijoter 5 minutes.", "Retirez du feu et mélangez 1 dose de whey protéine.", "Garnissez d'une c.à.s de beurre de cacahuète."], category: "Breakfast", prepTimeMinutes: 10, difficulty: "Facile", systemImage: "bowl"),
        StarterRecipe(name: "Poulet, Riz & Brocoli", calories: 550, protein: 45.0, carbs: 65.0, fat: 10.0, instructions: ["Cuisez 70g de riz jasmin selon les instructions.", "Assaisonnez 150g de poulet et faites-le dorer à la poêle.", "Cuisez 100g de brocoli à la vapeur pendant 4 minutes.", "Servez le tout avec un trait de sauce soja."], category: "Lunch", prepTimeMinutes: 25, difficulty: "Moyen", systemImage: "frying.pan"),
        StarterRecipe(name: "Toast Avocat & Œuf", calories: 480, protein: 20.0, carbs: 35.0, fat: 28.0, instructions: ["Faites griller 2 tranches de pain complet.", "Écrasez un demi-avocat et étalez-le sur le pain.", "Faites frire ou pocher 2 œufs à votre goût.", "Placez les œufs sur l'avocat et assaisonnez."], category: "Breakfast", prepTimeMinutes: 10, difficulty: "Facile", systemImage: "carrot"),
        StarterRecipe(name: "Yaourt Grec aux Fruits", calories: 250, protein: 22.0, carbs: 30.0, fat: 4.0, instructions: ["Mettez 200g de yaourt grec dans un bol.", "Ajoutez un peu d'édulcorant ou de miel.", "Garnissez de 100g de fruits rouges et de granola."], category: "Snack", prepTimeMinutes: 5, difficulty: "Facile", systemImage: "cup.and.saucer"),
        StarterRecipe(name: "Shaker Protéiné Rapide", calories: 150, protein: 25.0, carbs: 5.0, fat: 2.0, instructions: ["Versez 300ml d'eau froide ou de lait dans un shaker.", "Ajoutez 1 dose (30g) de protéine whey en poudre.", "Secouez vigoureusement 15 secondes."], category: "Snack", prepTimeMinutes: 2, difficulty: "Facile", systemImage: "waterbottle")
    ]
}