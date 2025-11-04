import Foundation
import UIKit

protocol KakaoAuthProvider {
    func getAccessCode(presenting: UIViewController?) async throws -> String
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
    func getAccessCode(presenting: UIViewController?) async throws -> String {
        #if canImport(KakaoSDKAuth)
        return try await withCheckedThrowingContinuation { cont in
            // Prefer KakaoTalk login if available, else KakaoAccount
            if let AuthApiClass = NSClassFromString("KakaoSDKAuth.AuthApi") as? NSObject.Type,
               AuthApiClass.responds(to: NSSelectorFromString("hasToken")) {
                // Fallback: Use Account login for simplicity in this scaffold
            }
            // Since exact SDK calls are not available without importing the frameworks here,
            // forward a placeholder error to guide setup.
            cont.resume(throwing: KakaoAuthError.notConfigured)
        }
        #else
        // Development fallback: return a pseudo code
        return "simulated_kakao_code_\(UUID().uuidString.prefix(8))"
        #endif
    }
}

