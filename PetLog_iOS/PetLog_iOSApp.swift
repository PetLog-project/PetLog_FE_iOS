//
//  PetLog_iOSApp.swift
//  PetLog_iOS
//
//  Created by Dongha Ryu on 10/11/25.
//

import SwiftUI

@main
struct PetLog_iOSApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

