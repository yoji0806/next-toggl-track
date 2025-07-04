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
    @StateObject var textParsedKeyBaord = InputText()
    @StateObject var textURL = InputText()
    @StateObject var textInput_parsed = KeyInputParser()

    let keyTapManager = KeyTapManager()
    
    @State var focusMonitor: FocusMonitor?
    @State var fileOpenMonitor: FileOpenMonitor?


    var body: some View {
        NavigationView{
            Sidebar()
            HStack {
                TextEditor(text: $textInput.data)
                    .disabled(true)
                TextEditor(text: $textInput_parsed.log)
                    .disabled(true)
                List(fileOpenMonitor?.logs ?? []) { log in
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
                TextEditor(text: $textURL.data)
                    .disabled(true)
                //Button{ logger.debug("button is clicked!") } label: {}
            }
        }
        .onAppear {
            logger.info("onApper!")
            textInput.appendLog(eventType: "app", content: "起動")
            textInput_parsed.appendLog_parsed(eventType: "app", content: "起動")
            
            let accessibilityEnabled = checkAccessibilityPermission()
            if !accessibilityEnabled {
                requestAccessibilityPermission()
            }
            
            let KeyboardMonitor = KeyboardMonitor(textInput: textInput)
            focusMonitor = FocusMonitor(textInput: textInput, textURL: textURL, textInput_parsed: textInput_parsed)
            fileOpenMonitor = FileOpenMonitor(textInput: textInput, textInput_parsed: textInput_parsed)

            KeyboardMonitor.startMonitoring()
            focusMonitor?.startMonitoring()
            
            keyTapManager.startTap(inputBuffer: textInput_parsed)

        }
    }
}



struct Sidebar: View {

    var body: some View {
        List {

        }
    }
}
