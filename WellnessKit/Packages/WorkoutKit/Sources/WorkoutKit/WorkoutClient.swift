import Foundation
import ComposableArchitecture
import CoreDependencies

// MARK: - Workout Client Protocol
public struct WorkoutClient {
    public var createWorkout: @Sendable (WorkoutType) async throws -> Workout
    public var updateWorkout: @Sendable (Workout) async throws -> Workout
    public var finishWorkout: @Sendable (UUID, Date) async throws -> Workout
    public var deleteWorkout: @Sendable (UUID) async throws -> Void
    public var getWorkout: @Sendable (UUID) async -> Workout?
    public var getAllWorkouts: @Sendable () async -> [Workout]
    public var getWorkoutsInRange: @Sendable (Date, Date) async -> [Workout]
    public var getActiveWorkout: @Sendable () async -> Workout?
    public var addExercise: @Sendable (UUID, Exercise) async throws -> Exercise
    public var updateExercise: @Sendable (UUID, Exercise) async throws -> Exercise
    public var deleteExercise: @Sendable (UUID, UUID) async throws -> Void
    public var addSet: @Sendable (UUID, UUID, ExerciseSet) async throws -> ExerciseSet
    public var updateSet: @Sendable (UUID, UUID, ExerciseSet) async throws -> ExerciseSet
    public var deleteSet: @Sendable (UUID, UUID, UUID) async throws -> Void
    public var getWorkoutStats: @Sendable (Date, Date) async -> WorkoutStats
    public var searchExercises: @Sendable (String) async -> [Exercise]

    public init(
        createWorkout: @escaping @Sendable (WorkoutType) async throws -> Workout,
        updateWorkout: @escaping @Sendable (Workout) async throws -> Workout,
        finishWorkout: @escaping @Sendable (UUID, Date) async throws -> Workout,
        deleteWorkout: @escaping @Sendable (UUID) async throws -> Void,
        getWorkout: @escaping @Sendable (UUID) async -> Workout?,
        getAllWorkouts: @escaping @Sendable () async -> [Workout],
        getWorkoutsInRange: @escaping @Sendable (Date, Date) async -> [Workout],
        getActiveWorkout: @escaping @Sendable () async -> Workout?,
        addExercise: @escaping @Sendable (UUID, Exercise) async throws -> Exercise,
        updateExercise: @escaping @Sendable (UUID, Exercise) async throws -> Exercise,
        deleteExercise: @escaping @Sendable (UUID, UUID) async throws -> Void,
        addSet: @escaping @Sendable (UUID, UUID, ExerciseSet) async throws -> ExerciseSet,
        updateSet: @escaping @Sendable (UUID, UUID, ExerciseSet) async throws -> ExerciseSet,
        deleteSet: @escaping @Sendable (UUID, UUID, UUID) async throws -> Void,
        getWorkoutStats: @escaping @Sendable (Date, Date) async -> WorkoutStats,
        searchExercises: @escaping @Sendable (String) async -> [Exercise]
    ) {
        self.createWorkout = createWorkout
        self.updateWorkout = updateWorkout
        self.finishWorkout = finishWorkout
        self.deleteWorkout = deleteWorkout
        self.getWorkout = getWorkout
        self.getAllWorkouts = getAllWorkouts
        self.getWorkoutsInRange = getWorkoutsInRange
        self.getActiveWorkout = getActiveWorkout
        self.addExercise = addExercise
        self.updateExercise = updateExercise
        self.deleteExercise = deleteExercise
        self.addSet = addSet
        self.updateSet = updateSet
        self.deleteSet = deleteSet
        self.getWorkoutStats = getWorkoutStats
        self.searchExercises = searchExercises
    }
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var workoutClient: WorkoutClient {
        get { self[WorkoutClient.self] }
        set { self[WorkoutClient.self] = newValue }
    }
}