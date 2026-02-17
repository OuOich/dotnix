# AGENTS.md

Operational guide for coding agents working in `dotnix`.

This repository is a Nix flake with NixOS/Home Manager modules, shared helpers,
deploy-rs integration, and sops-managed secrets.

## Quick start

- Run all commands from the repository root.
- In agent environments, do not use interactive `nix develop`.
- Run dev-shell tooling with `nix develop -c <cmd>`:

```bash
nix develop -c statix check .
nix develop -c deploy .#mochi
```

- Dev shell tools: `nil`, `statix`, `nixfmt-rfc-style`, `prettier`, `sops`, `deploy`.

## Repository layout

- `flake.nix`: top-level flake inputs and outputs.
- `flake/*.nix`: flake-parts modules exposing outputs.
- `nixos/hosts/*`: host entrypoints (`mochi`, `taco`).
- `nixos/options/system/*`: reusable NixOS modules/options.
- `nixos/options/home/*`: reusable Home Manager modules/options.
- `nixos/home/<user@host>/*`: user + host Home Manager composition.
- `library/*`: reusable helpers under `dotnix.lib.*`.
- `secrets/*` and `.sops.yaml`: encrypted secrets and key policies.

## Common commands

### Flake validation

```bash
nix flake check
nix flake check --all-systems
nix flake show
```

### Build

```bash
# Build host closures
nix build .#nixosConfigurations.mochi.config.system.build.toplevel
nix build .#nixosConfigurations.taco.config.system.build.toplevel

# Rebuild/switch the machine running this command (not remote deploy)
sudo nixos-rebuild build --flake .#mochi
sudo nixos-rebuild switch --flake .#mochi
```

### Lint

```bash
# Lint all Nix files
nix develop -c statix check .

# Lint one file
nix develop -c statix check nixos/options/system/security/ssh-keys-mount.nix
```

### Format

Formatting is handled automatically by agent tools; no manual formatting step is
required.

### Tests

Current state:

- No dedicated `tests/` tree.
- No named `checks.<system>.<name>` outputs yet.

Today, use:

```bash
# "Run all tests" equivalent
nix flake check

# "Run one test" equivalent
nix build .#nixosConfigurations.mochi.config.system.build.toplevel
```

If named checks are added later:

```bash
nix build .#checks.x86_64-linux.<check-name>
```

If NixOS VM tests are added later:

```bash
nix build .#nixosTests.<test-name>
```

### Deploy

- Never run `deploy` to real machines unless the user explicitly approves it or
  has delegated deployment in advance.
- Before any deploy, ensure all checks relevant to the target host/configuration
  have passed.

```bash
nix develop -c deploy .#mochi
```

## Code style guidelines

### Formatting and readability

- Do not hand-tune spacing that a formatter rewrites.
- Keep modules focused and composable.
- Prefer `imports = [ ... ];` over deeply nested inline attrsets.
- Keep comments sparse and high signal.

### Imports and module signatures

- Keep module arg sets multiline and stable (commonly `{ dotnix, config, lib, pkgs, ... }:`).
- Include only arguments that are actually used.
- Keep `...` as the final argument.
- In option modules, use `let cfg = config.dotnix.<path>; in`.
- Gate optional behavior with `lib.mkIf cfg.enable`.
- Keep host-specific code in `nixos/hosts/*`.
- Keep reusable code in `nixos/options/*` and `library/*`.

### Module and option conventions

- Use `lib.mkEnableOption` for boolean feature toggles.
- Use `lib.mkOption` with explicit `type` for configurable values.
- Prefer explicit `lib.types` (`bool`, `str`, `path`, `attrsOf`, `submodule`, etc.).
- Add `description` for non-trivial options.
- Use `default` and `lib.mkDefault` to keep overrides easy.
- Follow existing namespaces (`dotnix.configurations.*`, `dotnix.security.*`).

### Naming conventions

- Use `camelCase` for local names/helpers (`mkSopsEntry`, `parseUserHost`).
- Use established `kebab-case` option paths (`common-nix`, `ssh-keys-mount`).
- Keep host/user identifiers lowercase (`mochi`, `taco`, `cheng`).
- Keep directory module entry files as `default.nix` unless justified.
- Preserve exported helper names unless doing a coordinated full rename.

### Error handling and validation

- Validate input shapes/types in reusable functions.
- Use explicit `throw` messages with function context.
- Fail fast on impossible states.
- Prefer explicit defaults over implicit `null` behavior.

### Secrets and security

- Never commit decrypted secrets.
- Keep secrets under `secrets/*` and aligned with `.sops.yaml`.
- Consume secrets via `sops.secrets`, not plaintext literals.
- Reuse `dotnix.security.sshKeysMount` patterns for SSH keys.

### Prettier rules

- Use `prettier` for `json`, `jsonc`, `yaml`, `yml`, and `md`.
- `.prettierrc` default: `trailingComma: all`.
- `*.jsonc` override: `trailingComma: none`.

## Agent workflow checklist

- Prefer minimal, targeted edits.
- Extend existing patterns before introducing new architecture.
- Run `nix flake check` after substantial changes.
- For host-targeted edits, run the relevant host build command.
- Avoid touching secrets unless the task explicitly requires it.

## Instruction precedence status

Checked paths in this repository:

- `.cursorrules`: not present
- `.cursor/rules/`: not present
- `.github/copilot-instructions.md`: not present

If these files are added later, treat them as higher-priority repository
instructions and update this guide.
