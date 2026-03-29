#!/usr/bin/env zsh

# cckit installer
# Usage: curl -fsSL https://raw.githubusercontent.com/beryllw/cckit/main/install.sh | zsh

set -e

CCKIT_DIR="$HOME/.cckit"
REPO_URL="https://github.com/beryllw/cckit.git"
ZSHRC="$HOME/.zshrc"
SOURCE_MARKER="# cckit"
SOURCE_LINE='for f in ~/.cckit/*/cc-*.zsh; do [ -f "$f" ] && source "$f"; done'

main() {
    echo "Installing cckit..."
    echo ""

    # 1. Clone or update repository
    if [[ -d "$CCKIT_DIR/.git" ]]; then
        echo "Updating existing installation..."
        git -C "$CCKIT_DIR" pull --quiet
    elif [[ -d "$CCKIT_DIR" ]]; then
        echo "Error: $CCKIT_DIR exists but is not a git repo." >&2
        echo "Remove it first: rm -rf $CCKIT_DIR" >&2
        exit 1
    else
        echo "Cloning to $CCKIT_DIR..."
        git clone --quiet "$REPO_URL" "$CCKIT_DIR"
    fi

    # 2. Ensure profiles directory and default config exist
    mkdir -p "$CCKIT_DIR/profiles"
    if [[ ! -f "$CCKIT_DIR/profiles/default.json" ]]; then
        echo '{}' > "$CCKIT_DIR/profiles/default.json"
    fi

    # 3. Add source line to .zshrc (idempotent)
    if [[ ! -f "$ZSHRC" ]]; then
        touch "$ZSHRC"
    fi

    if ! grep -qF "$SOURCE_MARKER" "$ZSHRC" 2>/dev/null; then
        echo "" >> "$ZSHRC"
        echo "$SOURCE_MARKER" >> "$ZSHRC"
        echo "$SOURCE_LINE" >> "$ZSHRC"
        echo "Added source line to ~/.zshrc"
    else
        echo "Source line already exists in ~/.zshrc, skipping."
    fi

    echo ""
    echo "Installation complete!"
    echo ""
    echo "Run the following to activate:"
    echo "  source ~/.zshrc"
    echo ""
    echo "Then try:"
    echo "  cc-profile help"
    echo "  cc-profile list"
}

main "$@"
