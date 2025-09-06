//
//  ContentView.swift
//  next-toggl-track
//
//  Created by 山本燿司 on 2025/06/20.
//

import SwiftUI
import Cocoa

struct ContentView: View {
    
    // MARK: - 新しいデータモデル
    @StateObject private var activityData = ActivityDataModel()
    
    // MARK: - 既存のクラス（互換性のため）
    let keyTapManager = KeyTapManager()
    
    @State var focusMonitor: FocusMonitor?
    @State var fileOpenMonitor: FileOpenMonitor?
    
    // MARK: - フロー用ルート
    @StateObject private var flowRoot = FlowNode(
        iconName: "macwindow",
        appName: "Root",
        children: [
            FlowNode(iconName: "hammer", appName: "Xcodeでアプリ開発", workSeconds: 13600, projectName: "next-toggl", children: [
                FlowNode(iconName: "doc.text", appName: "wordでドキュメント作成", workSeconds: 1800, projectName: "next-toggl")
            ]),
            FlowNode(iconName: "safari", appName: "Safariで統計手法の数理的背景を検索", workSeconds: 5400, projectName: "fly-sleep", children: [
                FlowNode(iconName: "envelope", appName: "Mail: T教授にデータの意味を尋ねる", workSeconds: 900, projectName: "fly-sleep", children: [
                    FlowNode(iconName: "antenna.radiowaves.left.and.right", appName: "Slackで分析の進捗を報告", workSeconds: 1200, projectName: "fly-sleep")
                ])
            ])
        ])

    var body: some View {
        NavigationView {
            SidebarView()
            VSplitView {
                // MARK: - 4つの列のビュー（元の構成を維持）
                HStack {
                    // 左列: キーボード入力の生情報
                    ActivityLogColumn(activityLog: activityData.activityLog)
                    
                    // 中列: IMEを通したキーボード入力
                    ContextualTextColumn(contextualText: activityData.contextualText)
                    
                    // 右列: ファイル操作
                    FileWebHistoryColumn(fileWebHistory: activityData.fileWebHistory)
                    
                    // 右右列: URLログ
                    URLLogColumn(urlLog: activityData.urlLog)
                }
                
                // MARK: - フロー図
                FlowGraphView(root: flowRoot, direction: .horizontal)
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            logger.info("onApper!")
            
            // 起動ログを追加
            activityData.appendActivityLog(eventType: "app", content: "起動")
            activityData.appendContextualText(eventType: "app", content: "起動")
            
            // アクセシビリティ権限の確認
            let accessibilityEnabled = checkAccessibilityPermission()
            if !accessibilityEnabled {
                requestAccessibilityPermission()
            }
            
            // モニターの開始
            let keyboardMonitor = KeyboardMonitor(textInput: activityData.inputTextInstance)
            focusMonitor = FocusMonitor(
                textInput: activityData.inputTextInstance,
                textURL: activityData.urlTextInstance, // URLログ用のインスタンスを使用
                textInput_parsed: activityData.keyInputParserInstance
            )
            fileOpenMonitor = activityData.fileOpenMonitorInstance

            keyboardMonitor.startMonitoring()
            focusMonitor?.startMonitoring()
            
            keyTapManager.startTap(inputBuffer: activityData.keyInputParserInstance)
        }
    }
}








