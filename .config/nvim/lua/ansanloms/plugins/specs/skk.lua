-- skk (skkeleton 一式)。

---@class SkkeletonDict
---@field url string ダウンロード元 URL
---@field name string 保存先ファイル名
---@field encoding "euc-jp"|"euc-jis-2004"|"utf-8" 配布物の文字コード

-- ダウンロード対象の辞書定義。build 時に取得し、必要なら UTF-8 へ変換する。
---@type SkkeletonDict[]
local dicts = {
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.L",
    name = "SKK-JISYO.L",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.jinmei",
    name = "SKK-JISYO.jinmei",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.fullname",
    name = "SKK-JISYO.fullname",
    encoding = "euc-jis-2004",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.geo",
    name = "SKK-JISYO.geo",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.propernoun",
    name = "SKK-JISYO.propernoun",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.station",
    name = "SKK-JISYO.station",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.law",
    name = "SKK-JISYO.law",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.assoc",
    name = "SKK-JISYO.assoc",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.edict2",
    name = "SKK-JISYO.edict2",
    encoding = "utf-8",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.itaiji",
    name = "SKK-JISYO.itaiji",
    encoding = "euc-jp",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.itaiji.JIS3_4",
    name = "SKK-JISYO.itaiji.JIS3_4",
    encoding = "euc-jis-2004",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/SKK-JISYO.emoji",
    name = "SKK-JISYO.emoji",
    encoding = "utf-8",
  },
  {
    url = "https://github.com/ymrl/SKK-JISYO.emoji-ja/raw/refs/heads/master/SKK-JISYO.emoji-ja.utf8",
    name = "SKK-JISYO.emoji-ja",
    encoding = "utf-8",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/zipcode/SKK-JISYO.zipcode",
    name = "SKK-JISYO.zipcode",
    encoding = "euc-jis-2004",
  },
  {
    url = "https://github.com/skk-dev/dict/raw/refs/heads/master/zipcode/SKK-JISYO.office.zipcode",
    name = "SKK-JISYO.office.zipcode",
    encoding = "euc-jis-2004",
  },
  {
    url = "https://github.com/ansanloms/skk-dict-mountain/releases/latest/download/SKK-JISYO.mountain",
    name = "SKK-JISYO.mountain",
    encoding = "utf-8",
  },
}

-- 辞書ファイルの文字コードから iconv の変換元コードへの対応表。
-- skkeleton はロード時に euc-jp を pure-JS でデコードするため遅い。
-- ビルド時に UTF-8 へ寄せておき、ロードをネイティブデコード経路に乗せる。
-- euc-jis-2004 は TextDecoder が非対応で、UTF-8 化しておかないとロードに失敗する。
local iconvFrom = {
  ["euc-jp"] = "EUC-JP",
  ["euc-jis-2004"] = "EUC-JISX0213",
  ["utf-8"] = false,
}

return {
  {
    "vim-skk/skkeleton",
    dependencies = { "vim-denops/denops.vim" },
    build = function()
      local dictDir = vim.fn.expand(vim.fn.stdpath("data") .. "/skkeleton")
      if vim.fn.isdirectory(dictDir) == 0 then
        vim.fn.mkdir(dictDir, "p")
      end

      for _, dict in ipairs(dicts) do
        local filepath = vim.fn.expand(dictDir .. "/" .. dict.name)
        local from = iconvFrom[dict.encoding]

        if not from then
          -- 既に UTF-8。直接ダウンロードする。
          vim.system({
            "curl", "-L", "-f", "--silent", "--show-error",
            "-o", filepath, dict.url,
          }, { text = true }, function(result)
            vim.schedule(function()
              if result.code == 0 then
                vim.notify(string.format("[skkeleton] dict download succeeded: %s", dict.url), vim.log.levels.INFO)
              else
                vim.notify(string.format("[skkeleton] dict download failed: %s", dict.url), vim.log.levels.ERROR)
              end
            end)
          end)
        else
          -- ダウンロード後、iconv で UTF-8 へ変換する。
          local tmp = filepath .. ".raw"
          vim.system({
            "curl", "-L", "-f", "--silent", "--show-error",
            "-o", tmp, dict.url,
          }, { text = true }, function(dl)
            vim.schedule(function()
              if dl.code ~= 0 then
                vim.notify(string.format("[skkeleton] dict download failed: %s", dict.url), vim.log.levels.ERROR)
                return
              end
              vim.system({
                "iconv", "-f", from, "-t", "UTF-8", "-o", filepath, tmp,
              }, { text = true }, function(conv)
                vim.schedule(function()
                  vim.fn.delete(tmp)
                  if conv.code == 0 then
                    vim.notify(string.format("[skkeleton] dict converted to utf-8: %s", dict.name), vim.log.levels.INFO)
                  else
                    vim.notify(string.format("[skkeleton] dict iconv failed: %s", dict.name), vim.log.levels.ERROR)
                  end
                end)
              end)
            end)
          end)
        end
      end
    end,
    config = function()
      vim.fn["skkeleton#config"]({
        globalDictionaries = vim.tbl_map(function(path)
          -- ビルド時に全辞書を UTF-8 化済み。encoding を明示することで
          -- skkeleton 側の per-file エンコーディング判定 (encoding.detect) を省く。
          return { path, "utf-8" }
        end, vim.fs.find(function(name)
          -- 変換失敗時に残る .raw を辞書として拾わない。
          return not name:match("%.raw$")
        end, {
          path = vim.fn.expand(vim.fn.stdpath("data") .. "/skkeleton"),
          type = "file",
          limit = math.huge
        })),
        eggLikeNewline = true,
        keepState = true,
        showCandidatesCount = 2,
        registerConvertResult = true,
      })

      -- 辞書ロードは初回変換時まで遅延される (skkeleton の LazyCell)。
      -- 初期化完了直後に裏でロードを発火し、初回入力のレイテンシを起動直後へ移す。
      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-post",
        callback = function()
          vim.fn["skkeleton#notify_async"]("initialize", {})
        end,
      })

      vim.keymap.set(
        { "i", "c", "t" },
        [[<C-j>]],
        [[<Plug>(skkeleton-toggle)]],
        { noremap = true, desc = "skkeleton toggle" }
      )
    end,
  },
  {
    "NI57721/skkeleton-state-popup",
    config = function()
      vim.fn["skkeleton_state_popup#config"]({
        labels = {
          input = {
            hira = "かな",
            kata = "カナ",
            hankata = "ｶﾅ",
            zenkaku = "Ａ"
          },
          ["input:okurinasi"] = {
            hira = "▽",
            kata = "▽",
            hankata = "▽",
            abbrev = "ab"
          },
          ["input:okuriari"] = {
            hira = "▽",
            kata = "▽",
            hankata = "▽"
          },
          henkan = {
            hira = "▼",
            kata = "▼",
            hankata = "▼",
            abbrev = "ab"
          },
          latin = "_A",
        },
        opts = {
          relative = "cursor",
          col = 0,
          row = 1,
          anchor = "NW",
          zindex = 100,
          style = "minimal",
        },
      })
      vim.fn["skkeleton_state_popup#enable"]()
    end,
  },
  {
    "NI57721/skkeleton-henkan-highlight",
    config = function()
      vim.cmd("highlight SkkeletonHenkan gui=underline term=underline cterm=reverse")
    end,
  },
  { "Xantibody/blink-cmp-skkeleton" },
}
