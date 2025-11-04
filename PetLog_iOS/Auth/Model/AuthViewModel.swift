//
//  AuthViewModel.swift
//  PetLog_iOS
//
//  Created by Agent on 11/02/25.
//

import SwiftUI
import UIKit
import Combine
import AuthenticationServices

enum AuthProvider {
    case kakao
    case apple
}

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    
    // Check if user is already logged in (from UserDefaults or Keychain)
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        // TODO: Implement actual auth check from secure storage
        
        #if DEBUG
        // DEBUG: Uncomment to force logout on app start
        // UserDefaults.standard.removeObject(forKey: "userId")
        // UserDefaults.standard.removeObject(forKey: "authToken")
        // return
        #endif
        
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
                // Try to login with test provider
                let loginData = try await AuthAPIService.shared.login(
                    oauthProvider: "test",
                    oauthId: testUserId,
                    email: "test@simulator.com"
                )
                print("DEBUG: Login succeeded with userId: \(loginData.userId)")
                
                handleSuccessfulAuth(loginData: loginData)
                print("DEBUG: handleSuccessfulAuth completed")
                
            } catch APIError.serverError(let statusCode, _) where statusCode == 404 {
                print("DEBUG: User not found (404), registering...")
                // Register test user
                do {
                    let registerData = try await AuthAPIService.shared.register(
                        oauthProvider: "test",
                        oauthId: testUserId,
                        email: "test@simulator.com",
                        nickname: "시뮬레이터 테스트",
                        profileImageUrl: nil
                    )
                    print("DEBUG: Registration succeeded with userId: \(registerData.userId)")
                    
                    handleSuccessfulAuth(loginData: registerData)
                    print("DEBUG: handleSuccessfulAuth completed after registration")
                    
                } catch {
                    print("DEBUG: Registration error: \(error)")
                    handleAuthError(error)
                }
            } catch {
                print("DEBUG: Login error: \(error)")
                handleAuthError(error)
            }
        }
    }
    
    // Kakao Login using backend exchange (/api/auth/login/kakao)
    func loginWithKakao() {
        isLoading = true
        errorMessage = nil
        let provider: KakaoAuthProvider = DefaultKakaoAuthProvider()
        
        Task {
            do {
                let code = try await provider.getAccessCode(presenting: UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
                    .first)
                try await AuthAPIService.shared.kakaoLogin(accessCode: code)
                await MainActor.run {
                    // We don’t get user profile here; mark as authenticated
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.handleAuthError(error)
                }
            }
        }
    }
    
    // Apple Login Handler
    func handleAppleLoginCompletion(result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let appleUserId = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                let nickname = [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespaces)
                
                Task {
                    do {
                        // Try to login first
                        let loginData = try await AuthAPIService.shared.login(
                            oauthProvider: "apple",
                            oauthId: appleUserId,
                            email: email
                        )
                        
                        handleSuccessfulAuth(loginData: loginData)
                        
                    } catch APIError.serverError(let statusCode, _) where statusCode == 404 {
                        // User not found, need to register
                        do {
                            let registerData = try await AuthAPIService.shared.register(
                                oauthProvider: "apple",
                                oauthId: appleUserId,
                                email: email,
                                nickname: nickname.isEmpty ? nil : nickname,
                                profileImageUrl: nil
                            )
                            
                            handleSuccessfulAuth(loginData: registerData)
                            
                        } catch {
                            handleAuthError(error)
                        }
                    } catch {
                        handleAuthError(error)
                    }
                }
            }
            
        case .failure(let error):
            errorMessage = "Apple 로그인 실패: \(error.localizedDescription)"
            isLoading = false
            print("Apple Login Error: \(error)")
        }
    }
    
    // Logout
    func logout() {
        isAuthenticated = false
        userIdentifier = nil
        userEmail = nil
        AuthAPIService.shared.logout()
    }
    
    // MARK: - Private Helper Methods
    
    private func handleSuccessfulAuth(loginData: LoginData) {
        print("DEBUG: handleSuccessfulAuth called")
        print("DEBUG: Setting userIdentifier: \(loginData.userId)")
        userIdentifier = loginData.userId
        userEmail = loginData.email
        
        print("DEBUG: Setting isAuthenticated to true")
        isAuthenticated = true
        isLoading = false
        
        print("DEBUG: isAuthenticated is now: \(isAuthenticated)")
        
        // Store user info
        UserDefaults.standard.set(loginData.userId, forKey: "userId")
        if let email = loginData.email {
            UserDefaults.standard.set(email, forKey: "userEmail")
        }
        
        print("✅ Login success - User ID: \(loginData.userId), isAuthenticated: \(isAuthenticated)")
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
