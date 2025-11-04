//
//  ContentView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/11/25.
//

import SwiftUI

// 개발 중: API 테스트를 위해 true로 설정
let showAPITestView = false

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var homeViewModel = HomeViewModel()
    @State private var selectedTab = 1
    @State private var showSharePopup = false
    @State private var showTestGroupPopup = false
    @State private var showNotesView = false
    @State private var showEditPopup = false
    @State private var showFeedingModal = false
    @State private var showWateringModal = false
    @State private var showPoopModal = false
    @State private var showJoinGroupView = false
    
    // Profile edit data
    @State private var profileName: String = ""
    @State private var profileAge: String = ""
    @State private var profileWeight: Double = 0.0
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
            
            VStack(spacing: 0) {
                // Header - 60px height
                FigmaAppHeader(
                    showSharePopup: $showSharePopup,
                    showNotesView: $showNotesView,
                    showJoinGroupView: $showJoinGroupView,
                    isWhiteBackground: showNotesView || selectedTab != 1
                )
                .animation(.easeInOut(duration: 0.25), value: showNotesView)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
                
                // Main content - Tab-based view switching or NotesView
                ZStack {
                    if showNotesView {
                        NotesView(isPresented: $showNotesView)
                            .transition(.opacity)
                            .zIndex(1)
                    } else {
                        currentTabView
                            .transition(.opacity)
                            .zIndex(0)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: showNotesView)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
                
                // Bottom Navigation - 60px height, fixed at bottom
                FigmaBottomNavigation(selectedTab: $selectedTab, showNotesView: $showNotesView)
            }
            
            // Test buttons (개발용)
            #if DEBUG
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Button(action: {
                            showTestGroupPopup = true
                        }) {
                            Text("그룹 생성 테스트")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(20)
                        }
                        
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            Text("로그아웃")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.red)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 80)
                }
            }
            #endif
            
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
                        petData: CreateGroupRequest(
                            imageUrl: "https://picsum.photos/200",
                            name: "테스트 펫",
                            age: "3살",
                            weight: "5.5kg",
                            gender: "MALE",
                            feedingCycle: 12,
                            lastFeedingTime: PetLogAPIService.formatDate(Date()),
                            wateringCycle: 24,
                            lastWateringTime: PetLogAPIService.formatDate(Date()),
                            notice: "테스트 그룹입니다"
                        )
                    )
                }
            
            if showEditPopup {
                ProfileEditPopup(
                    isPresented: $showEditPopup,
                    name: $profileName,
                    age: $profileAge,
                    weight: $profileWeight,
                    gender: $profileGender,
                    profileImage: $profileImage
                )
            }
            
            if showFeedingModal {
                ActivityCheckModal(
                    isPresented: $showFeedingModal,
                    activityType: .feeding,
                    onConfirm: { checkerName, memo in
                        // Refresh data from API
                        Task {
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
                        // Refresh data from API
                        Task {
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
                        // Refresh data from API
                        Task {
                            await homeViewModel.fetchData()
                        }
                    }
                )
            }
            
            if showJoinGroupView {
                JoinGroupView(isPresented: $showJoinGroupView) {
                    // Refresh data after joining new group
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
            // Initialize profile data when ViewModel data is available
            if profileName.isEmpty, let data = homeViewModel.data {
                profileName = data.profile.name
                profileAge = data.profile.age
                profileWeight = data.profile.weight
                profileGender = data.profile.gender
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
        .onChange(of: showEditPopup) { oldValue, newValue in
            // When popup closes, update ViewModel with new profile data
            if oldValue == true && newValue == false, var data = homeViewModel.data {
                data.profile.name = profileName
                data.profile.age = profileAge
                data.profile.weight = profileWeight
                if let gender = profileGender {
                    data.profile.gender = gender
                }
                homeViewModel.data = data
                // Save to backend and refresh data
                Task {
                    do {
                        let request = UpdateProfileRequest(
                            imageUrl: nil, // Image upload not supported; keep existing
                            name: profileName,
                            age: profileAge,
                            weight: String(format: "%gkg", profileWeight),
                            gender: profileGender?.rawValue,
                            feedingCycle: nil,
                            lastFeedingTime: nil,
                            wateringCycle: nil,
                            lastWateringTime: nil,
                            notice: nil
                        )
                        _ = try await PetLogAPIService.shared.updateProfile(request: request)
                        // Pull latest from server to ensure consistency
                        await homeViewModel.fetchData()
                    } catch {
                        // Silently fail for now; UI already updated optimistically
                        print("Failed to update profile: \(error)")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var currentTabView: some View {
        switch selectedTab {
        case 0:
            DiaryView() // 일기 뷰 (첫 번째 탭)
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
