import Foundation
import Cocoa

class FocusMonitor {
    private var timer: Timer?
    private var previousAppName: String = ""
    private var previousURL: String = ""
    private var textInput: InputText
    private var textURL: InputText
    private var textInput_parsed: KeyInputParser
    
    init(textInput: InputText, textURL: InputText, textInput_parsed: KeyInputParser) {
        self.textInput = textInput
        self.textURL = textURL
        self.textInput_parsed = textInput_parsed
    }
    
    func startMonitoring() {
        
        //フォーカスが切り替わったタイミングでアプリ名を取得するobserverを追加
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                let name = app.localizedName ?? "unknown"
                logger.debug("Focus: \(name)")
                
                DispatchQueue.main.async {
                    self?.textInput.data += "\n\n============================\n"
                    self?.textInput.data += "【focus: \(name)】"
                    self?.textInput.appendLog(eventType: "focus", content: name)
                    self?.textInput_parsed.appendLog_parsed(eventType: "focus", content: name)
                }
            }
        }
        
        // 1秒ごとのタイマーを開始
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkFrontApp()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
    }
    
    private func checkFrontApp() {
        guard let appName = NSWorkspace.shared.frontmostApplication?.localizedName else { return }
        
        
        if appName == "Google Chrome" || appName == "Safari" {
            getActiveBrowserURL(appName: appName) { url in
                if let url = url, url != self.previousURL {
                    
                    let df = DateFormatter()
                    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    df.locale = Locale.current
                    df.timeZone = TimeZone.current
                    let timestamp = df.string(from: Date())
                    
                    logger.debug("URL detected: \(url)")
                    self.previousURL = url
                    self.textInput.appendLog(eventType: "url", content: url)
                    self.textInput_parsed.appendLog_parsed(eventType: "", content: "") //1行開けるために　TODO: 本来はそのための関数やオプションをつけてもいいかも。
                    self.textInput_parsed.appendLog_parsed(eventType: "url", content: url)
                    self.textInput.data += "\n-------------------\n\(url)\n\n"
                    self.textURL.data += "\(timestamp): \n\(url)\n\n"
                }
            }
        }
        
    }
    
    private func getActiveBrowserURL(appName: String, completion: @escaping (String?) -> Void){
                
                
        let scriptSource: String
        
        switch appName {
        case "Google Chrome":
            scriptSource = """
            tell application "Google Chrome"
                if (count of windows) > 0 and (count of tabs of front window) > 0 then
                    return URL of active tab of front window
                else
                    return  ("" & "nannmoarahen")
                end if
            end tell
            """
        case "Safari":
            scriptSource = """
            tell application "Safari"
                if (count of documents) > 0 then
                    return URL of front document
                else
                    return ("" & "nannmoarahen")
                end if
            end tell
            """
        default:
            scriptSource = "unknown"
        }
        
        
        var error: NSDictionary?
        
        guard let script = NSAppleScript(source: scriptSource) else {
                completion(nil)
                return
        }

        
        DispatchQueue.global(qos: .background).async{
            let output = script.executeAndReturnError(&error)
            let result = output.stringValue
            completion(result)
        }
        
    }
}
