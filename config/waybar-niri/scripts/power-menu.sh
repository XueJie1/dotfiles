#!/usr/bin/env bash

set -euo pipefail

# layer-shell 让半透明背景覆盖整个输出；3 列形成 3×2 的大按钮布局。
exec wlogout \
    --protocol layer-shell \
    --buttons-per-row 3 \
    --column-spacing 18 \
    --row-spacing 18 \
    --margin-top 120 \
    --margin-bottom 120 \
    --margin-left 160 \
    --margin-right 160
