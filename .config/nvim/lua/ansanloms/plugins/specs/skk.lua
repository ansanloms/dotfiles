-- skk (skkelua.nvim)。

---@class SkkDict
---@field url string ダウンロード元 URL
---@field name string 保存先ファイル名
---@field encoding "euc-jp"|"euc-jis-2004"|"utf-8" 配布物の文字コード

-- ダウンロード対象の辞書定義。build 時に取得し、必要なら UTF-8 へ変換する。
---@type SkkDict[]
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
-- skkelua はエンコーディングを自動判定できるが、euc-jis-2004 の対応は未確認のため、
-- ビルド時に UTF-8 へ正規化して渡す。
local iconvFrom = {
  ["euc-jp"] = "EUC-JP",
  ["euc-jis-2004"] = "EUC-JISX0213",
  ["utf-8"] = false,
}

-- 辞書の保存先。skkelua の既定ユーザ辞書 stdpath("data")/skkelua/jisyo と
-- 同じ階層に置くと vim.fs.find が拾うため、サブディレクトリに分ける。
local function dictDirPath()
  return vim.fn.expand(vim.fn.stdpath("data") .. "/skkelua/dict")
end

return {
  "kjuq/skkelua.nvim",
  build = function()
    local dictDir = dictDirPath()
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
              vim.notify(string.format("[skkelua] dict download succeeded: %s", dict.url), vim.log.levels.INFO)
            else
              vim.notify(string.format("[skkelua] dict download failed: %s", dict.url), vim.log.levels.ERROR)
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
              vim.notify(string.format("[skkelua] dict download failed: %s", dict.url), vim.log.levels.ERROR)
              return
            end
            vim.system({
              "iconv", "-f", from, "-t", "UTF-8", "-o", filepath, tmp,
            }, { text = true }, function(conv)
              vim.schedule(function()
                vim.fn.delete(tmp)
                if conv.code == 0 then
                  vim.notify(string.format("[skkelua] dict converted to utf-8: %s", dict.name), vim.log.levels.INFO)
                else
                  vim.notify(string.format("[skkelua] dict iconv failed: %s", dict.name), vim.log.levels.ERROR)
                end
              end)
            end)
          end)
        end)
      end
    end
  end,
  config = function()
    local skkelua = require("skkelua")
    skkelua.config({
      globalDictionaries = vim.tbl_map(function(path)
        return { path, "utf-8" }
      end, vim.fs.find(function(name)
        -- 変換失敗時に残る .raw を辞書として拾わない。
        return not name:match("%.raw$")
      end, {
        path = dictDirPath(),
        type = "file",
        limit = math.huge,
      })),
      eggLikeNewline = true,
      keepState = true,
      showCandidatesCount = 2,
      registerConvertResult = true,
      completion = { enabled = true },
      indicator = {
        enabled = true,
        alwaysShown = true,
        fadeOutMs = 0,
        eijiText = "_A",
        hiraText = "かな",
        kataText = "カナ",
        hankataText = "ｶﾅ",
        zenkakuText = "Ａ",
        abbrevText = "ab",
      },
    })

    vim.keymap.set(
      { "i", "c", "t" },
      [[<C-j>]],
      [[<Plug>(skkelua-toggle)]],
      { noremap = true, desc = "skkelua toggle" }
    )
  end,
}
