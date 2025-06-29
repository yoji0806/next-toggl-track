//
//  ContentView.swift
//  next-toggl-track
//
//  Created by 山本燿司 on 2025/06/20.
//

import SwiftUI
import Cocoa



struct ContentView: View {
    
    @StateObject var textInput = InputText()
    @StateObject private var fileOpenMonitor = FileOpenMonitor()
    
    @State var textIntermediate: String = "intermediate"
    @State var textOutput: String = "output"
    
    @State var focusMonitor: FocusMonitor?


    var body: some View {
        NavigationView{
            Sidebar()
            HStack {
                TextEditor(text: $textInput.data)
                //TextEditor(text: $textIntermediate)
                List(fileOpenMonitor.logs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(log.name).bold()
                        Text(log.path).font(.caption2).foregroundStyle(.secondary)
                        Text(log.openedAt.formatted()).font(.caption2)
                        if let snippet = log.content?.prefix(120) {
                            Text(snippet + (log.content!.count > 120 ? "…" : ""))
                                .font(.caption)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                TextEditor(text: $textOutput)
                Button{ logger.debug("button is clicked!") } label: {}
            }
        }
        .onAppear {
            logger.info("onApper!")
            textInput.appendLog(eventType: "app", content: "起動")
            
            let accessibilityEnabled = checkAccessibilityPermission()
            if !accessibilityEnabled {
                requestAccessibilityPermission()
            }
            
            let KeyboardMonitor = KeyboardMonitor(textInput: textInput)
            focusMonitor = FocusMonitor(textInput: textInput)

            KeyboardMonitor.startMonitoring()
            focusMonitor?.startMonitoring()
        }
    }
}



struct Sidebar: View {

    var body: some View {
        List {

        }
    }
}
