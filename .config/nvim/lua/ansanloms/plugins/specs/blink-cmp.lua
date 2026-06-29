return {
  "saghen/blink.cmp",
  version = "1.*",
  config = function()
    require("blink.cmp").setup({
      -- fuzzy matcher 設定
      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },

      -- スニペット設定（vim-vsnip を使用）
      snippets = {
        preset = "vsnip",
      },

      -- キーマッピング
      keymap = {
        preset = "none",
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        --["<C-k>"] = { "select_prev", "fallback" },
        --["<C-j>"] = { "select_next", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-l>"] = { "show", "fallback" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Space>"] = {} -- Required: Let skkeleton handle Space
      },

      -- 補完ソース
      sources = {
        default = function()
          if require("blink-cmp-skkeleton").is_enabled() then
            return { "skkeleton" }
          else
            return { "lsp", "path", "snippets" }
          end
        end,
        providers = {
          skkeleton = {
            name = "skkeleton",
            module = "blink-cmp-skkeleton",
          },
          path = {
            opts = {
              get_cwd = function(context)
                local col = context.bounds.start_col - (context.bounds.length == 0 and 1 or 0)
                local before = context.line:sub(1, col)

                -- ./ や ../ で始まるパスはバッファのディレクトリ起点
                if before:match('%./$') or before:match('%.%./$') then
                  return vim.fn.expand(('#%d:p:h'):format(context.bufnr))
                end

                -- それ以外（/ 含む）は pwd 起点
                return vim.fn.getcwd()
              end,
              -- / をルート(/)ではなく get_cwd() 起点にする
              ignore_root_slash = true,
              -- ドットファイル（隠しファイル）を補完候補に表示する
              show_hidden_files_by_default = true,
            },
          },
        },
      },

      -- 補完メニュー設定
      completion = {
        ghost_text = {
          enabled = true,
        },
        menu = {
          auto_show = true,
        },
      },

      -- シグネチャヘルプ（トリガー文字で自動表示）
      signature = {
        enabled = true,
        trigger = {
          enabled = true,
          show_on_trigger_character = true,
        },
      },
    })
  end,
}
