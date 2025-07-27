import Foundation
import SwiftUI


//TODO: かな入力で以下をキャプチャーできていないので、する。
//    - んsdasだあ　みたいな
//    -　数字（全角）
//    - ？＋〜〜などの記号
//    - ,、。. などの句読点
//TODO: カタカナモードの追加



class KeyInputParser: ObservableObject {
    @Published var buffer = ""
    @Published var log = ""
    @Published var inputMode: InputMode = .english

    /// Queue for storing log lines before writing to disk
    ///  InputText.swift にも同じものはある。それぞれ別のファイルとして保存される。
    var logQueue: [String] = []
    /// Text accumulated since the last flush
    private var unflushedText: String = ""
    private var timer: Timer?
    
    init() {
        // Start timer to flush logs to disk every 10 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Write keyboard input collected since the previous flush
            if !self.unflushedText.isEmpty {
                let text = self.unflushedText
                self.appendLog_parsed(eventType: "keyboard(scheduled batch)", content: text)
                self.unflushedText.removeAll()
            }

            self.flushLog_parsed()
        }
    }
    
    deinit {
        timer?.invalidate()
    }


    enum InputMode {
        case english
        case japanese
    }

    let romajiToKana: [String: String] = [
        // 母音
        "a": "あ", "i": "い", "u": "う", "e": "え", "o": "お",

        // 清音
        "ka": "か", "ki": "き", "ku": "く", "ke": "け", "ko": "こ",
        "sa": "さ", "si": "し", "su": "す", "se": "せ", "so": "そ",
                    "shi": "し",
        "ta": "た", "ti": "ち", "tu": "つ", "te": "て", "to": "と",
                    "chi": "ち", "tsu": "つ",
        "na": "な", "ni": "に", "nu": "ぬ", "ne": "ね", "no": "の",
        "ha": "は", "hi": "ひ", "fu": "ふ", "he": "へ", "ho": "ほ",
        "ma": "ま", "mi": "み", "mu": "む", "me": "め", "mo": "も",
        "ya": "や", "yu": "ゆ", "yo": "よ",
        "ra": "ら", "ri": "り", "ru": "る", "re": "れ", "ro": "ろ",
        "wa": "わ", "wo": "を",
        "nn": "ん",

        // 濁音
        "ga": "が", "gi": "ぎ", "gu": "ぐ", "ge": "げ", "go": "ご",
        "za": "ざ", "zi": "じ", "zu": "ず", "ze": "ぜ", "zo": "ぞ",
                    "ji": "じ",
        "da": "だ", "di": "ぢ", "du": "づ", "de": "で", "do": "ど",
        "ba": "ば", "bi": "び", "bu": "ぶ", "be": "べ", "bo": "ぼ",

        // 半濁音
        "pa": "ぱ", "pi": "ぴ", "pu": "ぷ", "pe": "ぺ", "po": "ぽ",

        // 拗音・合拗音
        "kya": "きゃ", "kyu": "きゅ", "kyo": "きょ",
        "gya": "ぎゃ", "gyu": "ぎゅ", "gyo": "ぎょ",
        "sha": "しゃ", "shu": "しゅ", "sho": "しょ",
        "ja": "じゃ", "ju": "じゅ", "jo": "じょ",
        "cha": "ちゃ", "chu": "ちゅ", "cho": "ちょ",
        "nya": "にゃ", "nyu": "にゅ", "nyo": "にょ",
        "hya": "ひゃ", "hyu": "ひゅ", "hyo": "ひょ",
        "bya": "びゃ", "byu": "びゅ", "byo": "びょ",
        "pya": "ぴゃ", "pyu": "ぴゅ", "pyo": "ぴょ",
        "mya": "みゃ", "myu": "みゅ", "myo": "みょ",
        "rya": "りゃ", "ryu": "りゅ", "ryo": "りょ",

        // 外来語用音
        "fa": "ふぁ", "fi": "ふぃ", "fe": "ふぇ", "fo": "ふぉ",
        "va": "ゔぁ", "vi": "ゔぃ", "vu": "ゔ", "ve": "ゔぇ", "vo": "ゔぉ",
        "wi": "うぃ", "we": "うぇ",
        "she": "しぇ", "je": "じぇ",
        "che": "ちぇ",

        // 小文字・促音
        "ltu": "っ", "xtu": "っ",
        "tta": "った", "tti": "っち", "ttu": "っつ", "tte": "って", "tto": "っと",
        "la": "ぁ", "xa": "ぁ",
        "li": "ぃ", "xi": "ぃ",
        "lu": "ぅ", "xu": "ぅ",
        "le": "ぇ", "xe": "ぇ",
        "lo": "ぉ", "xo": "ぉ",
    ]
    
    
    /// Flush queued logs to the daily file
    func flushLog_parsed() {
        guard !logQueue.isEmpty else {
            logger.debug("logQueueが空なので無視")
            return
        }

        logger.debug("logQueueが空じゃないので以下を実行！")

        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let fileName = df.string(from: Date()) + "_parsed" + ".txt"

        let fileManager = FileManager.default
        let directory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent("next-toggl-track")
        let fileURL = directory.appendingPathComponent(fileName)

        logger.debug("fileURL:\(fileURL)")

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
    
    
    /// Append a new log entry
    func appendLog_parsed(eventType: String, content: String) {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale.current
        df.timeZone = TimeZone.current
        let timestamp = df.string(from: Date())
        let line = "\(timestamp), \(eventType), \(content)"
        logQueue.append(line)
    }
    


    func appendEnglish(_ char: String) {
        buffer += char
        log += char
        unflushedText += char
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
                    unflushedText += kana
                    return
                }
            }
        }

//        if buffer.hasSuffix("nn") {
//            buffer.removeLast()
//            log += "ん"
//        }
    }

    func deleteLast() {
        if !buffer.isEmpty {
            buffer.removeLast()
        } else if !log.isEmpty {
            log.removeLast()
            if !unflushedText.isEmpty {
                unflushedText.removeLast()
            }
        }
    }

    func commitTab() {
        log += "⇥"
        unflushedText += "⇥"
        buffer = ""
    }

    func commitEnter() {
        log += "\n"
        unflushedText += "\n"
        buffer = ""
    }
    
    
    
}





import Cocoa
import Carbon

class KeyTapManager {
    private var eventTap: CFMachPort?

    func detectInitialInputMode() -> KeyInputParser.InputMode {
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

    func startTap(inputBuffer: KeyInputParser) {
        inputBuffer.inputMode = detectInitialInputMode()

        let mask = (1 << CGEventType.keyDown.rawValue)
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, _, cgEvent, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(cgEvent) }
                let inputBuffer = Unmanaged<KeyInputParser>.fromOpaque(refcon).takeUnretainedValue()

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





//
//private func handleEvent(_ event: NSEvent) {
//    let action = parseAction(from: event)
//    DispatchQueue.main.async {
//        self.textInput.data += action
//        self.textInput.appendLog(eventType: String(describing: event.type), content: action)
//    }
//}
