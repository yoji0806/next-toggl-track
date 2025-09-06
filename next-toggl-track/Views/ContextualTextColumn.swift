import SwiftUI

/// 中列: コンテキストテキスト・フレーズを表示するビュー
struct ContextualTextColumn: View {
    let contextualText: String
    
    var body: some View {
        AutoScrollLogColumn(text: contextualText)
            .frame(minWidth: 200)
    }
} 