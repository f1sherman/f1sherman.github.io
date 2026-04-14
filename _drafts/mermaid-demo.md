---
layout: post
title: "Mermaid Demo Draft"
author: Brian John
meta: Local draft for layout and Mermaid verification
categories: [demo]
---

This is a local-only draft to verify code block styling and Mermaid rendering before publishing anything new.

## Example command

```bash
docker compose run --rm site bundle exec jekyll build
```

## Example diagram

```mermaid
flowchart LR
    Browser["GitHub Pages browser"]
    OpenClaw["OpenClaw instance"]
    BlueBubbles["BlueBubbles"]
    CmdRunner["cmdrunner"]

    Browser --> OpenClaw
    OpenClaw --> BlueBubbles
    BlueBubbles --> OpenClaw
    OpenClaw --> CmdRunner
```
