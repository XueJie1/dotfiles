return {
  'olimorris/codecompanion.nvim',
  version = '^19.0.0',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  -- 快捷键：<leader>gl — 打开/切换聊天窗口
  keys = {
    { '<leader>gl', function() require('codecompanion').chat() end, mode = { 'n', 'v' }, desc = '[G]o [L]LM chat' },
  },
  opts = {
    -- 设置回复语言为中文
    language = "Chinese",

    -- 默认使用 DeepSeek 适配器
    interactions = {
      chat = {
        adapter = 'deepseek',
      },
      inline = {
        adapter = 'deepseek',
      },
    },

    -- DeepSeek 适配器配置
    -- 内置 deepseek 适配器默认从环境变量 DEEPSEEK_API_KEY 读取密钥，因此无需覆盖 env。
    -- 请在 shell 中设置：export DEEPSEEK_API_KEY="sk-your-key-here"
    -- 若使用 1Password CLI，可改为覆盖：env = { api_key = 'cmd:op read op://personal/DeepSeek/credential --no-newline' }
    adapters = {
      http = {
        deepseek = function()
          return require('codecompanion.adapters').extend('deepseek', {
            schema = {
              model = {
                default = 'deepseek-v4-flash',
              },
            },
          })
        end,
      },
    },
  },
}
