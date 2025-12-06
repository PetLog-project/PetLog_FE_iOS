//
//  LoginView.swift
//  PetLog_iOS
//
//  Created by DonghaRyu on 11/02/25.
//

import SwiftUI
// Apple Sign In removed for now (no paid account)

struct LoginView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title at top
                Text("반려기록")
                    .font(.custom("BlackHanSans-Regular", size: 60))
                    .foregroundColor(Theme.Colors.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 50)
                    .padding(.top, 70)
                
                Spacer()
                
                // Illustration Section - Combined cat and llama image
                Image("login_illustration")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 440)
                    .padding(.horizontal, 0)
                    .padding(.bottom, 0)
                
                // Login Buttons Section with black background
                VStack(spacing: 16) {
                    // Kakao Login Button
                    Button(action: {
                        authViewModel.loginWithKakao()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Theme.Colors.kakaoBlack)
                            
                            Text("카카오톡으로 시작하기")
                                .font(Theme.Typography.boldM)
                                .foregroundColor(Theme.Colors.kakaoBlack)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.Colors.kakaoYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authViewModel.isLoading)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(Theme.Colors.black)
                .ignoresSafeArea(edges: .bottom)
                
                // Loading Indicator
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.mainYellow))
                        .scaleEffect(1.5)
                }
            }
            
            // Error Message
            if let errorMessage = authViewModel.errorMessage {
                VStack {
                    Spacer()
                    
                    Text(errorMessage)
                        .font(Theme.Typography.bodyM)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 32)
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom))
            }
        }
    }
}

#Preview {
    LoginView()
}
