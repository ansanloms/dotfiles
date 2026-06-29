// clip-image-watch の純粋ロジックとオーケストレーション。
// 副作用 (powershell リスナの行ストリーム / clip-image 起動 / 出力) は
// WatchDeps として注入する。エントリポイント (scripts/clip-image-watch.ts) が
// 実物を組み立てて run() を呼ぶ。
//
// Windows のクリップボード変更イベント (WM_CLIPBOARDUPDATE) は Linux からは
// 購読できないため、イベント検知は Windows 側の powershell プロセスに任せる。
// このプロセスは powershell を 1 個常駐させ、画像コピーのたびに 1 行
// (EVENT_LINE) を受け取り、clip-image を起動する役 (監督) を担う。

// C# のリスナクラスを別ファイルから text import する。deno bundle が
// ビルド時にテキストをインライン展開するため、生成物は単一ファイルのまま。
import watcherCs from "./clipboard-watcher.cs" with { type: "text" };

// 画像コピー時に powershell リスナが stdout へ吐く 1 行。
export const EVENT_LINE = "image";

// 常駐させる powershell リスナ。AddClipboardFormatListener でクリップボード
// 更新をイベント購読し、画像のときだけ EVENT_LINE を 1 行出力する。
// パイプ越しでも即座に届くよう毎回 Flush する。STA でないと Clipboard API が
// 使えないため、このスクリプトは powershell.exe -STA で起動する前提。
//
// C# クラスは単一引用符ヒアストリング (@'...'@) に埋め込む。@' は行末、'@ は
// 行頭でなければならない。watcherCs は末尾改行で終わるので '@ は行頭に来る。
export const LISTENER_PS = `Add-Type -AssemblyName System.Windows.Forms
$src = @'
${watcherCs}'@
Add-Type -TypeDefinition $src -ReferencedAssemblies System.Windows.Forms
$w = New-Object ClipboardWatcher
$w.add_Updated({
    if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
        [Console]::Out.WriteLine("${EVENT_LINE}")
        [Console]::Out.Flush()
    }
})
[System.Windows.Forms.Application]::Run()`;

export interface WatchDeps {
  lines(): AsyncIterable<string>;
  runClip(): Promise<void>;
  errorLine(msg: string): void;
}

// powershell リスナの行ストリームを読み、EVENT_LINE のたびに clip-image を
// 起動する。行ストリームが尽きた (= リスナが終了した) ら非 0 を返し、
// systemd の Restart=always にプロセスごと再起動させる。
export async function run(deps: WatchDeps): Promise<number> {
  for await (const raw of deps.lines()) {
    if (raw.trim() !== EVENT_LINE) {
      continue;
    }
    try {
      await deps.runClip();
    } catch (e) {
      // 1 回の失敗で監視を止めない。次のイベントを待ち続ける。
      deps.errorLine(`clip-image-watch: clip-image failed: ${e}`);
    }
  }

  deps.errorLine("clip-image-watch: listener exited");
  return 1;
}
