# Niri 桌面配置

> 公开仓库版本：本机用户名与个人壁纸路径使用通用占位符，历史归档未上传。

## 活动配置

- `config.kdl`：唯一入口，只负责按顺序加载下面的模块。
- `conf.d/animations.kdl`：动画。
- `conf.d/window-rules.kdl`：通用窗口与 layer 规则。
- `conf.d/session.kdl`：显示器、环境、输入、布局、快捷键、启动项及补充规则。
- `scripts/`：壁纸、动态配色和空闲管理脚本。

## 动态配色

`templates/colors.kdl` 是 Matugen 模板，生成结果写入
`dynamic_colors.kdl`。后者会在更换壁纸时被覆盖，不应手动修改。

Waybar 对应的活动配置是 `../waybar/niri/config.jsonc` 和
`../waybar/niri/style.css`；其颜色模板与生成文件也位于该目录。

`archive/` 仅保存整理前的快照与未启用配置，不会被 Niri 加载。
