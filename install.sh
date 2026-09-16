#!/usr/bin/env bash
# Ставит общие правила Claude Code из этого репо в ~/.claude через симлинки.
# Запуск:  ~/claude-rules/install.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE="${HOME}/.claude"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${CLAUDE}/backups/claude-rules-${STAMP}"

link() {  # link <в репо> <куда в ~/.claude>
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok      $dst"; return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/$(basename "$dst")"
    echo "backup  $BACKUP/$(basename "$dst")"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  echo "linked  $dst -> $src"
}

mkdir -p "$CLAUDE"

link "$REPO/CLAUDE.md"       "$CLAUDE/CLAUDE.md"
link "$REPO/constitution.md" "$CLAUDE/constitution.md"

mkdir -p "$CLAUDE/skills"
for s in "$REPO"/skills/*/; do
  s="${s%/}"
  link "$s" "$CLAUDE/skills/$(basename "$s")"
done

# settings.json копируется, не линкуется: Claude Code дописывает туда
# машинные вещи (autoMode и т.п.), им не место в git.
if [ -e "$CLAUDE/settings.json" ]; then
  echo "skip    $CLAUDE/settings.json уже есть; сверь с $REPO/settings.json руками"
else
  cp "$REPO/settings.json" "$CLAUDE/settings.json"
  echo "copied  $CLAUDE/settings.json"
fi

echo
echo "Готово."
echo "Плагины из settings.json Claude Code поставит сам при первом запуске."
