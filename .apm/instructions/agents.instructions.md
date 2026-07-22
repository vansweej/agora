---
description: General AI-OS rules that apply to all work, regardless of language or project.
---

# General rules

- Always run build tools in the Nix development shell (`nix develop . --command <cmd>`)
  when a `flake.nix` is present.
