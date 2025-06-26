//
//  Utility.swift
//  next-toggl-track
//
//  Created by 山本燿司 on 2025/06/26.
//

import Foundation
import Cocoa





func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
    let isTrusted = AXIsProcessTrusted()    //AXIsProcessTrustedWithOptionsとの違いは、ポップアップの表示有無らしいが念のためこちらでも確認。
    
    // 設定 > セキュリティとプライバシー > 入力監視　は今回は必要ない。この権限はCGEventTapCreateなどで入力値の置き換えなどの介入を行う際に必要。
    
    print("AXIsProcessTrusted(): \(isTrusted)")
    print("accessibilityEnabled: \(accessibilityEnabled)")
    
    if accessibilityEnabled != isTrusted {
        logger.warning("AXIsProcessTrustedWithOptions と AXIsProcessTrusted の値が違います。確認してください。")
        logger.warning("AXIsProcessTrusted(): \(isTrusted)")
        logger.warning("accessibilityEnabled: \(accessibilityEnabled)")
    }
    
    return accessibilityEnabled
}


func requestAccessibilityPermission() {
    let alert = NSAlert()
    alert.messageText = "cat-urging-a-break-for-mac.app"
    alert.informativeText = "システム環境設定でcat-urging-a-break-for-mac.app（このダイアログの後ろにあるダイアログを参照）のアクセシビリティを有効にして、このアプリを再度起動する必要があります"
    alert.addButton(withTitle: "OK")
    alert.runModal()
    // 設定できたらアプリを再起動しないと意味ないためアプリ強制終了
    //NSApplication.shared.terminate(self)
}
