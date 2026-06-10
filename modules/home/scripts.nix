{ ... }:

{
  home.file.".local/scripts/tmux-sessionizer" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash

      if [[ $# -eq 1 ]]; then
        selected=$1
      else
        selected=$(find ~/Developer -mindepth 1 -maxdepth 1 -type d | fzf)
      fi

      if [[ -z $selected ]]; then
        exit 0
      fi

      selected_name=$(basename "$selected" | tr . _)
      tmux_running=$(pgrep tmux)

      if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
        tmux new-session -s $selected_name -c $selected -d

        tmux rename-window -t $selected_name:0 "codex"
        tmux send-keys -t $selected_name:0 "codex" C-m

        tmux new-window -t $selected_name -n "node" -c $selected
        tmux send-keys -t $selected_name:1 "pnpm run dev" C-m

        tmux new-window -t $selected_name -n "misc" -c $selected

        tmux new-window -t $selected_name -n "git" -c $selected
        tmux send-keys -t $selected_name:3 "lazygit" C-m

        tmux new-window -t $selected_name -n "db" -c $selected
        tmux send-keys -t $selected_name:4 "lazysql" C-m

        tmux new-window -t $selected_name -n "rest" -c $selected
        tmux send-keys -t $selected_name:5 "posting" C-m

        tmux attach -t $selected_name
        exit 0
      fi

      if ! tmux has-session -t=$selected_name 2>/dev/null; then
        tmux new-session -ds $selected_name -c $selected

        tmux rename-window -t $selected_name:0 "codex"
        tmux send-keys -t $selected_name:0 "codex" C-m

        tmux new-window -t $selected_name -n "node" -c $selected
        tmux send-keys -t $selected_name:1 "pnpm run dev" C-m

        tmux new-window -t $selected_name -n "misc" -c $selected

        tmux new-window -t $selected_name -n "git" -c $selected
        tmux send-keys -t $selected_name:3 "lazygit" C-m

        tmux new-window -t $selected_name -n "db" -c $selected
        tmux send-keys -t $selected_name:4 "lazysql" C-m

        tmux new-window -t $selected_name -n "rest" -c $selected
        tmux send-keys -t $selected_name:5 "posting" C-m
      fi

      if [[ -z $TMUX ]]; then
        tmux attach -t $selected_name
      else
        tmux switch-client -t $selected_name
      fi
    '';
  };
}
