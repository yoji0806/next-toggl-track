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

    init() {
        print("ieiei: FileOpenMonitor の init()")
        // ▲ 初回だけ “これ以降で開かれたもの” に絞る
//        query.predicate = NSPredicate(format: "%K > %@", NSMetadataItemLastUsedDateKey, lastCheckpoint as NSDate)
//        query.searchScopes = [NSMetadataQueryUserHomeScope]   // 例：ホーム以下だけ
        
        
        query.predicate = NSPredicate(format: "%K != ''", NSMetadataItemPathKey)
        query.searchScopes = [NSMetadataQueryIndexedLocalComputerScope]  // Mac 全体に広げる

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
        print("ieiei: Spotlight クエリを非同期で開始")
    }
    
    @objc private func handleInitial(_ note: Notification) {
        print("ieiei 初期結果数: \(query.resultCount)")
        query.results.forEach { item in
            if let m = item as? NSMetadataItem {
                print(m)
            }
        }
    }


    @objc private func handleUpdate(_ note: Notification) {
        lastCheckpoint = Date()                    // 次回はこれ以降を監視
        query.disableUpdates()
        defer { query.enableUpdates() }
        
        print("ieiei: query.resultCount: \(query.resultCount)")

        query.results
            .compactMap { $0 as? NSMetadataItem }
            .forEach { item in
                guard let path  = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                      let name  = item.value(forAttribute: NSMetadataItemDisplayNameKey) as? String,
                      let date  = item.value(forAttribute: NSMetadataItemLastUsedDateKey) as? Date
                else { return }

                // 例：テキスト系だけ中身を読む（バイナリ巨大ファイルは無視）
                let content: String? = [
                    "txt","md","csv","json","swift"
                ].contains(URL(fileURLWithPath: path).pathExtension.lowercased())
                ? (try? String(contentsOfFile: path, encoding: .utf8)) : nil

                DispatchQueue.main.async {
                    self.logs.append(FileOpenLog(path: path,
                                                 name: name,
                                                 content: content,
                                                 openedAt: date))
                }
        }
    }
}
