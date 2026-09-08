{
  description = "agora: canonical source for AI OS agents, skills, and instructions, packaged for apm";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # No `packages` output: agora ships two apm packages (root apm.yml =
        # aios-agents-opencode, clients/claude/apm.yml = aios-agents-claude),
        # not Nix store trees. `apm install` is the packaging/distribution
        # mechanism for colleagues now; home-manager keeps reading agora's
        # raw source directly via readDir (inputs.agora), same as always —
        # this flake exists only for the devShell and the pure drift check
        # below.
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ bun coreutils jq ];
        };

        # checks.claude-render-fresh: PURE (no LLM, no network). Fails
        # `nix flake check` if any authored source — a shared skill, a
        # persona agent, or the renderer prompt itself — changed since
        # clients/claude/.apm/skills was last produced by renderers/render.sh.
        # Recomputes sha256 of each source from the store and diffs against
        # the committed manifest.json. This is the safety net for Option A:
        # it guards both Jan's claude.nix deploy and the aios-agents-claude
        # apm package against a stale render (edited a source, forgot to
        # re-render).
        checks.claude-render-fresh =
          pkgs.runCommand "check-claude-render-fresh"
            { nativeBuildInputs = [ pkgs.jq pkgs.coreutils ]; } ''
            manifest=${./clients/claude/.apm/manifest.json}
            agents=${./.apm/agents}
            skills=${./.apm/skills}
            prompt=${./renderers/opencode-to-claude.md}

            fail=0
            while IFS=$'\t' read -r rel want; do
              case "$rel" in
                .apm/agents/*)                   src="$agents/''${rel#.apm/agents/}" ;;
                .apm/skills/*)                    src="$skills/''${rel#.apm/skills/}" ;;
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

            # 17 shared skills + 3 persona agents (brainstorm/teach/build) +
            # 3 specialist subagents (explore/spar/plan) + 1 coordinator +
            # the renderer prompt = 25.
            n=$(jq 'length' "$manifest")
            [ "$n" -eq 25 ] || { echo "manifest has $n entries, expected 25"; exit 1; }

            [ "$fail" -eq 0 ] || exit 1
            touch $out
          '';
      }
    );
}
