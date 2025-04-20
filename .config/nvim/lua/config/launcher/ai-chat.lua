local M = {}

M.title = "🤖 AI Chat"

M.tasks = {
  {
    name = "🤖 OpenAI - GPT-4o mini",
    execute = function()
      vim.fn["denops#request"](
        "ramble",
        "new",
        {
          "OpenAI",
          {
            model = "gpt-4o-mini",
          },
          {
            {
              role = "system",
              type = "text",
              message = ""
            },
            {
              role = "user",
              type = "text",
              message = ""
            }
          }
        }
      )
    end,
  },
  {
    name = "🤖 OpenAI - o1-mini",
    execute = function()
      vim.fn["denops#request"](
        "ramble",
        "new",
        {
          "OpenAI",
          {
            model = "o1-mini-2024-09-12",
          },
          {
            {
              role = "user",
              type = "text",
              message = ""
            }
          }
        }
      )
    end,
  },
  {
    name = "🤖 Google - Gemini Pro",
    execute = function()
      vim.fn["denops#request"](
        "ramble",
        "new",
        {
          "GoogleGenerativeAI",
          {
            model = "gemini-pro",
          },
          {
            {
              role = "system",
              type = "text",
              message = ""
            },
            {
              role = "user",
              type = "text",
              message = ""
            }
          }
        }
      )
    end,
  },
  {
    name = "🤖 Anthropic - Claude 3.7 Sonnet",
    execute = function()
      vim.fn["denops#request"](
        "ramble",
        "new",
        {
          "Anthropic",
          {
            model = "claude-3-7-sonnet-20250219",
          },
          {
            {
              role = "system",
              type = "text",
              message = "あなたはプロフェッショナルのフルスタックエンジニアです。それを念頭にアドバイスしてください。一度の説明は最大 300 文字程度にしてください。"
            },
            {
              role = "user",
              type = "text",
              message = ""
            }
          }
        }
      )
    end,
  },
  {
    name = "Config",
    execute = function()
      vim.fn["denops#request"](
        "ramble",
        "config",
        {}
      )
    end,
  },
  {
    name = "Chat",
    execute = function()
      vim.fn["denops#request"](
        "ramble",
        "chat",
        { vim.api.nvim_get_current_buf()  }
      )
    end,
  },
}

return M
