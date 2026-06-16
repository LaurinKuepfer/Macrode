import Foundation

// The JSON Structure from Open Food Facts
struct OFFResponse: Codable {
    let status: Int
    let product: OFFProduct?
}

struct OFFSearchResponse: Codable {
    let count: Int?
    let products: [OFFProduct]?
}

struct OFFProduct: Codable {
    let productName: String?
    let categoriesTags: [String]?
    let nutriments: OFFNutriments?
    
    // Rich Metadata
    let imageFrontUrl: String?
    let nutriscoreGrade: String?
    let ecoscoreGrade: String?
    let novaGroup: Int?
    let ingredientsText: String?
    let allergens: String?
    let brands: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case categoriesTags = "categories_tags"
        case nutriments
        case imageFrontUrl = "image_front_url"
        case nutriscoreGrade = "nutriscore_grade"
        case ecoscoreGrade = "ecoscore_grade"
        case novaGroup = "nova_group"
        case ingredientsText = "ingredients_text"
        case allergens
        case brands
    }
}

struct OFFNutriments: Codable {
    let energyKcal: Double?
    let proteins: Double?
    let carbohydrates: Double?
    let fat: Double?
    let fiber: Double?
    let sugars: Double?
    let saturatedFat: Double?
    let sodium: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal = "energy-kcal_100g"
        case proteins = "proteins_100g"
        case carbohydrates = "carbohydrates_100g"
        case fat = "fat_100g"
        case fiber = "fiber_100g"
        case sugars = "sugars_100g"
        case saturatedFat = "saturated-fat_100g"
        case sodium = "sodium_100g"
    }
}

// The Network Client
class OpenFoodFactsAPI {
    static func fetchProduct(barcode: String) async throws -> (name: String, calories: Double, protein: Double, carbs: Double, fat: Double, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)? {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OFFResponse.self, from: data)
        
        guard response.status == 1, let product = response.product else { return nil }
        
        let rawName = product.productName ?? "Unknown Product"
        let cleanName = rawName.replacingOccurrences(of: "ÔÇó", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let category = mapCategory(tags: product.categoriesTags ?? [])
        
        let fiber = product.nutriments?.fiber.flatMap { $0 > 0 ? $0 : nil }
        let sugar = product.nutriments?.sugars.flatMap { $0 > 0 ? $0 : nil }
        let satFat = product.nutriments?.saturatedFat.flatMap { $0 > 0 ? $0 : nil }
        let sodium = product.nutriments?.sodium.flatMap { $0 > 0 ? $0 : nil }
        
        return (
            name: cleanName,
            calories: product.nutriments?.energyKcal ?? 0,
            protein: product.nutriments?.proteins ?? 0,
            carbs: product.nutriments?.carbohydrates ?? 0,
            fat: product.nutriments?.fat ?? 0,
            category: category,
            fiber: fiber,
            sugar: sugar,
            saturatedFat: satFat,
            sodium: sodium,
            imageUrl: product.imageFrontUrl,
            nutriscore: product.nutriscoreGrade,
            ecoscore: product.ecoscoreGrade,
            novaGroup: product.novaGroup,
            ingredients: product.ingredientsText,
            allergens: product.allergens,
            brand: product.brands
        )
    }
    
    static func searchProducts(query: String) async throws -> [(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=30"
        
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        
        var results: [(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)] = []
        
        if let products = response.products {
            for product in products {
                let rawName = product.productName ?? ""
                if rawName.isEmpty { continue }
                
                let cleanName = rawName.replacingOccurrences(of: "ÔÇó", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let category = mapCategory(tags: product.categoriesTags ?? [])
                
                let energy = product.nutriments?.energyKcal ?? 0
                let protein = product.nutriments?.proteins ?? 0
                let carbs = product.nutriments?.carbohydrates ?? 0
                let fat = product.nutriments?.fat ?? 0
                let fiber = product.nutriments?.fiber.flatMap { $0 > 0 ? $0 : nil }
                let sugar = product.nutriments?.sugars.flatMap { $0 > 0 ? $0 : nil }
                let satFat = product.nutriments?.saturatedFat.flatMap { $0 > 0 ? $0 : nil }
                let sodium = product.nutriments?.sodium.flatMap { $0 > 0 ? $0 : nil }
                
                if energy > 0 || protein > 0 || carbs > 0 || fat > 0 {
                    results.append((name: cleanName, calories: energy, protein: protein, carbs: carbs, fat: fat, category: category, fiber: fiber, sugar: sugar, saturatedFat: satFat, sodium: sodium, imageUrl: product.imageFrontUrl, nutriscore: product.nutriscoreGrade, ecoscore: product.ecoscoreGrade, novaGroup: product.novaGroup, ingredients: product.ingredientsText, allergens: product.allergens, brand: product.brands))
                }
            }
        }
        
        var uniqueResults = [(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, category: String, fiber: Double?, sugar: Double?, saturatedFat: Double?, sodium: Double?, imageUrl: String?, nutriscore: String?, ecoscore: String?, novaGroup: Int?, ingredients: String?, allergens: String?, brand: String?)]()
        var seenNames = Set<String>()
        for result in results {
            let lowerName = result.name.lowercased()
            if !seenNames.contains(lowerName) {
                seenNames.insert(lowerName)
                uniqueResults.append(result)
            }
        }
        
        return uniqueResults
    }
    
    private static func mapCategory(tags: [String]) -> String {
        let combinedTags = tags.joined(separator: " ").lowercased()
        
        if combinedTags.contains("beverage") || combinedTags.contains("drink") || combinedTags.contains("milk") || combinedTags.contains("soda") || combinedTags.contains("juice") {
            return "Drinks"
        }
        if combinedTags.contains("meat") || combinedTags.contains("beef") || combinedTags.contains("chicken") || combinedTags.contains("pork") || combinedTags.contains("fish") || combinedTags.contains("seafood") {
            return "Meat"
        }
        if combinedTags.contains("fruit") {
            return "Fruits"
        }
        if combinedTags.contains("vegetable") || combinedTags.contains("plant") || combinedTags.contains("salad") {
            return "Vegetables"
        }
        if combinedTags.contains("bread") || combinedTags.contains("cereal") || combinedTags.contains("pasta") || combinedTags.contains("rice") || combinedTags.contains("carb") || combinedTags.contains("potato") {
            return "Carbs"
        }
        if combinedTags.contains("dairy") || combinedTags.contains("cheese") || combinedTags.contains("butter") || combinedTags.contains("fat") || combinedTags.contains("oil") || combinedTags.contains("nut") {
            return "Dairy & Fats"
        }
        if combinedTags.contains("fast food") || combinedTags.contains("snack") || combinedTags.contains("candy") || combinedTags.contains("chocolate") || combinedTags.contains("sweet") {
            return "Fast Food"
        }
        
        return "Other"
    }
}
