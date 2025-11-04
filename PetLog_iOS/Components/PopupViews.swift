import SwiftUI

// MARK: - Share Invite Code Popup
struct ShareInvitePopup: View {
    @Binding var isPresented: Bool
    let inviteCode: String?
    let petData: CreateGroupRequest?
    @State private var showCopiedMessage = false
    @State private var generatedCode: String?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea(.all, edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    isPresented = false
                }
            
            // Popup content - Figma design
            VStack(spacing: 40) {
                // Title
                Text("공동 보호자 초대하기")
                    .font(Theme.Typography.bodyM)
                    .foregroundColor(Theme.Colors.text)
                
                // Invite code display
                if isGenerating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 40)
                } else if let error = errorMessage {
                    Text(error)
                        .font(Theme.Typography.bodyM)
                        .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.38))
                        .multilineTextAlignment(.center)
                } else {
                    Text(displayCode)
                        .font(Theme.Typography.headingL)
                        .foregroundColor(Theme.Colors.text)
                        .tracking(2)
                }
                
                // Buttons
                HStack(spacing: 80) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("닫기")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 100, height: 40)
                    }
                    .background(Color(red: 0.96, green: 0.94, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.black, lineWidth: 1)
                    )
                    
                    Button {
                        copyToClipboard()
                    } label: {
                        Text("복사 하기")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 100, height: 40)
                    }
                    .background(Theme.Colors.mainYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.black, lineWidth: 1)
                    )
                    .disabled(isGenerating || errorMessage != nil)
                    .opacity(isGenerating || errorMessage != nil ? 0.5 : 1.0)
                }
            }
            .frame(width: 320)
            .padding(20)
            .background(Theme.Colors.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.5), radius: 15)
            .overlay(
                Group {
                    if showCopiedMessage {
                        VStack {
                            Spacer()
                            Text("✓ 복사되었습니다")
                                .font(Theme.Typography.bodyM)
                                .foregroundColor(Theme.Colors.white)
                                .padding()
                                .background(Theme.Colors.black.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.bottom, -60)
                        }
                        .transition(.opacity)
                    }
                }
            )
        }
        .onAppear {
            // If invite code is not provided but pet data is, generate it
            if inviteCode == nil, let petData = petData {
                generateInviteCode(with: petData)
            }
        }
    }
    
    private var displayCode: String {
        generatedCode ?? inviteCode ?? "로딩 중..."
    }
    
    private func generateInviteCode(with petData: CreateGroupRequest) {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                print("🔵 Attempting to create group with data: \(petData)")
                _ = try await PetLogAPIService.shared.createGroup(request: petData)
                // Fetch current user to get groupId, then invite code
                let me = try await AuthAPIService.shared.getCurrentUser()
                let code = try await PetLogAPIService.shared.getInviteCode(groupId: me.groupId ?? "")
                print("✅ Group created, invite code fetched: \(code)")
                await MainActor.run {
                    generatedCode = code
                    isGenerating = false
                }
            } catch let error as APIError {
                await MainActor.run {
                    print("❌ API Error: \(error.errorDescription ?? "Unknown error")")
                    errorMessage = error.errorDescription ?? "초대 코드 생성 실패"
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    print("❌ Unexpected error: \(error)")
                    errorMessage = "초대 코드 생성 실패: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = displayCode
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        withAnimation {
            showCopiedMessage = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }
}

// MARK: - Profile Edit Popup
struct ProfileEditPopup: View {
    @Binding var isPresented: Bool
    @Binding var name: String
    @Binding var age: String
    @Binding var weight: Double
    @Binding var gender: Gender?
    @Binding var profileImage: UIImage?
    
    @State private var editedName: String
    @State private var editedAge: String
    @State private var editedWeight: String  // Keep as String for TextField input
    @State private var editedGender: Gender?
    @State private var editedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showNameError = false
    @State private var showAgeError = false
    @State private var showWeightError = false
    
    init(
        isPresented: Binding<Bool>,
        name: Binding<String>,
        age: Binding<String>,
        weight: Binding<Double>,
        gender: Binding<Gender?>,
        profileImage: Binding<UIImage?>
    ) {
        self._isPresented = isPresented
        self._name = name
        self._age = age
        self._weight = weight
        self._gender = gender
        self._profileImage = profileImage
        
        // Initialize state with current values
        self._editedName = State(initialValue: name.wrappedValue)
        self._editedAge = State(initialValue: age.wrappedValue)
        self._editedWeight = State(initialValue: String(format: "%.1f", weight.wrappedValue))
        self._editedGender = State(initialValue: gender.wrappedValue)
        self._editedImage = State(initialValue: profileImage.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all, edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    isPresented = false
                }
            
            // Popup content
            VStack(spacing: 20) {
                // Profile image with tap to change
                Button {
                    showImagePicker = true
                } label: {
                    VStack(spacing: 8) {
                        if let image = editedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.white, lineWidth: 4)
                                )
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.white, lineWidth: 4)
                                )
                        }
                        
                        Text("프로필 사진 변경")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.66, green: 0.66, blue: 0.66))
                    }
                }
                
                // Form fields - Figma design
                VStack(spacing: 8) {
                    // Name field
                    FigmaInputField(
                        label: "이름",
                        text: $editedName,
                        showError: showNameError
                    )
                    
                    // Age field
                    FigmaInputField(
                        label: "나이",
                        text: $editedAge,
                        showError: showAgeError
                    )
                    
                    // Weight field
                    FigmaInputField(
                        label: "몸무게",
                        text: $editedWeight,
                        showError: showWeightError
                    )
                    
                    // Gender selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("성별")
                            .font(.system(size: 8))
                            .foregroundColor(Theme.Colors.text)
                        
                        HStack(spacing: 44) {
                            FigmaGenderButton(
                                gender: .female,
                                isSelected: editedGender == .female
                            ) {
                                editedGender = .female
                            }
                            
                            FigmaGenderButton(
                                gender: .male,
                                isSelected: editedGender == .male
                            ) {
                                editedGender = .male
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("닫기")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 100, height: 40)
                    }
                    .background(Color(red: 0.96, green: 0.94, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.black, lineWidth: 1)
                    )
                    
                    Button {
                        saveChanges()
                    } label: {
                        Text("확인")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 100, height: 40)
                    }
                    .background(Theme.Colors.mainYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.black, lineWidth: 1)
                    )
                }
            }
            .frame(width: 300)
            .padding(20)
            .background(Theme.Colors.white)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: Color.black.opacity(0.5), radius: 15)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $editedImage)
        }
    }
    
    private func saveChanges() {
        // Validate
        showNameError = editedName.isEmpty
        showAgeError = editedAge.isEmpty
        
        // Validate weight as number
        let weightValue = Double(editedWeight.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespaces))
        showWeightError = weightValue == nil
        
        guard !editedName.isEmpty && !editedAge.isEmpty, let validWeight = weightValue else {
            return
        }
        
        name = editedName
        age = editedAge
        weight = validWeight
        gender = editedGender
        profileImage = editedImage
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isPresented = false
    }
}

// MARK: - Figma Input Field
struct FigmaInputField: View {
    let label: String
    @Binding var text: String
    let showError: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.system(size: 8))
                    .foregroundColor(Theme.Colors.text)
                
                TextField("", text: $text)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.Colors.text)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 260)
            .background(Theme.Colors.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(showError ? Color(red: 1.0, green: 0.38, blue: 0.38) : Color(red: 0.66, green: 0.66, blue: 0.66), lineWidth: 1)
            )
            
            // Fixed height error message area
            HStack {
                if showError {
                    Text("해당 항목은 비워둔 수 없습니다")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 1.0, green: 0.38, blue: 0.38))
                } else {
                    Text(" ")
                        .font(.system(size: 8))
                }
                Spacer()
            }
            .frame(height: 16)
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Figma Gender Button
struct FigmaGenderButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(gender == .male ? "ic_baseline_male" : "ic_baseline_female")
                .resizable()
                .scaledToFit()
                .frame(width: 25, height: 25)
                .foregroundColor(isSelected ? Color.white : Theme.Colors.text)
                .frame(width: 49, height: 49)
                .background(isSelected ? (gender == .female ? Color(red: 0.99, green: 0.56, blue: 0.69) : Theme.Colors.blue) : Color(red: 0.87, green: 0.87, blue: 0.87))
                .clipShape(Circle())
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Activity Check Modal
struct ActivityCheckModal: View {
    @Binding var isPresented: Bool
    let activityType: ActivityType
    @State private var checkerName: String = ""
    @State private var memo: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    let onConfirm: (String, String) -> Void
    
    enum ActivityType {
        case feeding
        case watering
        case poop
        
        var title: String {
            switch self {
            case .feeding:
                return "다음 급여 시 참고사항이 있다면 적어주세요"
            case .watering:
                return "다음 물 교체 시"
            case .poop:
                return "다음 배변 체크 시"
            }
        }
        
        var subtitle: String? {
            switch self {
            case .feeding:
                return nil
            case .watering, .poop:
                return "참고사항이 있다면 적어주세요"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea(.all, edges: .all)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    isPresented = false
                }
            
            // Modal content
            VStack(spacing: 20) {
                // Title
                VStack(spacing: activityType == .feeding ? 0 : 2) {
                    Text(activityType.title)
                        .font(Theme.Typography.boldM)
                        .foregroundColor(Theme.Colors.text)
                    
                    if let subtitle = activityType.subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                    }
                }
                .multilineTextAlignment(.center)
                
                // Checker name field
                VStack(alignment: .leading, spacing: 4) {
                    Text("급여자")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    TextField("이름을 입력하세요", text: $checkerName)
                        .font(.system(size: 14))
                        .padding(8)
                        .background(Color(red: 0.96, green: 0.97, blue: 0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 1)
                        )
                }
                
                // Memo text field
                VStack(alignment: .leading, spacing: 4) {
                    Text("참고사항")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.Colors.text)
                    
                    TextEditor(text: $memo)
                        .font(.system(size: 12))
                        .foregroundColor(Theme.Colors.text)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(red: 0.96, green: 0.97, blue: 0.97))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color(red: 0.87, green: 0.87, blue: 0.87), lineWidth: 1)
                        )
                }
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
                
                // Buttons
                HStack(spacing: 80) {
                    Button {
                        isPresented = false
                    } label: {
                        Text("닫기")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 100, height: 40)
                    }
                    .background(Color(red: 0.96, green: 0.94, blue: 0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.black, lineWidth: 1)
                    )
                    
                    Button {
                        handleConfirm()
                    } label: {
                        Text("확인")
                            .font(Theme.Typography.boldM)
                            .foregroundColor(Theme.Colors.text)
                            .frame(width: 100, height: 40)
                    }
                    .background(Theme.Colors.mainYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.Colors.black, lineWidth: 1)
                    )
                }
            }
            .frame(width: 320)
            .padding(20)
            .background(Theme.Colors.white)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: Color.black.opacity(0.5), radius: 15)
        }
    }
    
    private func handleConfirm() {
        guard !checkerName.isEmpty else {
            errorMessage = "급여자 이름을 입력해주세요."
            return
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Call appropriate API based on activity type
                switch activityType {
                case .feeding:
                    _ = try await PetLogAPIService.shared.createFeedingLog(
                        checkerName: checkerName,
                        memo: memo.isEmpty ? nil : memo
                    )
                case .watering:
                    _ = try await PetLogAPIService.shared.createWateringLog(
                        checkerName: checkerName,
                        memo: memo.isEmpty ? nil : memo
                    )
                case .poop:
                    _ = try await PetLogAPIService.shared.createPoopLog(
                        checkerName: checkerName,
                        memo: memo.isEmpty ? nil : memo
                    )
                }
                
                await MainActor.run {
                    isLoading = false
                    onConfirm(checkerName, memo)
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "저장에 실패했습니다."
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Share Invite Popup - With Code") {
    ShareInvitePopup(
        isPresented: .constant(true),
        inviteCode: "ABC123",
        petData: nil
    )
}

#Preview("Share Invite Popup - Generate Code") {
    ShareInvitePopup(
        isPresented: .constant(true),
        inviteCode: nil,
        petData: CreateGroupRequest(
            imageUrl: "https://example.com/image.jpg",
            name: "ㄱㄱ이",
            age: "3살",
            weight: "5.2kg",
            gender: "MALE",
            feedingCycle: 12,
            lastFeedingTime: "2024-01-01T09:00",
            wateringCycle: 24,
            lastWateringTime: "2024-01-01T09:00",
            notice: nil
        )
    )
}

#Preview("Profile Edit Popup") {
    ProfileEditPopup(
        isPresented: .constant(true),
        name: .constant("ㄱㄱ이"),
        age: .constant("3살"),
        weight: .constant(5.2),
        gender: .constant(.male),
        profileImage: .constant(nil)
    )
}

#Preview("Activity Check Modal - Feeding") {
    ActivityCheckModal(
        isPresented: .constant(true),
        activityType: .feeding,
        onConfirm: { _, _ in }
    )
}

#Preview("Activity Check Modal - Watering") {
    ActivityCheckModal(
        isPresented: .constant(true),
        activityType: .watering,
        onConfirm: { _, _ in }
    )
}

#Preview("Activity Check Modal - Poop") {
    ActivityCheckModal(
        isPresented: .constant(true),
        activityType: .poop,
        onConfirm: { _, _ in }
    )
}
