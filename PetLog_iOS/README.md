# PetLog iOS — App Architecture & Modules

This folder contains the iOS app source code organized with MVVM and SwiftUI.

## Project Structure
```
PetLog_iOS/
├── PetLog_iOSApp.swift        # App entry point (SwiftUI App)
├── Models/                    # Data models and view models
│   ├── HomeModels.swift       # Profile/Feeding/Watering/Poop, HomeResponse, etc.
│   └── HomeViewModel.swift    # Home screen state + business logic
├── Views/                     # Screens and containers
│   ├── ContentView.swift      # Tab shell, header, popups, modals
│   ├── HomeView/...           # Home screen
│   ├── DiaryView/...          # Diary tab
│   ├── CalendarView/...       # Calendar tab
│   └── NotesView/...          # Shared notes editor
├── Components/                # Reusable UI components (cards, headers, nav)
├── Services/                  # Networking and domain services
│   ├── APIClient.swift        # Lightweight HTTP client
│   ├── APIConfig.swift        # Base URL, endpoints, timeouts
│   ├── AuthAPIService.swift   # Auth-related requests (current user, token)
│   └── PetLogAPIService.swift # Groups, pet profile, notes, activity logs
├── Auth/                      # Authentication (Apple, Kakao)
│   ├── SETUP_GUIDE.md         # Step-by-step setup for Apple/Kakao
│   └── ...                    # ViewModel, Views, Kakao integration
├── Theme/                     # Design system (colors, typography, spacing)
└── Assets.xcassets/           # Images, icons, color assets
```

## Architecture (MVVM)
- Models: `Profile`, `Feeding`, `Watering`, `Poop`, API DTOs and envelopes.
- ViewModels: `HomeViewModel` handles fetching/mapping `HomeResponse` and UI state.
- Views: SwiftUI screens composed from components, bind to ViewModels for data.
- Services: API composition, mapping, and side-effects isolated from UI.

## Authentication
- Supports Apple Sign In and Kakao Login.
- Setup and required capabilities/keys: see `Auth/SETUP_GUIDE.md`.
- Tokens are stored in `UserDefaults` for development; consider Keychain for prod.

## Networking
- Base URL and environment: `Services/APIConfig.swift`
  - Simulator: `http://localhost:8080`
  - Device: `http://<your-mac-ip>:8080`
- Domain services:
  - `PetLogAPIService`: group profile, invite code, notes, activity logs (feeding/watering/poop), profile updates.
  - `AuthAPIService`: current user and group membership.

## Features
- Group: create, join via invite code, share invite.
- Pet Profile: image, name, age, weight, gender; update via modal.
- Activity Logs: feeding, watering, poop with memo and checker name.
- Notes: group reference notes (create/update/delete).
- Auth: Apple/Kakao login flow.

## Development Notes
- Toggle API test UI: set `showAPITestView` in `Views/ContentView.swift`.
- Debug buttons (in `#if DEBUG`) for quick group-create test and logout.
- Error strings and server codes bubble up from `APIError` in `APIConfig.swift`.

## Adding Features
- Model: add types under `Models/` and extend mapping in services or view models.
- Screen: add SwiftUI view under `Views/` and bind to a ViewModel.
- Component: place reusable UI in `Components/`.
- Service: add endpoints/methods under `Services/` and wire to ViewModels.

## Security
- Do not commit secrets (Kakao keys, signing assets). Follow `Auth/SETUP_GUIDE.md`.
