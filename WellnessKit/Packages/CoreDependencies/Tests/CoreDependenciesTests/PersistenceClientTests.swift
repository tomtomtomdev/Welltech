import Foundation
import Testing
import ComposableArchitecture
@testable import CoreDependencies

@Suite("PersistenceClient Tests")
struct PersistenceClientTests {
    @Test("PersistenceClient mock should store and retrieve values")
    func mockStorage() async throws {
        let client = PersistenceClient.mockValue
        
        let testKey = "test_key"
        let testValue = "test_value"
        
        try await client.set(testKey, testValue, .userDefaults)
        let retrievedValue = try await client.get(testKey, .userDefaults) as? String
        
        #expect(retrievedValue == testValue)
    }
    
    @Test("PersistenceClient mock should handle Codable objects")
    func codableStorage() async throws {
        let client = PersistenceClient.mockValue
        
        struct TestStruct: Codable, Equatable {
            let id: String
            let name: String
        }
        
        let testObject = TestStruct(id: "123", name: "Test")
        let testKey = "test_object"
        
        try await client.set(testObject, forKey: testKey, storageType: .userDefaults)
        let retrievedObject = try await client.get(TestStruct.self, forKey: testKey, storageType: .userDefaults)
        
        #expect(retrievedObject == testObject)
    }
    
    @Test("PersistenceClient mock should handle nil values")
    func nilValueHandling() async throws {
        let client = PersistenceClient.mockValue
        
        let testKey = "test_key"
        
        // Set a value first
        try await client.set(testKey, "test_value", .userDefaults)
        
        // Verify it exists
        let retrievedValue = try await client.get(testKey, .userDefaults) as? String
        #expect(retrievedValue == "test_value")
        
        // Set it to nil (should remove it)
        try await client.set(testKey, nil, .userDefaults)
        
        // Verify it's removed
        let nilValue = try await client.get(testKey, .userDefaults)
        #expect(nilValue == nil)
    }
    
    @Test("PersistenceClient mock should remove specific keys")
    func keyRemoval() async throws {
        let client = PersistenceClient.mockValue
        
        let testKey1 = "test_key_1"
        let testKey2 = "test_key_2"
        
        try await client.set(testKey1, "value1", .userDefaults)
        try await client.set(testKey2, "value2", .userDefaults)
        
        // Remove only key1
        try await client.remove(testKey1, .userDefaults)
        
        let value1 = try await client.get(testKey1, .userDefaults)
        let value2 = try await client.get(testKey2, .userDefaults) as? String
        
        #expect(value1 == nil)
        #expect(value2 == "value2")
    }
    
    @Test("PersistenceClient mock should clear all data for storage type")
    func clearStorage() async throws {
        let client = PersistenceClient.mockValue
        
        let testKey1 = "test_key_1"
        let testKey2 = "test_key_2"
        
        try await client.set(testKey1, "value1", .userDefaults)
        try await client.set(testKey2, "value2", .userDefaults)
        
        // Clear all UserDefaults data
        try await client.clear(.userDefaults)
        
        let value1 = try await client.get(testKey1, .userDefaults)
        let value2 = try await client.get(testKey2, .userDefaults)
        
        #expect(value1 == nil)
        #expect(value2 == nil)
    }
    
    @Test("PersistenceError should have correct descriptions")
    func persistenceErrorDescriptions() {
        #expect(PersistenceError.keychainError("test").localizedDescription == "Keychain error: test")
        #expect(PersistenceError.encodingError.localizedDescription == "Data encoding error")
        #expect(PersistenceError.decodingError.localizedDescription == "Data decoding error")
        #expect(PersistenceError.itemNotFound.localizedDescription == "Item not found")
        #expect(PersistenceError.unknownError("test").localizedDescription == "Unknown error: test")
    }
    
    @Test("KeychainItem should encode and decode correctly")
    func keychainItemEncoding() throws {
        let item = KeychainItem(
            account: "test-account",
            service: "test-service",
            accessGroup: "test-group"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        
        let decoder = JSONDecoder()
        let decodedItem = try decoder.decode(KeychainItem.self, from: data)
        
        #expect(decodedItem.account == "test-account")
        #expect(decodedItem.service == "test-service")
        #expect(decodedItem.accessGroup == "test-group")
    }
    
    @Test("Dependency injection should work correctly")
    func dependencyInjection() async throws {
        let testClient = PersistenceClient.mockValue
        
        await withDependencies {
            $0.persistenceClient = testClient
        } operation: {
            let testKey = "dependency_test"
            let testValue = "dependency_value"
            
            try await DependencyValues().persistenceClient.set(testKey, testValue, .userDefaults)
            let retrievedValue = try await DependencyValues().persistenceClient.get(testKey, .userDefaults) as? String
            
            #expect(retrievedValue == testValue)
        }
    }
    
    @Test("Complex Codable objects should be stored correctly")
    func complexCodableStorage() async throws {
        let client = PersistenceClient.mockValue
        
        struct ComplexObject: Codable, Equatable {
            let id: UUID
            let name: String
            let tags: [String]
            let metadata: [String: Double]
            let createdAt: Date
        }
        
        let testObject = ComplexObject(
            id: UUID(),
            name: "Complex Test",
            tags: ["tag1", "tag2", "tag3"],
            metadata: ["score": 95.5, "rating": 4.8],
            createdAt: Date()
        )
        
        let testKey = "complex_object"
        
        try await client.set(testObject, forKey: testKey, storageType: .userDefaults)
        let retrievedObject = try await client.get(ComplexObject.self, forKey: testKey, storageType: .userDefaults)
        
        #expect(retrievedObject == testObject)
    }
}
