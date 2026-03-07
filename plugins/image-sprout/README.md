# image-sprout

Claude Code plugin for [image-sprout](https://github.com/tmchow/image-sprout) — generate and iterate on images with consistent style and subject identity.

## What it does

Provides a skill that teaches Claude how to use the image-sprout CLI to create projects, manage reference images, derive style/subject guides, and generate images with repeatable context.

## Prerequisites

- [image-sprout](https://github.com/tmchow/image-sprout) installed (`npm install -g image-sprout`) or available via `npx`
- An [OpenRouter](https://openrouter.ai/) API key configured via `npx image-sprout config set apiKey <key>`

## Install

```
/plugin marketplace add tmchow/tmc-marketplace
/plugin install image-sprout@tmc-marketplace
```

## Skills

| Skill | Description |
|-------|-------------|
| image-sprout | Create and manage image generation projects with consistent style and subject identity |
