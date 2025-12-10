import Foundation
import ComposableArchitecture

// MARK: - Analytics Event
public struct AnalyticsEvent: Codable, Equatable, Sendable {
    public let name: String
    public let parameters: [String: AnyCodable]
    public let timestamp: Date
    
    public init(name: String, parameters: [String: AnyCodable] = [:]) {
        self.name = name
        self.parameters = parameters
        self.timestamp = Date()
    }
}

// MARK: - AnyCodable Helper
public enum AnyCodable: Codable, Equatable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
        } else if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            self = .null
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        }
    }
}

// MARK: - User Property
public struct UserProperty: Codable, Equatable, Sendable {
    public let key: String
    public let value: AnyCodable
    
    public init(key: String, value: AnyCodable) {
        self.key = key
        self.value = value
    }
}

// MARK: - Analytics Client Protocol
public struct AnalyticsClient {
    public var track: @Sendable (AnalyticsEvent) async -> Void
    public var setUserProperty: @Sendable (UserProperty) async -> Void
    public var setUserId: @Sendable (String?) async -> Void
    public var reset: @Sendable () async -> Void
    public var flush: @Sendable () async -> Void
    
    public init(
        track: @escaping @Sendable (AnalyticsEvent) async -> Void,
        setUserProperty: @escaping @Sendable (UserProperty) async -> Void,
        setUserId: @escaping @Sendable (String?) async -> Void,
        reset: @escaping @Sendable () async -> Void,
        flush: @escaping @Sendable () async -> Void
    ) {
        self.track = track
        self.setUserProperty = setUserProperty
        self.setUserId = setUserId
        self.reset = reset
        self.flush = flush
    }
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var analyticsClient: AnalyticsClient {
        get { self[AnalyticsClient.self] }
        set { self[AnalyticsClient.self] = newValue }
    }
}

// MARK: - Live Implementation (Console Logging)
extension AnalyticsClient: DependencyKey {
    public static var liveValue: AnalyticsClient {
        var eventQueue: [AnalyticsEvent] = []
        var userProperties: [UserProperty] = []
        var currentUserId: String? = nil
        
        return AnalyticsClient(
            track: { event in
                eventQueue.append(event)
                print("📊 Analytics Event: \(event.name)")
                if !event.parameters.isEmpty {
                    print("  Parameters: \(event.parameters)")
                }
                
                // In a real implementation, this would send to a service
                // For now, we just log and queue locally
            },
            setUserProperty: { property in
                userProperties.append(property)
                print("👤 User Property: \(property.key) = \(property.value)")
                
                // In a real implementation, this would update user properties
                // For now, we just log and store locally
            },
            setUserId: { userId in
                currentUserId = userId
                print("🆔 User ID: \(userId ?? "nil")")
                
                // In a real implementation, this would set the user ID
                // For now, we just log and store locally
            },
            reset: {
                eventQueue.removeAll()
                userProperties.removeAll()
                currentUserId = nil
                print("🔄 Analytics Reset")
                
                // In a real implementation, this would reset the analytics session
                // For now, we just clear local storage
            },
            flush: {
                print("📤 Flushing \(eventQueue.count) events")
                
                // In a real implementation, this would send queued events to the server
                // For now, we just log and keep them in memory
                eventQueue.removeAll()
            }
        )
    }
}

// MARK: - Mock Implementation
extension AnalyticsClient {
    public static var mockValue: AnalyticsClient {
        let trackedEvents = LockIsolated<[AnalyticsEvent]>([])
        let userProperties = LockIsolated<[UserProperty]>([])
        let currentUserId = LockIsolated<String?>(nil)
        
        return AnalyticsClient(
            track: { event in
                trackedEvents.withValue { $0.append(event) }
            },
            setUserProperty: { property in
                userProperties.withValue { $0.append(property) }
            },
            setUserId: { userId in
                currentUserId.setValue(userId)
            },
            reset: {
                trackedEvents.withValue { $0.removeAll() }
                userProperties.withValue { $0.removeAll() }
                currentUserId.setValue(nil)
            },
            flush: {
                // Mock flush - just clear the queue
                trackedEvents.withValue { $0.removeAll() }
            }
        )
    }
}

// MARK: - Common Event Types
extension AnalyticsEvent {
    public static let appLaunched = AnalyticsEvent(name: "app_launched")
    public static let appBackgrounded = AnalyticsEvent(name: "app_backgrounded")
    public static let appForegrounded = AnalyticsEvent(name: "app_foregrounded")
    
    public static func login(method: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "login_completed",
            parameters: ["method": .string(method)]
        )
    }
    
    public static func logout() -> AnalyticsEvent {
        return AnalyticsEvent(name: "logout_completed")
    }
    
    public static func workoutStarted(type: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "workout_started",
            parameters: ["workout_type": .string(type)]
        )
    }
    
    public static func workoutCompleted(type: String, duration: TimeInterval) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "workout_completed",
            parameters: [
                "workout_type": .string(type),
                "duration_seconds": .double(duration)
            ]
        )
    }
    
    public static func screenView(screenName: String) -> AnalyticsEvent {
        return AnalyticsEvent(
            name: "screen_view",
            parameters: ["screen_name": .string(screenName)]
        )
    }
}

// MARK: - Common User Properties
extension UserProperty {
    public static let isPremiumUser = UserProperty(key: "is_premium_user", value: .bool(false))
    public static let hasCompletedOnboarding = UserProperty(key: "has_completed_onboarding", value: .bool(false))
    
    public static func workoutCount(_ count: Int) -> UserProperty {
        return UserProperty(key: "workout_count", value: .int(count))
    }
    
    public static func totalWorkoutTime(_ time: TimeInterval) -> UserProperty {
        return UserProperty(key: "total_workout_time_seconds", value: .double(time))
    }
}
