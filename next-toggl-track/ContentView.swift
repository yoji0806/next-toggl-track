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



// MARK: - Data Model
/// ノード 1 つ分の情報。アプリ名や URL を \`iconName\` に入れると SF Symbols が表示されます。
/// 実際のアイコン画像を使いたい場合は \`Image(uiImage:)\` などに差し替えてください。
final class FlowNode: Identifiable, ObservableObject {
    let id = UUID()
    let iconName: String
    @Published var children: [FlowNode]

    init(iconName: String, children: [FlowNode] = []) {
        self.iconName = iconName
        self.children  = children
    }
}

// MARK: - ノードの見た目
struct NodeView: View {
    let node: FlowNode

    var body: some View {
        Image(systemName: node.iconName)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.primary)
            .padding(16)
            .background(
                Circle()
                    .fill(.background)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
    }
}

// MARK: - レイアウト計算
/// それぞれのノードをキャンバス上の座標にマッピングします。
fileprivate func layoutPositions(root: FlowNode,
                                 hSpacing: CGFloat,
                                 vSpacing: CGFloat) -> [UUID: CGPoint] {
    var positions: [UUID: CGPoint] = [:]
    func helper(node: FlowNode, depth: Int, centerX: CGFloat) -> CGFloat {
        // 再帰的に横幅を計算しつつ位置を決定
        let childWidths = node.children.map { helper(node: $0, depth: depth + 1, centerX: centerX) }
        let subtreeWidth = max( CGFloat(childWidths.reduce(0, +)), 1) * hSpacing
        let x = centerX
        let y = CGFloat(depth) * vSpacing + 50
        positions[node.id] = CGPoint(x: x, y: y)

        // 子供の中心を分配
        var startX = x - subtreeWidth / 2
        for child in node.children {
            positions[child.id]?.x = startX + hSpacing / 2
            startX += hSpacing
        }
        return max(subtreeWidth, hSpacing)
    }
    _ = helper(node: root, depth: 0, centerX: 0)
    return positions
}

// MARK: - グラフ全体
struct FlowGraphView: View {
    @ObservedObject var root: FlowNode
    var hSpacing: CGFloat = 140
    var vSpacing: CGFloat = 120

    var body: some View {
        GeometryReader { geo in
            let positions = layoutPositions(root: root,
                                             hSpacing: hSpacing,
                                             vSpacing: vSpacing)
            ZStack {
                // 点線を Canvas で描画
                Canvas { ctx, size in
                    drawLines(from: root, positions: positions, ctx: &ctx)
                }
                // ノードを配置
                ForEach(nodes(from: root)) { node in
                    if let pos = positions[node.id] {
                        NodeView(node: node)
                            .position(pos)
                    }
                }
            }
            // 少し余白を確保
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    /// すべてのノードを DFS で取得
    private func nodes(from node: FlowNode) -> [FlowNode] {
        return [node] + node.children.flatMap { nodes(from: $0) }
    }

    /// 再帰的に点線を描く
    private func drawLines(from node: FlowNode,
                           positions: [UUID: CGPoint],
                           ctx: inout GraphicsContext) {
        guard let from = positions[node.id] else { return }
        for child in node.children {
            if let to = positions[child.id] {
                var path = Path()
                path.move(to: from)
                path.addLine(to: to)
                ctx.stroke(path,
                           with: .color(.secondary),
                           style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                drawLines(from: child, positions: positions, ctx: &ctx)
            }
        }
    }
}

// MARK: - プレビュー
#Preview {
    // サンプルデータ生成
    let mail = FlowNode(iconName: "envelope")
    let browser = FlowNode(iconName: "safari")
    let docs = FlowNode(iconName: "doc.text")
    let terminal = FlowNode(iconName: "terminal")

    let design = FlowNode(iconName: "pencil.and.ruler")
    design.children = [mail, browser]

    let root = FlowNode(iconName: "app.fill", children: [design, docs, terminal])

    return ScrollView([.horizontal, .vertical]) {
        FlowGraphView(root: root)
            .frame(minWidth: 800, minHeight: 600)
            .padding(80)
    }
}
