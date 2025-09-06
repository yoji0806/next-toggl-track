import Foundation
import SwiftUI
import Combine

// MARK: - メインのデータモデル
/// アプリ全体のデータを管理するクラス
class ActivityDataModel: ObservableObject {
    // MARK: - 4列のデータ（元の構成を維持）
    @Published var activityLog: String = ""           // 左列: キーボード入力の生情報
    @Published var contextualText: String = ""        // 中列: IMEを通したキーボード入力
    @Published var fileWebHistory: [FileOpenLog] = [] // 右列: ファイル操作
    @Published var urlLog: String = ""                // 右右列: URLログ
    
    // MARK: - 内部データソース（既存のクラスとの互換性のため）
    private let inputText = InputText()
    private let keyInputParser = KeyInputParser()
    private let urlText = InputText()  // URLログ用
    private var fileOpenMonitor: FileOpenMonitor?
    
    init() {
        setupFileMonitor()
        setupDataBinding()
    }
    
    private func setupFileMonitor() {
        fileOpenMonitor = FileOpenMonitor(
            textInput: inputText,
            textInput_parsed: keyInputParser
        )
        
        // ファイルモニターの更新を監視
        fileOpenMonitor?.$logs
            .receive(on: DispatchQueue.main)
            .assign(to: &$fileWebHistory)
    }
    
    private func setupDataBinding() {
        // 各データソースの更新を監視して、表示用プロパティを更新
        inputText.$data
            .receive(on: DispatchQueue.main)
            .assign(to: &$activityLog)
        
        keyInputParser.$log
            .receive(on: DispatchQueue.main)
            .assign(to: &$contextualText)
        
        urlText.$data
            .receive(on: DispatchQueue.main)
            .assign(to: &$urlLog)
    }
    
    // MARK: - アクティビティログ関連
    func appendActivityLog(eventType: String, content: String) {
        inputText.appendLog(eventType: eventType, content: content)
    }
    
    // MARK: - コンテキストテキスト関連
    func appendContextualText(eventType: String, content: String) {
        keyInputParser.appendLog_parsed(eventType: eventType, content: content)
    }
    
    // MARK: - URLログ関連
    func appendURLLog(eventType: String, content: String) {
        urlText.appendLog(eventType: eventType, content: content)
    }
    
    // MARK: - ファイル履歴関連
    func getFileHistory() -> [FileOpenLog] {
        return fileWebHistory
    }
    
    // MARK: - 既存のクラスへのアクセス（互換性のため）
    var inputTextInstance: InputText { inputText }
    var keyInputParserInstance: KeyInputParser { keyInputParser }
    var urlTextInstance: InputText { urlText }
    var fileOpenMonitorInstance: FileOpenMonitor? { fileOpenMonitor }
}

 