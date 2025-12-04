import SwiftUI

struct APITestView: View {
    @State private var status: String = "대기 중..."
    @State private var isLoading: Bool = false
    @State private var joinCode: String = ""
    
    private let apiService = PetLogAPIService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    
                    // Test Buttons
                    VStack(spacing: 12) {
                        // Get My Group
                        Button(action: testGetMyGroup) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "person.2.fill")
                                }
                                Text("내 그룹 조회")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                        
                        // Create Group
                        Button(action: testCreateGroup) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                                Text("그룹 생성")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                        
                        // Join Group
                        VStack(spacing: 8) {
                            TextField("참여 코드 입력", text: $joinCode)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.characters)
                            
                            Button(action: testJoinGroup) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "person.badge.plus")
                                    }
                                    Text("그룹 참여")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .disabled(isLoading || joinCode.isEmpty)
                        }
                        
                        // Get Notes
                        Button(action: testGetNotes) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "note.text")
                                }
                                Text("참고사항 조회")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("API 테스트")
        }
    }
    
    // MARK: - Test Methods
    
    func testGetMyGroup() {
        isLoading = true
        status = "내 그룹 조회 중..."
        
        Task {
            do {
                guard let groupId = UserDefaults.standard.string(forKey: "groupId") else {
                    throw APIError.serverError(statusCode: 404, message: "그룹 ID 없습니다.")
                }
                
                let petInfo = try await apiService.getPetInfo(groupId: groupId)
                await MainActor.run {
                    status = "✅ 성공!\n이름: \(petInfo.name)\n나이: \(petInfo.age)"
                    isLoading = false
                }
            } catch let error as APIError {
                await MainActor.run {
                    status = "❌ 실패: \(error.localizedDescription)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    status = "❌ 에러: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    func testCreateGroup() {
        isLoading = true
        status = "그룹 생성 중..."
        
        Task {
            do {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                let now = dateFormatter.string(from: Date())
                
                let request = CreateGroupRequest(
                    imageUrl: "https://example.com/pet.jpg",
                    name: "테스트반려동물",
                    age: "1살",
                    weight: "2kg",
                    gender: "FEMALE",
                    feedingCycle: 6,
                    lastFeedingTime: now,
                    wateringCycle: 6,
                    lastWateringTime: now,
                    note: "테스트"
                )
                _ = try await apiService.createGroup(request: request)
                await MainActor.run {
                    status = "✅ 그룹 생성 성공!"
                    isLoading = false
                }
            } catch let error as APIError {
                await MainActor.run {
                    status = "❌ 실패: \(error.localizedDescription)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    status = "❌ 에러: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    func testJoinGroup() {
        isLoading = true
        status = "그룹 참여 중..."
        
        Task {
            do {
                let groupData = try await apiService.joinGroup(inviteCode: joinCode)
                await MainActor.run {
                    status = "✅ 그룹 참여 성공!\nGroupId: \(groupData.groupId)"
                    isLoading = false
                }
            } catch let error as APIError {
                await MainActor.run {
                    status = "❌ 실패: \(error.localizedDescription)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    status = "❌ 에러: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    func testGetNotes() {
        isLoading = true
        status = "참고사항 조회 중..."
        
        Task {
            do {
                guard let groupId = UserDefaults.standard.string(forKey: "groupId") else {
                    throw APIError.serverError(statusCode: 404, message: "그룹 ID 없습니다.")
                }
                let note = try await apiService.getNote(groupId: groupId)
                await MainActor.run {
                    status = "✅ 조회 성공!\n\(note ?? "<없음>")"
                    isLoading = false
                }
            } catch let error as APIError {
                await MainActor.run {
                    status = "❌ 실패: \(error.localizedDescription)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    status = "❌ 에러: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    APITestView()
}
