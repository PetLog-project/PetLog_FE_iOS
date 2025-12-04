import Foundation
import UIKit
#if canImport(KakaoSDKAuth)
import KakaoSDKAuth
#endif
#if canImport(KakaoSDKUser)
import KakaoSDKUser
#endif

// MARK: - Kakao User Info Model
struct KakaoUserInfo {
    let name: String?
    let email: String?
}

protocol KakaoAuthProvider {
    func getAccessCode(presenting: UIViewController?) async throws -> String
    func getUserInfo() async throws -> KakaoUserInfo
}

enum KakaoAuthError: Error, LocalizedError { case notConfigured, cancelled
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "Kakao SDK가 설정되지 않았습니다. SETUP_GUIDE.md를 참고하세요."
        case .cancelled: return "로그인이 취소되었습니다."
        }
    }
}

struct DefaultKakaoAuthProvider: KakaoAuthProvider {
    func getUserInfo() async throws -> KakaoUserInfo {
        #if canImport(KakaoSDKUser)
        print("🔐 [KakaoAuthProvider] Fetching user info...")
        
        return try await withCheckedThrowingContinuation { cont in
            UserApi.shared.me { user, error in
                if let error = error {
                    print("🔐 [KakaoAuthProvider] ❌ Failed to fetch user info: \(error)")
                    cont.resume(throwing: error)
                    return
                }
                
                guard let user = user else {
                    print("🔐 [KakaoAuthProvider] ❌ No user info returned")
                    cont.resume(throwing: KakaoAuthError.notConfigured)
                    return
                }
                
                // Try to get name from kakao_account.name or profile.nickname
                let name = user.kakaoAccount?.name ?? user.kakaoAccount?.profile?.nickname
                let email = user.kakaoAccount?.email
                
                print("🔐 [KakaoAuthProvider] ✅ User info: name=\(name ?? "nil"), email=\(email ?? "nil")")
                
                let userInfo = KakaoUserInfo(
                    name: name,
                    email: email
                )
                cont.resume(returning: userInfo)
            }
        }
        #else
        return KakaoUserInfo(
            name: "시뮬레이터",
            email: "simulator@petlog.com"
        )
        #endif
    }
    
    func getAccessCode(presenting: UIViewController?) async throws -> String {
        #if canImport(KakaoSDKAuth) && canImport(KakaoSDKUser)
        print("🔐 [KakaoAuthProvider] Starting Kakao SDK login...")
        print("🔐 [KakaoAuthProvider] KakaoTalk available: \(UserApi.isKakaoTalkLoginAvailable())")
        
        return try await withCheckedThrowingContinuation { cont in
            // Prefer KakaoTalk app if available; otherwise fall back to Kakao Account (web)
            if UserApi.isKakaoTalkLoginAvailable() {
                print("🔐 [KakaoAuthProvider] Using KakaoTalk app login...")
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        print("🔐 [KakaoAuthProvider] ❌ KakaoTalk login error: \(error)")
                        cont.resume(throwing: error)
                        return
                    }
                    if let token = oauthToken?.accessToken {
                        print("🔐 [KakaoAuthProvider] ✅ KakaoTalk login success! Token: \(token.prefix(20))...")
                        cont.resume(returning: token)
                    } else {
                        print("🔐 [KakaoAuthProvider] ❌ KakaoTalk login cancelled")
                        cont.resume(throwing: KakaoAuthError.cancelled)
                    }
                }
            } else {
                print("🔐 [KakaoAuthProvider] Using Kakao Account (web) login...")
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        print("🔐 [KakaoAuthProvider] ❌ Kakao Account login error: \(error)")
                        cont.resume(throwing: error)
                        return
                    }
                    if let token = oauthToken?.accessToken {
                        print("🔐 [KakaoAuthProvider] ✅ Kakao Account login success! Token: \(token.prefix(20))...")
                        cont.resume(returning: token)
                    } else {
                        print("🔐 [KakaoAuthProvider] ❌ Kakao Account login cancelled")
                        cont.resume(throwing: KakaoAuthError.cancelled)
                    }
                }
            }
        }
        #else
        // Development fallback: return a pseudo code for simulator/no-SDK environments
        print("🔐 [KakaoAuthProvider] ⚠️ Kakao SDK not available - using simulated token")
        let simulatedToken = "simulated_kakao_code_\(UUID().uuidString.prefix(8))"
        print("🔐 [KakaoAuthProvider] Simulated token: \(simulatedToken)")
        return simulatedToken
        #endif
    }
}
