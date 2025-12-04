# PetLog iOS

PetLog is an iOS app for tracking your pet’s daily care. This repo contains the SwiftUI frontend built with MVVM and integrates Apple Sign In and Kakao Login.

## Overview
- SwiftUI app with MVVM structure
- Authentication: Kakao Login (Apple currently disabled)
- Group-based pet profile and shared activity logs (Dashboard)
- Local/dev-friendly API configuration (Info.plist + xcconfig overrides)

## Requirements
- Xcode 15+
- iOS 17+ (uses modern SwiftUI APIs like the new `onChange`)

## Project Structure
- `PetLog_iOS/`: App sources (Views, Models, Services, Theme, Auth)
- `PetLog_iOS/README.md`: Architecture and module-level docs
- `PetLog_iOS.xcodeproj`: Xcode project
- `build/`: Derived artifacts (ignored)

See `PetLog_iOS/README.md` for a detailed breakdown of folders and files.

## Getting Started
1. Open `PetLog_iOS.xcodeproj` in Xcode.
2. Select the `PetLog_iOS` scheme and an iOS 17+ simulator/device.
3. Configure API/auth (below) or use defaults for local dev.
4. Run.

## Configuration
- API base URL: resolved in `Services/APIConfig.swift` from `Info.plist` key `API_BASE_URL` if present; otherwise falls back to:
  - Simulator: `http://localhost:8080`
  - Device: `http://<your-mac-ip>:8080` (replace with your Mac’s LAN IP)
- Kakao SDK: see `PetLog_iOS/Auth/SETUP_GUIDE.md`. Required keys/schemes live in `Info.plist` (`KAKAO_NATIVE_APP_KEY`, `CFBundleURLTypes`).
- xcconfig (optional but recommended): `PetLog_iOS/Config.xcconfig` defines `KAKAO_NATIVE_APP_KEY` and `API_BASE_URL`. Point your target’s build settings to this file so `${KAKAO_NATIVE_APP_KEY}` resolves in Info.plist.

### Environments
- Production (deploy): `http://dev.petlog.site`
- Testing default: keep using localhost (above defaults) during the testing phase. To target production, set `API_BASE_URL` in your target’s Info.plist or via `Config.xcconfig`.

## Features
- Profile: pet image, name, age, weight, gender
- Logs: feeding, watering, poop with memo and checker
- Notes: shared notes per group
- Group: create, join via invite code, share invite link

## Development Notes
- Toggle API test view: set `showAPITestView` in `Views/ContentView.swift`.
- Auth tokens are stored in `UserDefaults` during development by `AuthAPIService`.
- Login flows:
  - Kakao: app/account login → backend exchange (`/api/auth/login/kakao`) → token persisted.
  - Apple: login then `login` or `register` fallback based on existence; token persisted.

## Contributing
Issues and PRs are welcome. Do not commit secrets (Kakao keys, signing assets). Follow `Auth/SETUP_GUIDE.md` for secure local setup.
