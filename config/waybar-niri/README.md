# Niri Waybar 配置

> 公开仓库版本：历史归档未上传。

- `config.jsonc`：Niri 会话当前加载的模块配置。
- `style.css`：当前样式，导入 `dynamic_colors.css`。
- `scripts/power-menu.sh`：启动全屏 MD3 风格的 Wlogout 电源面板。
- `scripts/platform-profile.sh`：显示并切换 ACPI 平台能效模式；优先使用
  Polkit 图形认证，失败时在 Kitty 中执行 `sudo tee`。
- `templates/colors.css`：Matugen 颜色模板。
- `dynamic_colors.css`：Matugen 生成文件，不应手动修改。
- `archive/`：历史配置，不参与当前会话。

启动命令由 `../../niri/conf.d/session.kdl` 调用。Matugen 的输入、输出与
刷新命令统一定义在 `../../matugen/config.toml`。
