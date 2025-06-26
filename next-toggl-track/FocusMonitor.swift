import Cocoa

// FocusMonitor that detects the focus and

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
                logger.debug("Focus: \(name)")

                DispatchQueue.main.async {
                    self?.textInput.data += "【focus: \(name)】"
                    self?.textInput.appendLog(eventType: "focus", content: name)
                }
            }
        }
    }
}
