//
//  next_toggl_trackApp.swift
//  next-toggl-track
//
//  Created by 山本燿司 on 2025/06/20.
//

import SwiftUI
import os

let logger = Logger(subsystem: "com.yojiyamamoto.next-toggl-track", category: "logging")
// level: [debug, info, notice, warning, error, fault]


@main
struct next_toggl_trackApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
