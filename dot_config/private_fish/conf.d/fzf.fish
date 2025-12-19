# Setup fzf
# ---------
# Setups up fzf, adding it to the path if it is installed locally and sourcing
# the zsh script for it, adding its shipped keybindings to the shell.
# Also sets up base configuration for fzf, the fzf-tab plugin, and the
# keybindings.

# If fzf locally installed, ensure the local installation is on the path.
# if test -d ~/.fzf/bin && ! "$PATH" == *$HOME/.fzf/bin*
    # PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
    # end

if not command -v fzf &>/dev/null
    if test -d ~/.fzf/bin && not contains "$HOME/.fzf/bin" $PATH
        fish_add_path -a "$HOME/.fzf/bin"
    end
end

# If fzf is installed and available, source and configure the bidnings.
if command -v fzf &>/dev/null
  fzf --fish | source

  set FZF_PREVIEW "if [ -d {} ]; then $DIRECTORY_PREVIEW {}; else $FILE_PREVIEW {}; fi"

  # Base FZF default options.
  set -gx FZF_DEFAULT_OPTS "--height 40% --tmux bottom,90%,40% --color=bg:$THEME_256_BG \
    --color=fg:$THEME_256_FG,hl:$THEME_256_CYAN,hl+:$THEME_256_YELLOW,info:$THEME_256_BLUE,pointer:$THEME_256_RED,marker:$THEME_256_RED \
    --layout reverse --border rounded --ansi --preview-window=border-line --color=preview-border:gray:dim \
    --preview '$FZF_PREVIEW'"

  # Use fdfind if it is installed.
  if command -v fd &>/dev/null
    set -gx FZF_DEFAULT_COMMAND "fd --hidden --exclude .git --color=always --strip-cwd-prefix"
    set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND --type file"
    set -gx FZF_ALT_C_COMMAND "$FZF_DEFAULT_COMMAND --type directory"
  end

  # Keybinding widget styling
  set -gx FZF_CTRL_R_OPTS "--no-preview --color=label:$THEME_256_GREEN --border-label=' History '"

  # Preview when scrolled, show selected list when multi select.
  # no-preview for performance since binds handle it.
  set -gx FZF_CTRL_T_OPTS "--no-preview --color=label:$THEME_256_PURPLE --input-label=' Target File(s) ' \
    --input-border top --preview-border top \
    --bind 'multi:change-preview(printf \"%s\\n\" {+})+transform-preview-label(echo \" Selected Files \")' \
    --bind 'focus:change-preview($FILE_PREVIEW {})+transform-preview-label(echo \" {} \")'"

  set -gx FZF_ALT_C_OPTS "--color=label:$THEME_256_BLUE \
    --bind 'focus:transform-border-label:[[ -n {} ]] && printf \" cd %s \" {}'"

  set -gx FZF_ALT_C_OPTS "--color=label:$THEME_256_BLUE \
    --input-border top --preview-border top \
    --bind 'focus:transform-input-label(echo \" cd \")+transform-preview-label(printf \" {} \" {})'"
end

