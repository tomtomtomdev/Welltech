import Foundation
import ComposableArchitecture
import Security

// MARK: - Storage Types
public enum StorageType: Sendable {
    case userDefaults
    case keychain
    case coreData
}

// MARK: - Persistence Error
public enum PersistenceError: Error, Equatable, Sendable {
    case keychainError(String)
    case encodingError
    case decodingError
    case itemNotFound
    case unknownError(String)
    
    public var localizedDescription: String {
        switch self {
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .encodingError:
            return "Data encoding error"
        case .decodingError:
            return "Data decoding error"
        case .itemNotFound:
            return "Item not found"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Keychain Item
public struct KeychainItem: Codable, Sendable {
    public let account: String
    public let service: String
    public let accessGroup: String?
    
    public init(account: String, service: String, accessGroup: String? = nil) {
        self.account = account
        self.service = service
        self.accessGroup = accessGroup
    }
}

// MARK: - Persistence Client Protocol
public struct PersistenceClient {
    public var set: @Sendable (String, Any?, StorageType) async throws -> Void
    public var get: @Sendable (String, StorageType) async throws -> Any?
    public var remove: @Sendable (String, StorageType) async throws -> Void
    public var clear: @Sendable (StorageType) async throws -> Void
    
    public init(
        set: @escaping @Sendable (String, Any?, StorageType) async throws -> Void,
        get: @escaping @Sendable (String, StorageType) async throws -> Any?,
        remove: @escaping @Sendable (String, StorageType) async throws -> Void,
        clear: @escaping @Sendable (StorageType) async throws -> Void
    ) {
        self.set = set
        self.get = get
        self.remove = remove
        self.clear = clear
    }
}

// MARK: - Codable Convenience Methods
extension PersistenceClient {
    public func set<T: Codable>(_ value: T?, forKey key: String, storageType: StorageType) async throws {
        guard let value = value else {
            try await remove(key, storageType)
            return
        }
        
        let data = try JSONEncoder().encode(value)
        try await set(key, data, storageType)
    }
    
    public func get<T: Codable>(_ type: T.Type, forKey key: String, storageType: StorageType) async throws -> T? {
        guard let data = try await get(key, storageType) as? Data else {
            return nil
        }
        
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Dependency Extension
extension DependencyValues {
    public var persistenceClient: PersistenceClient {
        get { self[PersistenceClient.self] }
        set { self[PersistenceClient.self] = newValue }
    }
}

// MARK: - Live Implementation
extension PersistenceClient: DependencyKey {
    public static var liveValue: PersistenceClient {
        let userDefaults = UserDefaults.standard
        let keychain = Keychain(service: "com.welltech.wellnesskit")
        
        return PersistenceClient(
            set: { key, value, storageType in
                switch storageType {
                case .userDefaults:
                    if let value = value {
                        userDefaults.set(value, forKey: key)
                    } else {
                        userDefaults.removeObject(forKey: key)
                    }
                    
                case .keychain:
                    if let data = value as? Data {
                        try keychain.set(data, key: key)
                    } else {
                        try keychain.remove(key: key)
                    }
                    
                case .coreData:
                    // CoreData implementation would go here
                    throw PersistenceError.unknownError("CoreData not implemented yet")
                }
            },
            get: { key, storageType in
                switch storageType {
                case .userDefaults:
                    return userDefaults.object(forKey: key)
                    
                case .keychain:
                    return try keychain.get(key: key)
                    
                case .coreData:
                    throw PersistenceError.unknownError("CoreData not implemented yet")
                }
            },
            remove: { key, storageType in
                switch storageType {
                case .userDefaults:
                    userDefaults.removeObject(forKey: key)
                    
                case .keychain:
                    try keychain.remove(key: key)
                    
                case .coreData:
                    throw PersistenceError.unknownError("CoreData not implemented yet")
                }
            },
            clear: { storageType in
                switch storageType {
                case .userDefaults:
                    let domain = Bundle.main.bundleIdentifier!
                    userDefaults.removePersistentDomain(forName: domain)
                    
                case .keychain:
                    try keychain.clear()
                    
                case .coreData:
                    throw PersistenceError.unknownError("CoreData not implemented yet")
                }
            }
        )
    }
}

// MARK: - Keychain Helper
private struct Keychain {
    let service: String
    
    init(service: String) {
        self.service = service
    }
    
    func set(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw PersistenceError.keychainError("Unable to add item: \(status)")
        }
        
        if status == errSecDuplicateItem {
            try update(data, key: key)
        }
    }
    
    func get(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw PersistenceError.keychainError("Unable to get item: \(status)")
        }
        
        return result as? Data
    }
    
    func update(_ data: Data, key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw PersistenceError.keychainError("Unable to update item: \(status)")
        }
    }
    
    func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PersistenceError.keychainError("Unable to remove item: \(status)")
        }
    }
    
    func clear() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PersistenceError.keychainError("Unable to clear keychain: \(status)")
        }
    }
}

// MARK: - Mock Implementation
extension PersistenceClient {
    public static var mockValue: PersistenceClient {
        let storage = LockIsolated<[String: Any]>([:])
        
        return PersistenceClient(
            set: { key, value, _ in
                storage.withValue { $0[key] = value }
            },
            get: { key, _ in
                return storage.withValue { $0[key] }
            },
            remove: { key, _ in
                storage.withValue { $0.removeValue(forKey: key) }
            },
            clear: { _ in
                storage.withValue { $0.removeAll() }
            }
        )
    }
}
