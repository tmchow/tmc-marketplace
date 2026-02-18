# tmc-marketplace

Plugins for Claude Code and Codex by Trevin Chow.

[trev.in](https://trev.in) · [LinkedIn](https://linkedin.com/in/trevin)

## Quick Install

```bash
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash
```

Installs the Claude Code plugin and Codex skills. Safe to re-run (idempotent). Skips anything not detected (e.g., no Codex installed).

To uninstall:

```bash
curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --uninstall
```

## Manual Install

### Claude Code

```
/plugin marketplace add tmchow/tmc-marketplace
/plugin install iterative-engineering@tmc-marketplace
```

Verify with `/plugin list`.

### Codex

Download the skills into your Codex skills directory:

```bash
curl -sL https://github.com/tmchow/tmc-marketplace/archive/refs/heads/main.tar.gz \
  | tar xz --strip-components=4 -C ~/.codex/skills/ \
    tmc-marketplace-main/plugins/iterative-engineering/skills/
```

This extracts all skills (with their reference files) to `~/.codex/skills/`.

## Plugins

| Plugin | Description |
|--------|-------------|
| [iterative-engineering](./plugins/iterative-engineering) | Iterative development workflow — brainstorming → tech planning → implementing with multi-agent reviews, dependency-aware execution, and severity-based acceptance |

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for a detailed history of all changes, new features, and fixes across releases.

## License

MIT
