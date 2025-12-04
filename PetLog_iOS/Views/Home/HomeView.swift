//
//  HomeView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/31/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: PetDashboardViewModel
    @Binding var showEditPopup: Bool
    @Binding var showFeedingModal: Bool
    @Binding var showWateringModal: Bool
    @Binding var showPoopModal: Bool
    
    // Profile data for editing - now bindings from ContentView
    @Binding var profileName: String
    @Binding var profileAge: String
    @Binding var profileWeight: Double
    @Binding var profileGender: Gender?
    @Binding var profileImage: UIImage?
    
    // Track current group ID to detect changes
    @State private var currentGroupId: String?
    
    var body: some View {
        Group {
            // Show content immediately if data exists, even while loading
            if viewModel.data != nil {
                mainContent
                    .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    .overlay(
                        // Show subtle loading indicator on top if refreshing
                        Group {
                            if viewModel.isLoading {
                                VStack {
                                    ProgressView()
                                        .tint(Theme.Colors.mainYellow)
                                        .scaleEffect(0.8)
                                        .padding(8)
                                        .background(Theme.Colors.white.opacity(0.9))
                                        .clipShape(Circle())
                                    Spacer()
                                }
                                .padding(.top, 20)
                            }
                        }
                    )
            } else if viewModel.isLoading {
                // Only show full loading view on first load
                LoadingView()
            } else {
                mainContent
            }
        }
        .onAppear {
            let groupId = UserDefaults.standard.string(forKey: "groupId")
            let groupChanged = groupId != currentGroupId
            
            print("🏠 HomeView appeared - Current group: \(currentGroupId ?? "nil"), New group: \(groupId ?? "nil"), Changed: \(groupChanged)")
            
            // Update current group ID
            currentGroupId = groupId
            
            // Only fetch if group changed or no data loaded yet
            if groupChanged || viewModel.data == nil {
                print("🏠 Fetching fresh data from API...")
                Task {
                    // If groupId is nil, fetch first group from /api/groups/my
                    if groupId == nil {
                        print("🏠 No group ID stored, fetching first group from API...")
                        do {
                            let myGroups = try await PetLogAPIService.shared.getMyGroups()
                            if let firstGroupId = myGroups.first {
                                UserDefaults.standard.set(firstGroupId, forKey: "groupId")
                                currentGroupId = firstGroupId
                                print("🏠 GroupId auto-selected: \(firstGroupId)")
                            } else {
                                print("🏠 No groups found for user")
                            }
                        } catch {
                            print("🏠 Failed to fetch groups: \(error)")
                        }
                    }
                    
                    // Now fetch data with groupId (stored or newly fetched)
                    await viewModel.fetchData()
                    
                    // After fetch completes, update profile data
                    await MainActor.run {
                        if let data = viewModel.data {
                            print("🟢 [HomeView] Profile updated after fetch: \(data.profile.name)")
                            profileName = data.profile.name
                            profileAge = data.profile.age
                            profileWeight = data.profile.weight
                            profileGender = data.profile.gender
                        }
                    }
                }
            } else {
                print("🏠 Group unchanged, skipping fetch")
            }
            
            // Initialize profile state when data loads
            // This ensures profile info is always in sync with viewModel data
            if let data = viewModel.data {
                if profileName.isEmpty || groupChanged {
                    print("🟢 [HomeView] Updating profile from viewModel data")
                    profileName = data.profile.name
                    profileAge = data.profile.age
                    profileWeight = data.profile.weight
                    profileGender = data.profile.gender
                }
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Profile Header Section + Test Button
            if let data = viewModel.data {
                HStack {
                    FigmaProfileHeader(
                        imageURL: URL(string: buildImageUrl(data.profile.imageUrl) ?? ""),
                        name: $profileName,
                        age: $profileAge,
                        weight: $profileWeight,
                        gender: $profileGender,
                        showEditPopup: $showEditPopup
                    )
                }
            }
            
            // Activity Cards Section
            if let data = viewModel.data {
                let _ = print("📊 HomeView rendering SwipeableActivityCards with:")
                let _ = print("   Feeding time: \(data.feeding.lastFeedingTime), memo: \(data.feeding.lastMemo)")
                let _ = print("   Watering time: \(data.watering.lastWateringTime), memo: \(data.watering.lastMemo)")
                let _ = print("   Poop count: \(data.poop.todayPoopCount), memo: \(data.poop.lastMemo)")
                SwipeableActivityCards(
                    feedingData: data.feeding,
                    wateringData: data.watering,
                    poopData: data.poop,
                    showFeedingModal: $showFeedingModal,
                    showWateringModal: $showWateringModal,
                    showPoopModal: $showPoopModal
                )
                .frame(height: 328)
                .id("\(data.feeding.lastFeedingTime)-\(data.watering.lastWateringTime)-\(data.poop.todayPoopCount)")
            }
            
            // Error State
            if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    refreshData()
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private func refreshData() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation(Theme.Animation.smooth) {
            viewModel.loadFromAPI()
        }
    }
    
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
}

#Preview {
    struct PreviewWrapper: View {
        @State private var showEditPopup = false
        @State private var showFeedingModal = false
        @State private var showWateringModal = false
        @State private var showPoopModal = false
        @State private var profileName = ""
        @State private var profileAge = ""
        @State private var profileWeight: Double = 0.0
        @State private var profileGender: Gender? = nil
        @State private var profileImage: UIImage? = nil
        let viewModel: PetDashboardViewModel
        
        init() {
            let vm = PetDashboardViewModel()
            vm.loadSampleSync()
            self.viewModel = vm
        }
        
        var body: some View {
            HomeView(
                viewModel: viewModel,
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
    return PreviewWrapper()
}

