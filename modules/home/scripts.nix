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
      else
        tmux -2 attach-session -t "$SESSION_NAME"
      fi
    '';
  };
}
