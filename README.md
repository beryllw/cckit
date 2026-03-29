# cckit

A CLI toolset for managing Claude Code configurations.

## Tools

### cc-profile

Quickly switch between different `~/.claude/settings.json` configurations via symlink.

Useful for switching between model providers (API / Bedrock / Vertex), permission policies, or any other settings scenarios.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/beryllw/cckit/main/install.sh | zsh
```

This will:
1. Clone the repo to `~/.cckit/`
2. Add a source line to `~/.zshrc`
3. Create `~/.cckit/profiles/` with a default empty config

Then reload your shell:

```bash
source ~/.zshrc
```

## Usage

### Create profiles

Create JSON config files in `~/.cckit/profiles/`:

```bash
# Direct API access
cat > ~/.cckit/profiles/api.json << 'EOF'
{
  "model": "claude-sonnet-4-20250514"
}
EOF

# Amazon Bedrock
cat > ~/.cckit/profiles/bedrock.json << 'EOF'
{
  "model": "claude-sonnet-4-20250514",
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "AWS_REGION": "us-east-1"
  }
}
EOF
```

### Switch profiles

```bash
cc-profile use bedrock     # Switch to Bedrock config
cc-profile use api         # Switch to direct API config
```

### Other commands

```bash
cc-profile list            # List all profiles (* marks active)
cc-profile current         # Show active profile name
cc-profile help            # Show help
```

### Tab completion

Zsh tab completion is built-in:

```
cc-profile <TAB>           # Complete subcommands
cc-profile use <TAB>       # Complete profile names
```

## How it works

`~/.claude/settings.json` is managed as a symlink pointing to the active profile file in `~/.cckit/profiles/`. Switching profiles just updates the symlink target.

If an existing `settings.json` (non-symlink) is detected on first use, it is automatically backed up to `~/.cckit/profiles/_original_backup.json`.

## Uninstall

```bash
cc-profile uninstall
```

This will:
1. Restore `settings.json` from symlink to a real file (config preserved)
2. Remove the source line from `~/.zshrc`
3. Optionally delete `~/.cckit/`

## Project structure

```
profile/
  cc-profile.zsh    # Main function + zsh completion
profiles/
  default.json      # Default empty config
install.sh          # Installer script
```

## Adding new tools

This project is designed as a toolset. To add a new tool:

1. Create a directory: `mytool/`
2. Add a zsh script: `mytool/cc-mytool.zsh`
3. The `~/.zshrc` source line auto-loads any `cc-*.zsh` file in subdirectories

## Requirements

- zsh 5.0+
- git (for installation)
