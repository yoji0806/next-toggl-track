# next-toggl-track

完全自動で「何にどれだけ時間を使っているかを可視化する」ソフトウェア

> 「僕たちエンジニアが、  
　AIによる “ 既存プロジェクトの詳細なドキュメントや筋の良い大量のプルリクエスト” をみた時の感動を、  
　全ての一般業務で起こる状況を想像してください」  

# サービス：
- to C：パフォーマンス可視化 + タスク自動化 + 行動経済学/精神面で集中をサポートするAI
- to B：パフォーマンス可視化 + 業務フローの可視化 + チームタスク自動化
  - 競合：Toggl Track, 業務改善コンサル, 自動化ツール
  - 技術：
    - ローカルLLM
    - PC操作ログ（キーボード入力, マウス操作, 開いているファイル/ウィンドウ/タブ, 通信情報等々）

# 参考： Toggl Track Autotarck
現行のToggl TrackのAutotarckerは、ブラウザのタイトル or アプリ名のキーワード一致で各プロジェクト時間計測の開始/停止を行います。  
この機能をより細かい粒度で完全自動で達成するのが最初の1歩です。

<img width="720" alt="Autotracker_と_Toggl_Track_Desktop_App_for_macOS___Toggl_Track_Knowledge_Base" src="https://github.com/user-attachments/assets/231a5ba4-45ca-451c-8e25-4d58294a2b58" />
