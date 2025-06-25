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


class InputText: ObservableObject {
    @Published var data: String = "input"

    /// Queue for storing log lines before writing to disk
    var logQueue: [String] = []
    private var timer: Timer?

    init() {
        // Start timer to flush logs to disk every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.flushLog()
        }
    }

    deinit {
        timer?.invalidate()
    }

    /// Append a new log entry
    func appendLog(eventType: String, content: String) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale.current
        df.timeZone = TimeZone.current
        let timestamp = df.string(from: Date())
        let line = "\(timestamp), \(eventType), \(content)"
        logQueue.append(line)
    }

    /// Flush queued logs to the daily file
    func flushLog() {
        guard !logQueue.isEmpty else {
            print("logQueueが空なので無視")
            return
        }
        
        print("logQueueが空じゃないので以下を実行！")

        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let fileName = df.string(from: Date()) + ".txt"

        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = directory.appendingPathComponent(fileName)
        
        print("fileURL:\(fileURL)")

        let text = logQueue.joined(separator: "\n") + "\n"
        logQueue.removeAll()

        if let data = text.data(using: .utf8) {
            if fileManager.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    try? handle.close()
                }
            } else {
                try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                try? data.write(to: fileURL)
            }
        }
    }
}


class KeyboardMonitor: NSObject {
    
    var textInput: InputText
    
    init(textInput: InputText) {
        self.textInput = textInput
    }
    
    func startMonitoring() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown], handler: { (event: NSEvent) in
    
            var action = String()

            if event.type == .leftMouseDown {
                action = "【l_click】"
                print("Click: left")
            } else if event.type == .rightMouseDown {
                action = "【r_click】"
                print("Click: right")
            } else if event.type == .keyDown {

                switch event.modifierFlags.rawValue {
                    case 256:   //character or Enter or Space
                        switch event.keyCode {
                        case 36: action = "↵"   //Enter
                        case 48: action = "⇥"
                        case 49: action = "␣"   //Space
                        case 51: action = "⌫"   //Delete
                        case 53: action = "⎋"    //Escape(esc)
                        case 102: action = "【英数】"   //英数
                        case 104: action = "【かな】"   //かな
                        default: action = event.characters ?? ""  //normal key
                        }
                    case 65792:     //Shift(locked) + character
                        switch event.keyCode {
                        case 36: action = "↵"   //Enter
                        case 48: action = "⇥"
                        case 49: action = "␣"   //Space
                        case 51: action = "⌫"   //Delete
                        case 53: action = "⎋"    //Escape(esc)
                        case 102: action = "【英数】"   //英数
                        case 104: action = "【かな】"   //かな
                        default: action = event.characters ?? ""  //normal key
                        }
                        //TODO: 他に、以下のすべてのキー入力のFlag番号が変わるが、あまり入力されないだろうから、一旦そのまま。
                    case 131330: action = "\(event.characters ?? "")"  //Shift + character
                    case 262401: action = "【Command】\(event.characters ?? "")" //control + character
                    case 524576: action = "\(event.characters ?? "")"    //Option + character
                    case 1048840: action = "⌘\(event.characters ?? "")"  //Command(L) + character
                    case 1048848: action = "⌘\(event.characters ?? "")"  //Command(R) + character
                    case 1179914: action = "⌘\(event.characters ?? "")"   //Command(L) + Shift + character
                    case 1179922: action = "⌘\(event.characters ?? "")"   //Command(R) + Shift + character
                    case 1573160: action = "⌘\(event.characters ?? "")"   //Command(L) + option + character
                    case 1573168: action = "⌘\(event.characters ?? "")"   //Command(R) + option + character
                    case 8388864:   //fn
                        switch event.specialKey?.rawValue {
                        case nil: action = "🌐\(event.characters ?? "")"  //fn + character
                        case 63236: action = "【F1】"
                        case 63237: action = "【F2】"
                        case 63238: action = "【F3】"
                        case 63239: action = "【F4】"
                        case 63240: action = "【F5】"
                        case 63241: action = "【F6】"
                        case 63242: action = "【F7】"
                        case 63243: action = "【F8】"
                        case 63244: action = "【F9】"
                        case 63245: action = "【F10】"
                        case 63246: action = "【F11】"
                        case 63247: action = "【F12】"
                        default: action = "【unknown fn】"
                        }
                    case 10486016:  //arrow
                        switch event.keyCode {
                        case 123: action = "←"
                        case 124: action = "→"
                        case 125: action = "↓"
                        case 126: action = "↑"
                        default: action = event.characters ?? ""
                        }
        
                    default: action = "【unknown Flags char:\(event.characters ?? "") keycode:\(event.keyCode)】 specialKey:\(event.specialKey?.rawValue)"
                }
                print("Input: \(event.characters)  KeyCode:\(event.keyCode)   Flag:\(event.modifierFlags.rawValue) SpecialKey:\(event.specialKey?.rawValue)")

            } else {
                action = "unknown"
            }
            
            DispatchQueue.main.async {
                self.textInput.data += action
                self.textInput.appendLog(eventType: String(describing: event.type), content: action)
            }
        
        })
    }
}

class FocusMonitor: NSObject {

    var textInput: InputText

    init(textInput: InputText) {
        self.textInput = textInput
    }

    func startMonitoring() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let name = app.localizedName ?? "unknown"
                print("Focus: \(name)")
                
                DispatchQueue.main.async {
                    self?.textInput.data += "【focus: \(name)】"
                    self?.textInput.appendLog(eventType: "focus", content: name)
                }
            }
        }
    }
}
