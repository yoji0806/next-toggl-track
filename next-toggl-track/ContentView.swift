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
    @State var textIntermediate: String = "intermediate"
    @State var textOutput: String = "output"
    
    @State var focusMonitor: FocusMonitor?


    var body: some View {
        NavigationView{
            Sidebar()
            HStack {
                TextEditor(text: $textInput.data)
                TextEditor(text: $textIntermediate)
                TextEditor(text: $textOutput)
                Button{ print("button is clicked!") } label: {}
            }
        }
        .onAppear {
            print("onApper!")
            textInput.appendLog(eventType: "app", content: "起動")
            
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
            let accessEnabled = AXIsProcessTrustedWithOptions(options)
            let isTrusted = AXIsProcessTrusted()
            
            // 設定 > セキュリティとプライバシー > 入力監視　は今回は必要ない。この権限はCGEventTapCreateなどで入力値の置き換えや
            
            print("AXIsProcessTrusted(): \(isTrusted)")
            print("accessEnabled: \(accessEnabled)")
            
            if !accessEnabled {
               let alert = NSAlert()
               alert.messageText = "cat-urging-a-break-for-mac.app"
               alert.informativeText = "システム環境設定でcat-urging-a-break-for-mac.app（このダイアログの後ろにあるダイアログを参照）のアクセシビリティを有効にして、このアプリを再度起動する必要があります"
               alert.addButton(withTitle: "OK")
               alert.runModal()
               // 設定できたらアプリを再起動しないと意味ないためアプリ強制終了
               //NSApplication.shared.terminate(self)
            }
            
            // ContentViewが表示されるときにKeyboardMonitorを初期化する
            let monitor = KeyboardMonitor(textInput: textInput)
            monitor.startMonitoring()

            // フォーカス変更を監視する
            focusMonitor = FocusMonitor(textInput: textInput)
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
