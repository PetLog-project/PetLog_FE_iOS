# PetLog iOS — App Architecture & Modules

This folder contains the iOS app source organized with MVVM and SwiftUI.

## Project Structure
```
PetLog_iOS/
├── PetLog_iOSApp.swift          # App entry point (SwiftUI App)
├── Config.xcconfig              # Build-time vars (API_BASE_URL, KAKAO_NATIVE_APP_KEY)
├── Models/                      # Data models and view models
│   ├── PetDashboardModels.swift # Profile/Feeding/Watering/Poop, PetDashboardResponse mapping
│   └── PetDashboardViewModel.swift # Dashboard (Home) screen state + business logic
├── Views/                       # Screens and containers
│   ├── ContentView.swift        # Tab shell, header, popups, modals
│   ├── Home/HomeView.swift      # Home screen
│   ├── Diary/DiaryView.swift    # Diary tab
│   ├── Calendar/CalendarView.swift # Calendar tab
│   ├── Profile/ProfileView.swift   # Profile tab (WIP)
│   └── Settings/JoinGroupView.swift # Join by invite code modal
├── Components/                  # Reusable UI (cards, headers, bottom nav, popups)
│   ├── Components.swift         # Figma-based cards, header, bottom navigation
│   ├── ActivityCardViews.swift  # Swipeable activity cards
│   └── PopupViews.swift         # Share invite / profile edit / check modals
├── Services/                    # Networking and domain services
│   ├── APIClient.swift          # Lightweight HTTP client wrapper
│   ├── APIConfig.swift          # Base URL, endpoints, timeouts, APIError
│   ├── AuthAPIService.swift     # Auth: login/register/kakao/refresh/withdraw
│   └── PetLogAPIService.swift   # Groups, pet profile, notes, logs
├── Auth/                        # Authentication (Apple, Kakao)
│   ├── Model/AuthViewModel.swift   # Login state + flows (Apple/Kakao/Test)
│   ├── View/LoginView.swift        # Login screen (brand-aligned Kakao button)
│   ├── View/SignupView.swift       # Optional signup details UI (Apple)
│   ├── Kakao/KakaoAuthProvider.swift # KakaoTalk/Account login bridge
│   └── SETUP_GUIDE.md              # Step-by-step setup for Apple/Kakao
├── Theme/                       # Design system (colors, typography, spacing)
└── Assets.xcassets/             # Images, icons, color assets
```

## Architecture (MVVM)
- Models: `Profile`, `Feeding`, `Watering`, `Poop`, DTOs, envelopes.
- ViewModels: `PetDashboardViewModel` fetches/maps `PetDashboardResponse` and exposes UI state.
- Views: SwiftUI screens composed from components, bound via `@StateObject`/`@ObservedObject`.
- Services: API composition and side-effects isolated from UI.

## Authentication
- Providers: Kakao Login (Apple Sign In currently disabled).
- Kakao flow: native app/web → backend exchange (`/api/auth/login/kakao`) → save access/refresh tokens.
- Storage: dev uses `UserDefaults` for `authToken`/`refreshToken` and basic user info (consider Keychain for prod).
- Setup: Kakao capabilities/keys/URL schemes in `Auth/SETUP_GUIDE.md`.

## Networking
- Base URL resolution (`Services/APIConfig.swift`):
  - Uses `Info.plist` key `API_BASE_URL` when set (via build settings or xcconfig).
  - Falls back to `http://localhost:8080` (simulator) or `http://<your-mac-ip>:8080` (device).
- Domain services:
  - `PetLogAPIService`: group profile, invite code, notes, logs, profile update.
  - `AuthAPIService`: login/register/apple/kakao, refresh, withdraw, current user.

### Environments
- Production (deploy): `http://dev.petlog.site`
- Testing default: keep using localhost/device defaults above during testing. To target production, set `API_BASE_URL` in Info.plist or provide it via `Config.xcconfig`.

## UI/Theme
- `Theme/Theme.swift` centralizes colors/typography/spacing.
- Kakao brand colors are defined (`kakaoYellow`, `kakaoBlack`) and used in `LoginView`.
- Uses system fonts with Pretendard sizing; supply font files to switch to Pretendard.

## Features
- Group: create, join via invite code, share invite.
- Pet Profile: image, name, age, weight, gender; update via modal.
- Activity Logs: feeding, watering, poop with memo and checker name.
- Notes: group reference notes (create/update/delete).
- Auth: Apple/Kakao login flow + test login in DEBUG.

## Development Notes
- Toggle API test UI: set `showAPITestView` in `Views/ContentView.swift`.
- Debug buttons (`#if DEBUG`) for group-create test and logout in `ContentView`.
- Error strings and server codes bubble from `APIError` in `APIConfig.swift`.

## Build/Config Tips
- Use `Config.xcconfig` to define `KAKAO_NATIVE_APP_KEY` and `API_BASE_URL`, then assign it in the target’s Build Settings so `${KAKAO_NATIVE_APP_KEY}` resolves in `Info.plist`.
- `PetLog_iOSApp` also derives Kakao key from the URL scheme (`kakao{APP_KEY}`) if the `KAKAO_NATIVE_APP_KEY` placeholder isn’t resolved.

## Security
- Do not commit secrets (Kakao keys, signing assets). Follow `Auth/SETUP_GUIDE.md`.
