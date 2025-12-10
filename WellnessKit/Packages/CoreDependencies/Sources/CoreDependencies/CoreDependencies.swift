// MARK: - CoreDependencies Module
// This module provides all the foundational dependencies for the WellnessKit platform

// Public API
@_exported import Foundation
@_exported import ComposableArchitecture

// MARK: - Setup Function
public func setupCoreDependencies() {
    // This function can be called from the app to ensure all dependencies are properly configured
    // In the future, this could include additional setup like crash reporting, etc.
}

// MARK: - Live Dependencies Registration
public extension DependencyValues {
    var allLiveDependencies: Void {
        get { }
        set {
            self.networkClient = NetworkClient.liveValue
            self.persistenceClient = PersistenceClient.liveValue
            self.analyticsClient = AnalyticsClient.liveValue
            self.dateClient = DateClient.liveValue
            self.loggerClient = LoggerClient.liveValue
        }
    }
}

// MARK: - Mock Dependencies Registration (for testing)
public extension DependencyValues {
    var allMockDependencies: Void {
        get { }
        set {
            self.networkClient = NetworkClient.mockValue
            self.persistenceClient = PersistenceClient.mockValue
            self.analyticsClient = AnalyticsClient.mockValue
            self.dateClient = DateClient.mock(currentDate: Date())
            self.loggerClient = LoggerClient.mockValue
        }
    }
}
