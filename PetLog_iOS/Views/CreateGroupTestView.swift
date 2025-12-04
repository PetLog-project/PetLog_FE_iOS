//
//  CreateGroupTestView.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 12/02/25.
//

import SwiftUI
import PhotosUI

struct CreateGroupTestView: View {
    @Environment(\.dismiss) var dismiss
    @State private var petName: String = ""
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var gender: String = "FEMALE"
    @State private var feedingCycle: String = "6"
    @State private var wateringCycle: String = "6"
    @State private var note: String = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var inviteCode: String?
    var onGroupCreated: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("뒤로")
                        }
                        .foregroundColor(Theme.Colors.primary)
                    }
                    Spacer()
                    Text("그룹 생성 테스트")
                        .font(Theme.Typography.headline)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Image Picker
                        VStack(spacing: 12) {
                            Text("펫 사진 선택")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: { isImagePickerPresented = true }) {
                                if let selectedImage = selectedImage {
                                    Image(uiImage: selectedImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    VStack(spacing: 12) {
                                        Image(systemName: "photo.badge.plus")
                                            .font(.system(size: 40))
                                            .foregroundColor(Theme.Colors.primary)
                                        Text("사진을 선택해주세요")
                                            .font(Theme.Typography.bodyM)
                                            .foregroundColor(Theme.Colors.secondaryText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        
                        // Pet Name (10글자 제한)
                        VStack(spacing: 8) {
                            Text("펫 이름 (10글자 제한)")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("예: 여름", text: $petName)
                                .onChange(of: petName) { _, newValue in
                                    if newValue.count > 10 {
                                        petName = String(newValue.prefix(10))
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Age (4글자 제한)
                        VStack(spacing: 8) {
                            Text("나이 (4글자 제한)")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("예: 2개월", text: $age)
                                .onChange(of: age) { _, newValue in
                                    if newValue.count > 4 {
                                        age = String(newValue.prefix(4))
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Weight (6글자 제한)
                        VStack(spacing: 8) {
                            Text("몸무게 (6글자 제한)")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("예: 1kg", text: $weight)
                                .onChange(of: weight) { _, newValue in
                                    if newValue.count > 6 {
                                        weight = String(newValue.prefix(6))
                                    }
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Gender
                        VStack(spacing: 8) {
                            Text("성별")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Picker("성별", selection: $gender) {
                                Text("FEMALE").tag("FEMALE")
                                Text("MALE").tag("MALE")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // Feeding Cycle
                        VStack(spacing: 8) {
                            Text("밥 주기 (시간)")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("예: 6", text: $feedingCycle)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Watering Cycle
                        VStack(spacing: 8) {
                            Text("물 마실 때 (시간)")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("예: 6", text: $wateringCycle)
                                .keyboardType(.numberPad)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Note
                        VStack(spacing: 8) {
                            Text("메모 (선택)")
                                .font(Theme.Typography.bodyM)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("예: 밥 먹이고 입 닦아줘야 함", text: $note)
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.Colors.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(Theme.Typography.bodyXS)
                                    .foregroundColor(.red)
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Success Message
                        if let successMessage = successMessage {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(successMessage)
                                    .font(Theme.Typography.bodyXS)
                                    .foregroundColor(.green)
                            }
                            .padding(12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Invite Code Display
                        if let inviteCode = inviteCode {
                            VStack(spacing: 12) {
                                Text("초대 코드")
                                    .font(Theme.Typography.bodyM)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(inviteCode)
                                    .font(Theme.Typography.headingL)
                                    .foregroundColor(Theme.Colors.text)
                                    .tracking(2)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(Color(red: 0.96, green: 0.94, blue: 0.92))
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        UIPasteboard.general.string = inviteCode
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }
                                
                                Text("탭하여 복사")
                                    .font(Theme.Typography.bodyXS)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                }
                
                // Create Button
                Button(action: createGroup) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("그룹 생성")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(petName.isEmpty ? Color.gray : Theme.Colors.mainYellow)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(petName.isEmpty || isLoading)
                .padding(20)
            }
        }
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private func createGroup() {
        errorMessage = nil
        successMessage = nil
        isLoading = true
        
        // Validate required fields
        guard !petName.isEmpty, !age.isEmpty, !weight.isEmpty else {
            errorMessage = "필수 입력 필드를 모두 입력해주세요"
            isLoading = false
            return
        }
        
        Task {
            // Get current date/time in ISO 8601 format
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            let now = dateFormatter.string(from: Date())
            
            // Upload image to S3 if selected
            var imageURL: String? = nil
            if let selectedImage = selectedImage, let pngData = selectedImage.pngData() {
                do {
                    print("📸 Uploading image to S3...")
                    imageURL = try await S3UploadService.shared.uploadImage(pngData)
                    print("✅ Image uploaded: \(imageURL ?? "nil")")
                } catch {
                    print("❌ Image upload failed: \(error), using placeholder")
                    imageURL = "https://picsum.photos/200?random=\(Int.random(in: 1...10000))"
                }
            }
            
            let request = CreateGroupRequest(
                imageUrl: imageURL,
                name: petName,
                age: age,
                weight: weight,
                gender: gender,
                feedingCycle: Int(feedingCycle) ?? 6,
                lastFeedingTime: now,
                wateringCycle: Int(wateringCycle) ?? 6,
                lastWateringTime: now,
                note: note.isEmpty ? nil : note
            )
            do {
                print("🏠 Creating group: \(petName)...")
                let response = try await PetLogAPIService.shared.createGroup(request: request)
                print("🏠 Group created: \(response.message)")
                
                // 1️⃣ 그룹 생성 후 groupId 조회
                let myGroups = try await PetLogAPIService.shared.getMyGroups()
                guard let groupId = myGroups.first else {
                    throw APIError.serverError(statusCode: 500, message: "Failed to get groupId after creation")
                }
                print("✅ GroupId obtained: \(groupId)")
                
                // 2️⃣ groupId를 UserDefaults에 저장
                UserDefaults.standard.set(groupId, forKey: "groupId")
                
                // 3️⃣ 초대 코드 조회
                let code = try await PetLogAPIService.shared.getInviteCode(groupId: groupId)
                print("✅ Invite code fetched: \(code)")
                
                await MainActor.run {
                    successMessage = "✅ 그룹이 생성되었습니다!"
                    inviteCode = code
                    isLoading = false
                    
                    // 4️⃣ Notify parent that group was created (HomeView will refresh)
                    onGroupCreated?()
                }
            } catch {
                print("❌ Failed to create group: \(error)")
                await MainActor.run {
                    if let apiError = error as? APIError {
                        errorMessage = apiError.errorDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
}

// ImagePicker is defined in PopupViews.swift

#Preview {
    CreateGroupTestView()
}
