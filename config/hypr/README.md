# Hyprland 配置说明

本目录是当前 Hyprland 会话使用的配置目录。入口文件是
[`hyprland.lua`](hyprland.lua)，它会依次加载 `hyprland/` 中的默认设置，
再加载 `custom/` 中的个人覆盖设置。

## 常用操作

| 操作 | 快捷键 |
| --- | --- |
| 打开应用启动器 | 连按两次 `Super`（Windows 键） |
| 工作区总览 | `Super + Tab` |
| 剪贴板历史 | `Super + V` |
| Emoji 选择器 | `Super + .` |
| 区域截图到剪贴板 | `Super + Shift + S` |
| 关闭窗口 | `Super + Q` |
| 切换全屏 | `Super + F` |
| 重新启动桌面小组件 | `Ctrl + Super + R` |

完整快捷键见 [`hyprland/keybinds.lua`](hyprland/keybinds.lua)。

## 显示器设置

当前全局显示器设置在 [`hyprland/general.lua`](hyprland/general.lua) 顶部：

```lua
hl.monitor({
    output = "",              -- 空字符串：应用到所有显示器
    mode = "1920x1080@165",   -- 分辨率和刷新率
    position = "auto",        -- 自动排列多显示器
    scale = 1.2,               -- UI 缩放；1.25 即 125%
})
```

修改 `mode` 可改变分辨率或刷新率，例如 `"1920x1080@165"`；修改 `scale`
可改变界面大小，例如 `1.25` 为 125%。修改后运行：

```sh
hyprctl reload
```

如果屏幕黑屏或不支持指定模式，登录 TTY 后把 `mode` 改回 `"preferred"`，
或把 `scale` 改回 `1`，再重新加载/重新登录。

## 推荐的个人修改方式

主题的默认文件位于 `hyprland/`，更新主题时可能被覆盖。个人调整建议放到
`custom/` 下同名文件，例如在 `custom/general.lua` 中添加自己的 `hl.monitor(...)`
设置；该文件会在默认设置之后加载并覆盖它。

## 相关组件

- 小组件、侧边栏、概览和启动器：`~/.config/quickshell/ii`
- 锁屏：[`hyprlock.conf`](hyprlock.conf)
- 空闲与自动锁屏：[`hypridle.conf`](hypridle.conf)
- 安装来源和注意事项：[`INSTALL-NOTES.md`](INSTALL-NOTES.md)
