#!/usr/bin/env bash
# Hook this repository into ~/.bashrc and ~/.vimrc by appending a source line
# to each. Nothing is symlinked or overwritten; running it again is a no-op.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

add_line() {
  local file="$1" line="$2"
  touch "$file"
  if grep -qxF "$line" "$file"; then
    echo "already set: $file"
    return
  fi
  if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
    echo >> "$file"
  fi
  printf '%s\n' "$line" >> "$file"
  echo "updated:     $file"
}

add_line "$HOME/.bashrc" "source \"$repo/bash/bashrc\""
add_line "$HOME/.vimrc" "source ${repo// /\\ }/vim/vimrc"

# Git Bash starts a login shell, which reads ~/.bash_profile, not ~/.bashrc.
if [ ! -f "$HOME/.bash_profile" ]; then
  printf '%s\n' '[ -f ~/.bashrc ] && . ~/.bashrc' > "$HOME/.bash_profile"
  echo "created:     $HOME/.bash_profile"
elif ! grep -q 'bashrc' "$HOME/.bash_profile"; then
  echo "warning:     $HOME/.bash_profile does not seem to source ~/.bashrc"
fi

echo "Done. Open a new Git Bash window to pick up the changes."
