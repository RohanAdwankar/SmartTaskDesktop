//
//  TaskManagerApp.swift
//  SmartTaskDesktop
//
//  Created by Rohan Adwankar on 10/2/24.
//

import SwiftUI
import SwiftData

@main
struct TaskManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Task.self)
    }
}
