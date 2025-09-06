import SwiftUI

/// 左列: アクティビティログを表示するビュー
struct ActivityLogColumn: View {
    let activityLog: String
    
    var body: some View {
        AutoScrollLogColumn(text: activityLog)
            .frame(minWidth: 200)
    }
}

struct URLLogColumn: View {
    let urlLog: String
    var body: some View {
        AutoScrollLogColumn(text: urlLog)
            .frame(minWidth: 200)
    }
}

/// 読み取り専用ログを"常に末尾が見える"状態で表示
struct AutoScrollLogColumn: View {
    let text: String
    private let bottomID = "BOTTOM-ANCHOR"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(.vertical, 4)
                    .padding(.horizontal)

                Color.clear.frame(height: 1)   // ⬇︎ スクロール先アンカー
                    .id(bottomID)
            }
            .background(Color(NSColor.textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.2))
            )
            // 文字列が変わった直後に 1 フレーム遅延して末尾へ
            .onChange(of: text) { _ in
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 0.15)) {
                        proxy.scrollTo(bottomID, anchor: .bottom)
                    }
                }
            }
        }
    }
} 