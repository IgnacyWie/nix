{ ... }:

{
  home.file.".local/scripts/eta-shell" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      exec ssh eta "$@"
    '';
  };

  home.file.".local/scripts/eta-service" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      usage() {
        cat <<'USAGE'
      eta-service: invoke eta Service Control Commands over SSH.

      Service Control Commands run authoritatively on eta.

      Usage:
        eta-service list
        eta-service inspect <stack>
        eta-service <stack> <command> [args...]

      This gamma wrapper does not own Home Server state. It delegates to the
      managed eta-service command on the canonical SSH Host Alias eta.
      USAGE
      }

      case "''${1:-}" in
        "" | -h | --help)
          usage
          exit 0
          ;;
      esac

      exec ssh eta -- eta-service "$@"
    '';
  };

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
            [[ -d "$HOME/typst" ]] && printf '%s\n' "$HOME/typst"
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

      has_tty() {
        [[ -t 0 && -t 1 ]]
      }

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

        if has_tty; then
          tmux attach -t $selected_name
        else
          printf 'Created tmux session %s. Attach from a terminal with: tmux attach -t %s\n' "$selected_name" "$selected_name" >&2
        fi
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

      if [[ -z $TMUX ]] && has_tty; then
        tmux attach -t $selected_name
      elif [[ -n $TMUX ]]; then
        tmux switch-client -t $selected_name
      else
        printf 'Prepared tmux session %s. Attach from a terminal with: tmux attach -t %s\n' "$selected_name" "$selected_name" >&2
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

      run_selected_command() {
        local command=$1

        if [[ -n "''${TMUX:-}" && -n "''${DEV_COMMAND_RUNNER_TARGET_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
          local quoted_root
          printf -v quoted_root '%q' "$PROJECT_ROOT"
          tmux send-keys -t "$DEV_COMMAND_RUNNER_TARGET_PANE" "cd $quoted_root && $command" C-m
          return
        fi

        bash -c "$command"
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
            --bind='left-click:accept' \
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

  home.file.".local/scripts/open-github-repository" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      die() {
        printf '%s\n' "open-github-repository: $*" >&2
        exit 1
      }

      github_url_from_remote() {
        local remote_url=$1
        local repo

        case "$remote_url" in
          git@github.com:*.git)
            repo=''${remote_url#git@github.com:}
            repo=''${repo%.git}
            ;;
          git@github.com:*)
            repo=''${remote_url#git@github.com:}
            ;;
          ssh://git@github.com/*.git)
            repo=''${remote_url#ssh://git@github.com/}
            repo=''${repo%.git}
            ;;
          ssh://git@github.com/*)
            repo=''${remote_url#ssh://git@github.com/}
            ;;
          https://github.com/*.git)
            repo=''${remote_url#https://github.com/}
            repo=''${repo%.git}
            ;;
          https://github.com/*)
            repo=''${remote_url#https://github.com/}
            repo=''${repo%.git}
            ;;
          *)
            return 1
            ;;
        esac

        repo=''${repo%/}

        if [[ "$repo" != */* || "$repo" == */*/* || "$repo" == */ ]]; then
          return 1
        fi

        printf 'https://github.com/%s\n' "$repo"
      }

      current_github_url() {
        local remote_name remote_url github_url

        if remote_url=$(git remote get-url origin 2>/dev/null) && github_url=$(github_url_from_remote "$remote_url"); then
          printf '%s\n' "$github_url"
          return 0
        fi

        while read -r remote_name; do
          remote_url=$(git remote get-url "$remote_name" 2>/dev/null || true)
          if github_url=$(github_url_from_remote "$remote_url"); then
            printf '%s\n' "$github_url"
            return 0
          fi
        done < <(git remote)

        return 1
      }

      if [[ ''${OPEN_GITHUB_REPOSITORY_TEST_REMOTE:-0} == 1 ]]; then
        github_url_from_remote "$1"
        exit 0
      fi

      if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        die "not inside a git repository"
      fi

      cd "$repo_root"

      if ! github_url=$(current_github_url); then
        die "no GitHub remote found for $repo_root"
      fi

      exec "''${OPEN_GITHUB_REPOSITORY_OPEN_COMMAND:-open}" "$github_url"
    '';
  };

  home.file.".local/scripts/issue-picker" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      die() {
        printf '%s\n' "issue-picker: $*" >&2
        exit 1
      }

      github_repo_from_remote() {
        local remote_url=$1
        local repo

        case "$remote_url" in
          git@github.com:*.git)
            repo=''${remote_url#git@github.com:}
            repo=''${repo%.git}
            ;;
          git@github.com:*)
            repo=''${remote_url#git@github.com:}
            ;;
          https://github.com/*.git)
            repo=''${remote_url#https://github.com/}
            repo=''${repo%.git}
            ;;
          https://github.com/*)
            repo=''${remote_url#https://github.com/}
            repo=''${repo%.git}
            ;;
          *)
            return 1
            ;;
        esac

        if [[ "$repo" != */* || "$repo" == */ ]]; then
          return 1
        fi

        printf '%s\n' "$repo"
      }

      current_github_repo() {
        local remote_name remote_url repo

        if remote_url=$(git remote get-url origin 2>/dev/null) && repo=$(github_repo_from_remote "$remote_url"); then
          printf '%s\n' "$repo"
          return 0
        fi

        while read -r remote_name; do
          remote_url=$(git remote get-url "$remote_name" 2>/dev/null || true)
          if repo=$(github_repo_from_remote "$remote_url"); then
            printf '%s\n' "$repo"
            return 0
          fi
        done < <(git remote)

        return 1
      }

      slugify_title() {
        local title=$1

        title=$(printf '%s\n' "$title" | sed -E 's/^[[:alnum:]_-]+(\([^)]+\))?!?:[[:space:]]*//')
        printf '%s\n' "$title" \
          | tr '[:upper:]' '[:lower:]' \
          | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
      }

      if [[ ''${ISSUE_PICKER_TEST_REMOTE:-0} == 1 ]]; then
        github_repo_from_remote "$1"
        exit 0
      fi

      if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        die "not inside a git repository"
      fi

      cd "$repo_root"

      if ! github_repo=$(current_github_repo); then
        die "no GitHub remote found for $repo_root"
      fi

      issue_rows=$(
        gh issue list \
          --repo "$github_repo" \
          --state open \
          --limit 100 \
          --json number,title,labels,assignees,updatedAt \
          --template '{{range .}}{{printf "#%-5v %-60.60s " .number .title}}{{range .labels}}{{printf "%s " .name}}{{end}}{{range .assignees}}{{printf "@%s " .login}}{{end}}{{printf "%s\n" (timeago .updatedAt)}}{{end}}'
      )

      preview_command=$(cat <<PREVIEW
      number=\$(printf '%s\n' {} | sed -E 's/^#([0-9]+).*/\1/')

      if [ -z "\$number" ]; then
        exit 0
      fi

      gh issue view "\$number" \
        --repo "$github_repo" \
        --comments \
        --json number,title,state,labels,assignees,url,body,comments \
        --template '{{printf "#%v %s\n" .number .title}}{{printf "State: %s\n" .state}}{{printf "Labels: "}}{{range .labels}}{{printf "%s " .name}}{{end}}{{printf "\n"}}{{printf "Assignees: "}}{{range .assignees}}{{printf "%s " .login}}{{end}}{{printf "\nURL: %s\n\n" .url}}{{.body}}{{printf "\n\n"}}{{range .comments}}{{printf "---\n%s commented:\n%s\n" .author.login .body}}{{end}}' \
        2>/dev/null || printf 'Could not load issue preview.\n'
      PREVIEW
      )

      if ! selected=$(
        fzf \
          --prompt='issue> ' \
          --preview="$preview_command" \
          <<< "$issue_rows"
      ); then
        exit 0
      fi

      if [[ -z "$selected" ]]; then
        exit 0
      fi

      issue_number=$(printf '%s\n' "$selected" | sed -E 's/^#([0-9]+).*/\1/')
      if [[ -z "$issue_number" || "$issue_number" == "$selected" ]]; then
        die "could not parse selected issue number"
      fi

      issue_json=$(gh issue view "$issue_number" --repo "$github_repo" --json number,title,url)
      issue_title=$(printf '%s\n' "$issue_json" | jq -r '.title')
      issue_url=$(printf '%s\n' "$issue_json" | jq -r '.url')

      if ! action=$(
        printf '%s\n' open copy-url branch codex \
          | fzf --prompt='issue action> '
      ); then
        exit 0
      fi

      if [[ -z "$action" ]]; then
        exit 0
      fi

      case "$action" in
        open)
          open "$issue_url"
          ;;
        copy-url)
          printf '%s' "$issue_url" | pbcopy
          ;;
        branch)
          if [[ -n $(git status --porcelain) ]]; then
            die "refusing to switch branches with uncommitted local work"
          fi

          slug=$(slugify_title "$issue_title")
          if [[ -z "$slug" ]]; then
            slug="issue"
          fi
          branch_name="issue-$issue_number-$slug"

          if git show-ref --verify --quiet "refs/heads/$branch_name"; then
            git switch "$branch_name"
          else
            git switch -c "$branch_name"
          fi
          ;;
        codex)
          codex "Implement GitHub issue #$issue_number in $github_repo: $issue_url"
          ;;
        *)
          die "unknown action: $action"
          ;;
      esac
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
      elif [[ -t 0 && -t 1 ]]; then
        tmux -2 attach-session -t "$SESSION_NAME"
      else
        printf 'Created tmux session %s. Attach from a terminal with: tmux attach -t %s\n' "$SESSION_NAME" "$SESSION_NAME" >&2
      fi
    '';
  };

  home.file.".local/scripts/backup-restore-picker" = {
    executable = true;
    force = true;
    text = ''
      #!/usr/bin/env bash
      set -euo pipefail

      restic_repository='b2:gamma-backup-restic:gamma'
      b2_account_id_service='restic-gamma-b2-account-id'
      b2_account_key_service='restic-gamma-b2-account-key'
      restic_password_service='restic-gamma-password'

      security_bin="''${BACKUP_RESTORE_PICKER_SECURITY_BIN:-/usr/bin/security}"
      pbcopy_bin="''${BACKUP_RESTORE_PICKER_PBCOPY_BIN:-pbcopy}"

      require_command() {
        if ! command -v "$1" >/dev/null 2>&1; then
          printf 'backup-restore-picker: missing required command: %s\n' "$1" >&2
          exit 1
        fi
      }

      require_secret() {
        service="$1"
        description="$2"

        if ! value=$("$security_bin" find-generic-password -a "$USER" -s "$service" -w 2>/dev/null); then
          printf 'backup-restore-picker: missing Restic configuration: could not read %s from macOS Keychain service %s.\n' "$description" "$service" >&2
          exit 1
        fi

        if [[ -z "$value" ]]; then
          printf 'backup-restore-picker: missing Restic configuration: Keychain service %s returned an empty %s.\n' "$service" "$description" >&2
          exit 1
        fi

        printf '%s' "$value"
      }

      shell_quote() {
        printf '%q' "$1"
      }

      build_review_target() {
        snapshot_id="$1"
        timestamp="''${BACKUP_RESTORE_PICKER_NOW:-$(date +%Y%m%d-%H%M%S)}"
        safe_snapshot=$(printf '%s' "$snapshot_id" | tr -c '[:alnum:]_.-' '-')
        printf '%s/Restores/restic-%s-%s' "$HOME" "$safe_snapshot" "$timestamp"
      }

      build_restore_command() {
        snapshot_id="$1"
        selected_path="$2"
        review_target="$3"

        printf 'restic restore %s --target %s --include %s\n' \
          "$(shell_quote "$snapshot_id")" \
          "$(shell_quote "$review_target")" \
          "$(shell_quote "$selected_path")"
      }

      load_restic_environment() {
        require_command restic
        require_command fzf
        require_command jq

        if [[ ! -x "$security_bin" ]]; then
          printf 'backup-restore-picker: missing Restic configuration: security command not found at %s.\n' "$security_bin" >&2
          exit 1
        fi

        export RESTIC_REPOSITORY="$restic_repository"
        B2_ACCOUNT_ID=$(require_secret "$b2_account_id_service" "B2 account id")
        B2_ACCOUNT_KEY=$(require_secret "$b2_account_key_service" "B2 account key")
        RESTIC_PASSWORD=$(require_secret "$restic_password_service" "Restic password")
        export B2_ACCOUNT_ID
        export B2_ACCOUNT_KEY
        export RESTIC_PASSWORD
      }

      select_snapshot() {
        snapshot_json="$1"

        if ! restic snapshots --json > "$snapshot_json"; then
          printf 'backup-restore-picker: failed to list Restic snapshots.\n' >&2
          exit 1
        fi

        snapshot_lines=$(
          jq -r '
            .[]
            | [
                (.short_id // (.id | .[0:8])),
                (.time // ""),
                (.hostname // ""),
                ((.paths // []) | join(", ")),
                ((.tags // []) | join(", "))
              ]
            | @tsv
          ' "$snapshot_json"
        )

        if [[ -z "$snapshot_lines" ]]; then
          printf 'backup-restore-picker: no Restic snapshots found.\n' >&2
          exit 1
        fi

        snapshot_preview=$(cat <<'PREVIEW'
      snapshot_id=$(printf '%s' "{}" | awk -F '\t' '{print $1}')
      jq -r --arg id "$snapshot_id" '
        .[]
        | select((.short_id // (.id | .[0:8])) == $id)
        | "snapshot ID: " + (.id // "") +
          "\ntimestamp: " + (.time // "") +
          "\nhostname: " + (.hostname // "") +
          "\npaths:\n" + (((.paths // []) | map("  - " + .)) | join("\n")) +
          "\ntags: " + (((.tags // []) | join(", ")) // "") +
          "\nsummary: " + (if .summary == null then "" else (.summary | tostring) end)
      ' "$BACKUP_RESTORE_PICKER_SNAPSHOT_JSON"
      PREVIEW
        )

        export BACKUP_RESTORE_PICKER_SNAPSHOT_JSON="$snapshot_json"
        if ! selected=$(
          fzf \
            --prompt='backup snapshot> ' \
            --delimiter='\t' \
            --with-nth=1,2,3,4,5 \
            --preview="$snapshot_preview" \
            <<< "$snapshot_lines"
        ); then
          exit 0
        fi

        [[ -n "$selected" ]] || exit 0
        printf '%s' "$selected" | awk -F '\t' '{print $1}'
      }

      select_file() {
        snapshot_id="$1"
        file_json="$2"

        if ! restic ls --json "$snapshot_id" > "$file_json"; then
          printf 'backup-restore-picker: failed to list files for snapshot %s.\n' "$snapshot_id" >&2
          exit 1
        fi

        file_lines=$(
          jq -r '
            select(.path != null and .path != "")
            | [
                .path,
                (.type // ""),
                ((.size // "") | tostring),
                (.mtime // "")
              ]
            | @tsv
          ' "$file_json"
        )

        if [[ -z "$file_lines" ]]; then
          printf 'backup-restore-picker: snapshot %s did not contain listable files.\n' "$snapshot_id" >&2
          exit 1
        fi

        file_preview=$(cat <<'PREVIEW'
      selected_line={}
      selected_path=$(printf '%s' "$selected_line" | awk -F '\t' '{print $1}')
      jq -r --arg path "$selected_path" '
        select(.path == $path)
        | "path: " + (.path // "") +
          "\ntype: " + (.type // "") +
          "\nsize: " + ((.size // "") | tostring) +
          "\nmodified: " + (.mtime // "")
      ' "$BACKUP_RESTORE_PICKER_FILE_JSON"

      type=$(jq -r --arg path "$selected_path" 'select(.path == $path) | .type // ""' "$BACKUP_RESTORE_PICKER_FILE_JSON" | head -n 1)
      size=$(jq -r --arg path "$selected_path" 'select(.path == $path) | .size // 0' "$BACKUP_RESTORE_PICKER_FILE_JSON" | head -n 1)

      if [ "$type" = "dir" ]; then
        printf '\nDirectory selected; contents are not dumped in preview.\n'
        exit 0
      fi

      case "$size" in
        ""|*[!0-9]*) size=0 ;;
      esac

      if [ "$size" -gt 1048576 ]; then
        printf '\nFile is larger than 1 MiB; content preview skipped.\n'
        exit 0
      fi

      case "$selected_path" in
        *.txt|*.md|*.nix|*.json|*.yaml|*.yml|*.toml|*.sh|*.bash|*.zsh|*.lua|*.js|*.ts|*.tsx|*.css|*.html|*.typ)
          tmp_file=$(mktemp)
          if restic dump "$BACKUP_RESTORE_PICKER_SNAPSHOT_ID" "$selected_path" > "$tmp_file" 2>/dev/null; then
            printf '\n'
            if command -v bat >/dev/null 2>&1; then
              bat --style=plain --color=always --line-range :160 "$tmp_file"
            else
              sed -n '1,160p' "$tmp_file"
            fi
          else
            printf '\nUnable to preview file contents with restic dump.\n'
          fi
          rm -f "$tmp_file"
          ;;
        *)
          printf '\nBinary or unsupported file type; content preview skipped.\n'
          ;;
      esac
      PREVIEW
        )

        export BACKUP_RESTORE_PICKER_SNAPSHOT_ID="$snapshot_id"
        export BACKUP_RESTORE_PICKER_FILE_JSON="$file_json"
        if ! selected=$(
          fzf \
            --prompt='backup file> ' \
            --delimiter='\t' \
            --with-nth=1,2,3,4 \
            --preview="$file_preview" \
            <<< "$file_lines"
        ); then
          exit 0
        fi

        [[ -n "$selected" ]] || exit 0
        printf '%s' "$selected" | awk -F '\t' '{print $1}'
      }

      select_action() {
        if ! selected=$(
          printf '%s\n' \
            print-command \
            copy-command \
            restore-to-review-dir \
            | fzf --prompt='backup action> '
        ); then
          exit 0
        fi

        [[ -n "$selected" ]] || exit 0
        printf '%s' "$selected"
      }

      load_restic_environment

      temp_dir=$(mktemp -d)
      cleanup() {
        rm -rf "$temp_dir"
      }
      trap cleanup EXIT

      snapshot_id=$(select_snapshot "$temp_dir/snapshots.json")
      selected_path=$(select_file "$snapshot_id" "$temp_dir/files.json")
      review_target=$(build_review_target "$snapshot_id")
      restore_command=$(build_restore_command "$snapshot_id" "$selected_path" "$review_target")
      action=$(select_action)

      case "$action" in
        print-command)
          printf '%s' "$restore_command"
          ;;
        copy-command)
          if ! command -v "$pbcopy_bin" >/dev/null 2>&1; then
            printf 'backup-restore-picker: copy-command requires pbcopy.\n' >&2
            exit 1
          fi
          printf '%s' "$restore_command" | "$pbcopy_bin"
          printf 'Copied restore command to clipboard. Review it before running.\n'
          ;;
        restore-to-review-dir)
          printf 'The selected path will be restored into a review directory only.\n\n'
          printf '%s\n\n' "$restore_command"
          printf 'Type restore to run this command: '
          if ! read -r confirmation; then
            confirmation=""
          fi

          if [[ "$confirmation" != "restore" ]]; then
            printf 'Restore cancelled; confirmation did not match.\n' >&2
            exit 1
          fi

          if [[ -e "$review_target" ]]; then
            printf 'backup-restore-picker: review target already exists, refusing to restore over it: %s\n' "$review_target" >&2
            exit 1
          fi

          mkdir -p "$review_target"
          restic restore "$snapshot_id" --target "$review_target" --include "$selected_path"
          printf 'Restore completed into review directory: %s\n' "$review_target"
          ;;
        *)
          printf 'backup-restore-picker: unknown action: %s\n' "$action" >&2
          exit 1
          ;;
      esac
    '';
  };
}
