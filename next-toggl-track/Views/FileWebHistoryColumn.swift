import SwiftUI

/// 右列: ファイル・Web履歴ログを表示するビュー
struct FileWebHistoryColumn: View {
    let fileWebHistory: [FileOpenLog]
    
    var body: some View {
        AutoScrollFileList(logs: fileWebHistory)
            .frame(minWidth: 240)
    }
}

/// ファイルリストを"常に末尾が見える"状態で表示
struct AutoScrollFileList: View {
    let logs: [FileOpenLog]

    var body: some View {
        ScrollViewReader { proxy in
            List(logs) { log in
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.name).bold()
                    Text(log.path)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(log.openedAt.formatted())
                        .font(.caption2)
                    if let snippet = log.content?.prefix(120) {
                        Text(snippet + (log.content!.count > 120 ? "…" : ""))
                            .font(.caption)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
                .id(log.id)             // ← 重要：各行に ID
            }
            // 末尾追加時スクロール
            .onChange(of: logs.count) { _ in
                guard let last = logs.last else { return }
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 0.15)) {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }
} 