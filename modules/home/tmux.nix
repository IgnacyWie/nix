{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.file.".tmux.conf" = {
    force = true;
    text = ''
      source-file ${config.xdg.configHome}/tmux/tmux.conf
    '';
  };

  home.file.".tmux/plugins/tpm" = {
    force = true;
    source = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tpm";
      rev = "99469c4a9b1ccf77fade25842dc7bafbc8ce9946";
      hash = "sha256-hW8mfwB8F9ZkTQ72WQp/1fy8KL1IIYMZBtZYIwZdMQc=";
    };
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    # Homebrew tmux 3.3a crashes in Ghostty when tmux handles mouse selection.
    mouse = false;
    package = null;
    shell = "/bin/zsh";
    terminal = "tmux-256color";

    extraConfig = ''
      bind-key -n C-f display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/tmux-sessionizer"
      bind-key -r f display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/tmux-sessionizer"
      bind-key -n C-g display-popup -E -d "$HOME/typst" -w 90% -h 80% "~/.local/scripts/typst-smart-open"
      bind-key D display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/dev-command-runner"
      bind-key -n C-i display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/issue-picker"

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'

      # Codex and other full-screen terminal apps consume normal scroll input.
      # These no-prefix bindings make the scroll intent explicit to tmux first.
      bind-key -n S-Up copy-mode -u \; send-keys -X scroll-up
      bind-key -n S-Down copy-mode \; send-keys -X scroll-down
      bind-key -n S-PPage copy-mode -u \; send-keys -X page-up
      bind-key -n S-NPage copy-mode \; send-keys -X page-down
      bind-key -T copy-mode-vi S-Up send-keys -X scroll-up
      bind-key -T copy-mode-vi S-Down send-keys -X scroll-down
      bind-key -T copy-mode-vi S-PPage send-keys -X page-up
      bind-key -T copy-mode-vi S-NPage send-keys -X page-down

      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"

      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      set-option -g allow-rename off

      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none

      setw -g clock-mode-colour colour1
      setw -g mode-style 'fg=colour1 bg=colour18 bold'

      set -g pane-border-style 'fg=colour1'
      set -g pane-active-border-style 'fg=colour3'

      set -g status-justify left
      set -g status-style 'fg=colour1'
      set -g status-left ""
      set -g status-right '%Y-%m-%d %H:%M '
      set -g status-right-length 50
      set -g status-left-length 10

      setw -g window-status-current-format ' #I #W #F '
      setw -g window-status-style 'fg=colour1 dim'
      setw -g window-status-format ' #I #[fg=colour7]#W #[fg=colour1]#F '
      setw -g window-status-bell-style 'fg=colour2 bg=colour1 bold'

      set -g message-style 'fg=colour2 bg=colour0 bold'

      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R

      set-environment -g TMUX_PLUGIN_MANAGER_PATH ~/.tmux/plugins/

      set -g @plugin 'seebi/tmux-colors-solarized'
      set -g @plugin 'niksingh710/minimal-tmux-status'

      set -g @minimal-tmux-status "top"
      set -g @minimal-tmux-bg "#278BD3"
      set -g @colors-solarized 'dark'

      if-shell 'test -x ~/.tmux/plugins/tpm/tpm' 'run-shell ~/.tmux/plugins/tpm/tpm'

      unbind-key -n C-h
      unbind-key -n C-j
      unbind-key -n C-k
      unbind-key -n C-\\
      bind-key -n C-h display-popup -E -d "#{pane_current_path}" -w 90% -h 80% "~/.local/scripts/git-branch-switcher"

      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
    '';
  };

  home.activation.reloadTmuxConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
      run tmux source-file ${lib.escapeShellArg "${config.xdg.configHome}/tmux/tmux.conf"}
    fi
  '';
}
