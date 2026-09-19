#!/usr/bin/env bash
# mpvpaper 的 matugen 包装器
#
# 在启动 mpvpaper 之前，用 ffmpeg 抽取视频首帧，触发一次 matugen 颜色更新
# （生成 Material You 配色并刷新 niri / waybar / fuzzel / fcitx5 等所有模板），
# 随后透传全部参数给 mpvpaper。
#
# 用法与 mpvpaper 完全一致，可直接替换 mpvpaper 调用：
#   mpvpaper-matugen.sh '*' ~/Videos/foo.mp4 -o "--loop-file"
#
# 设计原则：颜色更新是“尽力而为”——任何一步失败都不应阻止 mpvpaper 启动。

set -u

# ---- 1. 从参数中识别视频源 ----------------------------------------------
# mpvpaper 的参数形如：[选项] <output> <url|path> [-o "mpv 选项"]
# 视频源 = 第一个“已存在的文件”或 http(s) URL。output(如 *、DP-2)、
# -o 及其值都不是文件，因此能可靠定位到视频。
VIDEO=""
for arg in "$@"; do
    case "$arg" in
        http://*|https://*) VIDEO="$arg"; break ;;
        *)
            if [ -f "$arg" ]; then VIDEO="$arg"; break; fi
            ;;
    esac
done

# ---- 2. 抽首帧 + matugen 颜色更新 --------------------------------------
if [ -n "$VIDEO" ]; then
    CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mpvpaper-matugen"
    FRAME="$CACHE_DIR/first_frame.png"
    # 同时建好 matugen 自身缓存目录，缺失时 matugen 4.1 会报 failed to store cache
    mkdir -p "$CACHE_DIR" "${XDG_CACHE_HOME:-$HOME/.cache}/matugen" 2>/dev/null || true

    # -frames:v 1 抽取第 1 个视频帧；-an 丢弃音频；失败则跳过颜色更新
    if ffmpeg -y -hide_banner -loglevel error -i "$VIDEO" -frames:v 1 -an "$FRAME" 2>/dev/null; then
        # 复用 change_wallpaper.sh 中验证过的调用方式：
        #   -m dark                暗色模式（与 config.toml 一致）
        #   --source-color-index 0 取最主色（索引 0-4），避免 matugen 在
        #                         无终端时因“多候选色”而报错退出
        if ! matugen image "$FRAME" -m dark --source-color-index 0 -q 2>"$CACHE_DIR/matugen.log"; then
            echo "mpvpaper-matugen: matugen 失败，日志见 $CACHE_DIR/matugen.log" >&2
        fi
    else
        echo "mpvpaper-matugen: 抽取首帧失败：$VIDEO" >&2
    fi
fi

# ---- 3. 透传给真正的 mpvpaper ------------------------------------------
# exec 替换进程：保持环境变量（如 VK_ICD_FILENAMES）与信号行为一致
exec mpvpaper "$@"
