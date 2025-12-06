//
//  WebViewContainer.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 12/04/25.
//

import SwiftUI
import WebKit

struct WebViewContainer: View {
    let url: URL
    let nativeRoute: String // "/diary" | "/setting" | "/start"
    @State private var webView: WKWebView?
    
    var body: some View {
        WebViewRepresentable(
            url: url,
            nativeRoute: nativeRoute,
            webView: $webView,
            onWebViewCreated: { webView in
                setupWebView(webView)
            }
        )
    }
    
    private func setupWebView(_ webView: WKWebView) {
        // Message handler는 이미 makeUIView에서 등록되었으므로 여기서는 스킵
    }
}

// MARK: - WebViewRepresentable

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    let nativeRoute: String
    @Binding var webView: WKWebView?
    var onWebViewCreated: ((WKWebView) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaPlaybackRequiresUserAction = false
        
        // Script Message Handler 설정
        let contentController = configuration.userContentController
        
        // Bridge handler
        contentController.removeScriptMessageHandler(forName: "bridge")
        contentController.add(WebViewBridgeService.shared, name: "bridge")
        
        // Console log handler - capture JavaScript console.log
        let consoleLogScript = WKUserScript(
            source: """
            (function() {
                const originalLog = console.log;
                console.log = function(...args) {
                    window.webkit.messageHandlers.consoleLog.postMessage(args.map(String).join(' '));
                    originalLog.apply(console, args);
                };
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(consoleLogScript)
        contentController.add(context.coordinator, name: "consoleLog")
        
        // window.__NATIVE_INIT__ 주입 (페이지 로드 전)
        if let accessToken = AuthAPIService.shared.getAccessToken() {
            let initDict: [String: Any] = [
                "nativeRoute": nativeRoute,
                "accessToken": accessToken,
                "isNative": true
            ]
            if let data = try? JSONSerialization.data(withJSONObject: initDict, options: []),
               let json = String(data: data, encoding: .utf8) {
                let script = WKUserScript(
                    source: "window.__NATIVE_INIT__ = \(json);",
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                )
                contentController.removeAllUserScripts()
                contentController.addUserScript(script)
            }
        }
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Disable auto zoom on input focus
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        
        // 현재 WebView 참조 저장
        WebViewBridgeService.shared.setCurrentWebView(webView)
        
        self.webView = webView
        onWebViewCreated?(webView)
        
        var request = URLRequest(url: url)
        // Authorization 헤더에 토큰 추가 (Swift -> React 요청 시)
        WebViewBridgeService.shared.addAuthorizationHeader(to: &request)
        
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 필요한 업데이트 로직
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewRepresentable
        
        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }
        
        // Handle JavaScript console.log messages
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog", let messageBody = message.body as? String {
                print("🔵 [JS Console] \(messageBody)")
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ WebView 로드 완료")
            
            // Check if nativeRoute is set correctly in JavaScript
            let checkScript = """
            (function() {
                const nativeStore = window.useNative?.getState?.();
                console.log('[iOS Debug] window.__NATIVE_INIT__:', window.__NATIVE_INIT__);
                console.log('[iOS Debug] useNative state:', nativeStore);
                console.log('[iOS Debug] current path:', window.location.pathname);
                return JSON.stringify({
                    nativeInit: window.__NATIVE_INIT__,
                    nativeRoute: nativeStore?.nativeRoute,
                    currentPath: window.location.pathname
                });
            })();
            """
            
            webView.evaluateJavaScript(checkScript) { result, error in
                if let error = error {
                    print("❌ [WebView Debug] Failed to check nativeRoute: \(error.localizedDescription)")
                } else if let jsonString = result as? String {
                    print("🔍 [WebView Debug] State: \(jsonString)")
                }
            }
            
            // Add debug interceptor for BackButton clicks
            let interceptScript = """
            (function() {
                console.log('[iOS Debug] Interceptor script starting...');
                
                // Intercept ALL events
                ['click', 'touchstart', 'touchend', 'mousedown', 'mouseup'].forEach(eventType => {
                    document.addEventListener(eventType, function(e) {
                        console.log('[iOS Debug] Event detected:', eventType, 'on:', e.target.tagName);
                        if (e.target.textContent) {
                            console.log('[iOS Debug] Text content:', e.target.textContent.trim().substring(0, 50));
                        }
                    }, true);
                });
                
                // Monitor window.webkit.messageHandlers.bridge calls
                if (window.webkit?.messageHandlers?.bridge) {
                    const originalPostMessage = window.webkit.messageHandlers.bridge.postMessage.bind(window.webkit.messageHandlers.bridge);
                    window.webkit.messageHandlers.bridge.postMessage = function(message) {
                        console.log('[iOS Debug] Bridge message:', message);
                        return originalPostMessage(message);
                    };
                    console.log('[iOS Debug] Bridge interceptor installed');
                } else {
                    console.log('[iOS Debug] Bridge not available!');
                }
                
                console.log('[iOS Debug] All interceptors ready');
            })();
            """
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                webView.evaluateJavaScript(interceptScript) { _, error in
                    if let error = error {
                        print("❌ [WebView Debug] Failed to add interceptor: \(error.localizedDescription)")
                    } else {
                        print("✅ [WebView Debug] Event interceptor added")
                    }
                }
            }
            
            // Force fix the nativeRoute in Zustand store (workaround for frontend bug)
            let fixStoreScript = """
            (function() {
                // Wait for useNative store to be available
                let attempts = 0;
                const interval = setInterval(() => {
                    attempts++;
                    if (window.useNative?.setState) {
                        const initData = window.__NATIVE_INIT__;
                        if (initData?.nativeRoute) {
                            window.useNative.setState({ nativeRoute: initData.nativeRoute });
                            console.log('[iOS Fix] nativeRoute set to:', initData.nativeRoute);
                            clearInterval(interval);
                        }
                    }
                    if (attempts > 20) {
                        console.log('[iOS Fix] Failed to set nativeRoute after 20 attempts');
                        clearInterval(interval);
                    }
                }, 100);
            })();
            """
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                webView.evaluateJavaScript(fixStoreScript) { _, error in
                    if let error = error {
                        print("❌ [WebView Fix] Failed to fix nativeRoute: \(error.localizedDescription)")
                    } else {
                        print("✅ [WebView Fix] nativeRoute fix script executed")
                    }
                }
            }
            
            // Prevent auto zoom on input focus by setting viewport
            let disableZoomScript = """
            (function() {
                // Find existing viewport meta tag
                let viewport = document.querySelector('meta[name="viewport"]');
                if (viewport) {
                    // Update existing viewport to disable zoom
                    viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
                } else {
                    // Create new viewport meta tag
                    viewport = document.createElement('meta');
                    viewport.name = 'viewport';
                    viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                    document.getElementsByTagName('head')[0].appendChild(viewport);
                }
                console.log('[iOS] Auto zoom disabled');
            })();
            """
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                webView.evaluateJavaScript(disableZoomScript) { _, error in
                    if let error = error {
                        print("❌ [WebView] Failed to disable auto zoom: \(error.localizedDescription)")
                    } else {
                        print("✅ [WebView] Auto zoom disabled")
                    }
                }
            }
            
            // Dismiss keyboard when tapping outside input fields
            let dismissKeyboardScript = """
            (function() {
                document.addEventListener('touchstart', function(e) {
                    // Check if the tap target is not an input or textarea
                    if (e.target.tagName !== 'INPUT' && e.target.tagName !== 'TEXTAREA') {
                        // Find the currently focused element
                        const focused = document.activeElement;
                        if (focused && (focused.tagName === 'INPUT' || focused.tagName === 'TEXTAREA')) {
                            focused.blur();
                            console.log('[iOS] Keyboard dismissed - tapped outside input');
                        }
                    }
                }, false);
                console.log('[iOS] Tap outside input to dismiss keyboard enabled');
            })();
            """
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                webView.evaluateJavaScript(dismissKeyboardScript) { _, error in
                    if let error = error {
                        print("❌ [WebView] Failed to add keyboard dismiss handler: \(error.localizedDescription)")
                    } else {
                        print("✅ [WebView] Keyboard dismiss handler added")
                    }
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ WebView 로드 실패: \(error.localizedDescription)")
        }
    }
}

#Preview {
    WebViewContainer(url: URL(string: "\(APIConfig.webViewBaseURL)/start")!, nativeRoute: "/start")
}
