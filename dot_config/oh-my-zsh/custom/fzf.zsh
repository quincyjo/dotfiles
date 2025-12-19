# Setup fzf
# ---------
# Setups up fzf, adding it to the path if it is installed locally and sourcing
# the zsh script for it, adding its shipped keybindings to the shell.
# Also sets up base configuration for fzf, the fzf-tab plugin, and the
# keybindings.

# If fzf is installed and available, source and configure the bidnings.
if command -v fzf &>/dev/null; then
  zvm_after_init_commands+=('source <(fzf --zsh)')

  FZF_PREVIEW="if [ -d {} ]; then $DIRECTORY_PREVIEW {}; else $FILE_PREVIEW {}; fi"

  # Base FZF default options.
  export FZF_DEFAULT_OPTS="--height 40% --tmux bottom,90%,40% --color=bg:$THEME_256_BG \
    --color=fg:$THEME_256_FG,hl:$THEME_256_CYAN,hl+:$THEME_256_YELLOW,info:$THEME_256_BLUE,pointer:$THEME_256_RED,marker:$THEME_256_RED \
    --layout reverse --border rounded --ansi --preview-window=border-line --color=preview-border:gray:dim \
    --preview '$FZF_PREVIEW'"

  # Use fdfind if it is installed.
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND="fd --hidden --exclude .git --color=always --strip-cwd-prefix"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND --type file"
    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type directory"
  fi

  # Keybinding widget styling
  export FZF_CTRL_R_OPTS="--no-preview --color=label:$THEME_256_GREEN --border-label=' History '"

  # Preview when scrolled, show selected list when multi select.
  # no-preview for performance since binds handle it.
  export FZF_CTRL_T_OPTS="--no-preview --color=label:$THEME_256_PURPLE --input-label=' Target File(s) ' \
    --input-border top --preview-border top \
    --bind 'multi:change-preview(printf \"%s\\n\" {+})+transform-preview-label(echo \" Selected Files \")' \
    --bind 'focus:change-preview($FILE_PREVIEW {})+transform-preview-label(echo \" {} \")'"

  export FZF_ALT_C_OPTS="--color=label:$THEME_256_BLUE \
    --bind 'focus:transform-border-label:[[ -n {} ]] && printf \" cd %s \" {}'"

  export FZF_ALT_C_OPTS="--color=label:$THEME_256_BLUE \
    --input-border top --preview-border top \
    --bind 'focus:transform-input-label(echo \" cd \")+transform-preview-label(printf \" {} \" {})'"
fi

