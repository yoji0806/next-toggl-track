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
}


class KeyboardMonitor: NSObject {
    
    var textInput: InputText
    
    init(textInput: InputText) {
        self.textInput = textInput
    }
    
    func startMonitoring() {
        NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown], handler: { (event: NSEvent) in
    
            var pressedKey = String()
            
            switch event.modifierFlags.rawValue {
                case 256:   //character or Enter or Space
                    switch event.keyCode {
                    case 36: pressedKey = "↵"   //Enter
                    case 48: pressedKey = "⇥"
                    case 49: pressedKey = "␣"   //Space
                    case 51: pressedKey = "⌫"   //Delete
                    case 53: pressedKey = "⎋"    //Escape(esc)
                    case 102: pressedKey = "【英数】"   //英数
                    case 104: pressedKey = "【かな】"   //かな
                    default: pressedKey = event.characters ?? ""  //normal key
                    }
                case 65792:     //Shift(locked) + character
                    switch event.keyCode {
                    case 36: pressedKey = "↵"   //Enter
                    case 48: pressedKey = "⇥"
                    case 49: pressedKey = "␣"   //Space
                    case 51: pressedKey = "⌫"   //Delete
                    case 53: pressedKey = "⎋"    //Escape(esc)
                    case 102: pressedKey = "【英数】"   //英数
                    case 104: pressedKey = "【かな】"   //かな
                    default: pressedKey = event.characters ?? ""  //normal key
                    }
                    //TODO: 他に、以下のすべてのキー入力のFlag番号が変わるが、あまり入力されないだろうから、一旦そのまま。
                case 131330: pressedKey = "\(event.characters ?? "")"  //Shift + character
                case 262401: pressedKey = "【Command】\(event.characters ?? "")" //control + character
                case 524576: pressedKey = "\(event.characters ?? "")"    //Option + character
                case 1048840: pressedKey = "⌘\(event.characters ?? "")"  //Command(L) + character
                case 1048848: pressedKey = "⌘\(event.characters ?? "")"  //Command(R) + character
                case 1179914: pressedKey = "⌘\(event.characters ?? "")"   //Command(L) + Shift + character
                case 1179922: pressedKey = "⌘\(event.characters ?? "")"   //Command(R) + Shift + character
                case 1573160: pressedKey = "⌘\(event.characters ?? "")"   //Command(L) + option + character
                case 1573168: pressedKey = "⌘\(event.characters ?? "")"   //Command(R) + option + character
                case 8388864:   //fn
                    switch event.specialKey?.rawValue {
                    case nil: pressedKey = "🌐\(event.characters ?? "")"  //fn + character
                    case 63236: pressedKey = "【F1】"
                    case 63237: pressedKey = "【F2】"
                    case 63238: pressedKey = "【F3】"
                    case 63239: pressedKey = "【F4】"
                    case 63240: pressedKey = "【F5】"
                    case 63241: pressedKey = "【F6】"
                    case 63242: pressedKey = "【F7】"
                    case 63243: pressedKey = "【F8】"
                    case 63244: pressedKey = "【F9】"
                    case 63245: pressedKey = "【F10】"
                    case 63246: pressedKey = "【F11】"
                    case 63247: pressedKey = "【F12】"
                    default: pressedKey = "【unknown fn】"
                    }
                case 10486016:  //arrow
                    switch event.keyCode {
                    case 123: pressedKey = "←"
                    case 124: pressedKey = "→"
                    case 125: pressedKey = "↓"
                    case 126: pressedKey = "↑"
                    default: pressedKey = event.characters ?? ""
                    }
     
                default: pressedKey = "【unknown Flags char:\(event.characters ?? "") keycode:\(event.keyCode)】 specialKey:\(event.specialKey?.rawValue)"
            }
    
            
            print("Input: \(event.characters)  KeyCode:\(event.keyCode)   Flag:\(event.modifierFlags.rawValue) SpecialKey:\(event.specialKey?.rawValue)")
            DispatchQueue.main.async {
                self.textInput.data += pressedKey
            }
        
        })
    }
}
