//
//  CodexTestingAppApp.swift
//  CodexTestingApp
//
//  Created by Francisco Jean on 15/09/25.
//

import SwiftUI
import UserNotifications

@main
struct CodexTestingAppApp: App {
    init() {
        // Configure notifications delegate early
        NotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
