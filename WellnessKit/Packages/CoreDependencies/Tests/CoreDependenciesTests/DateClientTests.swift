import Foundation
import Testing
import ComposableArchitecture
@testable import CoreDependencies

@Suite("DateClient Tests")
struct DateClientTests {
    @Test("DateClient mock should return consistent date")
    func mockConsistentDate() {
        let testDate = Date(timeIntervalSince1970: 1640995200) // January 1, 2022
        let client = DateClient.mock(currentDate: testDate)
        
        let now1 = client.now()
        let now2 = client.now()
        
        #expect(now1 == testDate)
        #expect(now2 == testDate)
        #expect(now1 == now2)
    }
    
    @Test("DateClient advancing time should increment correctly")
    func advancingTime() {
        let client = DateClient.advancingTime(by: 60) // 1 minute increments
        
        let now1 = client.now()
        let now2 = client.now()
        let now3 = client.now()
        
        #expect(now2.timeIntervalSince(now1) == 60)
        #expect(now3.timeIntervalSince(now2) == 60)
        #expect(now3.timeIntervalSince(now1) == 120)
    }
    
    @Test("DateClient utilities should work correctly")
    func dateUtilities() {
        let baseDate = Date(timeIntervalSince1970: 1640995200) // January 1, 2022, 00:00:00 UTC
        let client = DateClient.mock(currentDate: baseDate)
        
        #expect(client.tomorrow.timeIntervalSince(baseDate) == 24 * 60 * 60)
        #expect(client.yesterday.timeIntervalSince(baseDate) == -24 * 60 * 60)
        
        // Test date creation from time interval
        let epochDate = client.date(0)
        #expect(epochDate.timeIntervalSince1970 == 0)
        
        // Test time interval since
        let pastDate = baseDate.addingTimeInterval(-3600)
        #expect(client.timeIntervalSince(pastDate) == 3600)
        
        // Test adding time interval
        let futureDate = client.addingTimeInterval(3600)
        #expect(futureDate.timeIntervalSince(baseDate) == 3600)
    }
    
    @Test("DateClient start and end of day should work correctly")
    func dayBoundaries() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2022, month: 1, day: 15, hour: 14, minute: 30, second: 45))!
        let client = DateClient.mock(currentDate: testDate)
        
        let startOfDay = client.startOfDay
        let endOfDay = client.endOfDay
        
        let startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: startOfDay)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: endOfDay)
        
        #expect(startComponents.year == 2022)
        #expect(startComponents.month == 1)
        #expect(startComponents.day == 15)
        #expect(startComponents.hour == 0)
        #expect(startComponents.minute == 0)
        #expect(startComponents.second == 0)
        
        #expect(endComponents.year == 2022)
        #expect(endComponents.month == 1)
        #expect(endComponents.day == 15)
        #expect(endComponents.hour == 23)
        #expect(endComponents.minute == 59)
        #expect(endComponents.second == 59)
    }
    
    @Test("DateClient week/month/year start should work correctly")
    func periodBoundaries() {
        let calendar = Calendar.current
        let testDate = calendar.date(from: DateComponents(year: 2022, month: 1, day: 15, hour: 14, minute: 30))!
        let client = DateClient.mock(currentDate: testDate)
        
        let startOfWeek = client.startOfWeek(for: testDate)
        let startOfMonth = client.startOfMonth(for: testDate)
        let startOfYear = client.startOfYear(for: testDate)
        
        // Week start (assuming Sunday is first day of week)
        let weekComponents = calendar.dateComponents([.year, .month, .day, .weekday], from: startOfWeek)
        #expect(weekComponents.weekday == 1) // Sunday
        
        // Month start
        let monthComponents = calendar.dateComponents([.year, .month, .day], from: startOfMonth)
        #expect(monthComponents.year == 2022)
        #expect(monthComponents.month == 1)
        #expect(monthComponents.day == 1)
        
        // Year start
        let yearComponents = calendar.dateComponents([.year, .month, .day], from: startOfYear)
        #expect(yearComponents.year == 2022)
        #expect(yearComponents.month == 1)
        #expect(yearComponents.day == 1)
    }
    
    @Test("DateClient date comparison utilities should work correctly")
    func dateComparisons() {
        let calendar = Calendar.current
        let today = calendar.date(from: DateComponents(year: 2022, month: 1, day: 15))!
        let client = DateClient.mock(currentDate: today)
        
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let sameDayDifferentTime = calendar.date(byAdding: .hour, value: 14, to: today)!
        
        #expect(client.isToday(today))
        #expect(client.isYesterday(yesterday))
        #expect(client.isTomorrow(tomorrow))
        #expect(client.isSameDay(today, as: sameDayDifferentTime))
        #expect(!client.isSameDay(today, as: yesterday))
        
        #expect(client.daysBetween(from: today, to: tomorrow) == 1)
        #expect(client.daysBetween(from: today, to: yesterday) == -1)
        #expect(client.daysBetween(from: yesterday, to: tomorrow) == 2)
    }
    
    @Test("DateClient live implementation should use current date")
    func liveImplementation() {
        let client = DateClient.liveValue
        
        let beforeDate = Date()
        let now = client.now()
        let afterDate = Date()
        
        #expect(now >= beforeDate)
        #expect(now <= afterDate)
        
        let today = client.startOfDay
        let calendar = client.calendar()
        
        #expect(calendar.isDateInToday(today))
    }
    
    @Test("DateClient dependency injection should work correctly")
    func dependencyInjection() {
        let testDate = Date(timeIntervalSince1970: 1640995200) // January 1, 2022
        let testClient = DateClient.mock(currentDate: testDate)
        
        withDependencies {
            $0.dateClient = testClient
        } operation: {
            let now = DependencyValues().dateClient.now()
            #expect(now == testDate)
        }
    }
    
    @Test("DateClient should handle leap years correctly")
    func leapYearHandling() {
        let calendar = Calendar.current
        
        // Test leap year (2020)
        let feb29_2020 = calendar.date(from: DateComponents(year: 2020, month: 2, day: 29))!
        let client2020 = DateClient.mock(currentDate: feb29_2020)
        
        #expect(client2020.isToday(feb29_2020))
        #expect(client2020.startOfMonth(for: feb29_2020).timeIntervalSince1970 > 0)
        #expect(client2020.startOfYear(for: feb29_2020).timeIntervalSince1970 > 0)
        
        // Test non-leap year (2021)
        let feb28_2021 = calendar.date(from: DateComponents(year: 2021, month: 2, day: 28))!
        let client2021 = DateClient.mock(currentDate: feb28_2021)
        
        #expect(client2021.isToday(feb28_2021))
        #expect(client2021.startOfMonth(for: feb28_2021).timeIntervalSince1970 > 0)
        #expect(client2021.startOfYear(for: feb28_2021).timeIntervalSince1970 > 0)
    }
    
    @Test("DateClient should handle different time zones consistently")
    func timeZoneConsistency() {
        let utc = TimeZone(secondsFromGMT: 0)!
        let est = TimeZone(secondsFromGMT: -18000)! // EST (UTC-5)
        
        var calendar1 = Calendar.current
        calendar1.timeZone = utc
        
        var calendar2 = Calendar.current
        calendar2.timeZone = est
        
        let testDate = Date()
        
        let client1 = DateClient.mock(currentDate: testDate)
        let client2 = DateClient.mock(currentDate: testDate)
        
        // Both should return the same base date regardless of timezone
        #expect(abs(client1.now().timeIntervalSince(client2.now())) < 0.001)
        
        // But calendar operations should respect the timezone
        let startOfDay1 = client1.calendar().startOfDay(for: testDate)
        let startOfDay2 = client2.calendar().startOfDay(for: testDate)
        
        // The difference should be exactly 5 hours (300 minutes)
        let difference = startOfDay1.timeIntervalSince(startOfDay2)
        #expect(abs(difference - 18000) < 1) // Allow for minor rounding errors
    }
}
