return {
  'milanglacier/minuet-ai.nvim',
  version = '^0.9.0',
  dependencies = {
    -- 可选：如果使用 virtual-text 前端则不需要 cmp，但 blink.cmp 已安装
    -- 'hrsh7th/nvim-cmp',
    -- 'Saghen/blink.cmp', -- 已在主配置中声明
  },
  config = function()
    require('minuet').setup {
      -- === 提供商：DeepSeek（与 codecompanion 保持一致） ===
      provider = 'openai_compatible',
      provider_options = {
        openai_compatible = {
          name = 'DeepSeek',
          api_key = 'DEEPSEEK_API_KEY',
          end_point = 'https://api.deepseek.com/v1/chat/completions',
          model = 'deepseek-v4-flash',
          optional = {
            max_tokens = 256,
            top_p = 0.9,
            -- Minuet 的 OpenAI 兼容流式解析只消费 delta.content；关闭思考模式，
            -- 避免 DeepSeek V4 先返回 reasoning_content 时被误报为流式错误。
            thinking = { type = 'disabled' },
          },
          stream = true,
        },
      },

      -- === 虚拟文本前端（行内幽灵文本） ===
      virtualtext = {
        -- 在哪些文件类型中自动触发补全，{} 表示仅手动触发
        auto_trigger_ft = {},
        -- 自动触发的排除文件类型（当 auto_trigger_ft = { '*' } 时有用）
        auto_trigger_ignore_ft = {},
        keymap = {
          accept = '<A-A>', -- 接受整个补全
          accept_line = '<A-a>', -- 只接受一行
          accept_n_lines = '<A-z>', -- 接受 n 行（会提示输入数量）
          prev = '<A-[>', -- 上一个补全项 / 手动触发（也可用 <M-[>）
          next = '<A-]>', -- 下一个补全项 / 手动触发（也可用 <M-]>）
          dismiss = '<A-e>', -- 关闭当前补全
        },
        -- 当补全菜单（cmp / blink）显示时是否同时展示幽灵文本
        show_on_completion_menu = false,
      },

      -- === LSP 补全集成（Neovim 内置补全菜单） ===
      lsp = {
        completion = {
          enable = false,
          adjust_indentation = true,
          enabled_auto_trigger_ft = {},
          disabled_auto_trigger_ft = {},
        },
        inline_completion = {
          enable = false,
          enabled_auto_trigger_ft = {},
          disabled_auto_trigger_ft = {},
        },
      },

      -- === 通用配置 ===
      n_completions = 3, -- 每次请求生成的补全项数量
      context_window = 16000, -- 上下文窗口（字符数）
      context_ratio = 0.75, -- 光标前后上下文比例
      throttle = 1000, -- 请求节流（毫秒）
      debounce = 400, -- 请求防抖（毫秒）
      request_timeout = 3, -- 请求超时（秒）
      notify = 'warn', -- 通知级别：false / "debug" / "verbose" / "warn" / "error"
      curl_cmd = 'curl',
      curl_extra_args = {},
      add_single_line_entry = true, -- 多行补全时也生成单行条目
    }
  end,
}
