//
//  FileOpenMonitor.swift
//  next-toggl-track
//
//  Created by 山本燿司 on 2025/06/29.
//

import Foundation
import SwiftUI
import Combine
import Cocoa

/// ログ 1 件
struct FileOpenLog: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    let content: String?
    let openedAt: Date
}

/// Spotlight 監視クラス
final class FileOpenMonitor: ObservableObject {
    @Published var logs: [FileOpenLog] = []

    private let query = NSMetadataQuery()
    private var lastCheckpoint = Date()
    private let appStartTime: Date
    private var textInput: InputText
    private var textInput_parsed: KeyInputParser

    init(textInput: InputText, textInput_parsed: KeyInputParser) {
        self.textInput = textInput
        self.textInput_parsed = textInput_parsed
        
        self.appStartTime = Date()  // アプリ起動時刻を記録
        let formatter = DateFormatter()
        formatter.locale = Locale.current           // ロケールをPCの設定に合わせる
        formatter.timeZone = TimeZone.current       // タイムゾーンをPCの設定に合わせる
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 好きなフォーマットで（例: 2025-06-29 14:30:00）

        let formattedTime = formatter.string(from: self.appStartTime)
        
        logger.debug("FileOpenMonitor 起動時刻: \(formattedTime)")
        
        // アプリ起動時刻よりも遅い時刻に開かれたファイル、という条件でフィルター
        query.predicate = NSPredicate(format: "%K > %@", NSMetadataItemLastUsedDateKey, appStartTime as NSDate)
        //その他の条件
        //  - "%K != ''"　：パスが空じゃなかったら
                
        query.searchScopes = ["/Users/yamamoto/Downloads/tmp_next_toggl"]
        //その他の.searchScopes
        //  - NSMetadataQueryIndexedLocalComputerScope: Mac全体。数十万件を読み込むので、UI描写の時にかなり重くなる。
        //  - NSMetadataQueryUserHomeScope: ホーム以下
        
        //TODO: 保存などの操作を行うと、なぜか handleUpdate() が2回呼ばれる。→ どうやら、ファイルを開くという操作は"NSMetadataQueryDidUpdate"という通知が2回発生するらしい。
        //  →フラグを見直す or 2回目の動作をなくす。
        //TODO: ファイルを開いたときの現在時刻は反映されるが、そのまま再保存しても最初の開いたきの時刻でFileOpenLogオブジェクトに格納される？
        //TODO: まずは開かれたファイルだけ取得したい。（→更新の有無も後で取りたい）
            //現状は、対象のフォルダ内のファイルが毎回全部呼ばれる。
        
        query.valueListAttributes = [NSMetadataItemDisplayNameKey,
                                     NSMetadataItemPathKey,
                                     NSMetadataItemLastUsedDateKey]

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleUpdate),
                                               name: .NSMetadataQueryDidUpdate,
                                               object: query)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInitial),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )


        query.start()
    }
    
    @objc private func handleInitial(_ note: Notification) {
        logger.debug("初期結果数: \(self.query.resultCount)")
        query.results.forEach { item in
            if let m = item as? NSMetadataItem {
                logger.debug("      \(m)")
            }
        }
    }


    @objc private func handleUpdate(_ note: Notification) {

        lastCheckpoint = Date()
        query.disableUpdates()
        defer { query.enableUpdates() }
        
        if let added = note.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem] {
            processItems(added, reason: "added")
        }
        
//        if let changed = note.userInfo?[NSMetadataQueryUpdateChangedItemsKey] as? [NSMetadataItem] {
//            processItems(changed, reason: "changed")
//        }

        
        
//        query.results.forEach { item in
//            if let m = item as? NSMetadataItem,
//               let path = m.value(forAttribute: NSMetadataItemPathKey) as? String,
//               let date = m.value(forAttribute: NSMetadataItemLastUsedDateKey) as? Date {
//                logger.debug("path: \(path), lastUsedDate: \(date)")
//                self.textInput.appendLog(eventType: "file", content: path)
//            }
//        }
        
    }
    
    private func processItems(_ items: [NSMetadataItem], reason: String) {
        
        print("items: \(items)")
        
        for item in items {
            
            guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                  let name = item.value(forAttribute: NSMetadataItemDisplayNameKey) as? String,
                  let date = item.value(forAttribute: NSMetadataItemLastUsedDateKey) as? Date
            else { continue }
            
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let localDateString = formatter.string(from: date)
            
            logger.debug("(\(reason)) path: \(path), lastUsedDate: \(localDateString)")
            
            self.textInput.appendLog(eventType: "file", content: path)
            self.textInput.appendLog(eventType: "file", content: localDateString)
            
            self.textInput_parsed.appendLog_parsed(eventType: "", content: "")   //1行開けるために　TODO: 本来はそのための関数やオプションをつけてもいいかも。
            self.textInput_parsed.appendLog_parsed(eventType: "file", content: path)
            self.textInput_parsed.appendLog_parsed(eventType: "file", content: localDateString)
            
            let content: String? = [
                "txt","md","csv","json","swift"
            ].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
            ? (try? String(contentsOfFile: path, encoding: .utf8)) : nil

            DispatchQueue.main.async {
                self.logs.append(FileOpenLog(path: path,
                                             name: name,
                                             content: content,
                                             openedAt: date))
                self.textInput_parsed.appendLog_parsed(eventType: "file's content", content: content ?? "")
            }
        }
    }
}
