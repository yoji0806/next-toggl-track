import Foundation
import SwiftUI

class InputBuffer: ObservableObject {
    @Published var buffer = ""
    @Published var log = ""
    @Published var inputMode: InputMode = .english

    enum InputMode {
        case english
        case japanese
    }

    let romajiToKana: [String: String] = [
        "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",
        "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
        "sa": "さ", "shi": "し", "su": "す", "se": "せ", "so": "そ",
        "ta": "た", "chi": "ち", "tsu": "つ", "te": "て", "to": "と",
        "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
        "ha": "は", "hi": "ひ", "fu": "ふ", "he": "へ", "ho": "ほ",
        "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
        "ya": "や", "yu": "ゆ", "yo": "よ",
        "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
        "wa": "わ", "wo": "を", "n": "ん",
        "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
        "sha": "しゃ", "shu": "しゅ", "sho": "しょ",
        "cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ",
        "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
        "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
        "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
        "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",
        "ltu": "っ", "xtu": "っ",
        "la": "ぁ", "xa": "ぁ",
        "li": "ぃ", "xi": "ぃ",
        "lu": "ぅ", "xu": "ぅ",
        "le": "ぇ", "xe": "ぇ",
        "lo": "ぉ", "xo": "ぉ"
    ]

    func appendEnglish(_ char: String) {
        buffer += char
        log += char
    }

    func appendJapanese(_ char: String) {
        buffer += char.lowercased()

        for len in (1...3).reversed() {
            if buffer.count >= len {
                let start = buffer.index(buffer.endIndex, offsetBy: -len)
                let sub = String(buffer[start...])
                if let kana = romajiToKana[sub] {
                    buffer.removeSubrange(start...)
                    log += kana
                    return
                }
            }
        }

        if buffer.hasSuffix("nn") {
            buffer.removeLast()
            log += "ん"
        }
    }

    func deleteLast() {
        if !buffer.isEmpty {
            buffer.removeLast()
        } else if !log.isEmpty {
            log.removeLast()
        }
    }

    func commitTab() {
        log += "⇥"
        buffer = ""
    }

    func commitEnter() {
        log += "\n"
        buffer = ""
    }
}





import Cocoa
import Carbon

class KeyTapManager {
    private var eventTap: CFMachPort?

    func detectInitialInputMode() -> InputBuffer.InputMode {
        if let source = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue(),
           let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            let inputSourceID = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
            print("Initial Input Source ID: \(inputSourceID)")
            if inputSourceID.contains("Kotoeri") || inputSourceID.contains("Google") || inputSourceID.contains("ATOK") {
                return .japanese
            }
        }
        return .english
    }

    func startTap(inputBuffer: InputBuffer) {
        inputBuffer.inputMode = detectInitialInputMode()

        let mask = (1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, _, cgEvent, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(cgEvent) }
                let inputBuffer = Unmanaged<InputBuffer>.fromOpaque(refcon).takeUnretainedValue()

                let keyCode = cgEvent.getIntegerValueField(.keyboardEventKeycode)
                var cBuf: [UniChar] = Array(repeating: 0, count: 4)
                var cLen = 0
                cgEvent.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &cLen, unicodeString: &cBuf)
                let char = cLen > 0 ? String(utf16CodeUnits: cBuf, count: cLen) : ""

                DispatchQueue.main.async {
                    switch keyCode {
                    case 102: // 英数キー
                        inputBuffer.inputMode = .english
                        print("🔤 切替: 英数モード")
                    case 104: // かなキー
                        inputBuffer.inputMode = .japanese
                        print("🈂️ 切替: 日本語モード")
                    case 36: inputBuffer.commitEnter()
                    case 49:
                        if inputBuffer.inputMode == .english {
                            inputBuffer.appendEnglish(" ")
                        } else {
                            inputBuffer.appendJapanese(" ")
                        }
                    case 51: inputBuffer.deleteLast()
                    case 48: inputBuffer.commitTab()
                    default:
                        if inputBuffer.inputMode == .english {
                            inputBuffer.appendEnglish(char)
                        } else {
                            inputBuffer.appendJapanese(char)
                        }
                    }
                }

                return Unmanaged.passUnretained(cgEvent)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(inputBuffer).toOpaque())
        )

        if let tap = eventTap {
            let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    func stopTap() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
    }
}

