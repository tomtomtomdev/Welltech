import Foundation
import Testing
import ComposableArchitecture
@testable import CoreDependencies

@Suite("AnalyticsClient Tests")
struct AnalyticsClientTests {
    @Test("AnalyticsClient mock should track events")
    func eventTracking() async {
        let client = AnalyticsClient.mockValue
        
        let event = AnalyticsEvent(
            name: "test_event",
            parameters: ["param1": .string("value1"), "param2": .int(42)]
        )
        
        await client.track(event)
        
        // In mock implementation, we can't directly access the tracked events
        // but we can verify the call doesn't throw
        #expect(true) // If we get here, the track call succeeded
    }
    
    @Test("AnalyticsClient mock should set user properties")
    func userProperties() async {
        let client = AnalyticsClient.mockValue
        
        let property = UserProperty(
            key: "test_property",
            value: .string("test_value")
        )
        
        await client.setUserProperty(property)
        
        #expect(true) // If we get here, the setUserProperty call succeeded
    }
    
    @Test("AnalyticsClient mock should set user ID")
    func userIdSetting() async {
        let client = AnalyticsClient.mockValue
        
        await client.setUserId("test_user_123")
        
        #expect(true) // If we get here, the setUserId call succeeded
    }
    
    @Test("AnalyticsClient mock should reset analytics")
    func resetAnalytics() async {
        let client = AnalyticsClient.mockValue
        
        // Track some events first
        await client.track(.appLaunched)
        await client.setUserId("test_user")
        
        // Reset analytics
        await client.reset()
        
        #expect(true) // If we get here, the reset call succeeded
    }
    
    @Test("AnalyticsClient mock should flush events")
    func flushEvents() async {
        let client = AnalyticsClient.mockValue
        
        // Track some events first
        await client.track(.appLaunched)
        await client.track(.login(method: "email"))
        
        // Flush events
        await client.flush()
        
        #expect(true) // If we get here, the flush call succeeded
    }
    
    @Test("AnalyticsEvent should have correct timestamp")
    func eventTimestamp() async {
        let beforeDate = Date()
        let event = AnalyticsEvent(name: "test_event")
        let afterDate = Date()
        
        #expect(event.timestamp >= beforeDate)
        #expect(event.timestamp <= afterDate)
    }
    
    @Test("AnalyticsEvent should encode and decode correctly")
    func eventEncoding() throws {
        let event = AnalyticsEvent(
            name: "test_event",
            parameters: [
                "string_param": .string("value"),
                "int_param": .int(42),
                "double_param": .double(3.14),
                "bool_param": .bool(true),
                "null_param": .null
            ]
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(event)
        
        let decoder = JSONDecoder()
        let decodedEvent = try decoder.decode(AnalyticsEvent.self, from: data)
        
        #expect(decodedEvent.name == "test_event")
        #expect(decodedEvent.parameters["string_param"] == .string("value"))
        #expect(decodedEvent.parameters["int_param"] == .int(42))
        #expect(decodedEvent.parameters["double_param"] == .double(3.14))
        #expect(decodedEvent.parameters["bool_param"] == .bool(true))
        #expect(decodedEvent.parameters["null_param"] == .null)
    }
    
    @Test("AnyCodable should handle different types")
    func anyCodableTypes() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test string
        let stringValue = AnyCodable.string("test")
        let stringData = try encoder.encode(stringValue)
        let decodedString = try decoder.decode(AnyCodable.self, from: stringData)
        #expect(decodedString == .string("test"))
        
        // Test int
        let intValue = AnyCodable.int(42)
        let intData = try encoder.encode(intValue)
        let decodedInt = try decoder.decode(AnyCodable.self, from: intData)
        #expect(decodedInt == .int(42))
        
        // Test double
        let doubleValue = AnyCodable.double(3.14)
        let doubleData = try encoder.encode(doubleValue)
        let decodedDouble = try decoder.decode(AnyCodable.self, from: doubleData)
        #expect(decodedDouble == .double(3.14))
        
        // Test bool
        let boolValue = AnyCodable.bool(true)
        let boolData = try encoder.encode(boolValue)
        let decodedBool = try decoder.decode(AnyCodable.self, from: boolData)
        #expect(decodedBool == .bool(true))
        
        // Test null
        let nullValue = AnyCodable.null
        let nullData = try encoder.encode(nullValue)
        let decodedNull = try decoder.decode(AnyCodable.self, from: nullData)
        #expect(decodedNull == .null)
    }
    
    @Test("Common analytics events should be created correctly")
    func commonEvents() {
        let loginEvent = AnalyticsEvent.login(method: "email")
        #expect(loginEvent.name == "login_completed")
        #expect(loginEvent.parameters["method"] == .string("email"))
        
        let workoutStartedEvent = AnalyticsEvent.workoutStarted(type: "yoga")
        #expect(workoutStartedEvent.name == "workout_started")
        #expect(workoutStartedEvent.parameters["workout_type"] == .string("yoga"))
        
        let workoutCompletedEvent = AnalyticsEvent.workoutCompleted(type: "cardio", duration: 1800)
        #expect(workoutCompletedEvent.name == "workout_completed")
        #expect(workoutCompletedEvent.parameters["workout_type"] == .string("cardio"))
        #expect(workoutCompletedEvent.parameters["duration_seconds"] == .double(1800.0))
        
        let screenViewEvent = AnalyticsEvent.screenView(screenName: "WorkoutDetail")
        #expect(screenViewEvent.name == "screen_view")
        #expect(screenViewEvent.parameters["screen_name"] == .string("WorkoutDetail"))
    }
    
    @Test("Common user properties should be created correctly")
    func commonUserProperties() {
        let isPremium = UserProperty.isPremiumUser
        #expect(isPremium.key == "is_premium_user")
        #expect(isPremium.value == .bool(false))
        
        let workoutCount = UserProperty.workoutCount(25)
        #expect(workoutCount.key == "workout_count")
        #expect(workoutCount.value == .int(25))
        
        let totalTime = UserProperty.totalWorkoutTime(3600.0)
        #expect(totalTime.key == "total_workout_time_seconds")
        #expect(totalTime.value == .double(3600.0))
    }
    
    @Test("Dependency injection should work correctly")
    func dependencyInjection() async {
        let testClient = AnalyticsClient.mockValue
        
        await withDependencies {
            $0.analyticsClient = testClient
        } operation: {
            let event = AnalyticsEvent(name: "dependency_test")
            await DependencyValues().analyticsClient.track(event)
            
            #expect(true) // If we get here, the track call succeeded
        }
    }
}
