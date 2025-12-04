//
//  AuthViewModel.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/02/25.
//

import SwiftUI
import UIKit
import Combine
// Apple Sign In removed for now

enum AuthProvider { case kakao }

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false {
        didSet {
            print("🔐 [AuthViewModel] isAuthenticated changed: \(oldValue) → \(isAuthenticated)")
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    
    // Check if user is already logged in (from UserDefaults or Keychain)
    init() {
        print("🔐 [AuthViewModel] init() called")
        checkAuthStatus()
        print("🔐 [AuthViewModel] init() completed - isAuthenticated: \(isAuthenticated)")
    }
    
    func checkAuthStatus() {
        // TODO: Implement actual auth check from secure storage
        // Note: Do NOT clear UserDefaults in DEBUG mode anymore - keep auth tokens persistent
        
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            userIdentifier = userId
            isAuthenticated = true
        }
    }
    
    // Test Login (for development/simulator)
    func loginWithTestAccount() {
        print("DEBUG: loginWithTestAccount started")
        isLoading = true
        errorMessage = nil
        
        let testUserId = "test_simulator_\(UUID().uuidString.prefix(8))"
        print("DEBUG: Generated testUserId: \(testUserId)")
        
        Task {
            do {
                print("DEBUG: Attempting login...")
                // Try to login with test provider - 명세서: providerId, name, email
                let tokenData = try await AuthAPIService.shared.login(
                    providerId: testUserId,
                    name: "테스트",
                    email: "test@simulator.com"
                )
                print("DEBUG: Login succeeded with accessToken: \(tokenData.accessToken.prefix(20))...")
                
                handleSuccessfulAuth(tokenData: tokenData)
                print("DEBUG: handleSuccessfulAuth completed")
                
            } catch {
                print("DEBUG: Login error: \(error)")
                handleAuthError(error)
            }
        }
    }
    
    // Kakao Login using backend exchange (명세서: POST /api/auth/login)
    func loginWithKakao() {
        print("🔐 [Kakao Login] Starting Kakao login flow...")
        isLoading = true
        errorMessage = nil
        let provider: KakaoAuthProvider = DefaultKakaoAuthProvider()
        
        Task {
            do {
                print("🔐 [Kakao Login] Getting access code from Kakao provider...")
                let code = try await provider.getAccessCode(presenting: UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                    .first)
                print("🔐 [Kakao Login] ✅ Access code obtained: \(code.prefix(20))...")
                
                // Get user info from Kakao
                print("🔐 [Kakao Login] Fetching Kakao user info...")
                let userInfo = try await provider.getUserInfo()
                print("🔐 [Kakao Login] ✅ User info obtained: name=\(userInfo.name ?? "nil"), email=\(userInfo.email ?? "nil")")
                
                // 명세서: login(providerId:name:email:) - code는 providerId
                print("🔐 [Kakao Login] Sending login request to backend...")
                let tokenData = try await AuthAPIService.shared.login(
                    providerId: code,
                    name: userInfo.name,
                    email: userInfo.email
                )
                print("🔐 [Kakao Login] ✅ Backend login successful! Token: \(tokenData.accessToken.prefix(20))...")
                
                await MainActor.run {
                    print("🔐 [Kakao Login] Handling successful auth...")
                    self.handleSuccessfulAuth(tokenData: tokenData)
                    self.isLoading = false
                }
            } catch {
                print("🔐 [Kakao Login] ❌ Error during login: \(error)")
                print("🔐 [Kakao Login] Error description: \(error.localizedDescription)")
                await MainActor.run {
                    self.handleAuthError(error)
                }
            }
        }
    }
    
    // Apple login is disabled in this build
    
    // Logout
    func logout() {
        isAuthenticated = false
        userIdentifier = nil
        userEmail = nil
        
        // Remove push token from backend
        Task {
            do {
                try await PetLogAPIService.shared.deletePushToken()
                print("✅ Push token removed from backend")
            } catch {
                print("⚠️ Failed to remove push token: \(error)")
            }
        }
        
        AuthAPIService.shared.logout()
    }
    
    // MARK: - Push Notification
    
    private func registerPushNotifications() async {
        await MainActor.run {
            NotificationManager.shared.requestNotificationPermission()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func handleSuccessfulAuth(tokenData: TokenData) {
        print("DEBUG: handleSuccessfulAuth called")
        print("DEBUG: accessToken: \(tokenData.accessToken.prefix(20))...")
        
        print("DEBUG: Setting isAuthenticated to true")
        isAuthenticated = true
        isLoading = false
        
        // Store userId (use email as identifier for now)
        UserDefaults.standard.set("user_\(UUID().uuidString.prefix(8))", forKey: "userId")
        
        print("DEBUG: isAuthenticated is now: \(isAuthenticated)")
        
        // Tokens are stored in AuthAPIService property
        print("✅ Login success - accessToken stored, isAuthenticated: \(isAuthenticated)")
        
        // Fetch and store groupId using /api/groups/my
        Task {
            do {
                let myGroups = try await PetLogAPIService.shared.getMyGroups()
                if let firstGroupId = myGroups.first {
                    UserDefaults.standard.set(firstGroupId, forKey: "groupId")
                    print("✅ GroupId stored: \(firstGroupId)")
                } else {
                    print("ℹ️ User has no groups yet")
                }
                
                // Register push notifications
                await registerPushNotifications()
            } catch {
                print("⚠️ Failed to fetch groupId: \(error)")
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        if let apiError = error as? APIError {
            errorMessage = apiError.errorDescription
        } else {
            errorMessage = "로그인 실패: \(error.localizedDescription)"
        }
        isLoading = false
        print("Auth error: \(error)")
    }
}
