//
//  HomeView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/31/25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
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
            // Only load if data is truly missing (not just switching tabs)
            if viewModel.data == nil {
                // Try to load from API first, fallback to sample data
                viewModel.loadFromAPI()
            }
            // Initialize profile state only if empty
            if profileName.isEmpty, let data = viewModel.data {
                profileName = data.profile.name
                profileAge = data.profile.age
                profileWeight = data.profile.weight
                profileGender = data.profile.gender
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Profile Header Section
            if let data = viewModel.data {
                FigmaProfileHeader(
                    imageURL: URL(string: data.profile.imageUrl),
                    name: $profileName,
                    age: $profileAge,
                    weight: $profileWeight,
                    gender: $profileGender,
                    showEditPopup: $showEditPopup
                )
            }
            
            // Activity Cards Section
            if let data = viewModel.data {
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
        let viewModel: HomeViewModel
        
        init() {
            let vm = HomeViewModel()
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
