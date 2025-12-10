import XCTest
import ComposableArchitecture
import CoreDependencies

@testable import Welltech

final class WelltechTests: XCTestCase {
    
    func testAnalyticsEventCreation() {
        // Test analytics events using CoreDependencies extensions
        let loginEvent = AnalyticsEvent.login(method: "email")
        XCTAssertEqual(loginEvent.name, "login_completed")
        XCTAssertEqual(loginEvent.parameters["method"], .string("email"))
        
        let logoutEvent = AnalyticsEvent.logout()
        XCTAssertEqual(logoutEvent.name, "logout_completed")
        XCTAssertTrue(logoutEvent.parameters.isEmpty)
        
        let appLaunchedEvent = AnalyticsEvent.appLaunched
        XCTAssertEqual(appLaunchedEvent.name, "app_launched")
        XCTAssertTrue(appLaunchedEvent.parameters.isEmpty)
    }
    
    func testUserPropertyCreation() {
        // Test user properties using CoreDependencies extensions
        let onboardingProperty = UserProperty.hasCompletedOnboarding
        XCTAssertEqual(onboardingProperty.key, "has_completed_onboarding")
        XCTAssertEqual(onboardingProperty.value, .bool(false)) // CoreDependencies default
    }
    
    func testAppFeatureState() {
        // Test that AppFeature.State is correct
        let initialState = AppFeature.State()
        XCTAssertFalse(initialState.isLoggingIn)
        XCTAssertFalse(initialState.isLoggedIn)
        XCTAssertNil(initialState.userName)
        
        let loggedInState = AppFeature.State(
            isLoggingIn: false,
            isLoggedIn: true,
            userName: "Test User"
        )
        XCTAssertFalse(loggedInState.isLoggingIn)
        XCTAssertTrue(loggedInState.isLoggedIn)
        XCTAssertEqual(loggedInState.userName, "Test User")
    }
    
    func testUserModel() {
        // Test User model
        let user = User(id: "123", name: "Test User", email: "test@example.com")
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.name, "Test User")
        XCTAssertEqual(user.email, "test@example.com")
    }
}
