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
