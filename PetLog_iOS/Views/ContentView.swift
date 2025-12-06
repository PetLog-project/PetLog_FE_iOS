//
//  ContentView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/11/25.
//

import SwiftUI

let showAPITestView = false

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var homeViewModel = PetDashboardViewModel()
    @State private var selectedTab = 1
    @State private var showSharePopup = false
    @State private var showTestGroupPopup = false
    @State private var showNotesView = false
    @State private var showEditPopup = false
    @State private var showFeedingModal = false
    @State private var showWateringModal = false
    @State private var showPoopModal = false
    @State private var showJoinGroupView = false
    
    // WebView state (keeps header/footer intact)
    @State private var showWebPage = false
    @State private var webURL: URL? = nil
    @State private var nativeRoute: String = "/start" // "/diary" | "/setting" | "/start"
    @State private var hasShownInitialWebPage = false
    @State private var showSettingsWebView = false
    
    // Dimmed overlay for destructive actions from webview
    @State private var showDestructiveActionOverlay = false
    
    // Profile edit data
    @State private var profileName: String = ""
    @State private var profileAge: String = ""
    @State private var profileWeight: String = ""
    @State private var profileGender: Gender? = nil
    @State private var profileImage: UIImage? = nil
    
    // Activity data for modals
    @State private var feedingMemo: String = ""
    @State private var wateringMemo: String = ""
    @State private var poopMemo: String = ""
    @State private var poopCount: Int = 0
    
    var body: some View {
        Group {
            if showAPITestView {
                APITestView()
            } else {
                mainAppView
            }
        }
    }
    
    private var mainAppView: some View {
        ZStack {
            Theme.Colors.background
            
            // /start WebView만 전체 화면 표시
            // /diary, /setting은 헤더/푸터 유지
            if showWebPage && nativeRoute == "/start", let url = webURL {
                WebViewContainer(url: url, nativeRoute: nativeRoute)
                    .transition(.move(edge: .trailing))
                    .zIndex(100)
            } else {
                // Normal layout with header/footer for /diary and /settings
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Header - 60px height
                        FigmaAppHeader(
                            showSharePopup: $showSharePopup,
                            showNotesView: $showNotesView,
                            showJoinGroupView: $showJoinGroupView,
                            isWhiteBackground: showNotesView || selectedTab != 1 || showWebPage,
                            onSettingsTap: { openWebPage(route: "/setting") }
                        )
                        .frame(height: 60)
                        .animation(.easeInOut(duration: 0.25), value: showNotesView)
                        .animation(.easeInOut(duration: 0.25), value: selectedTab)
                        
                        // Main content - Tab-based view switching or NotesView
                        // Calculate available height: total - header - footer
                        ZStack {
                            if showNotesView {
                                NotesView(isPresented: $showNotesView)
                                    .transition(.opacity)
                                    .zIndex(2)
                            } else {
                                // 현재 탭 뷰 표시
                                ZStack {
                                    currentTabView
                                        .transition(.opacity)
                                        .zIndex(0)
                                    
                                    // /diary, /setting WebView는 탭 내에서 오버레이
                                    if showWebPage, let url = webURL, (nativeRoute == "/diary" || nativeRoute == "/setting") {
                                        WebViewContainer(url: url, nativeRoute: nativeRoute)
                                            .transition(.move(edge: .trailing))
                                            .zIndex(1)
                                    }
                                }
                            }
                        }
                        .frame(height: geometry.size.height - 120) // Total - Header(60) - Footer(60)
                        .animation(.easeInOut(duration: 0.25), value: showNotesView)
                        .animation(.easeInOut(duration: 0.25), value: selectedTab)
                        .animation(.easeInOut(duration: 0.25), value: showWebPage)
                        
                        // Bottom Navigation - 60px height, fixed at bottom
                        FigmaBottomNavigation(
                            selectedTab: $selectedTab,
                            showNotesView: $showNotesView,
                            onTabReselected: { tabIndex in
                                // 설정 탭만 WebView 닫기, 다이어리는 유지
                                if showWebPage && nativeRoute == "/setting" {
                                    print("🔄 [ContentView] Settings tab reselected - closing WebView")
                                    closeWebPage()
                                }
                                // 다이어리 탭(탭0)은 다시 눌러도 WebView 유지
                            }
                        )
                        .frame(height: 60)
                    }
                }
            }
            
            // Dimmed overlay for destructive actions (covers header and footer)
            if showDestructiveActionOverlay {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(999)
            }
            
            // Popup overlays at top level
            if showSharePopup {
                ShareInvitePopup(
                    isPresented: $showSharePopup,
                    inviteCode: homeViewModel.data?.joinCode,
                    petData: nil
                )
            }
            
                if showTestGroupPopup {
                    ShareInvitePopup(
                        isPresented: $showTestGroupPopup,
                        inviteCode: nil,
                        petData: nil
                    )
                }
            
            if showEditPopup {
                ProfileEditPopup(
                    isPresented: $showEditPopup,
                    name: $profileName,
                    age: $profileAge,
                    weight: $profileWeight,
                    gender: $profileGender,
                    profileImage: $profileImage,
                    selectedTab: $selectedTab,
                    imageURL: homeViewModel.data?.profile.imageUrl != nil ? URL(string: buildImageUrl(homeViewModel.data!.profile.imageUrl) ?? "") : nil
                )
            }
            
            if showFeedingModal {
                ActivityCheckModal(
                    isPresented: $showFeedingModal,
                    activityType: .feeding,
                    onConfirm: { checkerName, memo in
                        // Refresh data from API with slight delay to ensure backend is updated
                        print("🟡 Feeding confirmed - refreshing data...")
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                            await homeViewModel.fetchData()
                        }
                    }
                )
            }
            
            if showWateringModal {
                ActivityCheckModal(
                    isPresented: $showWateringModal,
                    activityType: .watering,
                    onConfirm: { checkerName, memo in
                        // Refresh data from API with slight delay to ensure backend is updated
                        print("🟡 Watering confirmed - refreshing data...")
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                            await homeViewModel.fetchData()
                        }
                    }
                )
            }
            
            if showPoopModal {
                ActivityCheckModal(
                    isPresented: $showPoopModal,
                    activityType: .poop,
                    onConfirm: { checkerName, memo in
                        // Refresh data from API with slight delay to ensure backend is updated
                        print("🟡 Poop confirmed - refreshing data...")
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                            await homeViewModel.fetchData()
                        }
                    }
                )
            }
            
            if showJoinGroupView {
                JoinGroupView(isPresented: $showJoinGroupView) {
                    // Clear cache and refresh data after joining new group
                    print("🔄 Group joined/changed, clearing all caches")
                    homeViewModel.clearCache()
                    
                    Task {
                        await homeViewModel.fetchData()
                        // Reset profile data to trigger re-initialization
                        await MainActor.run {
                            if let data = homeViewModel.data {
                                profileName = data.profile.name
                                profileAge = data.profile.age
                                profileWeight = data.profile.weight
                                profileGender = data.profile.gender
                            }
                        }
                    }
                }
                .zIndex(999)
            }
        }
        .onAppear {
            // UserDefaults에서 초기값 로드
            hasShownInitialWebPage = UserDefaults.standard.bool(forKey: "hasShownInitialWebPage")
            print("🔄 ContentView onAppear - hasShownInitialWebPage: \(hasShownInitialWebPage)")
            
            // AppStateManager 콜백 콜근 몬그 설정
            setupBridgeCallbacks()
            
            // 그룹이 없으면 즉시 /start로 이동 (세션 시작 시 보장)
            if authViewModel.isAuthenticated {
                let groupId = UserDefaults.standard.string(forKey: "groupId") ?? ""
                if groupId.isEmpty {
                    print("✅ onAppear: 그룹 없음 → 즉시 /start 표시")
                    if !(showWebPage && nativeRoute == "/start") {
                        openWebPage(route: "/start")
                    }
                    hasShownInitialWebPage = true
                }
            }
            
            // Initialize profile data when ViewModel data is available
            if profileName.isEmpty, let data = homeViewModel.data {
                profileName = data.profile.name
                profileAge = data.profile.age
                profileWeight = data.profile.weight
                profileGender = data.profile.gender
            }
        }
        .task(id: authViewModel.isAuthenticated) {
            // 로그인 상태 변경 감지
            if authViewModel.isAuthenticated {
                let groupId = UserDefaults.standard.string(forKey: "groupId") ?? ""
                if groupId.isEmpty {
                    // 그룹이 없으면 무조건 /start로 이동 (hasShownInitialWebPage 무시)
                    print("✅ 로그인 상태 - 그룹 없음 → /start 페이지 로드")
                    if !(showWebPage && nativeRoute == "/start") {
                        openWebPage(route: "/start")
                    }
                    hasShownInitialWebPage = true // 같은 세션에서 중복 오픈 방지
                } else if !hasShownInitialWebPage {
                    // 그룹이 있으면 홈으로 한 번만 진입
                    hasShownInitialWebPage = true
                    print("✅ 로그인 상태 - 그룹 ID 있음: \(groupId), 홈뷰로 이동")
                    selectedTab = 1
                }
            } else {
                // 로그아웃 시 플래그 리셋 (다음 로그인 시 /start 표시)
                hasShownInitialWebPage = false
                showWebPage = false
                print("🔄 로그아웃 - hasShownInitialWebPage 리셋")
            }
        }
        .onChange(of: homeViewModel.data) { oldValue, newValue in
            // Initialize profile data when it first loads
            if profileName.isEmpty, let data = newValue {
                profileName = data.profile.name
                profileAge = data.profile.age
                profileWeight = data.profile.weight
                profileGender = data.profile.gender
            }
        }
        .onChange(of: hasShownInitialWebPage) { oldValue, newValue in
            // UserDefaults에 저장
            UserDefaults.standard.set(newValue, forKey: "hasShownInitialWebPage")
            print("💾 hasShownInitialWebPage UserDefaults 저장: \(newValue)")
        }
        .onChange(of: showEditPopup) { oldValue, newValue in
            // When popup closes, fetch fresh data from API
            if oldValue == true && newValue == false {
                print("🔄 [ContentView] Profile edit popup closed - refreshing data...")
                Task {
                    // Add delay to ensure backend is updated
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    await homeViewModel.fetchData()
                    // Update local bindings from fresh data
                    await MainActor.run {
                        if let data = homeViewModel.data {
                            profileName = data.profile.name
                            profileAge = data.profile.age
                            profileWeight = data.profile.weight
                            profileGender = data.profile.gender
                            print("✅ [ContentView] Profile data refreshed from API")
                        }
                    }
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // 일기 탭 선택 시 /diary WebView 표시
            if newValue == 0 {
                print("📖 [ContentView] Diary tab selected - opening /diary WebView")
                openWebPage(route: "/diary")
            } else {
                // 다른 탭으로 이동 시 /diary 또는 /setting WebView 닫기
                if showWebPage && (nativeRoute == "/diary" || nativeRoute == "/setting") {
                    print("🔄 [ContentView] Tab changed to \(newValue) - closing WebView")
                    closeWebPage()
                }
            }
        }
    }
    
    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case 0:
            // 일기 탭: Native DiaryView (설정은 헤더 아이콘으로 접근)
            DiaryView()
        case 1:
            HomeView(
                viewModel: homeViewModel,
                showEditPopup: $showEditPopup,
                showFeedingModal: $showFeedingModal,
                showWateringModal: $showWateringModal,
                showPoopModal: $showPoopModal,
                profileName: $profileName,
                profileAge: $profileAge,
                profileWeight: $profileWeight,
                profileGender: $profileGender,
                profileImage: $profileImage
            ) // 홈 뷰 (중간 탭)
        case 2:
            CalendarView() // 캘린더 뷰 (세 번째 탭)
        default:
            HomeView(
                viewModel: homeViewModel,
                showEditPopup: $showEditPopup,
                showFeedingModal: $showFeedingModal,
                showWateringModal: $showWateringModal,
                showPoopModal: $showPoopModal,
                profileName: $profileName,
                profileAge: $profileAge,
                profileWeight: $profileWeight,
                profileGender: $profileGender,
                profileImage: $profileImage
            )
        }
    }
    
    // MARK: - Helper Functions
    private func buildImageUrl(_ imageUrl: String?) -> String? {
        guard let imageUrl = imageUrl else { return nil }
        if imageUrl.starts(with: "http") {
            // Already a full URL
            return imageUrl
        } else {
            // Relative path - add base URL
            return "https://bucket.s3.region.amazonaws.com/" + imageUrl
        }
    }
    
    // MARK: - Bridge Setup
    private func setupBridgeCallbacks() {
        // AppStateManager를 통한 ContentView 콜백 콜근 몬그 설정
        print("🔗 [ContentView] Setting up AppStateManager callbacks")
        
        // AppStateManager는 이미 delegate를 설정했으므로, 좜차 콜백만 설정
        AppStateManager.shared.onOnboardingFinished = { [self] in
            print("🏠 [ContentView] AppStateManager.onOnboardingFinished - GOING HOME!")
            self.goHome()
        }
        AppStateManager.shared.onWebViewClose = { [self] in
            print("📱 [ContentView] AppStateManager.onWebViewClose")
            // 다이어리 웹뷰는 닫지 않고 유지
            if self.nativeRoute != "/diary" {
                self.closeWebPage()
            } else {
                print("📍 [ContentView] Diary webview - ignoring close request")
            }
        }
        AppStateManager.shared.onLogout = { [self] in
            print("👋 [ContentView] AppStateManager.onLogout")
            self.showDestructiveActionOverlay = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.performLogout()
                self.showDestructiveActionOverlay = false
            }
        }
        AppStateManager.shared.onDeleteAccount = { [self] in
            print("🗑️ [ContentView] AppStateManager.onDeleteAccount")
            self.showDestructiveActionOverlay = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.performLogout()
                self.showDestructiveActionOverlay = false
            }
        }
        AppStateManager.shared.onLeaveGroup = { [self] in
            print("👋 [ContentView] AppStateManager.onLeaveGroup - 그룹 나가기, /start로 이동")
            self.showDestructiveActionOverlay = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.navigateToStart()
                self.showDestructiveActionOverlay = false
            }
        }
    }
    
    // MARK: - Web helpers
    private func openWebPage(route: String) {
        nativeRoute = route
        // WebView는 프론트엔드 URL을 사용
        let baseURL = APIConfig.webViewBaseURL
        let path = route.hasPrefix("/") ? route : "/" + route
        webURL = URL(string: baseURL + path)
        showWebPage = true
        print("📱 Opening WebView: \(route)")
    }
    
    private func closeWebPage() {
        showWebPage = false
        print("✅ Closing WebView")
    }
    private func goHome() {
        print("🏠 goHome() called")
        print("   Before: showWebPage=\(showWebPage), selectedTab=\(selectedTab)")
        closeWebPage()
        print("   After closeWebPage: showWebPage=\(showWebPage)")
        selectedTab = 1 // 홈 탭
        print("   After selectedTab=1: selectedTab=\(selectedTab)")
        print("🏠 Navigating to home tab - COMPLETE")
    }
    private func performLogout() {
        closeWebPage()
        authViewModel.logout()
    }
    
    private func navigateToStart() {
        print("👋 [ContentView] navigateToStart() - Opening /start WebView")
        // Clear groupId from UserDefaults
        UserDefaults.standard.removeObject(forKey: "groupId")
        print("✅ groupId cleared from UserDefaults")
        // Clear cache when leaving group
        homeViewModel.clearCache()
        // Open /start page for onboarding/joining new group
        openWebPage(route: "/start")
    }
}

// MARK: - Bridge Handler
final class BridgeHandler: NSObject, WebViewBridgeDelegate {
    let onClose: () -> Void
    let onGroupFinished: () -> Void
    let onLogout: () -> Void
    let onDeleteAccount: () -> Void
    let onLeaveGroup: () -> Void
    
    init(onClose: @escaping () -> Void,
         onGroupFinished: @escaping () -> Void,
         onLogout: @escaping () -> Void,
         onDeleteAccount: @escaping () -> Void,
         onLeaveGroup: @escaping () -> Void) {
        self.onClose = onClose
        self.onGroupFinished = onGroupFinished
        self.onLogout = onLogout
        self.onDeleteAccount = onDeleteAccount
        self.onLeaveGroup = onLeaveGroup
    }
    
    func webViewBridgeDidRequestClose(_ bridge: WebViewBridgeService) { onClose() }
    func webViewBridgeDidFinishGroupSetup(_ bridge: WebViewBridgeService) { onGroupFinished() }
    func webViewBridgeDidLogout(_ bridge: WebViewBridgeService) { onLogout() }
    func webViewBridgeDidDeleteAccount(_ bridge: WebViewBridgeService) { onDeleteAccount() }
    func webViewBridgeDidLeaveGroup(_ bridge: WebViewBridgeService) { onLeaveGroup() }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.Colors.primary)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            Text("Loading your pet's data...")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(Theme.Colors.warning)
            
            Text("Oops! Something went wrong")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)
            
            Text(message)
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                onRetry()
            }
            .figmaButtonStyle()
        }
        .padding(Theme.Spacing.xl)
        .cardStyle()
    }
}

// MARK: - Refreshable ScrollView
struct RefreshableScrollView<Content: View>: View {
    let onRefresh: () -> Void
    let content: Content
    
    init(onRefresh: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            onRefresh()
 
        }
    }
}

#Preview {
    ContentView()
}
