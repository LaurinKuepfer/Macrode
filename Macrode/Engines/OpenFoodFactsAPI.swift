import Foundation

struct OFFResponse: Codable {
    let status: Int
    let product: OFFProduct?
}

struct OFFSearchResponse: Codable {
    let count: Int?
    let products: [OFFProduct]?
}

@propertyWrapper
struct FlexibleDouble: Codable {
    var wrappedValue: Double?
    
    init(wrappedValue: Double? = nil) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            wrappedValue = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            let cleaned = stringValue.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .letters.union(.whitespaces))
            wrappedValue = Double(cleaned)
        } else {
            wrappedValue = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

struct OFFProduct: Codable {
    let productName: String?
    let categoriesTags: [String]?
    let nutriments: OFFNutriments?
    
    let imageFrontUrl: String?
    let nutriscoreGrade: String?
    let ecoscoreGrade: String?
    let novaGroup: Int?
    let ingredientsText: String?
    let allergens: String?
    let brands: String?
    @FlexibleDouble var productQuantity: Double?
    let servingSize: String?
    
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
        case productQuantity = "product_quantity"
        case servingSize = "serving_size"
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

struct OFFProductResult: Sendable {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let category: String
    let fiber: Double?
    let sugar: Double?
    let saturatedFat: Double?
    let sodium: Double?
    let imageUrl: String?
    let nutriscore: String?
    let ecoscore: String?
    let novaGroup: Int?
    let ingredients: String?
    let allergens: String?
    let brand: String?
    let householdUnitName: String?
    let householdUnitWeightGrams: Double?
}

class OpenFoodFactsAPI {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 100_000_000, diskPath: "off_cache")
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()

    static func fetchProduct(barcode: String) async throws -> OFFProductResult? {
        let fields = "product_name,categories_tags,nutriments,image_front_url,nutriscore_grade,ecoscore_grade,nova_group,ingredients_text,allergens,brands,product_quantity,serving_size"
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json?fields=\(fields)"
        guard let url = URL(string: urlString) else { return nil }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(OFFResponse.self, from: data)
        
        guard response.status == 1, let product = response.product else { return nil }
        
        let rawName = product.productName ?? "Unknown Product"
        let cleanName = rawName.replacingOccurrences(of: "ÔÇó", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let category = mapCategory(tags: product.categoriesTags ?? [])
        
        let fiber = product.nutriments?.fiber.flatMap { $0 > 0 ? $0 : nil }
        let sugar = product.nutriments?.sugars.flatMap { $0 > 0 ? $0 : nil }
        let satFat = product.nutriments?.saturatedFat.flatMap { $0 > 0 ? $0 : nil }
        let sodium = product.nutriments?.sodium.flatMap { $0 > 0 ? $0 : nil }
        
        var unitName: String? = nil
        if let s = product.servingSize, !s.isEmpty {
            unitName = "Serving (\(s))"
        } else if product.productQuantity != nil {
            unitName = "1 Package"
        }
        
        return OFFProductResult(
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
            brand: product.brands,
            householdUnitName: unitName,
            householdUnitWeightGrams: product.productQuantity
        )
    }
    
    static func searchProducts(query: String) async throws -> [OFFProductResult] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let fields = "product_name,categories_tags,nutriments,image_front_url,nutriscore_grade,ecoscore_grade,nova_group,ingredients_text,allergens,brands,product_quantity,serving_size"
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encodedQuery)&search_simple=1&action=process&json=1&page_size=30&sort_by=unique_scans_n&fields=\(fields)"
        
        guard let url = URL(string: urlString) else { return [] }
        
        let (data, _) = try await session.data(from: url)
        let response = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
        
        var results: [OFFProductResult] = []
        
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
                
                var unitName: String? = nil
                if let s = product.servingSize, !s.isEmpty {
                    unitName = "Serving (\(s))"
                } else if product.productQuantity != nil {
                    unitName = "1 Package"
                }
                
                if energy > 0 || protein > 0 || carbs > 0 || fat > 0 {
                    results.append(OFFProductResult(name: cleanName, calories: energy, protein: protein, carbs: carbs, fat: fat, category: category, fiber: fiber, sugar: sugar, saturatedFat: satFat, sodium: sodium, imageUrl: product.imageFrontUrl, nutriscore: product.nutriscoreGrade, ecoscore: product.ecoscoreGrade, novaGroup: product.novaGroup, ingredients: product.ingredientsText, allergens: product.allergens, brand: product.brands, householdUnitName: unitName, householdUnitWeightGrams: product.productQuantity))
                }
            }
        }
        
        var uniqueResults = [OFFProductResult]()
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
