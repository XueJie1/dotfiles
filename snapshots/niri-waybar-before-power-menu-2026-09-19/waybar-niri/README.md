# Niri Waybar 配置

- `config.jsonc`：Niri 会话当前加载的模块配置。
- `style.css`：当前样式，导入 `dynamic_colors.css`。
- `templates/colors.css`：Matugen 颜色模板。
- `dynamic_colors.css`：Matugen 生成文件，不应手动修改。
- `archive/`：历史配置，不参与当前会话。

启动命令由 `../../niri/conf.d/session.kdl` 调用。Matugen 的输入、输出与
刷新命令统一定义在 `../../matugen/config.toml`。
