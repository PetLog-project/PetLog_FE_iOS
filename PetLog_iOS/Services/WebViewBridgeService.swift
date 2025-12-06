//
//  WebViewBridgeService.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 12/04/25.
//

import Foundation
import WebKit

/// WKWebView와 네이티브 앱 간의 통신을 관리하는 서비스
class WebViewBridgeService: NSObject, WKScriptMessageHandler {
    static let shared = WebViewBridgeService()
    
    var delegate: WebViewBridgeDelegate?
    private weak var currentWebView: WKWebView?
    
    private override init() {
        super.init()
    }
    
    // MARK: - WebView 초기화
    
    /// WebView 로드 전에 Native 초기화 데이터를 주입합니다
    /// 반드시 페이지 로드 전에 호출해야 합니다
    func injectNativeInit(to webView: WKWebView, nativeRoute: String) {
        guard let accessToken = AuthAPIService.shared.getAccessToken() else {
            print("⚠️ No access token for native init")
            return
        }
        
        // JSON 형식으로 초기화 데이터 구성
        let initData: [String: Any] = [
            "nativeRoute": nativeRoute,
            "accessToken": accessToken
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: initData, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to serialize init data")
            return
        }
        
        let javaScript = """
        window.__NATIVE_INIT__ = \(jsonString);
        console.log('✅ Native init injected:', window.__NATIVE_INIT__);
        """
        
        webView.evaluateJavaScript(javaScript) { result, error in
            if let error = error {
                print("❌ Failed to inject native init: \(error.localizedDescription)")
            } else {
                print("✅ Native init injected successfully")
            }
        }
    }
    
    /// WebView 참조를 저장합니다
    func setCurrentWebView(_ webView: WKWebView) {
        self.currentWebView = webView
    }
    
    /// HTTP 요청 헤더에 액세스 토큰을 추가합니다
    func addAuthorizationHeader(to request: inout URLRequest) {
        guard let accessToken = AuthAPIService.shared.getAccessToken() else {
            return
        }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
    
    // MARK: - WKScriptMessageHandler
    
    /// "bridge" 메시지 핸들러로부터 메시지를 수신합니다
    func userContentController(_ userContentController: WKUserContentController,
                             didReceive message: WKScriptMessage) {
        guard message.name == "bridge" else { return }
        
        if let body = message.body as? [String: Any] {
            handleBridgeMessage(body)
        }
    }
    
    // MARK: - Message Handler
    
    private func handleBridgeMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else {
            print("⚠️ Missing message type")
            return
        }
        
        print("📨 [Bridge] Received message type: \(type)")
        
        switch type.uppercased() {
        case "CLOSE_WEBVIEW":
            handleCloseWebView()
        case "ONBOARDING_FINISHED":
            handleOnboardingFinished(message)
        case "REQUEST_TOKEN_REFRESH":
            // 🔑 토큰 재발급은 로그인 시에만 수행 (중복 방지)
            print("⚠️ REQUEST_TOKEN_REFRESH: iOS에서 처리하지 않음 (로그인 시 이미 토큰 재발급됨)")
        case "LOGOUT":
            handleLogout()
        case "DELETE_ACCOOUNT":  // Note: Frontend has typo with 3 O's
            handleDeleteAccount()
        case "LEAVE_GROUP":
            handleLeaveGroup()
        default:
            print("⚠️ Unknown message type: \(type)")
        }
    }
    
    private func handleCloseWebView() {
        print("📱 CLOSE_WEBVIEW: WebView를 닫고 이전 화면으로 돌아감")
        Task { @MainActor in
            delegate?.webViewBridgeDidRequestClose(self)
        }
    }
    
    private func handleOnboardingFinished(_ message: [String: Any]? = nil) {
        print("✅ ONBOARDING_FINISHED: 그룹 설정 완료, 홈 화면으로 이동")
        
        // Extract groupId from message if provided
        if let message = message, let groupId = message["groupId"] {
            let groupIdString = "\(groupId)"
            UserDefaults.standard.set(groupIdString, forKey: "groupId")
            print("   ✅ GroupId saved from WebView: \(groupIdString)")
        } else {
            print("   ⚠️ No groupId in ONBOARDING_FINISHED message, will fetch from API")
        }
        
        print("   [DEBUG] WebViewBridgeService.delegate is nil: \(delegate == nil)")
        Task { @MainActor in
            if let delegate = self.delegate {
                print("   [DEBUG] Calling delegate.webViewBridgeDidFinishGroupSetup")
                delegate.webViewBridgeDidFinishGroupSetup(self)
            } else {
                print("   [DEBUG] ❌ WebViewBridgeService.delegate is nil in MainActor")
            }
        }
    }
    
    private func handleTokenRefresh() {
        print("🔄 REQUEST_TOKEN_REFRESH: 토큰 리프레시 요청")
        Task {
            do {
                let newToken = try await AuthAPIService.shared.refreshAccessToken()
                // onNativeTokenUpdate 함수로 새 토큰을 JavaScript에 전달
                sendTokenUpdateToJS(newToken)
            } catch {
                print("❌ Token refresh failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleLogout() {
        print("👋 LOGOUT: 로그아웃 처리")
        AuthAPIService.shared.logout()
        Task { @MainActor in
            delegate?.webViewBridgeDidLogout(self)
        }
    }
    
    private func handleDeleteAccount() {
        print("🗑️ DELETE_ACCOUNT: 계정 삭제 처리")
        AuthAPIService.shared.logout()
        Task { @MainActor in
            delegate?.webViewBridgeDidDeleteAccount(self)
        }
    }
    
    private func handleLeaveGroup() {
        print("👋 LEAVE_GROUP: 그룹 나가기, /start로 이동")
        // Clear groupId from UserDefaults
        UserDefaults.standard.removeObject(forKey: "groupId")
        Task { @MainActor in
            delegate?.webViewBridgeDidLeaveGroup(self)
        }
    }
    
    // MARK: - Native -> JS 통신
    
    /// 토큰 업데이트를 JavaScript로 전달합니다
    private func sendTokenUpdateToJS(_ token: String) {
        guard let webView = currentWebView else { return }
        let escapedToken = token.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let js = "window.onNativeTokenUpdate('\(escapedToken)');"
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("❌ Failed to send token update: \(error.localizedDescription)")
            } else {
                print("✅ Token update sent successfully")
            }
        }
    }
}

// MARK: - Delegate Protocol

protocol WebViewBridgeDelegate: AnyObject {
    /// WebView 닫기 사싱
    func webViewBridgeDidRequestClose(_ bridge: WebViewBridgeService)
    
    /// 그룹 설정 완료 싱
    func webViewBridgeDidFinishGroupSetup(_ bridge: WebViewBridgeService)
    
    /// 로그아웃 싱
    func webViewBridgeDidLogout(_ bridge: WebViewBridgeService)
    
    /// 계정 삭제 싱
    func webViewBridgeDidDeleteAccount(_ bridge: WebViewBridgeService)
    
    /// 그룹 나가기 싱
    func webViewBridgeDidLeaveGroup(_ bridge: WebViewBridgeService)
}

// MARK: - AuthAPIService Extension

extension AuthAPIService {
    /// 저장된 액세스 토큰을 반환하는 메서드
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: "accessToken")
    }
}
