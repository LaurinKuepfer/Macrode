import Foundation
import ActivityKit

public struct MacrodeAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var caloriesLeft: Int
        public var fastingHours: Double
        
        public init(caloriesLeft: Int, fastingHours: Double) {
            self.caloriesLeft = caloriesLeft
            self.fastingHours = fastingHours
        }
    }
    
    public var name: String
    
    public init(name: String) {
        self.name = name
    }
}
