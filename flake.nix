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
      in
      {
        packages.default = opencode-tree;
        packages.opencode-tree = opencode-tree;

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [ bun ];
        };
      }
    );
}
