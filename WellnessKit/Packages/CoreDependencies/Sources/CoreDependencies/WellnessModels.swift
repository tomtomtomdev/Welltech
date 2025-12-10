import Foundation

// MARK: - Nutrition Models
public struct NutritionEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date
    public let meals: [Meal]
    public let calories: Int
    public let macros: MacroNutrients
    public let water: Double // Liters

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        meals: [Meal] = [],
        calories: Int = 0,
        macros: MacroNutrients = MacroNutrients(),
        water: Double = 0
    ) {
        self.id = id
        self.date = date
        self.meals = meals
        self.calories = calories
        self.macros = macros
        self.water = water
    }
}

public struct Meal: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let type: MealType
    public let name: String
    public let foods: [Food]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        type: MealType,
        name: String,
        foods: [Food] = [],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.foods = foods
        self.timestamp = timestamp
    }

    public var totalCalories: Int {
        foods.reduce(0) { $0 + $1.calories }
    }
}

public enum MealType: String, CaseIterable, Codable, Sendable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"

    public var displayName: String {
        switch self {
        case .breakfast:
            return "Breakfast"
        case .lunch:
            return "Lunch"
        case .dinner:
            return "Dinner"
        case .snack:
            return "Snack"
        }
    }
}

public struct Food: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let calories: Int
    public let macros: MacroNutrients
    public let quantity: Double
    public let unit: String

    public init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        macros: MacroNutrients = MacroNutrients(),
        quantity: Double,
        unit: String
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.macros = macros
        self.quantity = quantity
        self.unit = unit
    }
}

public struct MacroNutrients: Codable, Equatable, Sendable {
    public let protein: Double // grams
    public let carbs: Double // grams
    public let fat: Double // grams
    public let fiber: Double // grams

    public init(
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        fiber: Double = 0
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
    }

    public var totalCalories: Int {
        Int(protein * 4 + carbs * 4 + fat * 9)
    }
}

// MARK: - Sleep Models
public struct SleepEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let date: Date // The date of sleep
    public let bedtime: Date
    public let wakeTime: Date
    public let quality: SleepQuality
    public let duration: TimeInterval
    public let notes: String?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        bedtime: Date,
        wakeTime: Date,
        quality: SleepQuality = .good,
        notes: String? = nil
    ) {
        self.id = id
        self.date = date
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.quality = quality
        self.duration = wakeTime.timeIntervalSince(bedtime)
        self.notes = notes
    }
}

public enum SleepQuality: String, CaseIterable, Codable, Sendable {
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"

    public var displayName: String {
        switch self {
        case .poor:
            return "Poor"
        case .fair:
            return "Fair"
        case .good:
            return "Good"
        case .excellent:
            return "Excellent"
        }
    }

    public var score: Int {
        switch self {
        case .poor:
            return 1
        case .fair:
            return 2
        case .good:
            return 3
        case .excellent:
            return 4
        }
    }
}

// MARK: - Mood Models
public struct MoodEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let mood: MoodLevel
    public let energy: EnergyLevel
    public let stress: StressLevel
    public let notes: String?
    public let factors: [MoodFactor]

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        mood: MoodLevel = .neutral,
        energy: EnergyLevel = .moderate,
        stress: StressLevel = .moderate,
        notes: String? = nil,
        factors: [MoodFactor] = []
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mood = mood
        self.energy = energy
        self.stress = stress
        self.notes = notes
        self.factors = factors
    }
}

public enum MoodLevel: String, CaseIterable, Codable, Sendable {
    case veryLow = "very_low"
    case low = "low"
    case neutral = "neutral"
    case high = "high"
    case veryHigh = "very_high"

    public var displayName: String {
        switch self {
        case .veryLow:
            return "Very Low"
        case .low:
            return "Low"
        case .neutral:
            return "Neutral"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        }
    }

    public var emoji: String {
        switch self {
        case .veryLow:
            return "😢"
        case .low:
            return "😔"
        case .neutral:
            return "😐"
        case .high:
            return "😊"
        case .veryHigh:
            return "😄"
        }
    }
}

public enum EnergyLevel: String, CaseIterable, Codable, Sendable {
    case veryLow = "very_low"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"

    public var displayName: String {
        switch self {
        case .veryLow:
            return "Very Low"
        case .low:
            return "Low"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        }
    }
}

public enum StressLevel: String, CaseIterable, Codable, Sendable {
    case veryLow = "very_low"
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case veryHigh = "very_high"

    public var displayName: String {
        switch self {
        case .veryLow:
            return "Very Low"
        case .low:
            return "Low"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        case .veryHigh:
            return "Very High"
        }
    }
}

public struct MoodFactor: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let impact: FactorImpact

    public init(
        id: UUID = UUID(),
        name: String,
        impact: FactorImpact = .neutral
    ) {
        self.id = id
        self.name = name
        self.impact = impact
    }
}

public enum FactorImpact: String, CaseIterable, Codable, Sendable {
    case negative = "negative"
    case neutral = "neutral"
    case positive = "positive"

    public var displayName: String {
        switch self {
        case .negative:
            return "Negative"
        case .neutral:
            return "Neutral"
        case .positive:
            return "Positive"
        }
    }
}