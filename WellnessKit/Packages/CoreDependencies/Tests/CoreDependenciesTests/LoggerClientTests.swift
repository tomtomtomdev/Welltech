import Foundation
import Testing
import ComposableArchitecture
@testable import CoreDependencies

@Suite("LoggerClient Tests")
struct LoggerClientTests {
    @Test("LoggerClient mock should create log entries correctly")
    func logEntryCreation() {
        let testDate = Date(timeIntervalSince1970: 1640995200) // Fixed date for testing
        let entry = LogEntry(
            timestamp: testDate,
            level: .info,
            category: "TestCategory",
            message: "Test message",
            metadata: ["key": "value"]
        )
        
        #expect(entry.timestamp == testDate)
        #expect(entry.level == .info)
        #expect(entry.category == "TestCategory")
        #expect(entry.message == "Test message")
        #expect(entry.metadata["key"] == "value")
    }
    
    @Test("LogEntry should encode and decode correctly")
    func logEntryEncoding() throws {
        let entry = LogEntry(
            level: .warning,
            category: "TestCategory",
            message: "Test warning",
            metadata: ["error_code": "404", "user_id": "123"]
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(entry)
        let decodedEntry = try decoder.decode(LogEntry.self, from: data)
        
        #expect(decodedEntry.level == .warning)
        #expect(decodedEntry.category == "TestCategory")
        #expect(decodedEntry.message == "Test warning")
        #expect(decodedEntry.metadata["error_code"] == "404")
        #expect(decodedEntry.metadata["user_id"] == "123")
    }
    
    @Test("LogLevel should have correct properties")
    func logLevelProperties() {
        #expect(CoreLogLevel.debug.emoji == "🔍")
        #expect(CoreLogLevel.debug.name == "DEBUG")
        #expect(CoreLogLevel.debug.osLogType == .debug)
        #expect(CoreLogLevel.debug.rawValue == 0)
        
        #expect(CoreLogLevel.info.emoji == "ℹ️")
        #expect(CoreLogLevel.info.name == "INFO")
        #expect(CoreLogLevel.info.osLogType == .info)
        #expect(CoreLogLevel.info.rawValue == 1)
        
        #expect(CoreLogLevel.warning.emoji == "⚠️")
        #expect(CoreLogLevel.warning.name == "WARNING")
        #expect(CoreLogLevel.warning.osLogType == .default)
        #expect(CoreLogLevel.warning.rawValue == 2)
        
        #expect(CoreLogLevel.error.emoji == "❌")
        #expect(CoreLogLevel.error.name == "ERROR")
        #expect(CoreLogLevel.error.osLogType == .error)
        #expect(CoreLogLevel.error.rawValue == 3)
        
        #expect(CoreLogLevel.critical.emoji == "🚨")
        #expect(CoreLogLevel.critical.name == "CRITICAL")
        #expect(CoreLogLevel.critical.osLogType == .fault)
        #expect(CoreLogLevel.critical.rawValue == 4)
    }
    
    @Test("LoggerClient mock should store logs correctly")
    func mockLogStorage() async {
        let client = LoggerClient.mockValue
        
        await client.debug("DebugCat", "Debug message", ["debug_key": "debug_value"])
        await client.info("InfoCat", "Info message")
        await client.warning("WarningCat", "Warning message", ["warning_key": "warning_value"])
        await client.error("ErrorCat", "Error message")
        await client.critical("CriticalCat", "Critical message", ["critical_key": "critical_value"])
        
        // Get all logs
        let allLogs = client.getLogs(nil)
        #expect(allLogs.count == 5)
        
        // Get logs from info level and above
        let infoAndAbove = client.getLogs(.info)
        #expect(infoAndAbove.count == 4) // info, warning, error, critical
        
        // Get logs from error level and above
        let errorAndAbove = client.getLogs(.error)
        #expect(errorAndAbove.count == 2) // error, critical
        
        // Verify specific log entries
        let debugLogs = infoAndAbove.filter { $0.category == "DebugCat" }
        #expect(debugLogs.isEmpty) // Debug should be filtered out
        
        let infoLogs = infoAndAbove.filter { $0.category == "InfoCat" }
        #expect(infoLogs.count == 1)
        #expect(infoLogs.first?.level == .info)
        #expect(infoLogs.first?.message == "Info message")
        
        let warningLogs = infoAndAbove.filter { $0.category == "WarningCat" }
        #expect(warningLogs.count == 1)
        #expect(warningLogs.first?.level == .warning)
        #expect(warningLogs.first?.message == "Warning message")
        #expect(warningLogs.first?.metadata["warning_key"] == "warning_value")
    }
    
    @Test("LoggerClient mock should clear logs correctly")
    func clearLogs() async {
        let client = LoggerClient.mockValue
        
        await client.info("TestCategory", "Test message 1")
        await client.info("TestCategory", "Test message 2")
        
        let logsBefore = client.getLogs(nil)
        #expect(logsBefore.count == 2)
        
        await client.clearLogs()
        
        let logsAfter = client.getLogs(nil)
        #expect(logsAfter.isEmpty)
    }
    
    @Test("LoggerClient convenience methods should work correctly")
    func convenienceMethods() async {
        let client = LoggerClient.mockValue
        
        // Test network logging
        await client.logNetworkRequest(url: "https://api.example.com/test", method: "GET", statusCode: 200)
        await client.logNetworkRequest(url: "https://api.example.com/error", method: "POST", statusCode: 404)
        
        // Test error logging
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        await client.logError(testError, category: "TestCategory")
        
        // Test user action logging
        await client.logUserAction("button_tapped", parameters: ["button_id": "submit"])
        
        // Test analytics event logging
        await client.logAnalyticsEvent("screen_view", parameters: ["screen_name": "Home"])
        
        // Test performance logging
        await client.logPerformance(operation: "api_call", duration: 1.234)
        
        let logs = client.getLogs(nil)
        #expect(logs.count >= 5)
        
        // Verify specific log types
        let networkLogs = logs.filter { $0.category == "Network" }
        #expect(networkLogs.count >= 2)
        
        let userActionLogs = logs.filter { $0.category == "UserAction" }
        #expect(userActionLogs.count >= 1)
        
        let analyticsLogs = logs.filter { $0.category == "Analytics" }
        #expect(analyticsLogs.count >= 1)
        
        let performanceLogs = logs.filter { $0.category == "Performance" }
        #expect(performanceLogs.count >= 1)
    }
    
    @Test("LoggerClient dependency injection should work correctly")
    func dependencyInjection() async {
        let testClient = LoggerClient.mockValue
        
        await withDependencies {
            $0.loggerClient = testClient
        } operation: {
            let client = DependencyValues().loggerClient
            
            await client.info("DependencyTest", "Test message", ["test_key": "test_value"])
            
            let logs = client.getLogs(nil)
            #expect(logs.count == 1)
            #expect(logs.first?.category == "DependencyTest")
            #expect(logs.first?.message == "Test message")
            #expect(logs.first?.metadata["test_key"] == "test_value")
        }
    }
    
    @Test("LoggerClient should handle different log levels correctly")
    func logLevelFiltering() async {
        let client = LoggerClient.mockValue
        
        await client.log(.debug, "Debug", "Debug message")
        await client.log(.info, "Info", "Info message")
        await client.log(.warning, "Warning", "Warning message")
        await client.log(.error, "Error", "Error message")
        await client.log(.critical, "Critical", "Critical message")
        
        let debugLogs = client.getLogs(.debug)
        #expect(debugLogs.count == 5)
        
        let infoLogs = client.getLogs(.info)
        #expect(infoLogs.count == 4)
        
        let warningLogs = client.getLogs(.warning)
        #expect(warningLogs.count == 3)
        
        let errorLogs = client.getLogs(.error)
        #expect(errorLogs.count == 2)
        
        let criticalLogs = client.getLogs(.critical)
        #expect(criticalLogs.count == 1)
    }
    
    @Test("LoggerClient should handle empty metadata correctly")
    func emptyMetadataHandling() async {
        let client = LoggerClient.mockValue
        
        await client.info("Test", "Message without metadata")
        
        let logs = client.getLogs(nil)
        #expect(logs.count == 1)
        #expect(logs.first?.metadata.isEmpty == true)
    }
    
    @Test("LoggerClient should handle special characters in messages and metadata")
    func specialCharacterHandling() async {
        let client = LoggerClient.mockValue
        
        let specialMessage = "Message with emojis 🚀 and special chars: ñáéíóú"
        let specialMetadata = ["special_key": "Special value with émojis: 🎉 and áccents"]
        
        await client.info("Special", specialMessage, specialMetadata)
        
        let logs = client.getLogs(nil)
        #expect(logs.count == 1)
        #expect(logs.first?.message == specialMessage)
        #expect(logs.first?.metadata["special_key"] == specialMetadata["special_key"])
    }
}
