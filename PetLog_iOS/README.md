# PetLog iOS - MVVM Architecture

## 📁 Project Structure

```
PetLog_iOS/
├── Models/                 # Data Models & ViewModels
│   ├── HomeModels 2.swift     # Pet data models (Profile, Feeding, etc.)
│   ├── HomeModels.swift       # Additional model definitions
│   └── HomeViewModel.swift    # Home screen ViewModel
├── Views/                  # SwiftUI Views
│   ├── PetLog_iOSApp.swift   # App entry point
│   └── ContentView.swift     # Home screen view
├── Components/            # Reusable UI Components
│   └── Components.swift      # ProfileCard, InfoCard, etc.
├── Services/             # Business Logic & Data Services
│   └── BaseService.swift     # Generic ViewModel base & Network services
├── Theme/                # Styling & Design System
│   └── Theme.swift          # Colors, fonts, spacing constants
└── Assets.xcassets/      # Images, icons, colors
```

## 🏗️ Architecture Pattern: MVVM

### **Models** (`/Models/`)
- **Data Models**: `Profile`, `Feeding`, `Watering`, `Poop` structs
- **Response Models**: `HomeResponse` for API responses
- **ViewModels**: Business logic and data management (`HomeViewModel`)

### **Views** (`/Views/`)
- **SwiftUI Views**: User interface components
- **App Entry**: Main app configuration
- **Screen Views**: Individual screen implementations

### **Components** (`/Components/`)
- **Reusable UI**: `ProfileCard`, `InfoCard`, `CardView`
- **Utilities**: `DateFormatters` for consistent date formatting

### **Services** (`/Services/`)
- **Base Services**: `BaseViewModel<T>` for generic data handling
- **Network Layer**: `NetworkService` protocol and implementations
- **Data Processing**: JSON decoding, API communication

### **Theme** (`/Theme/`)
- **Design System**: Centralized styling constants
- **Typography**: Font definitions
- **Colors**: App color palette
- **Spacing**: Layout constants

## 🚀 Benefits

1. **Separation of Concerns**: Each folder has a specific responsibility
2. **Reusability**: Components and services can be easily reused
3. **Maintainability**: Easy to locate and modify specific functionality
4. **Scalability**: Simple to add new features following the same pattern
5. **Testability**: Clear boundaries make unit testing easier

## 📝 Adding New Features

1. **New Data Type**: Add model to `/Models/`, create ViewModel inheriting from `BaseViewModel<T>`
2. **New Screen**: Add view to `/Views/`, connect to appropriate ViewModel
3. **New Component**: Add reusable UI to `/Components/`
4. **New Service**: Add business logic to `/Services/`
5. **Styling Changes**: Modify `/Theme/Theme.swift`