import Foundation
import Cocoa

class FocusMonitor {
    private var timer: Timer?
    private var previousAppName: String = ""
    private var previousURL: String = ""
    private var textInput: InputText

    init(textInput: InputText) {
        self.textInput = textInput
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkFrontApp()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
    }

    private func checkFrontApp() {
        guard let appName = NSWorkspace.shared.frontmostApplication?.localizedName else { return }

        if appName != previousAppName {
            previousAppName = appName
            textInput.appendLog(eventType: "focus", content: appName)
        }

        if appName == "Google Chrome" || appName == "Safari" {
            if let url = self.getActiveBrowserURL(appName: appName), url != previousURL {
                previousURL = url
                textInput.appendLog(eventType: "url", content: url)
            }
        }
    }

    private func getActiveBrowserURL(appName: String) -> String? {
        let scriptSource: String

        switch appName {
        case "Google Chrome":
            scriptSource = """
            tell application "Google Chrome"
                if (count of windows) > 0 and (count of tabs of front window) > 0 then
                    return URL of active tab of front window
                else
                    return ""
                end if
            end tell
            """
        case "Safari":
            scriptSource = """
            tell application "Safari"
                if (count of documents) > 0 then
                    return URL of front document
                else
                    return ""
                end if
            end tell
            """
        default:
            return nil
        }

        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let output = script.executeAndReturnError(&error)
            guard let result = output.stringValue else {
            return nil
                
        }
        return nil
    }
}
