import Foundation
import ComposableArchitecture
import CoreDependencies

// MARK: - Live Implementation
extension WorkoutClient: DependencyKey {
    public static let liveValue = WorkoutClient(
        createWorkout: { workoutType in
            let persistenceClient = DependencyValues.shared.persistenceClient
            let workout = Workout(
                type: workoutType,
                startTime: Date(),
                exercises: []
            )
            try await persistenceClient.saveWorkout(workout)
            return workout
        },

        updateWorkout: { workout in
            let persistenceClient = DependencyValues.shared.persistenceClient
            try await persistenceClient.saveWorkout(workout)
            return workout
        },

        finishWorkout: { workoutId, endTime in
            let persistenceClient = DependencyValues.shared.persistenceClient
            guard var workout = await persistenceClient.getWorkout(id: workoutId) else {
                throw WorkoutError.workoutNotFound
            }
            workout.endTime = endTime
            try await persistenceClient.saveWorkout(workout)
            return workout
        },

        deleteWorkout: { workoutId in
            let persistenceClient = DependencyValues.shared.persistenceClient
            try await persistenceClient.deleteWorkout(id: workoutId)
        },

        getWorkout: { workoutId in
            let persistenceClient = DependencyValues.shared.persistenceClient
            return await persistenceClient.getWorkout(id: workoutId)
        },

        getAllWorkouts: {
            let persistenceClient = DependencyValues.shared.persistenceClient
            return await persistenceClient.getAllWorkouts()
        },

        getWorkoutsInRange: { startDate, endDate in
            let persistenceClient = DependencyValues.shared.persistenceClient
            return await persistenceClient.getWorkouts(from: startDate, to: endDate)
        },

        getActiveWorkout: {
            let persistenceClient = DependencyValues.shared.persistenceClient
            return await persistenceClient.getActiveWorkout()
        },

        addExercise: { workoutId, exercise in
            let persistenceClient = DependencyValues.shared.persistenceClient
            guard var workout = await persistenceClient.getWorkout(id: workoutId) else {
                throw WorkoutError.workoutNotFound
            }
            workout.exercises.append(exercise)
            try await persistenceClient.saveWorkout(workout)
            return exercise
        },

        updateExercise: { workoutId, exercise in
            let persistenceClient = DependencyValues.shared.persistenceClient
            guard var workout = await persistenceClient.getWorkout(id: workoutId) else {
                throw WorkoutError.workoutNotFound
            }
            if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
                workout.exercises[index] = exercise
                try await persistenceClient.saveWorkout(workout)
            } else {
                throw WorkoutError.exerciseNotFound
            }
            return exercise
        },

        deleteExercise: { workoutId, exerciseId in
            let persistenceClient = DependencyValues.shared.persistenceClient
            guard var workout = await persistenceClient.getWorkout(id: workoutId) else {
                throw WorkoutError.workoutNotFound
            }
            workout.exercises.removeAll { $0.id == exerciseId }
            try await persistenceClient.saveWorkout(workout)
        },

        addSet: { workoutId, exerciseId, exerciseSet in
            let persistenceClient = DependencyValues.shared.persistenceClient
            guard var workout = await persistenceClient.getWorkout(id: workoutId) else {
                throw WorkoutError.workoutNotFound
            }
            if let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                workout.exercises[exerciseIndex].sets.append(exerciseSet)
                try await persistenceClient.saveWorkout(workout)
            } else {
                throw WorkoutError.exerciseNotFound
            }
            return exerciseSet
        },

        updateSet: { workoutId, exerciseId, exerciseSet in
            let persistenceClient = DependencyValues.shared.persistenceClient
            guard var workout = await persistenceClient.getWorkout(id: workoutId) else {
                throw WorkoutError.workoutNotFound
            }
            if let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }),
               let setIndex = workout.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == exerciseSet.id }) {
                workout.exercises[exerciseIndex].sets[setIndex] = exerciseSet
                try await persistenceClient.saveWorkout(workout)
            } else {
                throw WorkoutError.setNotFound
            }
            return exerciseSet
        },

        deleteSet: { workoutId, exerciseId, setId in
            let persistenceClient = DependencyValues.shared.persistenceClient
            guard var workout = await persistenceClient.getWorkout(id: workoutId) else {
                throw WorkoutError.workoutNotFound
            }
            if let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }) {
                workout.exercises[exerciseIndex].sets.removeAll { $0.id == setId }
                try await persistenceClient.saveWorkout(workout)
            } else {
                throw WorkoutError.exerciseNotFound
            }
        },

        getWorkoutStats: { startDate, endDate in
            let persistenceClient = DependencyValues.shared.persistenceClient
            let workouts = await persistenceClient.getWorkouts(from: startDate, to: endDate)

            let totalWorkouts = workouts.count
            let totalDuration = workouts.reduce(0) { sum, workout in
                sum + (workout.duration ?? workout.totalDuration)
            }
            let totalDistance = workouts.reduce(0) { sum, workout in
                sum + workout.totalDistance
            }
            let totalCalories = workouts.reduce(0) { sum, workout in
                sum + workout.estimatedCalories
            }

            let averageWorkoutDuration = totalWorkouts > 0 ? totalDuration / Double(totalWorkouts) : 0

            // Calculate personal records
            var personalRecords: [PersonalRecord] = []

            // Find max weight lifted
            let maxWeight = workouts.flatMap { $0.exercises }
                .flatMap { $0.sets }
                .compactMap { $0.weight }
                .max()
            if let maxWeight = maxWeight {
                personalRecords.append(
                    PersonalRecord(
                        type: .heaviestWeight,
                        value: maxWeight,
                        unit: "kg",
                        date: workouts.first?.startTime ?? Date()
                    )
                )
            }

            // Find longest duration
            if let maxDuration = workouts.compactMap({ $0.duration }).max() {
                personalRecords.append(
                    PersonalRecord(
                        type: .longestDuration,
                        value: maxDuration,
                        unit: "seconds",
                        date: workouts.first(where: { $0.duration == maxDuration })?.startTime ?? Date()
                    )
                )
            }

            // Find furthest distance
            let maxDistance = workouts.map { $0.totalDistance }.max()
            if maxDistance > 0 {
                personalRecords.append(
                    PersonalRecord(
                        type: .furthestDistance,
                        value: maxDistance,
                        unit: "meters",
                        date: workouts.first(where: { $0.totalDistance == maxDistance })?.startTime ?? Date()
                    )
                )
            }

            // Find most reps in a single set
            let maxReps = workouts.flatMap { $0.exercises }
                .flatMap { $0.sets }
                .compactMap { $0.reps }
                .max()
            if let maxReps = maxReps {
                personalRecords.append(
                    PersonalRecord(
                        type: .mostReps,
                        value: Double(maxReps),
                        unit: "reps",
                        date: workouts.first?.startTime ?? Date()
                    )
                )
            }

            return WorkoutStats(
                totalWorkouts: totalWorkouts,
                totalDuration: totalDuration,
                totalDistance: totalDistance,
                totalCalories: totalCalories,
                averageWorkoutDuration: averageWorkoutDuration,
                personalRecords: personalRecords
            )
        },

        searchExercises: { query in
            // In a real implementation, this would search a database or API
            // For now, return a curated list based on the query
            let allExercises = [
                // Cardio
                Exercise(name: "Running", category: .cardio),
                Exercise(name: "Cycling", category: .cardio),
                Exercise(name: "Swimming", category: .cardio),
                Exercise(name: "Rowing", category: .cardio),
                Exercise(name: "Jumping Jacks", category: .cardio),

                // Strength
                Exercise(name: "Squat", category: .strength),
                Exercise(name: "Deadlift", category: .strength),
                Exercise(name: "Bench Press", category: .strength),
                Exercise(name: "Overhead Press", category: .strength),
                Exercise(name: "Barbell Row", category: .strength),
                Exercise(name: "Pull-ups", category: .strength),
                Exercise(name: "Dips", category: .strength),
                Exercise(name: "Push-ups", category: .strength),
                Exercise(name: "Lunges", category: .strength),
                Exercise(name: "Bicep Curls", category: .strength),
                Exercise(name: "Tricep Extensions", category: .strength),

                // Flexibility
                Exercise(name: "Plank", category: .flexibility),
                Exercise(name: "Yoga", category: .flexibility),
                Exercise(name: "Stretching", category: .flexibility),
                Exercise(name: "Pilates", category: .flexibility)
            ]

            if query.isEmpty {
                return Array(allExercises.prefix(10))
            } else {
                return allExercises.filter {
                    $0.name.localizedCaseInsensitiveContains(query) ||
                    $0.category.displayName.localizedCaseInsensitiveContains(query)
                }
            }
        }
    )
}

// MARK: - Workout Error
public enum WorkoutError: LocalizedError, Equatable {
    case workoutNotFound
    case exerciseNotFound
    case setNotFound
    case invalidWorkout
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .workoutNotFound:
            return "Workout not found"
        case .exerciseNotFound:
            return "Exercise not found"
        case .setNotFound:
            return "Exercise set not found"
        case .invalidWorkout:
            return "Invalid workout data"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}