//
//  WebViewRouterService.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 12/04/25.
//

import Foundation
import WebKit

/// WKWebView와 네이티브 간의 라우팅을 관리하는 서비스
class WebViewRouterService {
    static let shared = WebViewRouterService()
    
    private var currentWebView: WKWebView?
    
    private init() {}
    
    // MARK: - Web 라우팅 메서드
    
    /// React 앱의 특정 경로로 라우팅합니다.
    /// - Parameters:
    ///   - path: 라우팅할 경로 (예: "/start", "/diary", "/setting")
    func routeToWebPage(_ path: String) {
        guard let webView = currentWebView else {
            print("⚠️ No active WebView")
            return
        }
        
        // WebView는 프론트엔드 URL을 사용
        let baseURL = APIConfig.webViewBaseURL
        let fullPath = path.hasPrefix("/") ? path : "/" + path
        let targetURL = baseURL + fullPath
        
        print("📱 Routing to: \(targetURL)")
        
        if let url = URL(string: targetURL) {
            var request = URLRequest(url: url)
            // 라우팅 시마다 액세스 토큰 헤더 추가
            WebViewBridgeService.shared.addAuthorizationHeader(to: &request)
            webView.load(request)
        }
    }
    
    /// WebView를 닫습니다 (CLOSE_WEBVIEW 메시지와 동일 동작)
    func closeWebView() {
        WebViewBridgeService.shared.delegate?.webViewBridgeDidRequestClose(WebViewBridgeService.shared)
    }
    
    /// 그룹 설정 완료 처리 (ONBOARDING_FINISHED 메시지와 동일 동작)
    func finishGroupSetup() {
        WebViewBridgeService.shared.delegate?.webViewBridgeDidFinishGroupSetup(WebViewBridgeService.shared)
    }
    
    // MARK: - WebView 참조 관리
    
    func setWebView(_ webView: WKWebView) {
        self.currentWebView = webView
        WebViewBridgeService.shared.setCurrentWebView(webView)
    }
}
