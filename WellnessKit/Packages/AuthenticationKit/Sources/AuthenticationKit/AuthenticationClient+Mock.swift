import Foundation
import ComposableArchitecture
import CoreDependencies

// MARK: - Mock Implementation
extension AuthenticationClient {
    public static var mockValue: AuthenticationClient {
        let currentUser = LockIsolated<User?>(nil)
        let isLoggedIn = LockIsolated<Bool>(false)
        
        return AuthenticationClient(
            login: { credentials in
                if credentials.email == "test@example.com" && credentials.password == "password" {
                    let user = User(
                        id: "12345",
                        email: credentials.email,
                        name: "Test User",
                        isPremium: false,
                        createdAt: Date()
                    )
                    
                    let token = AuthToken(
                        token: "mock_jwt_token",
                        refreshToken: "mock_refresh_token",
                        expiresAt: Date().addingTimeInterval(3600),
                        user: user
                    )
                    
                    currentUser.setValue(user)
                    isLoggedIn.setValue(true)
                    return token
                } else {
                    throw AuthenticationError.invalidCredentials
                }
            },
            
            loginWithSocial: { provider, token in
                let user = User(
                    id: UUID().uuidString,
                    email: "user@\(provider.rawValue).com",
                    name: "\(provider.displayName) User",
                    isPremium: false,
                    createdAt: Date()
                )
                
                let authToken = AuthToken(
                    token: "social_token_\(provider.rawValue)",
                    refreshToken: "social_refresh_\(provider.rawValue)",
                    expiresAt: Date().addingTimeInterval(3600),
                    user: user
                )
                
                currentUser.setValue(user)
                isLoggedIn.setValue(true)
                return authToken
            },
            
            logout: {
                currentUser.setValue(nil)
                isLoggedIn.setValue(false)
            },
            
            refreshToken: { refreshToken in
                if refreshToken == "mock_refresh_token" {
                    let user = currentUser.value ?? User(
                        id: "12345",
                        email: "test@example.com",
                        name: "Test User",
                        isPremium: false,
                        createdAt: Date()
                    )
                    
                    let token = AuthToken(
                        token: "refreshed_jwt_token",
                        refreshToken: "new_refresh_token",
                        expiresAt: Date().addingTimeInterval(3600),
                        user: user
                    )
                    
                    return token
                } else {
                    throw AuthenticationError.tokenExpired
                }
            },
            
            signUp: { credentials, password in
                let user = User(
                    id: UUID().uuidString,
                    email: credentials.email,
                    name: credentials.email.components(separatedBy: "@").first ?? "New User",
                    isPremium: false,
                    createdAt: Date()
                )
                
                currentUser.setValue(user)
                isLoggedIn.setValue(true)
                return user
            },
            
            resetPassword: { email in
                // Mock password reset - just simulate success
            },
            
            getCurrentUser: {
                return currentUser.value
            },
            
            updateProfile: { user in
                currentUser.setValue(user)
                return user
            },
            
            deleteAccount: { password in
                currentUser.setValue(nil)
                isLoggedIn.setValue(false)
            },
            
            isTokenValid: {
                return isLoggedIn.value
            }
        )
    }
}
