# PetLog iOS

PetLog is an iOS app for tracking your pet’s daily care with a clean MVVM architecture and SwiftUI-based UI. This repository contains the iOS frontend for the PetLog project.

## Overview
- SwiftUI app with MVVM structure
- Auth with Apple Sign In and Kakao Login
- Group-based shared pet profiles and activity logs
- Local/dev-friendly API configuration

## Requirements
- Xcode 15+
- iOS 17+ (uses new SwiftUI APIs like the new `onChange` signature)

## Project Structure
- `PetLog_iOS/`: Main app sources (views, models, services, theme, auth)
- `PetLog_iOS/README.md`: Detailed module documentation (architecture, folders)
- `PetLog_iOS.xcodeproj`: Xcode project
- `build/`: Derived artifacts (ignored by Git)

See `PetLog_iOS/README.md` for a full breakdown of MVVM layers and folders.

## Getting Started
- Open `PetLog_iOS.xcodeproj` in Xcode.
- Select the `PetLog_iOS` scheme and an iOS 17+ simulator or device.
- Run the app.

## Configuration
- API Base URL: `PetLog_iOS/Services/APIConfig.swift`
  - Simulator: `http://localhost:8080`
  - Device: `http://<your-mac-ip>:8080` (replace with your machine IP)
- Auth Setup: See `PetLog_iOS/Auth/SETUP_GUIDE.md` for Apple Sign In and Kakao configuration (keys, URL schemes, capabilities).

## Features
- Profile: Pet image, name, age, weight, gender
- Logs: Feeding, watering, poop with notes and checkers
- Notes: Shared reference notes for the group
- Group: Create, join via invite code, share invite link

## Development Notes
- Toggle API test UI: `showAPITestView` in `PetLog_iOS/Views/ContentView.swift`
- The app reads an auth token from `UserDefaults` for API calls; see services in `PetLog_iOS/Services/`.

## Contributing
Issues and PRs are welcome. Please avoid committing any secrets (Kakao keys, signing assets). See the auth setup guide for secure local configuration.
