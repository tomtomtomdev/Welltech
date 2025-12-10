import Foundation
import OSLog
import ComposableArchitecture

// MARK: - Log Level
public enum CoreLogLevel: Int, CaseIterable, Sendable, Codable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    public var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
    
    public var emoji: String {
        switch self {
        case .debug:
            return "🔍"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "🚨"
        }
    }
    
    public var name: String {
        switch self {
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        case .critical:
            return "CRITICAL"
        }
    }
}

// MARK: - Log Entry
public struct LogEntry: Codable, Equatable, Sendable {
    public let timestamp: Date
    public let level: CoreLogLevel
    public let category: String
    public let message: String
    public let metadata: [String: String]
    
    public init(
        timestamp: Date = Date(),
        level: CoreLogLevel,
        category: String,
        message: String,
        metadata: [String: String] = [:]
    ) {
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
        self.metadata = metadata
    }
}

// MARK: - Logger Client Protocol
public struct LoggerClient {
    public var log: @Sendable (CoreLogLevel, String, String, [String: String]) -> Void
    public var debug: @Sendable (String, String, [String: String]) -> Void
    public var info: @Sendable (String, String, [String: String]) -> Void
    public var warning: @Sendable (String, String, [String: String]) -> Void
    public var error: @Sendable (String, String, [String: String]) -> Void
    public var critical: @Sendable (String, String, [String: String]) -> Void
    public var getLogs: @Sendable (CoreLogLevel?) -> [LogEntry]
    public var clearLogs: @Sendable () -> Void
    
    public init(
        log: @escaping @Sendable (CoreLogLevel, String, String, [String: String]) -> Void,
        debug: @escaping @Sendable (String, String, [String: String]) -> Void,
        info: @escaping @Sendable (String, String, [String: String]) -> Void,
        warning: @escaping @Sendable (String, String, [String: String]) -> Void,
        error: @escaping @Sendable (String, String, [String: String]) -> Void,
        critical: @escaping @Sendable (String, String, [String: String]) -> Void,
        getLogs: @escaping @Sendable (CoreLogLevel?) -> [LogEntry],
        clearLogs: @escaping @Sendable () -> Void
    ) {
        self.log = log
        self.debug = debug
        self.info = info
        self.warning = warning
        self.error = error
        self.critical = critical
        self.getLogs = getLogs
        self.clearLogs = clearLogs
    }
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var loggerClient: LoggerClient {
        get { self[LoggerClient.self] }
        set { self[LoggerClient.self] = newValue }
    }
}

// MARK: - Live Implementation
extension LoggerClient: DependencyKey {
    public static var liveValue: LoggerClient {
        let logger = Logger(subsystem: "com.welltech.wellnesskit", category: "CoreDependencies")
        var logHistory: [LogEntry] = []
        let maxLogCount = 1000
        
        return LoggerClient(
            log: { level, category, message, metadata in
                let entry = LogEntry(
                    level: level,
                    category: category,
                    message: message,
                    metadata: metadata
                )
                
                // Add to history
                logHistory.append(entry)
                
                // Trim history if needed
                if logHistory.count > maxLogCount {
                    logHistory.removeFirst(logHistory.count - maxLogCount)
                }
                
                // Log to OSLog
                let osLogger = Logger(subsystem: "com.welltech.wellnesskit", category: category)
                
                var logMessage = message
                if !metadata.isEmpty {
                    let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                    logMessage += " [\(metadataString)]"
                }
                
                osLogger.log(level: level.osLogType, "\(logMessage, privacy: .public)")
                
                // Also print to console for debugging (in debug builds)
                #if DEBUG
                print("\(level.emoji) [\(level.name)] \(category): \(logMessage)")
                #endif
            },
            debug: { category, message, metadata in
                LoggerClient.liveValue.log(.debug, category, message, metadata)
            },
            info: { category, message, metadata in
                LoggerClient.liveValue.log(.info, category, message, metadata)
            },
            warning: { category, message, metadata in
                LoggerClient.liveValue.log(.warning, category, message, metadata)
            },
            error: { category, message, metadata in
                LoggerClient.liveValue.log(.error, category, message, metadata)
            },
            critical: { category, message, metadata in
                LoggerClient.liveValue.log(.critical, category, message, metadata)
            },
            getLogs: { minLevel in
                if let minLevel = minLevel {
                    return logHistory.filter { $0.level.rawValue >= minLevel.rawValue }
                } else {
                    return logHistory
                }
            },
            clearLogs: {
                logHistory.removeAll()
            }
        )
    }
}

// MARK: - Mock Implementation
extension LoggerClient {
    public static var mockValue: LoggerClient {
        let mockLogs = LockIsolated<[LogEntry]>([])
        
        return LoggerClient(
            log: { level, category, message, metadata in
                let entry = LogEntry(
                    level: level,
                    category: category,
                    message: message,
                    metadata: metadata
                )
                mockLogs.withValue { $0.append(entry) }
                
                // Print to console for testing
                print("\(level.emoji) [\(level.name)] \(category): \(message)")
                if !metadata.isEmpty {
                    print("  Metadata: \(metadata)")
                }
            },
            debug: { category, message, metadata in
                LoggerClient.mockValue.log(.debug, category, message, metadata)
            },
            info: { category, message, metadata in
                LoggerClient.mockValue.log(.info, category, message, metadata)
            },
            warning: { category, message, metadata in
                LoggerClient.mockValue.log(.warning, category, message, metadata)
            },
            error: { category, message, metadata in
                LoggerClient.mockValue.log(.error, category, message, metadata)
            },
            critical: { category, message, metadata in
                LoggerClient.mockValue.log(.critical, category, message, metadata)
            },
            getLogs: { minLevel in
                return mockLogs.withValue { logs in
                    if let minLevel = minLevel {
                        return logs.filter { $0.level.rawValue >= minLevel.rawValue }
                    } else {
                        return logs
                    }
                }
            },
            clearLogs: {
                mockLogs.withValue { $0.removeAll() }
            }
        )
    }
}

// MARK: - Convenience Extensions
extension LoggerClient {
    public func logNetworkRequest(url: String, method: String, statusCode: Int? = nil) {
        var metadata = ["url": url, "method": method]
        if let statusCode = statusCode {
            metadata["status_code"] = String(statusCode)
        }
        
        if let statusCode = statusCode, (200...299).contains(statusCode) {
            info("Network", "Request completed", metadata)
        } else {
            warning("Network", "Request completed with non-2xx status", metadata)
        }
    }
    
    public func logError(_ error: Error, category: String = "General") {
        self.error(category, error.localizedDescription, ["error_type": String(describing: type(of: error))])
    }
    
    public func logUserAction(_ action: String, parameters: [String: String] = [:]) {
        info("UserAction", action, parameters)
    }
    
    public func logAnalyticsEvent(_ eventName: String, parameters: [String: String] = [:]) {
        debug("Analytics", "Event tracked: \(eventName)", parameters)
    }
    
    public func logPerformance(operation: String, duration: TimeInterval) {
        info("Performance", "Operation completed", [
            "operation": operation,
            "duration_ms": String(Int(duration * 1000))
        ])
    }
}
