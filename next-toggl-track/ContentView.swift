//
//  ContentView.swift
//  next-toggl-track
//
//  Created by 山本燿司 on 2025/06/20.
//

import SwiftUI
import Cocoa



struct ContentView: View {
    
    @StateObject var textInput = InputText()
    @StateObject var textParsedKeyBaord = InputText()
    @StateObject var textURL = InputText()
    @StateObject var textInput_parsed = KeyInputParser()

    let keyTapManager = KeyTapManager()
    
    @State var focusMonitor: FocusMonitor?
    @State var fileOpenMonitor: FileOpenMonitor?
    
    /// サンプル用ツリー（macwindow → Safari と Xcode に分岐、Safari → Mail）
    @StateObject var flowRoot = FlowNode(iconName: "macwindow", children: [
        FlowNode(iconName: "safari", children: [
            FlowNode(iconName: "envelope")
        ]),
        FlowNode(iconName: "hammer")
    ])


    var body: some View {
        NavigationView{
            Sidebar()
            VStack(spacing: 12) {
                
                HStack {
                    TextEditor(text: $textInput.data)
                        .disabled(true)
                    TextEditor(text: $textInput_parsed.log)
                        .disabled(true)
                    List(fileOpenMonitor?.logs ?? []) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.name).bold()
                            Text(log.path).font(.caption2).foregroundStyle(.secondary)
                            Text(log.openedAt.formatted()).font(.caption2)
                            if let snippet = log.content?.prefix(120) {
                                Text(snippet + (log.content!.count > 120 ? "…" : ""))
                                    .font(.caption)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    TextEditor(text: $textURL.data)
                        .disabled(true)
                    //Button{ logger.debug("button is clicked!") } label: {}
                }
                // ─── 2段目: フロー図 ───
                FlowGraphView(root: flowRoot)
                    .frame(maxWidth: .infinity, maxHeight: 300)   // 高さはお好みで
                    .padding(.horizontal)
            }
            .navigationTitle("next-toggl-track")   // 必要ならタイトルを設定
        }
        .onAppear {
            logger.info("onApper!")
            textInput.appendLog(eventType: "app", content: "起動")
            textInput_parsed.appendLog_parsed(eventType: "app", content: "起動")
            
            let accessibilityEnabled = checkAccessibilityPermission()
            if !accessibilityEnabled {
                requestAccessibilityPermission()
            }
            
            let KeyboardMonitor = KeyboardMonitor(textInput: textInput)
            focusMonitor = FocusMonitor(textInput: textInput, textURL: textURL, textInput_parsed: textInput_parsed)
            fileOpenMonitor = FileOpenMonitor(textInput: textInput, textInput_parsed: textInput_parsed)

            KeyboardMonitor.startMonitoring()
            focusMonitor?.startMonitoring()
            
            keyTapManager.startTap(inputBuffer: textInput_parsed)

        }
    }
}



struct Sidebar: View {

    var body: some View {
        List {

        }
    }
}



// MARK: - Data Model
/// ノード 1 つ分の情報。`iconName` には SF Symbols 名やアセット名を入れ、階層を `children` で表現します。
final class FlowNode: Identifiable, ObservableObject {
    let id = UUID()
    let iconName: String
    @Published var children: [FlowNode]

    init(iconName: String, children: [FlowNode] = []) {
        self.iconName = iconName
        self.children  = children
    }
}

// MARK: - ビュー本体
/// フロー全体を行ごと (レベルごと) に並べ、各行を左右中央揃えで表示します。
/// 点線のエッジは Canvas で描画し、ダッシュパターンでモダンな見た目に。
struct FlowGraphView: View {
    @ObservedObject var root: FlowNode

    // 行内・行間の間隔を調整したい場合はここを変更
    var hSpacing: CGFloat = 40
    var vSpacing: CGFloat = 32

    var body: some View {
        GeometryReader { geo in
            // レベル配列を 1 回だけ計算
            let rows = levels(of: root)

            ZStack {
                // ── 点線エッジ ──
                edgeLayer(rows: rows, in: geo.size)

                // ── ノード (アイコン) ──
                VStack(alignment: .center, spacing: vSpacing) {
                    // \`rows\` は [[FlowNode]]。行番号を ID にして中央揃えを維持
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, level in
                        HStack(spacing: hSpacing) {
                            Spacer(minLength: 0)          // ✔︎ 行を中央揃えに
                            ForEach(level) { node in      // FlowNode は Identifiable
                                NodeView(node: node)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.vertical)
    }

    // MARK: - Edge Drawing
    /// 子ノードへの線をすべて描画
    private func edgeLayer(rows: [[FlowNode]], in size: CGSize) -> some View {
        Canvas { context, _ in
            let nodeSize: CGFloat = 48 + 24    // アイコン 48 + padding 12*2

            for (rowIndex, row) in rows.enumerated() where rowIndex + 1 < rows.count {
                let nextRow = rows[rowIndex + 1]

                // 行幅を計算して X オフセットを求める
                let rowWidth      = CGFloat(row.count) * nodeSize + CGFloat(max(0, row.count - 1)) * hSpacing
                let nextRowWidth  = CGFloat(nextRow.count) * nodeSize + CGFloat(max(0, nextRow.count - 1)) * hSpacing
                let rowStartX     = (size.width - rowWidth)  / 2 + nodeSize / 2
                let nextRowStartX = (size.width - nextRowWidth) / 2 + nodeSize / 2
                let fromY = CGFloat(rowIndex) * (nodeSize + vSpacing) + nodeSize / 2 + 12   // 12 = padding
                let toY   = fromY + nodeSize + vSpacing - 24                               // -24 で下端調整

                for (colIndex, node) in row.enumerated() {
                    for (nextIndex, child) in nextRow.enumerated() where node.children.contains(where: { $0.id == child.id }) {
                        let fromX = rowStartX + CGFloat(colIndex) * (nodeSize + hSpacing)
                        let toX   = nextRowStartX + CGFloat(nextIndex) * (nodeSize + hSpacing)

                        var path = Path()
                        path.move(to: CGPoint(x: fromX, y: fromY))
                        path.addLine(to: CGPoint(x: toX, y: toY))
                        context.stroke(path, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Helpers
    /// BFS でレベル別にノードを収集
    private func levels(of root: FlowNode) -> [[FlowNode]] {
        var result: [[FlowNode]] = []
        var queue: [FlowNode] = [root]
        while !queue.isEmpty {
            result.append(queue)
            queue = queue.flatMap { $0.children }
        }
        return result
    }
}

// MARK: - 個々のノードビュー
struct NodeView: View {
    @ObservedObject var node: FlowNode

    var body: some View {
        Image(systemName: node.iconName)
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.windowBackgroundColor))
                    .shadow(radius: 4)
            )
    }
}

// MARK: - プレビュー
struct FlowGraphView_Previews: PreviewProvider {
    static var sample: FlowNode = {
        FlowNode(iconName: "macwindow", children: [
            FlowNode(iconName: "safari", children: [ FlowNode(iconName: "envelope") ]),
            FlowNode(iconName: "hammer")
        ])
    }()

    static var previews: some View {
        FlowGraphView(root: sample)
            .frame(height: 300)
            .padding()
    }
}
