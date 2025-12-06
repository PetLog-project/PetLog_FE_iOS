//
//  PetLog_iOSApp.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/11/25.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct PetLog_iOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // AppStateManager 초기화 (자동으로 WebView Bridge delegate 설정)
        _ = AppStateManager.shared
        print("🔗 [PetLog_iOSApp] AppStateManager initialized")
        
        // 개발 중: 테스트 토큰 사용하려면 아래 주석 제거
#if DEBUG
        let useTestToken = false  // true로 변경하면 테스트 토큰 사용
        
        if useTestToken {
            // 테스트 토큰으로 직접 로그인 (그룹 15에 이미 멤버임)
            UserDefaults.standard.set("{{TEST_ACCESS_TOKEN}}", forKey: "accessToken")
            UserDefaults.standard.set("test-group-id", forKey: "groupId")
            UserDefaults.standard.set(true, forKey: "hasShownInitialWebPage")
            print("✅ [DEBUG] Test token set - ready to test")
        }
        // 🔑 Note: 로그인 유지를 위해 토큰을 삭제하지 않음
#endif
        
        // Kakao SDK 초기화
        var appKey: String? = Bundle.main.object(forInfoDictionaryKey: "KAKAO_NATIVE_APP_KEY") as? String
        // If xcconfig substitution failed or key is absent, try to derive from URL scheme 'kakao{appKey}'
        if appKey == nil || appKey?.contains("${") == true || appKey?.isEmpty == true {
            if let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
                let schemes = urlTypes.compactMap { $0["CFBundleURLSchemes"] as? [String] }.flatMap { $0 }
                if let kakaoScheme = schemes.first(where: { $0.hasPrefix("kakao") }) {
                    appKey = String(kakaoScheme.dropFirst("kakao".count))
                }
            }
        }
        if let key = appKey, key.isEmpty == false, key.contains("${") == false {
            KakaoSDK.initSDK(appKey: key)
        } else {
            print("[Kakao] Failed to initialize: missing KAKAO_NATIVE_APP_KEY or kakao scheme in Info.plist")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if authViewModel.isAuthenticated {
                    ContentView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                        .onAppear {
                            print("📱 [PetLog_iOSApp] Showing ContentView (authenticated)")
                        }
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                        .onAppear {
                            print("📱 [PetLog_iOSApp] Showing LoginView (not authenticated)")
                        }
                }
            }
            .onOpenURL { url in
                if AuthApi.isKakaoTalkLoginUrl(url) {
                    _ = AuthController.handleOpenUrl(url: url)
                }
            }
        }
    }
}
