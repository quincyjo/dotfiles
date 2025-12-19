if status is-interactive
    starship init fish | source
    fzf --fish | source

    fish_vi_key_bindings
    enable_transience

    # Got this to work by taking the bind from bind output.
    # Should just be the following, but kills the shell.
    # bind -M insert -m default ctrl-k
    bind -M insert ctrl-k """
       if commandline -P
            commandline -f cancel
       else
           set fish_bind_mode default
           if test (count (commandline --cut-at-cursor | tail -c2)) != 2
               commandline -f backward-char
           end
           commandline -f repaint-mode
       end"""

    bind -M visual -m default ctrl-k end-selection repaint-mode
    bind -M replace -m default ctrl-k cancel repaint-mode
    bind -M replace_ond -m default ctrl-k cancel repaint-mode
end

set fish_greeting

# TODO: Setup nvm, cargo, and sdkman
