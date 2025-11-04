//
//  JoinGroupView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/31/25.
//

import SwiftUI

struct JoinGroupView: View {
    @Binding var isPresented: Bool
    let onSuccess: () -> Void
    @State private var joinCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert: Bool = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isPresented = false
                }
            
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("다른 방 참가하기")
                        .font(Theme.Typography.headingL)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.lg)
                .background(Theme.Colors.white)
                
                Divider()
                
                // Content
                VStack(spacing: Theme.Spacing.xl) {
                    // Icon
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.Colors.mainYellow)
                        .padding(.top, Theme.Spacing.xxl)
                    
                    // Description
                    VStack(spacing: Theme.Spacing.sm) {
                        Text("초대 코드를 입력하세요")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.text)
                        
                        Text("다른 사람의 그룹에 참가할 수 있어요")
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    
                    // Join Code Input
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("초대 코드")
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        TextField("예: ABC123", text: $joinCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                            .font(Theme.Typography.body)
                            .frame(height: 44)
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(Theme.Typography.callout)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.xl)
                    }
                    
                    Spacer()
                    
                    // Join Button
                    Button(action: {
                        joinGroup()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("참가하기")
                                .font(Theme.Typography.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(joinCode.isEmpty || isLoading ? Color.gray : Theme.Colors.mainYellow)
                    .cornerRadius(12)
                    .disabled(joinCode.isEmpty || isLoading)
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.bottom, Theme.Spacing.xl)
                }
                .background(Theme.Colors.white)
            }
            .frame(maxWidth: .infinity, maxHeight: 600)
            .background(Theme.Colors.white)
            .cornerRadius(20)
            .padding(.horizontal, Theme.Spacing.xl)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        }
        .alert("참가 완료!", isPresented: $showSuccessAlert) {
            Button("확인", role: .cancel) {
                onSuccess()
                isPresented = false
            }
        } message: {
            Text("그룹에 성공적으로 참가했습니다!")
        }
    }
    
    private func joinGroup() {
        guard !joinCode.isEmpty else { return }
        
        print("DEBUG: Starting join group with code: \(joinCode)")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("DEBUG: Calling API...")
                let response = try await PetLogAPIService.shared.joinGroup(joinCode: joinCode.uppercased())
                print("DEBUG: API response - statusCode: \(response.statusCode), message: \(response.message)")
                
                await MainActor.run {
                    isLoading = false
                    if response.statusCode == 200 {
                        print("DEBUG: Showing success alert")
                        showSuccessAlert = true
                    } else {
                        print("DEBUG: Showing error: \(response.message)")
                        errorMessage = response.message
                    }
                }
            } catch {
                print("DEBUG: API Error: \(error)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "참가에 실패했습니다. 코드를 확인해주세요."
                }
            }
        }
    }
}

#Preview {
    JoinGroupView(isPresented: .constant(true), onSuccess: {})
}
