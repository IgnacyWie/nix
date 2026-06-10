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
        preview_command=$(cat <<'PREVIEW'
      project={}
      readme=$(
        find "$project" -maxdepth 1 -type f \( -iname "README" -o -iname "README.*" \) \
          | sort \
          | head -n 1
      )

      if [ -n "$readme" ]; then
        printf 'README: %s\n\n' "$(basename "$readme")"

        if command -v glow >/dev/null 2>&1; then
          glow -s dark -w "''${FZF_PREVIEW_COLUMNS:-100}" "$readme" | sed -n '1,120p'
        elif command -v bat >/dev/null 2>&1; then
          bat --style=plain --color=always --line-range :120 "$readme"
        else
          sed -n '1,120p' "$readme"
        fi
      elif git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        printf 'Git status:\n'
        git -C "$project" status --short
        printf '\nRecent commits:\n'
        git -C "$project" log --oneline --decorate --color=always -n 12
      else
        printf 'Files:\n'
        find "$project" -maxdepth 2 -mindepth 1 | sort | sed "s|$project|.|" | head -n 60
      fi
      PREVIEW
        )

        if ! selected=$(
          {
            find "$HOME/Developer" -mindepth 1 -maxdepth 1 -type d
            [[ -d "$HOME/nix" ]] && printf '%s\n' "$HOME/nix"
          } | fzf \
            --prompt='tmux session> ' \
            --preview="$preview_command"
        ); then
          exit 0
        fi
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

  home.file.".local/scripts/dev-command-runner" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      find_project_root() {
        if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
          printf '%s\n' "$git_root"
        else
          pwd -P
        fi
      }

      package_manager() {
        if [[ -f pnpm-lock.yaml ]]; then
          printf '%s\n' "pnpm"
        elif [[ -f yarn.lock ]]; then
          printf '%s\n' "yarn"
        elif [[ -f bun.lockb || -f bun.lock ]]; then
          printf '%s\n' "bun"
        elif [[ -f package-lock.json ]]; then
          printf '%s\n' "npm"
        else
          printf '%s\n' "npm"
        fi
      }

      package_script_command() {
        local manager=$1
        local script_name=$2

        case "$manager" in
          pnpm)
            if [[ $script_name == "test" ]]; then
              printf 'pnpm test'
            else
              printf 'pnpm run %s' "$script_name"
            fi
            ;;
          npm)
            if [[ $script_name == "test" ]]; then
              printf 'npm test'
            else
              printf 'npm run %s' "$script_name"
            fi
            ;;
          yarn)
            printf 'yarn %s' "$script_name"
            ;;
          bun)
            printf 'bun run %s' "$script_name"
            ;;
        esac
      }

      add_command() {
        local source=$1
        local label=$2
        local command=$3
        local kind=$4
        local name=$5
        local file=$6

        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$source" "$label" "$command" "$kind" "$name" "$file"
      }

      discover_package_json() {
        [[ -f package.json ]] || return 0

        local manager
        manager=$(package_manager)

        if command -v jq >/dev/null 2>&1; then
          jq -r '.scripts // {} | to_entries[] | [.key, .value] | @tsv' package.json 2>/dev/null || true
        else
          sed -n '
            /"scripts"[[:space:]]*:/,/^[[:space:]]*}/ {
              s/^[[:space:]]*"\([^"]*\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1	\2/p
            }
          ' package.json
        fi | while IFS=$'\t' read -r script_name script_body; do
          [[ -n $script_name ]] || continue
          command=$(package_script_command "$manager" "$script_name")
          add_command "package.json" "$command" "$command" "package" "$script_name" "package.json"
        done
      }

      discover_justfile() {
        local file=""
        if [[ -f justfile ]]; then
          file="justfile"
        elif [[ -f Justfile ]]; then
          file="Justfile"
        else
          return 0
        fi

        if command -v just >/dev/null 2>&1; then
          (just --justfile "$file" --summary --unsorted 2>/dev/null || true) \
            | tr ' ' '\n' \
            | sed '/^$/d;/^_/d'
        else
          awk '
            /^[[:space:]]*#/ { next }
            /^[[:alnum:]][[:alnum:]_-]*([[:space:]].*)?:/ {
              name = $1
              sub(/:.*/, "", name)
              if (name !~ /^_/) print name
            }
          ' "$file"
        fi | while read -r recipe; do
          [[ -n $recipe ]] || continue
          command="just $recipe"
          add_command "$file" "$command" "$command" "just" "$recipe" "$file"
        done
      }

      discover_makefile() {
        [[ -f Makefile ]] || return 0

        awk -F: '
          /^[[:alnum:]][[:alnum:]_.-]*:/ {
            target = $1
            if (target !~ /^[_%.]/ && target !~ /\$/ && target != "Makefile") print target
          }
        ' Makefile | awk '!seen[$0]++' | while read -r target; do
          [[ -n $target ]] || continue
          command="make $target"
          add_command "Makefile" "$command" "$command" "make" "$target" "Makefile"
        done
      }

      discover_nix() {
        [[ -f flake.nix ]] || return 0

        add_command "nix" "nix flake check" "nix flake check" "nix" "flake-check" "flake.nix"
      }

      discover_scripts() {
        [[ -d scripts ]] || return 0

        find scripts -maxdepth 1 -type f -perm -111 | sort | while read -r script; do
          command="./$script"
          add_command "scripts" "$command" "$command" "script" "$(basename "$script")" "$script"
        done
      }

      list_commands() {
        discover_package_json
        discover_justfile
        discover_makefile
        discover_nix
        discover_scripts
      }

      preview_block() {
        local file=$1
        local name=$2
        local pattern=$3

        awk -v name="$name" -v pattern="$pattern" '
          $0 ~ pattern {
            print
            shown = 1
            next
          }
          shown && /^[[:alnum:]_.-][^:]*:/ {
            exit
          }
          shown && /^[[:space:]]*$/ {
            print
            blanks++
            if (blanks > 1) exit
            next
          }
          shown {
            print
            blanks = 0
          }
        ' "$file" | sed -n '1,120p'
      }

      show_file_preview() {
        local file=$1

        if command -v bat >/dev/null 2>&1; then
          bat --style=plain --color=always --line-range :160 "$file"
        else
          sed -n '1,160p' "$file"
        fi
      }

      show_preview() {
        local row=$1
        local source label command kind name file

        IFS=$'\t' read -r source label command kind name file <<< "$row"

        case "$kind" in
          package)
            printf 'package.json  %s\n\n' "$label"
            if command -v jq >/dev/null 2>&1; then
              jq -r --arg name "$name" '
                "package: " + (.name // "(unnamed)") +
                "\npackageManager: " + (.packageManager // "(not declared)") +
                "\nscript: " + $name +
                "\n\n" + (.scripts[$name] // "")
              ' package.json
            else
              sed -n '1,80p' package.json
            fi
            ;;
          just)
            printf '%s  %s\n\n' "$file" "$label"
            preview_block "$file" "$name" "^$name([[:space:]].*)?:"
            ;;
          make)
            printf 'Makefile  %s\n\n' "$label"
            preview_block "$file" "$name" "^$name:"
            ;;
          script)
            printf '%s  %s\n\n' "$source" "$label"
            show_file_preview "$file"
            ;;
          nix)
            printf 'flake.nix  %s\n\n' "$label"
            if [[ -x scripts/check ]]; then
              show_file_preview "scripts/check"
            else
              sed -n '/checks\./,/formatter\./p' flake.nix | sed -n '1,160p'
            fi
            ;;
          *)
            printf '%s\n' "$command"
            ;;
        esac
      }

      is_long_running() {
        case "$1" in
          *" dev"|*" dev "*|*" watch"|*" watch "*|*" serve"|*" serve "*|*" server"|*" server "*|*" start"|*" start "*) return 0 ;;
          *) return 1 ;;
        esac
      }

      run_selected_command() {
        local command=$1

        if [[ -n "''${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; then
          if is_long_running "$command"; then
            tmux display-popup -E -d "$PROJECT_ROOT" -w 90% -h 80% "$command"
          else
            tmux display-popup -E -d "$PROJECT_ROOT" -w 90% -h 80% "$command; status=\$?; printf '\n[exit %s] Press Enter to close...' \"\$status\"; read -r _; exit \"\$status\""
          fi
        else
          bash -c "$command"
        fi
      }

      if [[ "''${1:-}" == "--preview" ]]; then
        show_preview "''${2:-}"
        exit 0
      fi

      PROJECT_ROOT=$(find_project_root)
      export PROJECT_ROOT
      cd "$PROJECT_ROOT"

      if ! selected=$(
        list_commands \
          | awk -F '\t' '!seen[$2]++' \
          | fzf \
            --prompt='dev command> ' \
            --delimiter=$'\t' \
            --with-nth=1,2 \
            --preview="$0 --preview {}"
      ); then
        exit 0
      fi

      [[ -n $selected ]] || exit 0

      IFS=$'\t' read -r _source _label selected_command _kind _name _file <<< "$selected"
      [[ -n $selected_command ]] || exit 0

      run_selected_command "$selected_command"
    '';
  };

  home.file.".local/scripts/git-branch-switcher" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        printf '%s\n' "git-branch-switcher: not inside a git repository" >&2
        exit 1
      fi

      cd "$repo_root"

      if [[ $# -eq 1 ]]; then
        selected=$1
      else
        branch_list=$(
          git for-each-ref \
            --sort=-committerdate \
            --format='%(refname:short)' \
            refs/heads \
            refs/remotes \
            | sed '/ -> /d;/\/HEAD$/d' \
            | awk '!seen[$0]++'
        )

        if ! selected=$(
          fzf \
            --prompt='git branch> ' \
            --preview='git log --oneline --decorate --color=always -n 20 {} 2>/dev/null' \
            <<< "$branch_list"
        ); then
          exit 0
        fi
      fi

      if [[ -z $selected ]]; then
        exit 0
      fi

      current_branch=$(git branch --show-current)
      if [[ $selected == "$current_branch" ]]; then
        exit 0
      fi

      if git show-ref --verify --quiet "refs/heads/$selected"; then
        git switch "$selected"
        exit 0
      fi

      if [[ $selected == */* ]] && git show-ref --verify --quiet "refs/remotes/$selected"; then
        local_branch=''${selected#*/}

        if git show-ref --verify --quiet "refs/heads/$local_branch"; then
          git switch "$local_branch"
        else
          git switch --track "$selected"
        fi

        exit 0
      fi

      git switch "$selected"
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

      PREVIEW_COMMAND=$(cat <<'PREVIEW'
      file={}

      if [ -z "$file" ] || [ ! -f "$file" ]; then
        printf 'Type a new document name to create it from the template.\n'
        exit 0
      fi

      if command -v typst >/dev/null 2>&1 && command -v chafa >/dev/null 2>&1; then
        preview_dir="''${TMPDIR:-/tmp}/typst-preview-$(id -u)"
        mkdir -p "$preview_dir"
        preview_image="$preview_dir/$(basename "''${file%.typ}").png"

        if typst compile --pages 1 "$file" "$preview_image" >/dev/null 2>&1 && [ -f "$preview_image" ]; then
          chafa --size "''${FZF_PREVIEW_COLUMNS:-80}x''${FZF_PREVIEW_LINES:-24}" "$preview_image"
          exit 0
        fi
      fi

      if command -v bat >/dev/null 2>&1; then
        bat --style=plain --color=always --line-range :120 "$file"
      else
        sed -n '1,120p' "$file"
      fi
      PREVIEW
      )

      if ! SELECTION=$(
        find . -maxdepth 1 -name "*.typ" -not -name "$TEMPLATE_FILE" \
          | sed 's|./||' \
          | fzf --print-query --prompt='typst document> ' --preview="$PREVIEW_COMMAND"
      ); then
        exit 0
      fi

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
