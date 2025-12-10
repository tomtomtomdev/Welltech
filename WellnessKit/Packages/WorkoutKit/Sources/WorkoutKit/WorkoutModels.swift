import Foundation

// MARK: - Workout Types
public enum WorkoutType: String, CaseIterable, Codable, Sendable {
    case running = "running"
    case cycling = "cycling"
    case weightlifting = "weightlifting"
    case bodyweight = "bodyweight"

    public var displayName: String {
        switch self {
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .weightlifting:
            return "Weightlifting"
        case .bodyweight:
            return "Bodyweight"
        }
    }

    public var iconName: String {
        switch self {
        case .running:
            return "figure.run"
        case .cycling:
            return "bicycle"
        case .weightlifting:
            return "dumbbell"
        case .bodyweight:
            return "figure.mind.and.body"
        }
    }
}

// MARK: - Exercise Category
public enum ExerciseCategory: String, CaseIterable, Codable, Sendable {
    case cardio = "cardio"
    case strength = "strength"
    case flexibility = "flexibility"

    public var displayName: String {
        switch self {
        case .cardio:
            return "Cardio"
        case .strength:
            return "Strength"
        case .flexibility:
            return "Flexibility"
        }
    }
}

// MARK: - Exercise Set
public struct ExerciseSet: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let reps: Int?
    public let weight: Double? // kg
    public let duration: TimeInterval? // seconds
    public let distance: Double? // meters
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        reps: Int? = nil,
        weight: Double? = nil,
        duration: TimeInterval? = nil,
        distance: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.timestamp = timestamp
    }

    public var isStrengthSet: Bool {
        reps != nil || weight != nil
    }

    public var isCardioSet: Bool {
        duration != nil || distance != nil
    }
}

// MARK: - Exercise
public struct Exercise: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let category: ExerciseCategory
    public var sets: [ExerciseSet]
    public let notes: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        sets: [ExerciseSet] = [],
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.sets = sets
        self.notes = notes
        self.createdAt = createdAt
    }

    public var totalReps: Int {
        sets.compactMap { $0.reps }.reduce(0, +)
    }

    public var totalWeight: Double {
        sets.compactMap { $0.weight }.reduce(0, +)
    }

    public var totalDuration: TimeInterval {
        sets.compactMap { $0.duration }.reduce(0, +)
    }

    public var totalDistance: Double {
        sets.compactMap { $0.distance }.reduce(0, +)
    }
}

// MARK: - Workout
public struct Workout: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let type: WorkoutType
    public let startTime: Date
    public var endTime: Date?
    public var exercises: [Exercise]
    public var notes: String?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        type: WorkoutType,
        startTime: Date = Date(),
        endTime: Date? = nil,
        exercises: [Exercise] = [],
        notes: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.exercises = exercises
        self.notes = notes
        self.createdAt = createdAt
    }

    public var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    public var isActive: Bool {
        endTime == nil
    }

    public var totalDuration: TimeInterval {
        duration ?? exercises.flatMap { exercise in
            exercise.sets.compactMap { $0.duration }.reduce(0, +)
        } ?? 0
    }

    public var totalDistance: Double {
        exercises.flatMap { exercise in
            exercise.sets.compactMap { $0.distance }.reduce(0, +)
        }
    }

    public var estimatedCalories: Int {
        // Simple estimation based on duration and workout type
        let baseCaloriesPerMinute: Double = {
            switch type {
            case .running:
                return 10.0
            case .cycling:
                return 8.0
            case .weightlifting:
                return 5.0
            case .bodyweight:
                return 7.0
            }
        }()

        return Int((totalDuration / 60) * baseCaloriesPerMinute)
    }
}

// MARK: - Workout Statistics
public struct WorkoutStats: Codable, Equatable, Sendable {
    public let totalWorkouts: Int
    public let totalDuration: TimeInterval
    public let totalDistance: Double
    public let totalCalories: Int
    public let averageWorkoutDuration: TimeInterval
    public let personalRecords: [PersonalRecord]

    public init(
        totalWorkouts: Int = 0,
        totalDuration: TimeInterval = 0,
        totalDistance: Double = 0,
        totalCalories: Int = 0,
        averageWorkoutDuration: TimeInterval = 0,
        personalRecords: [PersonalRecord] = []
    ) {
        self.totalWorkouts = totalWorkouts
        self.totalDuration = totalDuration
        self.totalDistance = totalDistance
        self.totalCalories = totalCalories
        self.averageWorkoutDuration = averageWorkoutDuration
        self.personalRecords = personalRecords
    }
}

// MARK: - Personal Record
public struct PersonalRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let type: RecordType
    public let exercise: String?
    public let value: Double
    public let unit: String
    public let date: Date

    public init(
        id: UUID = UUID(),
        type: RecordType,
        exercise: String? = nil,
        value: Double,
        unit: String,
        date: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.exercise = exercise
        self.value = value
        self.unit = unit
        self.date = date
    }
}

// MARK: - Record Type
public enum RecordType: String, CaseIterable, Codable, Sendable {
    case longestDuration = "longest_duration"
    case furthestDistance = "furthest_distance"
    case heaviestWeight = "heaviest_weight"
    case mostReps = "most_reps"

    public var displayName: String {
        switch self {
        case .longestDuration:
            return "Longest Duration"
        case .furthestDistance:
            return "Furthest Distance"
        case .heaviestWeight:
            return "Heaviest Weight"
        case .mostReps:
            return "Most Reps"
        }
    }
}