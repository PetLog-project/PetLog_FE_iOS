# 인증 설정 가이드

## Apple Sign In 설정

### 1. Xcode 프로젝트 설정
1. Xcode에서 `PetLog_iOS.xcodeproj` 열기
2. 프로젝트 네비게이터에서 `PetLog_iOS` 프로젝트 선택
3. `Signing & Capabilities` 탭으로 이동
4. `+ Capability` 버튼 클릭
5. `Sign in with Apple` 추가

### 2. Apple Developer Portal 설정
1. [Apple Developer Portal](https://developer.apple.com/account/) 접속
2. `Certificates, Identifiers & Profiles` > `Identifiers` 선택
3. 앱의 Bundle ID 선택
4. `Sign in with Apple` capability 활성화
5. 설정 저장

## Kakao Login 설정

### 1. Kakao Developers 설정
1. [Kakao Developers](https://developers.kakao.com/) 접속
2. 애플리케이션 추가 또는 기존 앱 선택
3. `앱 설정` > `일반` 에서 **네이티브 앱 키(b67deab6b9788c78dd01292ae4c87a7e)** 확인 (필요)
4. `앱 설정` > `플랫폼` 에서 iOS 플랫폼 추가
   - Bundle ID: `com.yourcompany.PetLog-iOS` (실제 Bundle ID로 변경)
5. `제품 설정` > `카카오 로그인` 활성화

### 2. Package Dependencies 추가
1. Xcode에서 `File` > `Add Package Dependencies...` 선택
2. 다음 URL 입력: `https://github.com/kakao/kakao-ios-sdk`
3. 버전: `2.20.0` 이상
4. 필요한 패키지 선택:
   - `KakaoSDKAuth`
   - `KakaoSDKUser`
   - `KakaoSDKCommon`

### 3. Info.plist 설정
Xcode에서 Info.plist에 다음 항목 추가:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>kakao{YOUR_NATIVE_APP_KEY}</string>
        </array>
    </dict>
</array>

<key>KAKAO_APP_KEY</key>
<string>{YOUR_NATIVE_APP_KEY}</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>kakaokompassauth</string>
    <string>kakaolink</string>
    <string>kakao{YOUR_NATIVE_APP_KEY}</string>
</array>
```

**주의**: `{YOUR_NATIVE_APP_KEY}`를 실제 카카오 네이티브 앱 키로 교체하세요.

### 4. AuthViewModel 업데이트
`Auth/Model/AuthViewModel.swift`의 `loginWithKakao()` 메서드를 다음과 같이 업데이트:

```swift
import KakaoSDKAuth
import KakaoSDKUser

func loginWithKakao() {
    isLoading = true
    errorMessage = nil
    
    // 카카오톡 설치 여부 확인
    if UserApi.isKakaoTalkLoginAvailable() {
        // 카카오톡으로 로그인
        UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "카카오 로그인 실패: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            // 사용자 정보 가져오기
            self.fetchKakaoUserInfo()
        }
    } else {
        // 카카오 계정으로 로그인
        UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = "카카오 로그인 실패: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            // 사용자 정보 가져오기
            self.fetchKakaoUserInfo()
        }
    }
}

private func fetchKakaoUserInfo() {
    UserApi.shared.me { [weak self] (user, error) in
        guard let self = self else { return }
        
        if let error = error {
            self.errorMessage = "사용자 정보 조회 실패: \(error.localizedDescription)"
            self.isLoading = false
            return
        }
        
        if let user = user {
            self.userIdentifier = "\(user.id ?? 0)"
            self.userEmail = user.kakaoAccount?.email
            self.isAuthenticated = true
            
            // 저장
            UserDefaults.standard.set(self.userIdentifier, forKey: "userId")
            if let email = self.userEmail {
                UserDefaults.standard.set(email, forKey: "userEmail")
            }
        }
        
        self.isLoading = false
    }
}
```

### 5. AppDelegate에 Kakao SDK 초기화 추가

`PetLog_iOSApp.swift`에 다음 코드 추가:

```swift
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct PetLog_iOSApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Kakao SDK 초기화
        if let appKey = Bundle.main.object(forInfoDictionaryKey: "KAKAO_APP_KEY") as? String {
            KakaoSDK.initSDK(appKey: appKey)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
                    .onOpenURL { url in
                        if AuthApi.isKakaoTalkLoginUrl(url) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
```

## 테스트 방법

1. **Apple Sign In 테스트**
   - 시뮬레이터에서 `Settings` > `Apple ID` 로그인 필요
   - 실제 기기에서 테스트 권장

2. **Kakao Login 테스트**
   - 실제 기기에 카카오톡 설치 후 테스트
   - 시뮬레이터에서는 카카오 계정 로그인만 가능

## 보안 주의사항

- **절대 GitHub에 커밋하지 말 것**:
  - Kakao Native App Key
  - Apple Team ID / Signing Certificate
  
- UserDefaults 대신 Keychain 사용 권장 (프로덕션)
- 백엔드 API와 연동 시 토큰 검증 필수
