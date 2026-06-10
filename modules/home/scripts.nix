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
          "\nsummary: " + ((.summary // {}) | tostring)
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
