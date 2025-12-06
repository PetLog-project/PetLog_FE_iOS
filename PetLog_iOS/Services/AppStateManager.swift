//
//  AppStateManager.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 12/04/25.
//

import Foundation

/// 앱 전체 상태를 관리하고 콜백을 제공하는 싱글톤
class AppStateManager: NSObject {
    static let shared = AppStateManager()
    
    // Callbacks for WebView bridge events
    var onWebViewClose: (() -> Void)?
    var onOnboardingFinished: (() -> Void)?
    var onLogout: (() -> Void)?
    var onDeleteAccount: (() -> Void)?
    var onLeaveGroup: (() -> Void)?
    
    // MARK: - Public Methods for Bridge Events
    
    /// WebView에서 온보딩 완료 이벤트를 처리합니다
    func handleOnboardingFinished() {
        print("🏠 [AppStateManager.handleOnboardingFinished] Calling onOnboardingFinished callback")
        
        // Fetch groupId from API after onboarding
        Task {
            do {
                print("🔄 [AppStateManager] Fetching group list after onboarding...")
                let myGroups = try await PetLogAPIService.shared.getMyGroups()
                if let firstGroupId = myGroups.first {
                    UserDefaults.standard.set(firstGroupId, forKey: "groupId")
                    print("✅ [AppStateManager] GroupId auto-selected: \(firstGroupId)")
                    
                    // 🐾 Create initial poop log to prevent 500 error
                    print("🔄 [AppStateManager] Creating initial poop log...")
                    do {
                        _ = try await PetLogAPIService.shared.createPoopLog(
                            groupId: firstGroupId,
                            checkerName: "시스템",
                            remindNotificationAt: nil,
                            memo: nil
                        )
                        print("✅ [AppStateManager] Initial poop log created")
                    } catch {
                        print("⚠️ [AppStateManager] Failed to create initial poop log (this is OK): \(error)")
                    }
                } else {
                    print("⚠️ [AppStateManager] No groups found after onboarding")
                }
            } catch {
                print("❌ [AppStateManager] Failed to fetch groups: \(error)")
            }
            
            // Call the callback after fetching groupId
            await MainActor.run {
                onOnboardingFinished?()
            }
        }
    }
    
    /// WebView 닫기 이벤트를 처리합니다
    func handleWebViewClose() {
        print("📱 [AppStateManager.handleWebViewClose] Calling onWebViewClose callback")
        onWebViewClose?()
    }
    
    /// 로그아웃 이벤트를 처리합니다
    func handleLogout() {
        print("👋 [AppStateManager.handleLogout] Calling onLogout callback")
        onLogout?()
    }
    
    /// 계정 삭제 이벤트를 처리합니다
    func handleDeleteAccount() {
        print("🗑️ [AppStateManager.handleDeleteAccount] Calling onDeleteAccount callback")
        onDeleteAccount?()
    }
    
    /// 그룹 나가기 이벤트를 처리합니다
    func handleLeaveGroup() {
        print("👋 [AppStateManager.handleLeaveGroup] Calling onLeaveGroup callback")
        onLeaveGroup?()
    }
    
    private override init() {
        super.init()
        setupWebViewBridgeDelegate()
    }
    
    /// WebView Bridge delegate를 설정합니다
    private func setupWebViewBridgeDelegate() {
        print("🔗 [AppStateManager] Setting up WebView Bridge delegate")
        
        let handler = AppWebViewBridgeHandler()
        WebViewBridgeService.shared.delegate = handler
        print("✅ [AppStateManager] WebView Bridge delegate set successfully")
    }
}

// MARK: - Bridge Handler
final class AppWebViewBridgeHandler: NSObject, WebViewBridgeDelegate {
    
    func webViewBridgeDidRequestClose(_ bridge: WebViewBridgeService) {
        print("📱 [AppWebViewBridgeHandler.webViewBridgeDidRequestClose]")
        AppStateManager.shared.handleWebViewClose()
    }
    
    func webViewBridgeDidFinishGroupSetup(_ bridge: WebViewBridgeService) {
        print("🏠 [AppWebViewBridgeHandler.webViewBridgeDidFinishGroupSetup]")
        AppStateManager.shared.handleOnboardingFinished()
    }
    
    func webViewBridgeDidLogout(_ bridge: WebViewBridgeService) {
        print("👋 [AppWebViewBridgeHandler.webViewBridgeDidLogout]")
        AppStateManager.shared.handleLogout()
    }
    
    func webViewBridgeDidDeleteAccount(_ bridge: WebViewBridgeService) {
        print("🗑️ [AppWebViewBridgeHandler.webViewBridgeDidDeleteAccount]")
        AppStateManager.shared.handleDeleteAccount()
    }
    
    func webViewBridgeDidLeaveGroup(_ bridge: WebViewBridgeService) {
        print("👋 [AppWebViewBridgeHandler.webViewBridgeDidLeaveGroup]")
        AppStateManager.shared.handleLeaveGroup()
    }
}
