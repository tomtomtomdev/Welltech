import Foundation
import Testing
import ComposableArchitecture
@testable import AuthenticationKit
@testable import CoreDependencies

@Suite("AuthenticationClient Tests")
struct AuthenticationClientTests {
    @Test("AuthenticationClient mock should login with valid credentials")
    func mockLogin() async throws {
        let client = AuthenticationClient.mockValue
        
        let credentials = AuthCredentials(email: "test@example.com", password: "password")
        let token = try await client.login(credentials)
        
        #expect(token.user.email == "test@example.com")
        #expect(token.user.name == "Test User")
        #expect(token.user.isPremium == false)
        #expect(token.isValid == true)
    }
    
    @Test("AuthenticationClient mock should fail with invalid credentials")
    func mockLoginFailure() async throws {
        let client = AuthenticationClient.mockValue
        
        let credentials = AuthCredentials(email: "invalid@example.com", password: "wrong")
        
        do {
            _ = try await client.login(credentials)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is AuthenticationError)
        }
    }
    
    @Test("AuthenticationClient mock should handle social login")
    func mockSocialLogin() async throws {
        let client = AuthenticationClient.mockValue
        
        let token = try await client.loginWithSocial(.google, "mock_token")
        
        #expect(token.user.email == "user@google.com")
        #expect(token.user.name == "Google User")
        #expect(token.isValid == true)
    }
    
    @Test("AuthenticationClient mock should handle logout")
    func mockLogout() async throws {
        let client = AuthenticationClient.mockValue
        
        // Login first
        let credentials = AuthCredentials(email: "test@example.com", password: "password")
        let token = try await client.login(credentials)
        #expect(token.user.email == "test@example.com")
        
        // Logout
        await client.logout()
        
        // Current user should be nil after logout
        let currentUser = await client.getCurrentUser()
        #expect(currentUser == nil)
    }
    
    @Test("AuthenticationClient mock should handle sign up")
    func mockSignUp() async throws {
        let client = AuthenticationClient.mockValue
        
        let credentials = AuthCredentials(email: "newuser@example.com", password: "password123")
        let user = try await client.signUp(credentials, "password123")
        
        #expect(user.email == "newuser@example.com")
        #expect(user.name == "newuser")
        #expect(user.isPremium == false)
    }
    
    @Test("AuthenticationClient mock should handle password reset")
    func mockPasswordReset() async throws {
        let client = AuthenticationClient.mockValue
        
        // Should not throw for valid email
        try await client.resetPassword("test@example.com")
    }
    
    @Test("AuthenticationClient mock should handle profile update")
    func mockProfileUpdate() async throws {
        let client = AuthenticationClient.mockValue
        
        // Login first
        let credentials = AuthCredentials(email: "test@example.com", password: "password")
        _ = try await client.login(credentials)
        
        var user = try await client.getCurrentUser()!
        user.name = "Updated Name"
        user.isPremium = true
        
        let updatedUser = try await client.updateProfile(user)
        
        #expect(updatedUser.name == "Updated Name")
        #expect(updatedUser.isPremium == true)
        #expect(updatedUser.email == "test@example.com")
    }
    
    @Test("AuthenticationClient mock should handle account deletion")
    func mockAccountDeletion() async throws {
        let client = AuthenticationClient.mockValue
        
        // Login first
        let credentials = AuthCredentials(email: "test@example.com", password: "password")
        _ = try await client.login(credentials)
        
        // Delete account
        try await client.deleteAccount("password")
        
        // Current user should be nil after deletion
        let currentUser = await client.getCurrentUser()
        #expect(currentUser == nil)
    }
    
    @Test("AuthenticationClient mock should handle token validation")
    func mockTokenValidation() async throws {
        let client = AuthenticationClient.mockValue
        
        // Initially not logged in
        #expect(await client.isTokenValid() == false)
        
        // Login first
        let credentials = AuthCredentials(email: "test@example.com", password: "password")
        _ = try await client.login(credentials)
        
        // Now should be valid
        #expect(await client.isTokenValid() == true)
    }
}

@Suite("Authentication Models Tests")
struct AuthenticationModelTests {
    @Test("User model should initialize correctly")
    func userModel() {
        let user = User(
            id: "123",
            email: "test@example.com",
            name: "Test User",
            avatarURL: URL(string: "https://example.com/avatar.jpg"),
            isPremium: true,
            createdAt: Date()
        )
        
        #expect(user.id == "123")
        #expect(user.email == "test@example.com")
        #expect(user.name == "Test User")
        #expect(user.avatarURL?.absoluteString == "https://example.com/avatar.jpg")
        #expect(user.isPremium == true)
    }
    
    @Test("AuthToken should validate expiration")
    func authTokenValidation() {
        let expiredToken = AuthToken(
            token: "expired_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            user: User(id: "123", email: "test@example.com", name: "Test")
        )
        
        let validToken = AuthToken(
            token: "valid_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour in future
            user: User(id: "123", email: "test@example.com", name: "Test")
        )
        
        #expect(expiredToken.isValid == false)
        #expect(validToken.isValid == true)
    }
    
    @Test("AuthenticationError should provide correct descriptions")
    func authenticationErrorDescriptions() {
        #expect(AuthenticationError.invalidCredentials.localizedDescription == "Invalid email or password")
        #expect(AuthenticationError.tokenExpired.localizedDescription == "Authentication token has expired")
        #expect(AuthenticationError.accountLocked.localizedDescription == "Account has been locked")
        #expect(AuthenticationError.invalidEmail.localizedDescription == "Invalid email address")
        #expect(AuthenticationError.weakPassword.localizedDescription == "Password is too weak")
    }
    
    @Test("AuthProvider should display correct names")
    func authProviderDisplayNames() {
        #expect(AuthProvider.email.displayName == "Email")
        #expect(AuthProvider.apple.displayName == "Apple")
        #expect(AuthProvider.google.displayName == "Google")
        #expect(AuthProvider.facebook.displayName == "Facebook")
        #expect(AuthProvider.twitter.displayName == "Twitter")
    }
}
