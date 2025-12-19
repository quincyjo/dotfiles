#!/usr/bin/env bash
# Modified from: https://github.com/wfxr/tmux-power
# Adjusted in the following ways:
# - Remove the highlight FG and BG options for a full attr like the others.
# - Add optionally seperate prompts and affixes for right side.
# - Changes default affixes to be empty because if explicitly set to empty
#   they were being set to the default single space, removing the ability
#   to have no affixes.
# 
# This allows for the qubit theme to have its buffers on both sides change
# colours based on the highlight state but have different appearances.

set -e

# Place holder for status left/right
place_holder="\#{prefix_highlight}"

# Possible configurations
output_prefix='@prefix_highlight_output_prefix'
output_suffix='@prefix_highlight_output_suffix'
prefix_prompt='@prefix_highlight_prefix_prompt'
copy_prompt='@prefix_highlight_copy_prompt'
sync_prompt='@prefix_highlight_sync_prompt'
empty_prompt='@prefix_highlight_empty_prompt'
output_prefix_right='@prefix_highlight_output_prefix_right'
output_suffix_right='@prefix_highlight_output_suffix_right'
prefix_prompt_right='@prefix_highlight_prefix_prompt_right'
copy_prompt_right='@prefix_highlight_copy_prompt_right'
sync_prompt_right='@prefix_highlight_sync_prompt_right'
empty_prompt_right='@prefix_highlight_empty_prompt_right'

# Formats
prefix_attr_config='@prefix_highlight_attr'
copy_attr_config='@prefix_highlight_copy_mode_attr'
sync_attr_config='@prefix_highlight_sync_mode_attr'
empty_attr_config='@prefix_highlight_empty_attr'

# Global options
show_copy_config='@prefix_highlight_show_copy_mode'
show_sync_config='@prefix_highlight_show_sync_mode'
empty_has_affixes='@prefix_highlight_empty_has_affixes'

tmux_option() {
    local -r value=$(tmux show-option -gqv "$1")
    local -r default="$2"

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

format_style() {
    echo "#[${1}]" | sed -e 's/,/]#[/g'
}

# Defaults
default_attr='fg=colour231,bg=colour04'
default_copy_attr='fg=default,bg=yellow'
default_sync_attr='fg=default,bg=yellow'
default_empty_attr='fg=default,bg=default'
default_prefix_prompt=$(tmux_option prefix | tr "[:lower:]" "[:upper:]" | sed 's/C-/\^/')
default_copy_prompt='Copy'
default_sync_prompt='Sync'
default_empty_prompt=''
default_affix=''

main() {
    local -r \
        attr=$(tmux_option "$prefix_attr_config" "$default_attr") \
        show_copy_mode=$(tmux_option "$show_copy_config" "off") \
        show_sync_mode=$(tmux_option "$show_sync_config" "off") \
        empty_attr=$(tmux_option "$empty_attr_config" "$default_empty_attr") \
        empty_has_affixes=$(tmux_option "$empty_has_affixes" "off") \
        copy_attr=$(tmux_option "$copy_attr_config" "$default_copy_attr") \
        sync_attr=$(tmux_option "$sync_attr_config" "$default_sync_attr") \
        output_prefix=$(tmux_option "$output_prefix" "$default_affix") \
        output_suffix=$(tmux_option "$output_suffix" "$default_affix") \
        prefix_prompt=$(tmux_option "$prefix_prompt" "$default_prefix_prompt") \
        copy_prompt=$(tmux_option "$copy_prompt" "$default_copy_prompt") \
        sync_prompt=$(tmux_option "$sync_prompt" "$default_sync_prompt") \
        empty_prompt=$(tmux_option "$empty_prompt" "$default_empty_prompt") \
        output_prefix_right=$(tmux_option "$output_prefix_right" "$default_affix") \
        output_suffix_right=$(tmux_option "$output_suffix_right" "$default_affix") \
        prefix_prompt_right=$(tmux_option "$prefix_prompt_right" "$default_prefix_prompt") \
        copy_prompt_right=$(tmux_option "$copy_prompt_right" "$default_copy_prompt") \
        sync_prompt_right=$(tmux_option "$sync_prompt_right" "$default_sync_prompt") \
        empty_prompt_right=$(tmux_option "$empty_prompt_right" "$default_empty_prompt")

    local -r prefix_highlight="$(format_style "${attr:+default,$attr}")"
    local -r prefix_mode="$prefix_highlight$output_prefix$prefix_prompt$output_suffix"
    local -r prefix_mode_right="$prefix_highlight$output_prefix_right$prefix_prompt_right$output_suffix_right"

    local -r copy_highlight="$(format_style "${copy_attr:+default,$copy_attr}")"
    local -r copy_mode="$copy_highlight$output_prefix$copy_prompt$output_suffix"
    local -r copy_mode_right="$copy_highlight$output_prefix_right$copy_prompt_right$output_suffix_right"

    local -r sync_highlight="$(format_style "${sync_attr:+default,$sync_attr}")"
    local -r sync_mode="$sync_highlight$output_prefix$sync_prompt$output_suffix"
    local -r sync_mode_right="$sync_highlight$output_prefix_right$sync_prompt_right$output_suffix_right"

    local -r empty_highlight="$(format_style "${empty_attr:+default,$empty_attr}")"
    if [[ "on" = "$empty_has_affixes" ]]; then
        local -r empty_mode="$empty_highlight$output_prefix$empty_prompt$output_suffix"
        local -r empty_mode_right="$empty_highlight$output_prefix_right$empty_prompt_right$output_suffix_right"
    else
        local -r empty_mode="$empty_highlight$empty_prompt"
        local -r empty_mode_right="$empty_highlight$empty_prompt_right"
    fi

    if [[ "on" = "$show_copy_mode" ]]; then
        if [[ "on" = "$show_sync_mode" ]]; then
            local -r fallback="#{?pane_in_mode,$copy_mode,#{?synchronize-panes,$sync_mode,$empty_mode}}"
            local -r fallback_right="#{?pane_in_mode,$copy_mode_right,#{?synchronize-panes,$sync_mode_right,$empty_mode_right}}"
        else
            local -r fallback="#{?pane_in_mode,$copy_mode,$empty_mode}"
            local -r fallback_right="#{?pane_in_mode,$copy_mode_right,$empty_mode_right}"
        fi
    elif [[ "on" = "$show_sync_mode" ]]; then
        local -r fallback="#{?synchronize-panes,$sync_mode,$empty_mode}"
        local -r fallback_right="#{?synchronize-panes,$sync_mode_right,$empty_mode_right}"
    else
        local -r fallback="$empty_mode"
        local -r fallback="$empty_mode_right"
    fi

    local -r highlight="#{?client_prefix,$prefix_mode,$fallback}#[default]"
    local -r highlight_right="#{?client_prefix,$prefix_mode_right,$fallback_right}#[default]"

    local -r status_left_value="$(tmux_option "status-left")"
    tmux set-option -gq "status-left" "${status_left_value//$place_holder/$highlight}"

    local -r status_right_value="$(tmux_option "status-right")"
    tmux set-option -gq "status-right" "${status_right_value//$place_holder/$highlight_right}"

    local -r status_format_0_value="$(tmux_option "status-format[0]")"
    tmux set-option -gq "status-format[0]" "${status_format_0_value//$place_holder/$highlight}"

    local -r status_format_1_value="$(tmux_option "status-format[1]")"
    tmux set-option -gq "status-format[1]" "${status_format_1_value//$place_holder/$highlight_right}"

}

main
