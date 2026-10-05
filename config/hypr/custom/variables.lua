-- 用户自定义变量覆盖
-- 加载顺序: hyprland/variables.lua -> custom/variables.lua (见 hyprland/keybinds.lua:2-5)，
-- 所以这里赋值会覆盖上游默认值，且 dotfiles 更新不会冲突。

-- 默认文件管理器: nautilus 优先
-- launch_first_available.sh 取第一个存在的命令，nautilus 已装于 /usr/bin/nautilus
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'nautilus' 'dolphin' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
