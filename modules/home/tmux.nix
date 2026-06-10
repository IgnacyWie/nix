{ config, ... }:

{
  home.file.".tmux.conf" = {
    force = true;
    text = ''
      source-file ${config.xdg.configHome}/tmux/tmux.conf
    '';
  };

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    mouse = true;
    package = null;
    shell = "/bin/zsh";
    terminal = "tmux-256color";

    extraConfig = ''
      bind-key -r f run-shell "tmux neww ~/.local/scripts/tmux-sessionizer"

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'pbcopy'

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

      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'christoomey/vim-tmux-navigator'
      set -g @plugin 'seebi/tmux-colors-solarized'
      set -g @plugin 'niksingh710/minimal-tmux-status'

      set -g @minimal-tmux-status "top"
      set -g @minimal-tmux-bg "#278BD3"
      set -g @colors-solarized 'dark'

      if-shell 'test -x ~/.tmux/plugins/tpm/tpm' 'run-shell ~/.tmux/plugins/tpm/tpm'

      unbind -n C-l

      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'
    '';
  };
}
