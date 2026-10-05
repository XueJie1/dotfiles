local jdtls = require 'jdtls'

-- 1. 定义基础路径 (确保在所有地方都能访问)
local mason_path = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
local launcher_jar = vim.fn.glob(mason_path .. '/plugins/org.eclipse.equinox.launcher_*.jar', true)
local config_dir = mason_path .. '/config_linux'

-- 2. 根目录识别逻辑 (针对多模块优化)
-- 优先寻找顶层标志，防止 jdtls 停留在子模块目录
local root_markers = { '.git', 'mvnw', 'gradlew' }
local root_dir = jdtls.setup.find_root(root_markers)

-- 如果没找到顶层标志，再找 pom.xml
if root_dir == '' then
  root_dir = jdtls.setup.find_root { 'pom.xml', 'build.gradle' }
end

-- 最终兜底
if root_dir == '' then
  root_dir = vim.fn.getcwd()
end

-- 3. 工作区路径 (基于确定的 root_dir，确保多模块共享一个工作区)
local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = vim.fn.stdpath 'cache' .. '/jdtls/workspace/' .. project_name

-- 4. 整合 Kickstart/blink.cmp 的能力
local capabilities = {}
local status_ok, blink = pcall(require, 'blink.cmp')
if status_ok then
  capabilities = blink.get_lsp_capabilities()
end

-- 5. 核心配置
local config = {
  cmd = {
    '/usr/lib/jvm/java-21-openjdk/bin/java', -- 运行服务自身的 JDK
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens',
    'java.base/java.util=ALL-UNNAMED',
    '--add-opens',
    'java.base/java.lang=ALL-UNNAMED',

    -- Lombok 代理 (必须在 -jar 之前)
    '-javaagent:' .. mason_path .. '/lombok.jar',

    '-jar',
    launcher_jar,
    '-configuration',
    config_dir,
    '-data',
    workspace_dir,
  },

  root_dir = root_dir,
  capabilities = capabilities,

  settings = {
    java = {
      configuration = {
        runtimes = {
          { name = 'JavaSE-1.8', path = '/usr/lib/jvm/java-8-openjdk/' },
          { name = 'JavaSE-11', path = '/usr/lib/jvm/java-11-openjdk/' },
          { name = 'JavaSE-17', path = '/usr/lib/jvm/java-17-openjdk/' },
          { name = 'JavaSE-21', path = '/usr/lib/jvm/java-21-openjdk/', default = true },
        },
      },
      -- 允许下载源码以供查看
      eclipse = { downloadSources = true },
      maven = { downloadSources = true },
      implementationsCodeLens = { enabled = true },
      referencesCodeLens = { enabled = true },
    },
  },

  on_attach = function(client, bufnr)
    -- 这里可以根据需要添加 jdtls 特有的快捷键
    -- 例如：require('jdtls').setup_dap({ hotcodereplace = 'auto' })
  end,
}

-- 6. 启动
jdtls.start_or_attach(config)
