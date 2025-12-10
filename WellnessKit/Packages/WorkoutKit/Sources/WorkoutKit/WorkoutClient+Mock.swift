import Foundation
import ComposableArchitecture
import CoreDependencies

// MARK: - Mock Implementation
extension WorkoutClient {
    public static let mockValue = WorkoutClient(
        createWorkout: { workoutType in
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            return Workout(
                type: workoutType,
                startTime: Date(),
                exercises: []
            )
        },

        updateWorkout: { workout in
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
            return workout
        },

        finishWorkout: { workoutId, endTime in
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
            return Workout(
                id: workoutId,
                type: .weightlifting,
                startTime: Date().addingTimeInterval(-3600), // 1 hour ago
                endTime: endTime,
                exercises: [
                    Exercise(
                        name: "Squat",
                        category: .strength,
                        sets: [
                            ExerciseSet(reps: 12, weight: 60.0),
                            ExerciseSet(reps: 10, weight: 70.0),
                            ExerciseSet(reps: 8, weight: 80.0)
                        ]
                    ),
                    Exercise(
                        name: "Bench Press",
                        category: .strength,
                        sets: [
                            ExerciseSet(reps: 10, weight: 50.0),
                            ExerciseSet(reps: 8, weight: 60.0),
                            ExerciseSet(reps: 6, weight: 70.0)
                        ]
                    )
                ]
            )
        },

        deleteWorkout: { workoutId in
            try await Task.sleep(nanoseconds: 200_000_000)
        },

        getWorkout: { workoutId in
            try await Task.sleep(nanoseconds: 100_000_000)
            return Workout(
                id: workoutId,
                type: .running,
                startTime: Date().addingTimeInterval(-1800), // 30 minutes ago
                endTime: Date().addingTimeInterval(-900), // 15 minutes ago
                exercises: [
                    Exercise(
                        name: "Running",
                        category: .cardio,
                        sets: [
                            ExerciseSet(duration: 1800, distance: 5000) // 30 minutes, 5km
                        ]
                    )
                ]
            )
        },

        getAllWorkouts: {
            try await Task.sleep(nanoseconds: 300_000_000)
            let now = Date()
            return [
                Workout(
                    type: .running,
                    startTime: now.addingTimeInterval(-86400), // Yesterday
                    endTime: now.addingTimeInterval(-84600),
                    exercises: [
                        Exercise(
                            name: "Morning Run",
                            category: .cardio,
                            sets: [
                                ExerciseSet(duration: 1800, distance: 5000)
                            ]
                        )
                    ]
                ),
                Workout(
                    type: .weightlifting,
                    startTime: now.addingTimeInterval(-172800), // 2 days ago
                    endTime: now.addingTimeInterval(-169200),
                    exercises: [
                        Exercise(
                            name: "Deadlift",
                            category: .strength,
                            sets: [
                                ExerciseSet(reps: 5, weight: 100.0),
                                ExerciseSet(reps: 5, weight: 100.0),
                                ExerciseSet(reps: 5, weight: 100.0)
                            ]
                        ),
                        Exercise(
                            name: "Pull-ups",
                            category: .strength,
                            sets: [
                                ExerciseSet(reps: 10, weight: nil),
                                ExerciseSet(reps: 8, weight: nil),
                                ExerciseSet(reps: 6, weight: nil)
                            ]
                        )
                    ]
                ),
                Workout(
                    type: .bodyweight,
                    startTime: now.addingTimeInterval(-259200), // 3 days ago
                    endTime: now.addingTimeInterval(-255600),
                    exercises: [
                        Exercise(
                            name: "Push-ups",
                            category: .strength,
                            sets: [
                                ExerciseSet(reps: 20, weight: nil),
                                ExerciseSet(reps: 15, weight: nil),
                                ExerciseSet(reps: 12, weight: nil)
                            ]
                        ),
                        Exercise(
                            name: "Plank",
                            category: .flexibility,
                            sets: [
                                ExerciseSet(duration: 60),
                                ExerciseSet(duration: 45),
                                ExerciseSet(duration: 30)
                            ]
                        )
                    ]
                )
            ]
        },

        getWorkoutsInRange: { startDate, endDate in
            try await Task.sleep(nanoseconds: 200_000_000)
            // Return some sample workouts within the date range
            return [
                Workout(
                    type: .cycling,
                    startTime: startDate,
                    endTime: startDate.addingTimeInterval(3600),
                    exercises: [
                        Exercise(
                            name: "Cycling",
                            category: .cardio,
                            sets: [
                                ExerciseSet(duration: 3600, distance: 20000)
                            ]
                        )
                    ]
                )
            ]
        },

        getActiveWorkout: {
            try await Task.sleep(nanoseconds: 100_000_000)
            return nil // No active workout by default
        },

        addExercise: { workoutId, exercise in
            try await Task.sleep(nanoseconds: 200_000_000)
            return exercise
        },

        updateExercise: { workoutId, exercise in
            try await Task.sleep(nanoseconds: 200_000_000)
            return exercise
        },

        deleteExercise: { workoutId, exerciseId in
            try await Task.sleep(nanoseconds: 200_000_000)
        },

        addSet: { workoutId, exerciseId, exerciseSet in
            try await Task.sleep(nanoseconds: 200_000_000)
            return exerciseSet
        },

        updateSet: { workoutId, exerciseId, exerciseSet in
            try await Task.sleep(nanoseconds: 200_000_000)
            return exerciseSet
        },

        deleteSet: { workoutId, exerciseId, setId in
            try await Task.sleep(nanoseconds: 200_000_000)
        },

        getWorkoutStats: { startDate, endDate in
            try await Task.sleep(nanoseconds: 300_000_000)
            return WorkoutStats(
                totalWorkouts: 5,
                totalDuration: 10800, // 3 hours
                totalDistance: 25000, // 25 km
                totalCalories: 1500,
                averageWorkoutDuration: 2160, // 36 minutes
                personalRecords: [
                    PersonalRecord(
                        type: .longestDuration,
                        exercise: "Running",
                        value: 3600,
                        unit: "seconds",
                        date: Date().addingTimeInterval(-86400)
                    ),
                    PersonalRecord(
                        type: .heaviestWeight,
                        exercise: "Deadlift",
                        value: 100.0,
                        unit: "kg",
                        date: Date().addingTimeInterval(-172800)
                    )
                ]
            )
        },

        searchExercises: { query in
            try await Task.sleep(nanoseconds: 200_000_000)
            let allExercises = [
                Exercise(name: "Squat", category: .strength),
                Exercise(name: "Deadlift", category: .strength),
                Exercise(name: "Bench Press", category: .strength),
                Exercise(name: "Pull-ups", category: .strength),
                Exercise(name: "Push-ups", category: .strength),
                Exercise(name: "Running", category: .cardio),
                Exercise(name: "Cycling", category: .cardio),
                Exercise(name: "Swimming", category: .cardio),
                Exercise(name: "Plank", category: .flexibility),
                Exercise(name: "Yoga", category: .flexibility)
            ]

            if query.isEmpty {
                return Array(allExercises.prefix(5))
            } else {
                return allExercises.filter {
                    $0.name.localizedCaseInsensitiveContains(query)
                }
            }
        }
    )
}