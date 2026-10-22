#!/bin/sh

set -u

socket_path=${1:-}
pane_id=${2:-${TMUX_PANE:-}}

if [ -z "$socket_path" ] || [ -z "$pane_id" ]; then
    exit 0
fi

tmux_cmd()
{
    tmux -S "$socket_path" "$@"
}

window_id=$(tmux_cmd display-message -p -t "$pane_id" '#{window_id}' 2>/dev/null)

if [ -z "$window_id" ]; then
    exit 0
fi

pane_count=$(tmux_cmd display-message -p -t "$pane_id" '#{window_panes}' 2>/dev/null)

case "$pane_count" in
    ''|*[!0-9]*)
        exit 0
        ;;
esac

if [ "$pane_count" -le 1 ]; then
    exit 0
fi

window_width=$(tmux_cmd display-message -p -t "$pane_id" '#{window_width}')
window_height=$(tmux_cmd display-message -p -t "$pane_id" '#{window_height}')

case "$window_width:$window_height" in
    ''|*[!0-9:]*)
        exit 0
        ;;
esac

target_width=$((window_width * 75 / 100))
target_height=$((window_height * 75 / 100))

# 使用窗口的绝对尺寸，避免 tmux 将百分比解释为父级布局的比例。
tmux_cmd resize-pane -t "$pane_id" -x "$target_width"
tmux_cmd resize-pane -t "$pane_id" -y "$target_height"
