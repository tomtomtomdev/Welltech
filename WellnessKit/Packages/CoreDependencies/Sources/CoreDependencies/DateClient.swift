import Foundation
import ComposableArchitecture

// MARK: - Date Client Protocol
public struct DateClient {
    public var now: @Sendable () -> Date
    public var date: @Sendable (TimeInterval) -> Date
    public var timeIntervalSince: @Sendable (Date) -> TimeInterval
    public var addingTimeInterval: @Sendable (TimeInterval) -> Date
    public var calendar: @Sendable () -> Calendar
    
    public init(
        now: @escaping @Sendable () -> Date,
        date: @escaping @Sendable (TimeInterval) -> Date,
        timeIntervalSince: @escaping @Sendable (Date) -> TimeInterval,
        addingTimeInterval: @escaping @Sendable (TimeInterval) -> Date,
        calendar: @escaping @Sendable () -> Calendar
    ) {
        self.now = now
        self.date = date
        self.timeIntervalSince = timeIntervalSince
        self.addingTimeInterval = addingTimeInterval
        self.calendar = calendar
    }
}

// MARK: - Date Utilities
extension DateClient {
    public var tomorrow: Date {
        now().addingTimeInterval(24 * 60 * 60)
    }
    
    public var yesterday: Date {
        now().addingTimeInterval(-24 * 60 * 60)
    }
    
    public var startOfDay: Date {
        calendar().startOfDay(for: now())
    }
    
    public var endOfDay: Date {
        let startOfToday = startOfDay
        let startOfTomorrow = calendar().date(byAdding: .day, value: 1, to: startOfToday)!
        return calendar().date(byAdding: .second, value: -1, to: startOfTomorrow)!
    }
    
    public func startOfWeek(for date: Date) -> Date {
        calendar().dateInterval(of: .weekOfYear, for: date)?.start ?? date
    }
    
    public func startOfMonth(for date: Date) -> Date {
        calendar().dateInterval(of: .month, for: date)?.start ?? date
    }
    
    public func startOfYear(for date: Date) -> Date {
        calendar().dateInterval(of: .year, for: date)?.start ?? date
    }
    
    public func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        calendar().dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    public func isToday(_ date: Date) -> Bool {
        calendar().isDateInToday(date)
    }
    
    public func isYesterday(_ date: Date) -> Bool {
        calendar().isDateInYesterday(date)
    }
    
    public func isTomorrow(_ date: Date) -> Bool {
        calendar().isDateInTomorrow(date)
    }
    
    public func isSameDay(_ date1: Date, as date2: Date) -> Bool {
        calendar().isDate(date1, inSameDayAs: date2)
    }
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var dateClient: DateClient {
        get { self[DateClient.self] }
        set { self[DateClient.self] = newValue }
    }
}

// MARK: - Live Implementation
extension DateClient: DependencyKey {
    public static var liveValue: DateClient {
        let calendar = Calendar.current
        
        return DateClient(
            now: { Date() },
            date: { Date(timeIntervalSince1970: $0) },
            timeIntervalSince: { Date().timeIntervalSince($0) },
            addingTimeInterval: { Date().addingTimeInterval($0) },
            calendar: { calendar }
        )
    }
}

// MARK: - Mock Implementation
extension DateClient {
    public static func mock(currentDate: Date = Date()) -> DateClient {
        let calendar = Calendar.current
        
        return DateClient(
            now: { currentDate },
            date: { Date(timeIntervalSince1970: $0) },
            timeIntervalSince: { currentDate.timeIntervalSince($0) },
            addingTimeInterval: { currentDate.addingTimeInterval($0) },
            calendar: { calendar }
        )
    }
    
    public static func advancingTime(by interval: TimeInterval) -> DateClient {
        var currentTime = Date()
        let calendar = Calendar.current
        
        return DateClient(
            now: {
                currentTime = currentTime.addingTimeInterval(interval)
                return currentTime
            },
            date: { Date(timeIntervalSince1970: $0) },
            timeIntervalSince: { currentTime.timeIntervalSince($0) },
            addingTimeInterval: { currentTime.addingTimeInterval($0) },
            calendar: { calendar }
        )
    }
}
