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

        # aios-agents-claude: the Claude flagship apm artifact. Pure copy of
        # the COMMITTED render output (clients/claude/generated) + the
        # hand-authored native skills + CLAUDE.md. The LLM transform
        # (renderers/render.sh) runs at dev/CI time and its output is
        # committed (Option A) — this derivation never runs the renderer,
        # stays pure/offline, and is byte-identical to what home-manager's
        # claude.nix deploys on Jan's own work Macs (M5/M1).
        aios-agents-claude = pkgs.runCommand "aios-agents-claude" { } ''
          mkdir -p $out/skills

          # 21 rendered skills (15 shared + 6 personas), SKILL.md each,
          # each carrying the DO-NOT-EDIT provenance marker.
          cp -r ${./clients/claude/generated/skills}/* $out/skills/

          # Native skills (grill-me, grill-with-docs) — copied WHOLE so
          # grill-with-docs' ADR-FORMAT.md + CONTEXT-FORMAT.md travel along
          # (a SKILL.md-only copy would drop them).
          for d in ${./clients/claude/native}/*/; do
            cp -r "$d" "$out/skills/$(basename "$d")"
          done

          # Global Claude instructions (native/ root file, not a skill dir).
          cp ${./clients/claude/native/CLAUDE.md} $out/CLAUDE.md

          # Store sources are read-only; make the artifact writable for any
          # downstream apm packaging/repackaging step.
          chmod -R u+w $out
        '';
      in
      {
        packages.default = opencode-tree;
        packages.opencode-tree = opencode-tree;
        packages.aios-agents-opencode = aios-agents-opencode;
        packages.aios-agents-claude = aios-agents-claude;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ bun coreutils jq ];
        };

        # Locks the aios-agents-opencode flagship contract: fails
        # `nix flake check` if the decomposition regresses (a mode:subagent
        # agent leaking in, context-audit going missing, an ai-coding-coupled
        # dir reappearing, etc.).
        checks.aios-agents-opencode = pkgs.runCommand "check-aios-agents-opencode" { } ''
          agents=$(ls ${aios-agents-opencode}/agents | wc -l)
          skills=$(ls ${aios-agents-opencode}/skills | wc -l)
          [ "$agents" -eq 6 ]  || { echo "expected 6 agents, got $agents"; exit 1; }
          [ "$skills" -eq 16 ] || { echo "expected 16 skills, got $skills"; exit 1; }
          test -e ${aios-agents-opencode}/AGENTS.md
          test -e ${aios-agents-opencode}/skills/context-audit/SKILL.md
          test ! -e ${aios-agents-opencode}/commands
          test ! -e ${aios-agents-opencode}/tools
          test ! -e ${aios-agents-opencode}/bin
          test ! -e ${aios-agents-opencode}/package.json
          touch $out
        '';

        # Locks the aios-agents-claude flagship contract: 21 generated +
        # 2 native = 23 skills, CLAUDE.md present, native aux docs survived
        # the whole-dir copy, every GENERATED skill carries the DO-NOT-EDIT
        # marker (native skills are hand-authored and legitimately have no
        # marker — checked separately below), and no source-only frontmatter
        # (clients/mode/temperature/license) leaked through the render.
        checks.aios-agents-claude = pkgs.runCommand "check-aios-agents-claude" { } ''
          skills=$(ls ${aios-agents-claude}/skills | wc -l)
          [ "$skills" -eq 23 ] || { echo "expected 23 skills, got $skills"; exit 1; }

          test -e ${aios-agents-claude}/CLAUDE.md
          test -e ${aios-agents-claude}/skills/grill-with-docs/SKILL.md
          test -e ${aios-agents-claude}/skills/grill-with-docs/ADR-FORMAT.md
          test -e ${aios-agents-claude}/skills/grill-with-docs/CONTEXT-FORMAT.md
          test -e ${aios-agents-claude}/skills/grill-me/SKILL.md

          # Every GENERATED skill (the 21 rendered ones) must carry the
          # DO-NOT-EDIT marker. Enumerated explicitly rather than looping
          # all of $out/skills, since native skills legitimately lack it.
          for name in analyst architect cpp debugger documenter explorer go \
                      haskell julia programmer python reviewer rust tester \
                      typescript brainstorm spar teach plan explore build; do
            f="${aios-agents-claude}/skills/$name/SKILL.md"
            test -e "$f" || { echo "missing generated skill: $name"; exit 1; }
            grep -q 'DO NOT EDIT' "$f" || { echo "missing marker: $f"; exit 1; }
          done

          # No source-only frontmatter leaked through the render.
          if grep -rqE '^(clients|mode|temperature|license):' ${aios-agents-claude}/skills; then
            echo "leaked source-only frontmatter into rendered skills"; exit 1
          fi

          # Guard (a): invalid/camelCase Claude frontmatter keys must never
          # appear. Claude's real fields are hyphenated (disallowed-tools,
          # allowed-tools); permissionMode does not exist for skills at all.
          if grep -rqE '^(disallowedTools|allowedTools|permissionMode):' ${aios-agents-claude}/skills; then
            echo "invalid frontmatter: use hyphenated disallowed-tools/allowed-tools; permissionMode is not a Claude skill field"; exit 1
          fi

          # Guard (b): the 6 persona skills must be user-invocation-only;
          # the 15 shared skills must stay auto-invocable (no such field).
          for name in brainstorm spar teach plan explore build; do
            f="${aios-agents-claude}/skills/$name/SKILL.md"
            grep -q '^disable-model-invocation: true' "$f" \
              || { echo "persona $name missing disable-model-invocation: true"; exit 1; }
          done
          for name in analyst architect cpp debugger documenter explorer go \
                      haskell julia programmer python reviewer rust tester \
                      typescript; do
            f="${aios-agents-claude}/skills/$name/SKILL.md"
            if grep -q '^disable-model-invocation:' "$f"; then
              echo "shared skill $name must not set disable-model-invocation"; exit 1
            fi
          done

          touch $out
        '';

        # checks.claude-render-fresh: PURE (no LLM, no network). Fails
        # `nix flake check` if any authored source — a shared skill, a
        # persona agent, or the renderer prompt itself — changed since
        # clients/claude/generated was last produced by renderers/render.sh.
        # Recomputes sha256 of each source from the store and diffs against
        # the committed manifest.json. This is the safety net for Option A:
        # it guards BOTH Jan's claude.nix deploy and the aios-agents-claude
        # apm against a stale render (edited a source, forgot to re-render).
        checks.claude-render-fresh =
          pkgs.runCommand "check-claude-render-fresh"
            { nativeBuildInputs = [ pkgs.jq pkgs.coreutils ]; } ''
            manifest=${./clients/claude/generated/manifest.json}
            agents=${./agents}
            skills=${./skills}
            prompt=${./renderers/opencode-to-claude.md}

            fail=0
            while IFS=$'\t' read -r rel want; do
              case "$rel" in
                agents/*)                        src="$agents/''${rel#agents/}" ;;
                skills/*)                        src="$skills/''${rel#skills/}" ;;
                renderers/opencode-to-claude.md) src="$prompt" ;;
                *) echo "manifest has unexpected path: $rel"; exit 1 ;;
              esac
              if [ ! -f "$src" ]; then
                echo "STALE: manifest lists $rel but source is gone"; fail=1; continue
              fi
              got=$(sha256sum "$src" | cut -d' ' -f1)
              if [ "$got" != "$want" ]; then
                echo "STALE: $rel changed since last render (re-run renderers/render.sh)"
                fail=1
              fi
            done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$manifest")

            # 21 authored sources + the renderer prompt = 22.
            n=$(jq 'length' "$manifest")
            [ "$n" -eq 22 ] || { echo "manifest has $n entries, expected 22"; exit 1; }

            [ "$fail" -eq 0 ] || exit 1
            touch $out
          '';
      }
    );
}
