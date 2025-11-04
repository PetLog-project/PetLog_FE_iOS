//
//  SignupView.swift
//  PetLog_iOS
//
//  Created by Agent on 11/02/25.
//

import SwiftUI

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var isAgreedToTerms: Bool = false
    @State private var isAgreedToPrivacy: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.Colors.black)
                    }
                    
                    Spacer()
                    
                    Text("회원가입")
                        .font(Theme.Typography.headingL)
                        .foregroundColor(Theme.Colors.black)
                    
                    Spacer()
                    
                    // Invisible spacer for alignment
                    Color.clear
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Profile Image Section
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.Colors.mainYellow.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Theme.Colors.mainYellow)
                            }
                            
                            Button("프로필 사진 추가") {
                                // TODO: Implement image picker
                            }
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.blue)
                        }
                        .padding(.top, 20)
                        
                        // Input Fields
                        VStack(spacing: 20) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("닉네임")
                                    .font(Theme.Typography.boldM)
                                    .foregroundColor(Theme.Colors.black)
                                
                                TextField("닉네임을 입력하세요", text: $username)
                                    .font(Theme.Typography.bodyM)
                                    .padding()
                                    .background(Theme.Colors.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.Colors.black, lineWidth: 1)
                                    )
                            }
                            
                            // Email Field (optional for Apple login)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("이메일")
                                    .font(Theme.Typography.boldM)
                                    .foregroundColor(Theme.Colors.black)
                                
                                TextField("이메일을 입력하세요", text: $email)
                                    .font(Theme.Typography.bodyM)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Theme.Colors.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Theme.Colors.black, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Agreement Checkboxes
                        VStack(spacing: 16) {
                            Button(action: {
                                isAgreedToTerms.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: isAgreedToTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 24))
                                        .foregroundColor(isAgreedToTerms ? Theme.Colors.mainYellow : Theme.Colors.secondaryText)
                                    
                                    Text("이용약관에 동의합니다")
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.black)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // TODO: Show terms
                                    }) {
                                        Text("보기")
                                            .font(Theme.Typography.boldXS)
                                            .foregroundColor(Theme.Colors.blue)
                                    }
                                }
                            }
                            
                            Button(action: {
                                isAgreedToPrivacy.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: isAgreedToPrivacy ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 24))
                                        .foregroundColor(isAgreedToPrivacy ? Theme.Colors.mainYellow : Theme.Colors.secondaryText)
                                    
                                    Text("개인정보처리방침에 동의합니다")
                                        .font(Theme.Typography.bodyM)
                                        .foregroundColor(Theme.Colors.black)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        // TODO: Show privacy policy
                                    }) {
                                        Text("보기")
                                            .font(Theme.Typography.boldXS)
                                            .foregroundColor(Theme.Colors.blue)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Sign Up Button
                        Button(action: {
                            handleSignUp()
                        }) {
                            Text("시작하기")
                                .font(Theme.Typography.boldM)
                                .foregroundColor(Theme.Colors.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(canSignUp() ? Theme.Colors.mainYellow : Theme.Colors.secondaryText.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(!canSignUp())
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func canSignUp() -> Bool {
        return !username.isEmpty && isAgreedToTerms && isAgreedToPrivacy
    }
    
    private func handleSignUp() {
        if username.isEmpty {
            alertMessage = "닉네임을 입력해주세요"
            showAlert = true
            return
        }
        
        if !isAgreedToTerms || !isAgreedToPrivacy {
            alertMessage = "약관에 동의해주세요"
            showAlert = true
            return
        }
        
        // TODO: Implement actual signup API call
        print("Sign up with username: \(username), email: \(email)")
        dismiss()
    }
}

#Preview {
    SignupView()
}
