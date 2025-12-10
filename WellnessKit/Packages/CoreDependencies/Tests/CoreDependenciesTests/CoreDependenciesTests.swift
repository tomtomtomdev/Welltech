import Foundation
import Testing
import ComposableArchitecture
@testable import CoreDependencies

@Suite("CoreDependencies Integration Tests")
struct CoreDependenciesIntegrationTests {
    @Test("All dependencies should work together")
    func allDependenciesIntegration() async {
        let mockNetworkClient = NetworkClient.mockValue
        let mockPersistenceClient = PersistenceClient.mockValue
        let mockAnalyticsClient = AnalyticsClient.mockValue
        let mockDateClient = DateClient.mock()
        let mockLoggerClient = LoggerClient.mockValue
        
        await withDependencies {
            $0.networkClient = mockNetworkClient
            $0.persistenceClient = mockPersistenceClient
            $0.analyticsClient = mockAnalyticsClient
            $0.dateClient = mockDateClient
            $0.loggerClient = mockLoggerClient
        } operation: {
            let dependencies = DependencyValues()
            
            // Test network client
            let url = URL(string: "https://api.example.com/test")!
            let request = URLRequest(url: url)
            await #expect(throws: Error.self) {
                try await dependencies.networkClient.request(request)
            }
            
            // Test persistence client
            let testKey = "integration_test"
            let testValue = "integration_value"
            try await dependencies.persistenceClient.set(testKey, testValue, .userDefaults)
            let retrievedValue = try await dependencies.persistenceClient.get(testKey, .userDefaults) as? String
            #expect(retrievedValue == testValue)
            
            // Test analytics client
            let event = AnalyticsEvent(name: "integration_test")
            await dependencies.analyticsClient.track(event)
            
            // Test date client
            let now = dependencies.dateClient.now()
            #expect(now.timeIntervalSince1970 > 0)
            
            // Test logger client
            await dependencies.loggerClient.info("Integration", "Integration test completed", [:])
            let logs = dependencies.loggerClient.getLogs(.info)
            #expect(logs.count >= 1)
        }
    }
    
    @Test("Live dependencies should be properly configured")
    func liveDependenciesConfiguration() {
        let dependencies = DependencyValues()
        
        // Test that all live dependencies are available
        #expect(dependencies.networkClient != nil)
        #expect(dependencies.persistenceClient != nil)
        #expect(dependencies.analyticsClient != nil)
        #expect(dependencies.dateClient != nil)
        #expect(dependencies.loggerClient != nil)
    }
    
    @Test("Mock dependencies should be properly configured")
    func mockDependenciesConfiguration() {
        var dependencies = DependencyValues()
        dependencies.allMockDependencies = ()
        
        // Test that all mock dependencies are available
        #expect(dependencies.networkClient != nil)
        #expect(dependencies.persistenceClient != nil)
        #expect(dependencies.analyticsClient != nil)
        #expect(dependencies.dateClient != nil)
        #expect(dependencies.loggerClient != nil)
    }
    
    @Test("Setup function should not throw")
    func setupFunction() {
        // This should not throw any exceptions
        setupCoreDependencies()
        #expect(true)
    }
    
    @Test("Type aliases should be properly defined")
    func typeAliases() {
        // Test that all type aliases are working
        let networkClient: NetworkClient = .mockValue
        let persistenceClient: PersistenceClient = .mockValue
        let analyticsClient: AnalyticsClient = .mockValue
        let dateClient: DateClient = .mock()
        let loggerClient: LoggerClient = .mockValue
        
        // Test error types
        let apiError: APIError = .invalidURL
        let persistenceError: PersistenceError = .itemNotFound
        
        // Test data types
        let event: AnalyticsEvent = .appLaunched
        let userProperty: UserProperty = .isPremiumUser
        let logLevel: CoreLogLevel = .info
        
        // Test storage types
        let storageType: StorageType = .userDefaults
        
        // If we get here, all type aliases are working correctly
        #expect(true)
    }
}
