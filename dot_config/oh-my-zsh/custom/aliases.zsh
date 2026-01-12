# Eza or ls?
if command -v eza &>/dev/null; then
  alias l="eza -lhG --git --git-repos --color=always"
  alias lt="l -T --level=3"
else
  alias l="ls -l --color=awlays"
fi

alias la="l -A"

alias up="cd .."
alias back="cd $OLDPWD"

# Only alias nvim over vi if installed.
if command -v nvim &>/dev/null; then
  alias v="nvim"
  alias vi="nvim"
  alias vim="nvim"
fi

# This don't matter if they aren't installed
alias ran="ranger"
alias ra="ranger"
alias vf="vifm"

alias zshconfig="$EDITOR ~/.config/zsh/zshrc"

