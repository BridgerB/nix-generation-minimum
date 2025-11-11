# nix-generation-minimum

Set a minimum generation number for your NixOS system.

## Quick Start

Run directly without adding to your config:

```bash
nix run github:BridgerB/nix-generation-minimum -- 1000
sudo nixos-rebuild switch
```

Your next rebuild will be generation 1000 (or higher if already past it).

## How It Works

NixOS generation numbers are determined by finding the highest-numbered
`system-N-link` symlink in `/nix/var/nix/profiles/` and incrementing it.

This tool creates a symlink at `system-(minimum-1)-link`, causing the next
rebuild to create generation `minimum`.

## Usage

```bash
# Set minimum to 1000
nix run github:BridgerB/nix-generation-minimum -- 1000

# Rebuild to create generation 1000
sudo nixos-rebuild switch
```

## Example

Starting from generation 39:

```bash
# Check current generation
$ nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1
  39   2025-11-11 00:26:49   (current)

# Set minimum to 1000
$ nix run github:BridgerB/nix-generation-minimum -- 1000
Current highest generation: 39
Target minimum generation: 1000
Creating generation 999...
✓ Created generation 999
Next rebuild will create generation 1000

# Rebuild
$ sudo nixos-rebuild switch
# ... build output ...

# Check new generation
$ nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -1
  1000   2025-11-11 00:30:15   (current)
```

## Use Cases

- **Fresh Systems**: Start at generation 100 instead of 1
- **Multiple Systems**: Keep generation numbers consistent across machines
- **Version Alignment**: Match generation numbers with external versioning
- **Testing**: Jump to high generation numbers to test generation management
  tools

## How Generation Numbers Work

NixOS tracks system generations using symlinks in `/nix/var/nix/profiles/`:

```
system -> system-39-link
system-1-link -> /nix/store/...-nixos-system-...
system-2-link -> /nix/store/...-nixos-system-...
system-39-link -> /nix/store/...-nixos-system-...
```

When you rebuild, NixOS:

1. Finds the highest N in `system-N-link`
2. Creates `system-(N+1)-link` pointing to the new system
3. Updates `system` to point to the new link

This tool exploits this mechanism by creating a symlink at the desired
`(minimum - 1)`.

## Caveats

- **One-time Jump**: Once you reach the minimum, normal incrementing resumes
- **No Gaps**: If you set minimum=1000 from generation 39, you'll have
  generations 1,2,...,39,999,1000
- **Root Required**: Creating symlinks in `/nix/var/nix/profiles/` requires sudo
- **No Rollback**: Setting a minimum doesn't affect rollback to older
  generations

## License

MIT - See [LICENSE](LICENSE) file

## Author

Created by BridgerB
