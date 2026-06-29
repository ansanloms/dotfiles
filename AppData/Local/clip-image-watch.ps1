#requires -Version 5.1

# =============================================================================
# clip-image-watch.ps1
#
# 何をするスクリプトか:
#   Windows のクリップボードに画像が入った瞬間 (例: Win+Shift+S での範囲
#   キャプチャ) を検知して、WSL 側の `clip-image` コマンドを自動で実行する
#   常駐プログラム。clip-image がキャプチャを ~/.cache/clip-image/ に PNG
#   として保存し、~/.cache/clip-image/latest.png を最新へ張り替えるので、
#   nvim や Claude Code はその固定パスから最新キャプチャを読める。
#
# どう動くか (ポーリングしない):
#   Windows には「クリップボードが変わったら知らせてくれる」OS の通知機能
#   (WM_CLIPBOARDUPDATE) がある。これを購読し、通知が来たときだけ動く。
#   一定間隔で監視し続ける (ポーリング) 方式ではないので無駄がない。
#
# 無限ループしない理由:
#   clip-image は (--copy-path を付けない限り) Windows のクリップボードを
#   書き換えない。だから clip-image の実行がクリップボード変更通知を
#   再度発生させることはなく、自分で自分を呼び続ける事故が起きない。
#
# PowerShell に不慣れでも読めるよう、各行に説明コメントを付けている。
# =============================================================================

# .NET の Windows Forms 機能を読み込む。
# これで [System.Windows.Forms.Clipboard] や NativeWindow が使えるようになる。
# (GUI は出さない。クリップボード API とウィンドウ機構だけを借りる)
Add-Type -AssemblyName System.Windows.Forms

# --- 多重起動の防止 -----------------------------------------------------------
# ログオンのたびに起動されてもウォッチャが何個も並走しないよう、名前付きの
# Mutex (排他ロック) を 1 個確保する。既に他のインスタンスが握っていれば
# WaitOne(0) が false を返すので、その場合は何もせず終了する。
$mutex = New-Object System.Threading.Mutex($false, "Local\clip-image-watch")
if (-not $mutex.WaitOne(0)) {
    # 既に別のウォッチャが動いている。二重起動を避けて静かに終了する。
    return
}

# --- クリップボード変更を受け取る隠しウィンドウ -------------------------------
# Windows の「クリップボードが変わった」通知 (WM_CLIPBOARDUPDATE) は、
# ウィンドウに対して送られてくる。そこで画面には出ない (メッセージ専用の)
# ウィンドウを 1 個作り、その通知を受け取って .NET のイベントに変換する。
#
# この部分だけは PowerShell では書きにくいので、C# のクラスを文字列で定義し、
# Add-Type でその場でコンパイルして使う。@" ... "@ は「ヒアストリング」と
# 呼ばれる複数行文字列。中身は C# のソースコード。
$source = @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class ClipboardWatcher : NativeWindow {
    // クリップボードの変更通知を、このウィンドウへ送ってもらうよう登録する
    // Win32 API。user32.dll の関数を C# から呼べるように宣言している。
    [DllImport("user32.dll", SetLastError = true)]
    static extern bool AddClipboardFormatListener(IntPtr hwnd);

    // 「クリップボードが更新された」を表す Windows メッセージ番号。
    const int WM_CLIPBOARDUPDATE = 0x031D;

    // PowerShell 側から購読できるように、更新を .NET イベントとして公開する。
    public event Action Updated;

    public ClipboardWatcher() {
        // 画面に出ないウィンドウのハンドルを作り、変更通知の宛先に登録する。
        this.CreateHandle(new CreateParams());
        AddClipboardFormatListener(this.Handle);
    }

    // ウィンドウに届く全メッセージを処理する場所。
    // クリップボード更新メッセージのときだけ Updated イベントを発火する。
    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_CLIPBOARDUPDATE && Updated != null) Updated();
        base.WndProc(ref m);
    }
}
"@

# 上で定義した C# クラスをコンパイルして読み込む。
# -ReferencedAssemblies で Windows Forms への参照を渡す。
Add-Type -TypeDefinition $source -ReferencedAssemblies System.Windows.Forms

# 実行中フラグ。clip-image を起動している最中に次の通知が来ても、
# 二重に走らせないために使う。$script: はスクリプト全体で共有する変数の意味。
$script:busy = $false

# 隠しウィンドウ (=ウォッチャ) を実体化する。コンストラクタの中で
# AddClipboardFormatListener が呼ばれ、この時点から通知を受け取り始める。
$watcher = New-Object ClipboardWatcher

# クリップボード更新イベントに対する処理を登録する。
# { ... } の中が「通知が来るたびに実行される処理」。
$watcher.add_Updated({
    # 前回の clip-image がまだ動いていたら、今回はスキップする。
    # (通知は短時間に連続して飛んでくることがあるため)
    if ($script:busy) { return }

    # クリップボードの中身が画像でなければ何もしない。
    # テキストをコピーしたときなどはここで弾かれる。
    if (-not [System.Windows.Forms.Clipboard]::ContainsImage()) { return }

    # ここから clip-image を起動する。実行中フラグを立てる。
    $script:busy = $true
    try {
        # WSL の clip-image をログインシェル経由で実行する。
        #   bash -lc ... : ログインシェルで実行し、~/.local/bin に PATH を通す。
        #   ~ は bash 側で home に展開される。
        #   -WindowStyle Hidden : コンソール窓を出さない。
        #   -Wait : 実行が終わるまで待つ (待っている間は busy=true)。
        Start-Process -FilePath "wsl.exe" `
            -ArgumentList @("bash", "-lc", "~/.local/bin/clip-image") `
            -WindowStyle Hidden -Wait
    } catch {
        # WSL が無い・既定ディストロが無い等で失敗しても、ウォッチャ自体は
        # 止めない。例外を握りつぶして監視を続ける。
    } finally {
        # 成否にかかわらず実行中フラグを下ろす。次の通知を受け付けられる。
        $script:busy = $false
    }
})

# --- メッセージループ ---------------------------------------------------------
# 隠しウィンドウに通知メッセージを届け続けるためのループ。
# これを回している間ウォッチャは生き続ける。Application.Run はここで
# ブロックし、プロセスが終了するまで戻ってこない。
[System.Windows.Forms.Application]::Run()
