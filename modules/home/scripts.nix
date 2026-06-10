{ ... }:

{
  home.file."typst/academic-template.typ" = {
    source = ../../assets/typst/academic-template.typ;
    force = true;
  };

  home.file.".local/scripts/tmux-sessionizer" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash

      if [[ $# -eq 1 ]]; then
        selected=$1
      else
        selected=$(
          {
            find "$HOME/Developer" -mindepth 1 -maxdepth 1 -type d
            [[ -d "$HOME/nix" ]] && printf '%s\n' "$HOME/nix"
          } | fzf
        )
      fi

      if [[ -z $selected ]]; then
        exit 0
      fi

      selected_name=$(basename "$selected" | tr . _)
      tmux_running=$(pgrep tmux)

      if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
        tmux new-session -s $selected_name -c "$selected" -d

        tmux rename-window -t $selected_name:0 "codex"
        tmux send-keys -t $selected_name:0 "codex" C-m

        tmux new-window -t $selected_name -n "node" -c "$selected"
        tmux send-keys -t $selected_name:1 "pnpm run dev" C-m

        tmux new-window -t $selected_name -n "misc" -c "$selected"

        tmux new-window -t $selected_name -n "git" -c "$selected"
        tmux send-keys -t $selected_name:3 "lazygit" C-m

        tmux new-window -t $selected_name -n "db" -c "$selected"
        tmux send-keys -t $selected_name:4 "lazysql" C-m

        tmux new-window -t $selected_name -n "rest" -c "$selected"
        tmux send-keys -t $selected_name:5 "posting" C-m

        tmux attach -t $selected_name
        exit 0
      fi

      if ! tmux has-session -t=$selected_name 2>/dev/null; then
        tmux new-session -ds $selected_name -c "$selected"

        tmux rename-window -t $selected_name:0 "codex"
        tmux send-keys -t $selected_name:0 "codex" C-m

        tmux new-window -t $selected_name -n "node" -c "$selected"
        tmux send-keys -t $selected_name:1 "pnpm run dev" C-m

        tmux new-window -t $selected_name -n "misc" -c "$selected"

        tmux new-window -t $selected_name -n "git" -c "$selected"
        tmux send-keys -t $selected_name:3 "lazygit" C-m

        tmux new-window -t $selected_name -n "db" -c "$selected"
        tmux send-keys -t $selected_name:4 "lazysql" C-m

        tmux new-window -t $selected_name -n "rest" -c "$selected"
        tmux send-keys -t $selected_name:5 "posting" C-m
      fi

      if [[ -z $TMUX ]]; then
        tmux attach -t $selected_name
      else
        tmux switch-client -t $selected_name
      fi
    '';
  };

  home.file.".local/scripts/typst-smart-open" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env zsh

      WORK_DIR="$HOME/typst"
      TEMPLATE_FILE="academic-template.typ"

      cd "$WORK_DIR" || exit

      SELECTION=$(
        find . -maxdepth 1 -name "*.typ" -not -name "$TEMPLATE_FILE" \
          | sed 's|./||' \
          | fzf --print-query --preview 'head -n 20 {}'
      )

      QUERY=$(echo "$SELECTION" | head -n 1)
      FILE=$(echo "$SELECTION" | tail -n 1)

      if [[ -z "$QUERY" && -z "$FILE" ]]; then
        exit 0
      fi

      if [[ -f "$FILE" ]]; then
        TARGET_FILE="$FILE"
      else
        clean_name="''${QUERY%.typ}"
        TARGET_FILE="''${clean_name}.typ"
        TITLE_TEXT="$clean_name"

        printf '%s\n' \
          "#import \"$TEMPLATE_FILE\": project" \
          "" \
          "// Apply the template" \
          "#show: project.with(" \
          "  title: \"$TITLE_TEXT\"," \
          "  subject: \"New Subject\"" \
          ")" \
          "" \
          "// Start writing here..." \
          > "$TARGET_FILE"
      fi

      SESSION_NAME="typst_$(date +%s)"

      tmux new-session -d -s "$SESSION_NAME" -n "editor"
      tmux send-keys -t "''${SESSION_NAME}:editor" "nvim '$TARGET_FILE'" C-m
      tmux select-window -t "''${SESSION_NAME}:editor"

      if [[ -n "$TMUX" ]]; then
        tmux switch-client -t "$SESSION_NAME"
      else
        tmux -2 attach-session -t "$SESSION_NAME"
      fi
    '';
  };
}
