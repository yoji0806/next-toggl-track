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
    
//    /// サンプル用ツリー（macwindow → Safari と Xcode に分岐、Safari → Mail）
//    @StateObject var flowRoot = FlowNode(iconName: "macwindow", children: [
//        FlowNode(iconName: "safari", children: [
//            FlowNode(iconName: "envelope")
//        ]),
//        FlowNode(iconName: "hammer")
//    ])
    
    // ① 高さを動的に変えたい場合
    @State private var flowHeight: CGFloat = 240   // 0 で非表示
    
    // フロー用ルート
    @StateObject var flowRoot = FlowNode(iconName: "macwindow", children: [
        FlowNode(iconName: "safari", children: [ FlowNode(iconName: "envelope") ]),
        FlowNode(iconName: "hammer")
    ])


    var body: some View {
        NavigationView{
            Sidebar()
            VSplitView{

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
                FlowGraphView(root: flowRoot, direction: .horizontal)
                    .frame(maxWidth: .infinity)   // 横はいっぱ
                
            }
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








// MARK: - Layout Direction
/// フローを縦 (トップダウン)・横 (レフトトゥライト) のどちらで描くか
enum GraphDirection { case vertical, horizontal }

// MARK: - Data Model
/// ノード 1 つ分の情報。`iconName` には SF Symbols 名やアセット名を入れ、階層を `children` で表現します。
/// `Identifiable` だけで十分ですが、将来 Set などで扱う可能性を考慮して `Hashable` も実装しています。
final class FlowNode: Identifiable, ObservableObject, Hashable {
    static func == (lhs: FlowNode, rhs: FlowNode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    let id = UUID()
    let iconName: String
    @Published var children: [FlowNode]

    init(iconName: String, children: [FlowNode] = []) {
        self.iconName = iconName
        self.children  = children
    }
}

// MARK: - ビュー本体
/// フロー全体を行 (縦) または列 (横) ごとに並べ、中央揃えで表示します。
/// 点線のエッジは Canvas で描画し、ダッシュパターンでモダンな見た目に。
struct FlowGraphView: View {
    @ObservedObject var root: FlowNode

    /// デフォルトは横向き
    var direction: GraphDirection = .horizontal

    /// ノード間隔
    var hSpacing: CGFloat = 40
    var vSpacing: CGFloat = 32

    var body: some View {
        GeometryReader { geo in
            let levels = levels(of: root)            // BFS 一発計算
            ZStack {
                edgeLayer(levels: levels, in: geo.size) // ── 点線エッジ ──

                // ── ノード ──
                if direction == .vertical {
                    VStack(alignment: .center, spacing: vSpacing) {
                        ForEach(Array(levels.enumerated()), id: \ .offset) { _, row in
                            HStack(spacing: hSpacing) {
                                Spacer(minLength: 0)
                                ForEach(row) { node in
                                    NodeView(node: node)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                } else { // horizontal
                    HStack(alignment: .center, spacing: hSpacing) {
                        Spacer(minLength: 0)
                        ForEach(Array(levels.enumerated()), id: \ .offset) { _, column in
                            VStack(spacing: vSpacing) {
                                ForEach(column) { node in
                                    NodeView(node: node)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Edge Drawing
    private func edgeLayer(levels: [[FlowNode]], in size: CGSize) -> some View {
        Canvas { context, _ in
            let nodeSize: CGFloat = 48 + 24    // NodeView: アイコン 48 + padding 12*2

            switch direction {
            // ──────────── 縦 ────────────
            case .vertical:
                for (rowIndex, row) in levels.enumerated() where rowIndex + 1 < levels.count {
                    let nextRow = levels[rowIndex + 1]

                    let rowWidth      = CGFloat(row.count) * nodeSize + CGFloat(max(0, row.count - 1)) * hSpacing
                    let nextRowWidth  = CGFloat(nextRow.count) * nodeSize + CGFloat(max(0, nextRow.count - 1)) * hSpacing
                    let rowStartX     = (size.width - rowWidth)      / 2 + nodeSize / 2
                    let nextRowStartX = (size.width - nextRowWidth)  / 2 + nodeSize / 2
                    let fromY = CGFloat(rowIndex) * (nodeSize + vSpacing) + nodeSize / 2 + 12
                    let toY   = fromY + nodeSize + vSpacing - 24

                    for (colIndex, node) in row.enumerated() {
                        for (nextIdx, child) in nextRow.enumerated() where node.children.contains(where: { $0.id == child.id }) {
                            let fromX = rowStartX     + CGFloat(colIndex) * (nodeSize + hSpacing)
                            let toX   = nextRowStartX + CGFloat(nextIdx)  * (nodeSize + hSpacing)

                            var path = Path()
                            path.move(to: CGPoint(x: fromX, y: fromY))
                            path.addLine(to: CGPoint(x: toX,   y: toY))
                            context.stroke(path, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
                    }
                }

            // ──────────── 横 ────────────
            case .horizontal:
                for (colIndex, column) in levels.enumerated() where colIndex + 1 < levels.count {
                    let nextColumn = levels[colIndex + 1]

                    let columnHeight     = CGFloat(column.count) * nodeSize + CGFloat(max(0, column.count - 1)) * vSpacing
                    let nextColumnHeight = CGFloat(nextColumn.count) * nodeSize + CGFloat(max(0, nextColumn.count - 1)) * vSpacing
                    let columnStartY     = (size.height - columnHeight)     / 2 + nodeSize / 2
                    let nextColumnStartY = (size.height - nextColumnHeight) / 2 + nodeSize / 2

                    let totalWidth = CGFloat(levels.count) * nodeSize + CGFloat(max(0, levels.count - 1)) * hSpacing
                    let colStartX  = (size.width - totalWidth) / 2 + nodeSize / 2 + CGFloat(colIndex) * (nodeSize + hSpacing)
                    let nextStartX = colStartX + nodeSize + hSpacing

                    for (rowIndex, node) in column.enumerated() {
                        for (nextRowIdx, child) in nextColumn.enumerated() where node.children.contains(where: { $0.id == child.id }) {
                            let fromY = columnStartY     + CGFloat(rowIndex)   * (nodeSize + vSpacing)
                            let toY   = nextColumnStartY + CGFloat(nextRowIdx) * (nodeSize + vSpacing)

                            var path = Path()
                            path.move(to: CGPoint(x: colStartX,  y: fromY))
                            path.addLine(to: CGPoint(x: nextStartX, y: toY))
                            context.stroke(path, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        }
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
        VStack(spacing: 24) {
            FlowGraphView(root: sample, direction: .horizontal)
                .frame(height: 160)
                .padding()
            FlowGraphView(root: sample, direction: .vertical)
                .frame(height: 160)
                .padding()
        }
        .frame(width: 600)
    }
}
