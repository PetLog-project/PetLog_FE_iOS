//
//  LoginView.swift
//  PetLog_iOS
//
//  Created by Agent on 11/02/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and Title Section
                VStack(spacing: 20) {
                    // Logo Placeholder - Replace with actual logo from Assets
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.Colors.mainYellow)
                    
                    Text("반려기록")
                        .font(Theme.Typography.headingL)
                        .foregroundColor(Theme.Colors.black)
                    
                    Text("소중한 반려동물의 일상을 기록해보세요")
                        .font(Theme.Typography.bodyM)
                        .foregroundColor(Theme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Login Buttons Section
                VStack(spacing: 16) {
                    // Kakao Login Button
                    Button(action: {
                        authViewModel.loginWithKakao()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                            
                            Text("카카오톡으로 시작하기")
                                .font(Theme.Typography.boldM)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(red: 0.996, green: 0.898, blue: 0))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authViewModel.isLoading)
                    
                    // Apple Login Button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        authViewModel.handleAppleLoginCompletion(result: result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(authViewModel.isLoading)
                    
                    // Test Login Button (for development/simulator)
                    #if DEBUG
                    Button(action: {
                        authViewModel.loginWithTestAccount()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                            
                            Text("테스트 계정으로 시작하기")
                                .font(Theme.Typography.boldM)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(authViewModel.isLoading)
                    #endif
                }
                .padding(.horizontal, 32)
                
                // Terms and Privacy Section
                HStack(spacing: 8) {
                    Text("계속 진행하면")
                        .font(Theme.Typography.bodyXS)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Button("이용약관") {
                        // TODO: Show terms
                    }
                    .font(Theme.Typography.boldXS)
                    .foregroundColor(Theme.Colors.black)
                    
                    Text("및")
                        .font(Theme.Typography.bodyXS)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Button("개인정보처리방침") {
                        // TODO: Show privacy policy
                    }
                    .font(Theme.Typography.boldXS)
                    .foregroundColor(Theme.Colors.black)
                    
                    Text("에 동의하는 것으로 간주됩니다")
                        .font(Theme.Typography.bodyXS)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                .padding(.bottom, 40)
                
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
