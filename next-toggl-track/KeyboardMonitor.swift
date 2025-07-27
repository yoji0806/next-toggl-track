import Cocoa
//KeyboardMonitor that recognizes keyboard + mousepad input


class KeyboardMonitor: NSObject {

    var textInput: InputText

    private var tap: CFMachPort?
    private var runLoopSrc: CFRunLoopSource?

    init(textInput: InputText) {
        self.textInput = textInput
    }

    func startMonitoring() {
        // Start mouse event monitor
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: handleMouseEvent)

        // Monitor keyDown and textInput via CGEventTap to capture committed strings
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.textInput.rawValue)

        tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, cgEvent, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(cgEvent) }
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleCGEvent(type: type, cgEvent: cgEvent)
                return Unmanaged.passUnretained(cgEvent)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        guard let tap = tap else { return }
        runLoopSrc = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSrc, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func handleMouseEvent(_ event: NSEvent) {
        let action = parseAction(from: event)
        DispatchQueue.main.async {
            self.textInput.data += action
            self.textInput.appendLog(eventType: String(describing: event.type), content: action)
        }
    }

    private func handleCGEvent(type: CGEventType, cgEvent: CGEvent) {
        switch type {
        case .textInput:
            var length: UniCharCount = 0
            var chars: [UniChar] = Array(repeating: 0, count: 256)
            CGEventKeyboardGetUnicodeString(cgEvent, 256, &length, &chars)
            if length > 0 {
                let str = String(utf16CodeUnits: chars, count: Int(length))
                DispatchQueue.main.async {
                    self.textInput.data += str
                    self.textInput.appendLog(eventType: "textInput", content: str)
                }
            }
        case .keyDown:
            if let event = NSEvent(cgEvent: cgEvent) {
                let action = parseAction(from: event)
                DispatchQueue.main.async {
                    self.textInput.data += action
                    self.textInput.appendLog(eventType: "keyDown", content: action)
                }
            }
        default:
            break
        }
    }

    private func parseAction(from event: NSEvent) -> String {
        var action = String()

        if event.type == .leftMouseDown {
            action = "【l_click】"
        } else if event.type == .rightMouseDown {
            action = "【r_click】"
        } else if event.type == .keyDown {
            switch event.modifierFlags.rawValue {
            case 256:   //character or Enter or Space
                switch event.keyCode {
                case 36: action = "↵"   //Enter
                case 48: action = "⇥"   //Tab
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
        } else {
            action = "unknown"
        }
        logger.debug("\(action)")
        return action
    }
}
