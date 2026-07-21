{
  description = "agora: canonical source for AI OS agents, skills, commands, and tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # opencode-tree: the full authored OpenCode content tree (agents,
        # skills, commands, tools, bin, AGENTS.md, package.json) copied
        # verbatim into the Nix store. Consumed by home-manager's
        # modules/opencode.nix, which readDir's each subdirectory to deploy
        # agents/skills/commands as nix-store copies, tools as
        # mkOutOfStoreSymlink targets (dev checkout, not this store path),
        # and bin as executable copies.
        opencode-tree = pkgs.runCommand "opencode-tree" { } ''
          mkdir -p $out
          cp -r ${./agents} $out/agents
          cp -r ${./skills} $out/skills
          cp -r ${./commands} $out/commands
          cp -r ${./bin} $out/bin
          cp ${./AGENTS.md} $out/AGENTS.md
          cp ${./package.json} $out/package.json
        '';

        # aios-agents-opencode: the flagship colleague-facing apm artifact.
        # Zero-dependency subset — 6 primary agents + shared skills +
        # opencode-native skills + AGENTS.md. Deliberately EXCLUDES
        # commands/tools/bin/package.json (ai-coding rung, not yet an apm)
        # and the mode:subagent dev workhorses (planner/tester/debugger/
        # reviewer). NOT consumed by home-manager, which reads agora's raw
        # source directly — this is artifact generation for non-Nix
        # colleagues only, no apm-in-the-middle for Jan's own machines.
        aios-agents-opencode = pkgs.runCommand "aios-agents-opencode" { } ''
          mkdir -p $out/agents $out/skills

          # Flagship agents = frontmatter `mode: primary` (6: brainstorm,
          # spar, teach, plan, explore, build). Filtering at build time
          # keeps the roster self-maintaining; mode:subagent workhorses
          # are dropped automatically.
          for f in ${./agents}/*.md; do
            if grep -qE '^mode:[[:space:]]*primary[[:space:]]*$' "$f"; then
              cp "$f" "$out/agents/$(basename "$f")"
            fi
          done

          # Shared canonical skills (15) — opencode IS the source format,
          # no render needed.
          cp -r ${./skills}/* $out/skills/

          # OpenCode-native skills (context-audit) merge into the SAME
          # skills namespace, mirroring home-manager's nativeSkillEntries.
          cp -r ${./clients/opencode/native}/* $out/skills/

          # Global agent instructions (included per explicit decision).
          cp ${./AGENTS.md} $out/AGENTS.md

          # Store sources are read-only; make the artifact writable for
          # any downstream apm packaging/repackaging step.
          chmod -R u+w $out
        '';
      in
      {
        packages.default = opencode-tree;
        packages.opencode-tree = opencode-tree;
        packages.aios-agents-opencode = aios-agents-opencode;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ bun ];
        };
      }
    );
}
