-- Markdownの設定
local augroup_markdown = vim.api.nvim_create_augroup("markdown-setting", { clear = true })

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = augroup_markdown,
  pattern = "*.{md,mdwn,mkd,mkdn,mark*}",
  callback = function()
    vim.opt_local.filetype = "markdown"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_markdown,
  pattern = "markdown",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true

    -- フォーマット指定。
    if vim.fn.executable("deno") == 1 then
      vim.opt_local.formatprg = "deno fmt --ext md --prose-wrap preserve -"
    end
  end,
})

local augroup_markdown_mdx = vim.api.nvim_create_augroup("markdown-mdx-setting", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup_markdown_mdx,
  pattern = "markdown.mdx",
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

-- quickrun - markdown
do
  -- 生成した html の書き出し先。repo 内にゴミを残さないよう、プラットフォーム
  -- ごとのキャッシュディレクトリ配下に置く (/tmp 固定は他ユーザから読める、ネ
  -- イティブ Windows 版 nvim には /tmp が無い、の両方の問題があるため)。
  local html_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "md2html")
  vim.fn.mkdir(html_dir, "p")

  -- 出力パス。%s (小文字) は既定で shellescape され、filename-modifiers も適用
  -- できる (vim-quickrun 本体で確認済み)。絶対パスの / を _ に置換して一意な
  -- ファイル名にする。置換前に既存の _ を __ へエスケープすることで、
  -- /a/b_c.md と /a_b/c.md のような別パスが同じ名前に衝突しないようにする
  -- (単射)。
  -- POSIX のパス区切り (/) のみを扱う。ネイティブ Windows 版 nvim ではパスに
  -- バックスラッシュとドライブレターが混じるため、この経路の一意化が完全に
  -- 機能する保証は無い (未対応)。
  local html_target = html_dir .. "/%s:p:gs?_?__?:gs?/?_?.html"

  -- ユーザ CSS の置き場。在るときだけ --css を渡す (md2html / pandoc 共通)。
  local css = vim.fs.joinpath(vim.fn.stdpath("data"), "pandoc", "markdown.css")
  local css_option = vim.fn.filereadable(css) == 1 and (" --css=" .. css) or ""

  -- 生成した HTML を OS 既定のブラウザで開くコマンド。open-browser.vim には依存しない。
  -- WSL では Windows 側プログラムに Linux パスを直接渡せないため wslpath で変換する。
  -- quickrun は exec を quickrun#expand() に通し & や $ を展開トリガとして解釈するため、
  -- シェルに渡したい & と $ はバックスラッシュでエスケープしておく (%s は quickrun の
  -- プレースホルダとして展開させるためエスケープしない)。
  local function browser_command(path)
    if vim.fn.has("wsl") == 1 then
      return 'rundll32.exe url.dll,FileProtocolHandler "\\$(wslpath -w ' .. path .. ')"'
    elseif vim.fn.has("mac") == 1 then
      return "open " .. path
    end
    return "xdg-open " .. path
  end

  local quickrun_config = vim.g.quickrun_config or {}

  if vim.fn.executable("pandoc") == 1 then
    -- md2html が無い環境向けの素の html 出力フォールバック (mermaid / shiki 無し)
    quickrun_config["markdown"] = { type = "markdown/pandoc" }

    quickrun_config["markdown/pandoc"] = {
      ["hook/cd/directory"] = "%S:p:h",
      outputter = "error",
      ["outputter/error/success"] = "null",
      ["outputter/error/error"] = "buffer",
      exec = "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6"
        .. css_option
        .. " --metadata title=%s --output=" .. html_target .. " \\&\\& "
        .. browser_command(html_target),
    }

    -- slidy 出力。html 出力先は元ファイルと同じディレクトリのまま (対象外・現状
    -- 維持)。理由: 主経路 (md2html) には無い pandoc 固有の出力形式で、実運用で
    -- の使用頻度が低いため、今回の出力先変更のスコープには含めていない。
    quickrun_config["markdown/pandoc-slidy"] = {
      ["hook/cd/directory"] = "%S:p:h",
      outputter = "error",
      ["outputter/error/success"] = "null",
      ["outputter/error/error"] = "buffer",
      exec = "pandoc %s --standalone --self-contained --from markdown --to=slidy --toc-depth=6"
        .. " --metadata title=%s --output=%s.html \\&\\& "
        .. browser_command("%s.html"),
    }

    -- Word docx 出力
    quickrun_config["markdown/pandoc-docx"] = {
      ["hook/cd/directory"] = "%S:p:h",
      outputter = "null",
      exec = "pandoc %s --standalone --self-contained --from markdown --to=docx --toc-depth=6 --highlight-style=zenburn --output=%s.docx",
    }

    -- 単一 markdown 出力
    quickrun_config["markdown/pandoc-self-contained"] = {
      ["hook/cd/directory"] = "%S:p:h",
      ["outputter/buffer/filetype"] = "markdown",
      exec = "pandoc %s --standalone --self-contained --from markdown --to=html5 --toc-depth=6 --no-highlight --metadata title=%s | pandoc --from html --to markdown --wrap none --markdown-headings=atx"
        .. ' | sed -r -e "s/```\\s*\\{\\.(.*)\\}/```\\1/g"',
    }
  end

  if vim.fn.executable("md2html") == 1 then
    -- 主経路: deno 製 md2html (shiki + mermaid 内蔵)。pandoc より優先する。
    quickrun_config["markdown"] = { type = "markdown/md2html" }

    quickrun_config["markdown/md2html"] = {
      ["hook/cd/directory"] = "%S:p:h",
      outputter = "error",
      ["outputter/error/success"] = "null",
      ["outputter/error/error"] = "buffer",
      exec = "md2html %s" .. css_option .. " --output " .. html_target .. " \\&\\& " .. browser_command(html_target),
    }

    -- 保存の度に自動再生成する watch 相当。vim-quickrun の既定 runner は同期の
    -- system() 呼び出しで (vim-quickrun 本体のソースで確認済み)、これを保存の
    -- 度に使うと生成が終わるまで nvim がブロックする。quickrun を経由せず、
    -- Neovim 標準の非同期ジョブ (jobstart) で直接 md2html を実行する。ブラウザ
    -- は開かない (保存の度に新規で開いてしまうため)。生成された html は手動で
    -- ブラウザをリロードして見る。失敗時も UI へ通知しない (best-effort)。
    -- ソースパスごとに直前の job id を追跡し、短時間の連続保存で同じ出力先へ
    -- 競合書き込みしないよう新規実行前に古い job を打ち切る。
    local watch_jobs = {}
    local augroup_markdown_watch = vim.api.nvim_create_augroup("markdown-watch", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = augroup_markdown_watch,
      pattern = "*.{md,mdwn,mkd,mkdn,mark*}",
      callback = function()
        local src = vim.fn.expand("<afile>:p")
        -- quickrun 側 (html_target) と同じ正規化にすることで、手動プレビューと
        -- watch の出力先を一致させる。
        local target = html_dir .. "/" .. src:gsub("_", "__"):gsub("/", "_") .. ".html"
        local cmd = { "md2html", src, "--output", target }
        if vim.fn.filereadable(css) == 1 then
          table.insert(cmd, "--css=" .. css)
        end
        local existing = watch_jobs[src]
        if existing then
          pcall(vim.fn.jobstop, existing)
        end
        local id
        id = vim.fn.jobstart(cmd, {
          cwd = vim.fn.fnamemodify(src, ":h"),
          on_exit = function()
            if watch_jobs[src] == id then
              watch_jobs[src] = nil
            end
          end,
        })
        watch_jobs[src] = id
      end,
    })
  end

  vim.g.quickrun_config = quickrun_config
end
