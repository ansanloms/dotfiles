// clip-image-watch の powershell リスナが Add-Type でコンパイルする C# クラス。
// クリップボード変更通知 (WM_CLIPBOARDUPDATE) を受け取る、画面に出ない
// メッセージ専用ウィンドウ。更新を Updated イベントとして公開する。
//
// このファイルは scripts/lib/clip-image-watch.ts から text import され、
// powershell の単一引用符ヒアストリング (@'...'@) に埋め込まれて Add-Type に
// 渡される。deno bundle がビルド時にテキストをインライン展開するため、生成物
// (.local/bin/clip-image-watch) は単一ファイルのまま自己完結する。

using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class ClipboardWatcher : NativeWindow {
    [DllImport("user32.dll", SetLastError = true)]
    static extern bool AddClipboardFormatListener(IntPtr hwnd);

    const int WM_CLIPBOARDUPDATE = 0x031D;
    public event Action Updated;

    public ClipboardWatcher() {
        this.CreateHandle(new CreateParams());
        AddClipboardFormatListener(this.Handle);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_CLIPBOARDUPDATE && Updated != null) Updated();
        base.WndProc(ref m);
    }
}
