#!/usr/bin/env bash
#===============================================================================
#   Author: quincyjo
#   Date: November 2025
#   Description: qubit theme for tmux. Like all qubit themes, it is driven by
#                environment variables where possible.
#   Requires:
#     - My custom modification of tmux-prefix-highlight,
#         or
#     - https://github.com/tmux-plugins/tmux-prefix-highlight
#       and use right gutter without highlight. It won't change color with the
#       left gutter, in this chase.
#         or
#     - Use the highlight free gutters by uncommenting the relevant lines below
#       for both the left and the right status.
#===============================================================================

# $1: option
# $2: value
tmux_set() {
    tmux set-option -gq "$1" "$2"
}

# Resolves the theme color based on environment capabilities and theme
# definitions.
# $1: true color value
# $2: 256 color value
# $3: fallback color value
theme_or() {
    (([ -n "$1" ] && ([ "$COLORTERM" = truecolor ] || [ "$COLORTERM" = 24bit ])) && echo "$1") || 
        ([ -n "$2" ] && [ "${TERM%"256"}" != "$TERM" ] && echo "colour$2") ||
        echo "colour$3"
}

# tmux set-option -g default-terminal "tmux-256color"

# Options
rslash=''
lslash=''
rtab=''
ltab=''
rtab_2=''
ltab_2=''
rdivider=''
ldivider=''
session_icon=''
#   󰩃 󰪭
user_icon=''
time_icon=''
date_icon=''
time_format='%T'
date_format='%F'

COLOR_GUTTER="$(theme_or "$THEME_TRUE_RED" "$THEME_256_RED" 1)"
COLOR_1="$(theme_or "$THEME_TRUE_YELLOW" "$THEME_256_YELLOW" 3)"
COLOR_2="$(theme_or "$THEME_TRUE_BLUE" "$THEME_256_BLUE" 4)"
COLOR_3="$(theme_or "$THEME_TRUE_PURPLE" "$THEME_256_PURPLE" 5)"

COLOR_ACTIVE="$(theme_or "$THEME_TRUE_YELLOW" "$THEME_256_YELLOW" 3)"
COLOR_INACTIVE="$(theme_or "$THEME_TRUE_PURPLE" "$THEME_256_PURPLE" 5)"
COLOR_BG="$(theme_or "$THEME_TRUE_BG" "$THEME_256_BG" 0)"
COLOR_BG_2="$(theme_or "$THEME_TRUE_BG2" "$THEME_256_BG2" 8)"
COLOR_FG="$(theme_or "$THEME_TRUE_FG" "$THEME_256_FG" 7)"
COLOR_FG_2="$(theme_or "$THEME_TRUE_FG_BRIGHT" "$THEME_256_FG_BRIGHT" 15)"

# Status options
tmux_set status-interval 1
tmux_set status on

# Basic status bar colors
tmux_set status-bg "$COLOR_BG"
tmux_set status-fg "$COLOR_1"
tmux-set status-style "fg=$COLOR_1,bg=$COLOR_BG"
tmux_set status-attr none
tmux_set status-left-style "bg=$COLOR_BG"
tmux_set status-right-style "bg=$COLOR_BG"
tmux_set status-left-length 150
tmux_set status-right-length 150

# tmux-prefix-highlight
tmux_set @prefix_highlight_show_copy_mode    'on'
tmux_set @prefix_highlight_show_sync_mode    'on'
tmux_set @prefix_highlight_empty_has_affixes 'on'
tmux_set @prefix_highlight_copy_mode_attr    "fg=$COLOR_FG_2,bg=$COLOR_3,bold"
tmux_set @prefix_highlight_sync_mode_attr    "fg=$COLOR_FG_2,bg=$COLOR_2,bold"
tmux_set @prefix_highlight_empty_attr        "fg=$COLOR_FG_2,bg=$COLOR_GUTTER,bold"
tmux_set @prefix_highlight_attr              "fg=$COLOR_BG,bg=$COLOR_1,bold"
# highlight seems to be adding a leading space, so we trim that here
tmux_set @prefix_highlight_empty_prompt      ' TMUX '
tmux_set @prefix_highlight_prefix_prompt     '  󰘴A  '
tmux_set @prefix_highlight_copy_prompt       '  C  '
tmux_set @prefix_highlight_sync_prompt       '  S  '
tmux_set @prefix_highlight_output_prefix     ''
tmux_set @prefix_highlight_output_suffix     "#[fg=$COLOR_BG]$lslash"
# Right
tmux_set @prefix_highlight_empty_prompt_right      '  '
tmux_set @prefix_highlight_prefix_prompt_right     '  '
tmux_set @prefix_highlight_copy_prompt_right       '  '
tmux_set @prefix_highlight_sync_prompt_right       '  '
tmux_set @prefix_highlight_output_prefix_right     "#[fg=$COLOR_BG]$rslash"
tmux_set @prefix_highlight_output_suffix_right     ''

# Fingers
tmux_set @fingers-hint-style               "fg=$COLOR_ACTIVE,bold"
tmux_set @fingers-highlight-style          "fg=$COLOR_INACTIVE"
tmux_set @fingers-selected-hint-style      "fg=$COLOR_GUTTER,bold"
tmux_set @fingers-selected-highlight-style "fg=$COLOR_2"



# Left side of status
# tmux_set status-left-bg "$COLOR_BG"
# tmux_set status-left-length 150

# Gutter
LS="#{prefix_highlight}"
# Gutter without prefix-hightlight 
# LS="#[bg=$COLOR_GUTTER,fg=$COLOR_FG_2] TMUX #[bg=$COLOR_BG,fg=$COLOR_GUTTER]$rslash"

# user@host
LS="$LS#[fg=$COLOR_1,bg=$COLOR_BG,bold] $user_icon $(whoami)@#h $rdivider"

# session
LS="$LS#[fg=$COLOR_2,bg=$COLOR_BG,nobold] $session_icon #S:#{window_index}.#{pane_index} $rdivider"

tmux_set status-left "$LS "

# Right side of status
# tmux_set status-right-bg "$COLOR_BG"
# tmux_set status-right-length 150

# Time
RS="#[fg=$COLOR_2,bg=$COLOR_BG]$ldivider $time_icon $time_format "

# Date
RS="$RS#[fg=$COLOR_1,bg=$COLOR_BG]$ldivider $date_icon $date_format "

# Gutter
tmux_set status-right "$RS#{prefix_highlight}"
# highlight free gutter.
# tmux_set status-right "$RS#[fg=$COLOR_GUTTER]$lslash#[bg=$COLOR_GUTTER] "

# Window status format
tmux_set window-status-format         "#[fg=$COLOR_INACTIVE,bg=$COLOR_BG]$rtab_2 #I:#W#F $ltab_2"
tmux_set window-status-current-format "#[fg=$COLOR_ACTIVE,bg=$COLOR_BG]$ltab#[fg=$COLOR_BG,bg=$COLOR_ACTIVE,bold] #I:#W#F #[fg=$COLOR_ACTIVE,bg=$COLOR_BG,nobold]$rtab"

# Window status style
tmux_set window-status-style          "fg=$COLOR_INACTIVE,bg=$COLOR_2,none"
tmux_set window-status-last-style     "fg=$COLOR_INACTIVE,bg=$COLOR_BG,bold"
tmux_set window-status-activity-style "fg=$COLOR_GUTTER,bg=$COLOR_BG,bold"

# Window separator
tmux_set window-status-separator " "

# Pane border
tmux_set pane-border-style "fg=$COLOR_INACTIVE,bg=default"

# Active pane border
tmux_set pane-active-border-style "fg=$COLOR_ACTIVE,bg=default"

# Pane number indicator
tmux_set display-panes-colour "$COLOR_INACTIVE"
tmux_set display-panes-active-colour "$COLOR_ACTIVE"

# Clock mode
tmux_set clock-mode-colour "$COLOR_1"
tmux_set clock-mode-style 24

# Message
tmux_set message-style "fg=$COLOR_1,bg=$COLOR_BG"

# Command message
tmux_set message-command-style "fg=$COLOR_1,bg=$COLOR_BG"

# Copy mode highlight
tmux_set mode-style "bg=$COLOR_3,fg=$COLOR_FG_2"

