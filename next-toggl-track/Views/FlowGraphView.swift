import SwiftUI

// MARK: - Layout Direction
/// グラフを縦 (トップダウン)・横 (レフトトゥライト) どちらで描くか
enum GraphDirection { case vertical, horizontal }

// MARK: - Data Model
/// アプリ 1 つ分のメタ情報を保持
final class FlowNode: Identifiable, ObservableObject, Hashable {
    static func == (lhs: FlowNode, rhs: FlowNode) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // Identity
    let id = UUID()
    let iconName: String            // SF Symbol などアイコン名
    let appName: String             // 表示用アプリ名
    let projectName: String?        // 所属プロジェクト (任意)
    @Published var workSeconds: Int  // 作業時間 (秒)
    @Published var children: [FlowNode]

    init(iconName: String,
         appName: String,
         workSeconds: Int = 0,
         projectName: String? = nil,
         children: [FlowNode] = []) {
        self.iconName     = iconName
        self.appName      = appName
        self.workSeconds  = workSeconds
        self.projectName  = projectName
        self.children     = children
    }

    /// 「h m」形式で整形
    var formattedDuration: String {
        let h = workSeconds / 3600
        let m = (workSeconds % 3600) / 60
        return "\(h)h \(m)min"
    }
}

// MARK: - FlowGraphView
struct FlowGraphView: View {
    @ObservedObject var root: FlowNode
    var direction: GraphDirection = .horizontal
    var hSpacing: CGFloat = 40
    var vSpacing: CGFloat = 32

    var body: some View {
        GeometryReader { geo in
            let levelsArr = levels(of: root)
            ZStack {
                edgeLayer(levels: levelsArr, in: geo.size)

                if direction == .vertical {
                    VStack(alignment: .center, spacing: vSpacing) {
                        ForEach(Array(levelsArr.enumerated()), id: \.offset) { enumerated in
                            HStack(spacing: hSpacing) {
                                Spacer(minLength: 0)
                                ForEach(enumerated.element) { node in
                                    NodeView(node: node)
                                }
                                Spacer(minLength: 0)
                            }
                        }
                    }
                } else {
                    HStack(alignment: .center, spacing: hSpacing) {
                        Spacer(minLength: 0)
                        ForEach(Array(levelsArr.enumerated()), id: \.offset) { enumerated in
                            VStack(spacing: vSpacing) {
                                ForEach(enumerated.element) { node in
                                    NodeView(node: node)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Edge Drawing (unchanged)
    private func edgeLayer(levels: [[FlowNode]], in size: CGSize) -> some View {
        Canvas { context, _ in
            let nodeSize: CGFloat = 72
            switch direction {
            case .vertical:
                for (rowIndex, row) in levels.enumerated() where rowIndex + 1 < levels.count {
                    let nextRow = levels[rowIndex + 1]
                    let fromY = CGFloat(rowIndex) * (nodeSize + vSpacing) + nodeSize/2 + 12
                    let toY   = fromY + nodeSize + vSpacing - 24

                    let rowWidth      = CGFloat(row.count) * nodeSize + CGFloat(max(0,row.count-1))*hSpacing
                    let nextRowWidth  = CGFloat(nextRow.count) * nodeSize + CGFloat(max(0,nextRow.count-1))*hSpacing
                    let rowStartX     = (size.width - rowWidth)/2 + nodeSize/2
                    let nextRowStartX = (size.width - nextRowWidth)/2 + nodeSize/2

                    for (colIdx, n) in row.enumerated() {
                        for (nextIdx, c) in nextRow.enumerated() where n.children.contains(c) {
                            let fromX = rowStartX + CGFloat(colIdx)*(nodeSize+hSpacing)
                            let toX   = nextRowStartX + CGFloat(nextIdx)*(nodeSize+hSpacing)
                            var p = Path()
                            p.move(to: CGPoint(x: fromX, y: fromY))
                            p.addLine(to: CGPoint(x: toX, y: toY))
                            context.stroke(p, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [5,5]))
                        }
                    }
                }
            case .horizontal:
                for (colIndex, column) in levels.enumerated() where colIndex + 1 < levels.count {
                    let nextColumn = levels[colIndex + 1]
                    let totalWidth = CGFloat(levels.count) * nodeSize + CGFloat(max(0,levels.count-1))*hSpacing
                    let colStartX  = (size.width - totalWidth)/2 + nodeSize/2 + CGFloat(colIndex)*(nodeSize+hSpacing)
                    let nextStartX = colStartX + nodeSize + hSpacing

                    let columnHeight     = CGFloat(column.count)*nodeSize + CGFloat(max(0,column.count-1))*vSpacing
                    let nextColumnHeight = CGFloat(nextColumn.count)*nodeSize + CGFloat(max(0,nextColumn.count-1))*vSpacing
                    let columnStartY     = (size.height - columnHeight)/2 + nodeSize/2
                    let nextColumnStartY = (size.height - nextColumnHeight)/2 + nodeSize/2

                    for (rowIdx, n) in column.enumerated() {
                        for (nextRowIdx, c) in nextColumn.enumerated() where n.children.contains(c) {
                            let fromY = columnStartY + CGFloat(rowIdx)*(nodeSize+vSpacing)
                            let toY   = nextColumnStartY + CGFloat(nextRowIdx)*(nodeSize+vSpacing)
                            var p = Path()
                            p.move(to: CGPoint(x: colStartX, y: fromY))
                            p.addLine(to: CGPoint(x: nextStartX, y: toY))
                            context.stroke(p, with: .color(.secondary), style: StrokeStyle(lineWidth: 1, dash: [5,5]))
                        }
                    }
                }
            }
        }.allowsHitTesting(false)
    }

    // MARK: - Helpers
    private func levels(of root: FlowNode) -> [[FlowNode]] {
        var res:[[FlowNode]]=[]; var q:[FlowNode] = [root]
        while !q.isEmpty{res.append(q); q = q.flatMap{$0.children}}
        return res
    }
}

// MARK: - NodeView (Hover Popover + Help Tooltip)
struct NodeView: View {
    @ObservedObject var node: FlowNode
    @State private var hovering = false

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
            .onHover { hovering = $0 }
            .popover(isPresented: $hovering, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(node.appName)
                        .font(.headline)
                    Text("作業時間：\(node.formattedDuration)")
                        .font(.subheadline)
                    if let proj = node.projectName {
                        Text("プロジェクト：\(proj)")
                            .font(.subheadline)
                    }
                }
                .padding(12)
                .frame(maxWidth: 220)
            }
            // Fallback ツールチップ (macOS 11+)
            .help("\(node.appName)\n作業時間：\(node.formattedDuration)\nプロジェクト：\(node.projectName ?? "-")")
    }
}

// MARK: - Preview
struct FlowGraphView_Previews: PreviewProvider {
    static var sample: FlowNode = {
        FlowNode(iconName: "macwindow", appName: "Root", children: [
            FlowNode(iconName: "hammer", appName: "Xcode", workSeconds: 13560, projectName: "next-toggl"),
            FlowNode(iconName: "safari", appName: "Safari", workSeconds: 3600, children: [
                FlowNode(iconName: "envelope", appName: "Mail", workSeconds: 600)
            ])
        ])
    }()

    static var previews: some View {
        FlowGraphView(root: sample, direction: .horizontal)
            .frame(height: 220)
            .padding()
            .frame(width: 600)
    }
} 