#!/bin/bash

# 显示一个包含 "Yes" 和 "No" 的 Rofi 菜单
chosen=$(echo -e "No\nYes" | rofi -dmenu -i -p "Do you really want to exit i3?")

# 如果用户选择了 "Yes"
if [ "$chosen" == "Yes" ]; then
    # 执行 i3 的退出命令
    i3-msg exit
fi
