# claude-rules

Правила работы с Claude Code, общие для всех проектов. Без привязки к компании, проекту, людям.

| Что | Куда встаёт | Зачем |
|---|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | короткое ядро: стиль, язык, стоп-краны. Читается всегда |
| `skills/*/` | `~/.claude/skills/` | тематические правила, подключаются по теме: drafts, git-workflow, review-loop, explaining, agents-tools, spec-pipeline, json-output, плюс analyzing, clarifying, converging, grilling, wait-what |
| `constitution.md` | `~/.claude/constitution.md` | шаблон, его читают /clarifying и /analyzing |
| `settings.json` | `~/.claude/settings.json` | модель, плагины, effort. Копия, не симлинк |

## Новая машина

```
git clone https://github.com/yliasolomennikowa-ml/claude-rules ~/claude-rules
~/claude-rules/install.sh
```

Скилы, CLAUDE.md и конституция встают симлинками в репо, settings.json копируется, если его ещё нет.
Плагины из settings.json Claude Code ставит сам при первом запуске.

## Правка правил

Открыть нужный `skills/<тема>/SKILL.md` или `CLAUDE.md`, поправить, `git commit`, `git push`.
На другой машине `git pull`, симлинки подхватят сразу.
