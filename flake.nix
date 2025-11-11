{
  description = "Set minimum NixOS generation number";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib;

    profileDir = "/nix/var/nix/profiles";

    script = pkgs.writeShellApplication {
      name = "set-generation-minimum";
      runtimeInputs = with pkgs; [coreutils gnugrep];
      text = ''
        MINIMUM="''${1:-}"

        # Validate input (must be done at runtime)
        if [[ -z "$MINIMUM" ]]; then
          echo "Error: No minimum generation specified" >&2
          echo "Usage: nix run github:BridgerB/nix-generation-minimum -- <minimum_generation>" >&2
          exit 1
        fi

        if ! [[ "$MINIMUM" =~ ^[0-9]+$ ]]; then
          echo "Error: Minimum must be a positive integer" >&2
          exit 1
        fi

        if [[ "$MINIMUM" -lt 1 ]]; then
          echo "Error: Minimum must be at least 1" >&2
          exit 1
        fi

        # Get current highest generation number
        CURRENT_MAX=$(
          for link in ${profileDir}/system-*-link; do
            [[ -e "$link" ]] || continue
            basename "$link" | grep -oP '^system-\K[0-9]+(?=-link$)'
          done | sort -n | tail -1
        )
        CURRENT_MAX=''${CURRENT_MAX:-0}

        echo "Current highest generation: $CURRENT_MAX"
        echo "Target minimum generation: $MINIMUM"

        # Check if we need to do anything
        if [[ "$CURRENT_MAX" -ge "$MINIMUM" ]]; then
          echo "Current generation ($CURRENT_MAX) is already >= minimum ($MINIMUM)"
          echo "Nothing to do."
          exit 0
        fi

        # Calculate the generation to create (minimum - 1)
        TARGET_GEN=$((MINIMUM - 1))

        echo "Creating generation $TARGET_GEN..."

        # Get current system closure
        CURRENT_SYSTEM=$(readlink -f /run/current-system)

        if [[ -z "$CURRENT_SYSTEM" ]]; then
          echo "Error: Could not determine current system closure" >&2
          exit 1
        fi

        # Create the symlink
        LINK_PATH="${profileDir}/system-$TARGET_GEN-link"

        if [[ -e "$LINK_PATH" ]]; then
          echo "Warning: $LINK_PATH already exists, removing it first"
          sudo rm "$LINK_PATH"
        fi

        sudo ln -s "$CURRENT_SYSTEM" "$LINK_PATH"

        echo "✓ Created generation $TARGET_GEN"
        echo "Next rebuild will create generation $MINIMUM"
      '';
    };
  in {
    apps.${system}.default = {
      type = "app";
      program = lib.getExe script;
    };
  };
}
