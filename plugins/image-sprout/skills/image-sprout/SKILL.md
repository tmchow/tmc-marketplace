---
name: image-sprout
description: >
  Use image-sprout to create and manage image generation projects with consistent
  style and subject identity. Use this skill when the user asks to generate images
  with saved context, iteratively refine image outputs, manage image projects with
  references and guides, or run image-sprout CLI commands in a workflow.
---

# image-sprout

Generate and iterate on images with consistent style and subject identity. Image Sprout turns reusable project context — reference images, derived guides, and persistent instructions — into repeatable outputs you can build on across runs.

Use this skill when:
- The user asks to generate images and wants results that stay consistent across multiple runs
- The user wants to iterate on outputs from a previous generation
- The user needs to set up or manage an image project with references or style context
- The workflow requires structured, scriptable image generation with `--json` output

## 1. Installation

Install globally from npm:

```bash
npm install -g image-sprout
```

Or run without installing — prefer this in Codex sandbox environments where PATH is unreliable:

```bash
npx image-sprout help
```

All examples below use `npx image-sprout`. Substitute `image-sprout` directly if you have a global install.

## 2. OpenRouter Key Setup

Image Sprout stores its OpenRouter key on disk. Set it once per machine:

```bash
npx image-sprout config set apiKey <your-openrouter-key>
npx image-sprout config show    # confirm key is set (does not reveal the raw key)
```

## 3. The Project Model

Three context layers drive every generation:

- **Visual Style** — consistent look and feel across outputs
- **Subject Guide** — consistent subject identity across outputs
- **Instructions** — persistent generation constraints (watermarks, framing, branding)

Two reference pools:

- **Shared refs** — drive both guides (default, simplest)
- **Split refs** — separate style and subject pools (advanced; use `--role style` or `--role subject` when adding)

Understanding this model prevents the most common agent mistake: generating without saved context and wondering why outputs are inconsistent.

## 4. Core CLI Workflow

```bash
# Create a project
npx image-sprout project create <name>

# Add references (3+ recommended; more refs = better derivation)
npx image-sprout ref add --project <name> ./ref1.png ./ref2.png ./ref3.png

# Optional: persistent instructions
npx image-sprout project update <name> --instructions "Watermark bottom-right: subtle."

# Derive guides from refs
npx image-sprout project derive <name> --target both   # or: style, subject

# Check readiness before generating
npx image-sprout project status <name> --json

# Generate (--count controls images per run: 1, 2, 4, 6; default is 4)
npx image-sprout project generate <name> --prompt "hero in neon rain"
npx image-sprout project generate <name> --prompt "hero in neon rain" --count 1

# Inspect results
npx image-sprout run latest --project <name> --json

# Delete a session and all its runs/images
npx image-sprout session delete --project <name> <session-id>
```

Top-level aliases:

```bash
npx image-sprout generate --project <name> --prompt "hero in neon rain"   # same as project generate
npx image-sprout analyze --project <name> --target both                    # same as project derive
```

## 5. JSON Output — the Agent Pattern

Always use `--json` for structured output:

```bash
npx image-sprout project show <name> --json
npx image-sprout project status <name> --json
npx image-sprout run latest --project <name> --json
npx image-sprout run list --project <name> --json --limit 5
```

Use `--value PATH` to pluck a single field:

```bash
npx image-sprout run latest --project <name> --json --value images[0].path
```

This is how agents hand image paths to downstream tools. Run images land in image-sprout's internal app data directory — use `run latest --json --value images[0].path` to get the path and leave what to do with it to the calling workflow.

## 6. Parallel-Safe Usage

`npx image-sprout project use <name>` sets a shared "current project" state on disk. In multi-agent workflows, this state can collide across concurrent processes. **Always pass `--project <name>` explicitly** — never rely on the current project shortcut.

## 7. Web UI — Agent Awareness

The web app runs over the same on-disk store as the CLI. Agents won't use it directly, but should surface it to users when interactive review is appropriate.

```bash
npx image-sprout web              # launches local app
npx image-sprout web --open       # also opens in default browser
npx image-sprout web --port 8080  # custom port (default: 4310)
```

Useful for:
- reviewing and comparing generated images visually
- setting up a project interactively before handing off to CLI/agent use
- iterating on outputs via the canvas interface

**Security: do not expose the web UI to the public internet.** The server has no authentication. Safe options are localhost only, or a private network like Tailscale. The risk is public internet exposure — LAN and tailnet access are fine.

## 8. Model Management

```bash
npx image-sprout model list
npx image-sprout model set-default google/gemini-3.1-flash-image-preview
npx image-sprout model add openai/gpt-5-image
npx image-sprout model restore-defaults
```

Default generation model is **Nano Banana 2** (`google/gemini-3.1-flash-image-preview`). Custom models must accept image input and produce image output via OpenRouter.

Guide derivation uses a separate configurable analysis model (default: `google/gemini-3.1-flash-image-preview`):

```bash
# Set a persistent analysis model
npx image-sprout config set analysisModel google/gemini-2.5-flash

# Override per-derive
npx image-sprout project derive <name> --target both --analysis-model google/gemini-2.5-flash
```
