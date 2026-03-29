#!/usr/bin/env zsh

# cc-profile: Claude Code settings.json profile switcher
# Part of cckit (https://github.com/beryllw/cckit)

CCKIT_DIR="$HOME/.cckit"
_CC_PROFILE_PROFILES_DIR="$CCKIT_DIR/profiles"
_CC_PROFILE_SETTINGS_FILE="$HOME/.claude/settings.json"

cc-profile() {
    local subcmd="$1"
    shift 2>/dev/null

    case "$subcmd" in
        use)
            _cc_profile_use "$@"
            ;;
        list|ls)
            _cc_profile_list
            ;;
        current)
            _cc_profile_current
            ;;
        uninstall)
            _cc_profile_uninstall
            ;;
        help|--help|-h|"")
            _cc_profile_help
            ;;
        *)
            echo "cc-profile: unknown command '$subcmd'" >&2
            echo "Run 'cc-profile help' for usage." >&2
            return 2
            ;;
    esac
}

_cc_profile_use() {
    local name="$1"

    if [[ -z "$name" ]]; then
        echo "Usage: cc-profile use <name>" >&2
        return 2
    fi

    # validate name
    if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "Error: profile name must match [a-zA-Z0-9._-]+" >&2
        return 1
    fi

    local profile_file="$_CC_PROFILE_PROFILES_DIR/${name}.json"

    if [[ ! -f "$profile_file" ]]; then
        echo "Error: profile '$name' not found." >&2
        echo ""
        _cc_profile_list_available
        return 1
    fi

    # ensure ~/.claude/ directory exists
    mkdir -p "$HOME/.claude"

    # if settings.json exists and is NOT a symlink, back it up
    if [[ -e "$_CC_PROFILE_SETTINGS_FILE" && ! -L "$_CC_PROFILE_SETTINGS_FILE" ]]; then
        local backup_file="$_CC_PROFILE_PROFILES_DIR/_original_backup.json"
        cp "$_CC_PROFILE_SETTINGS_FILE" "$backup_file"
        echo "Backed up original settings.json -> profiles/_original_backup.json"
    fi

    # create/update symlink
    ln -sf "$profile_file" "$_CC_PROFILE_SETTINGS_FILE"

    echo "Switched to profile '$name'"
    echo "  -> $(readlink "$_CC_PROFILE_SETTINGS_FILE")"
}

_cc_profile_list() {
    local profiles_dir="$_CC_PROFILE_PROFILES_DIR"

    if [[ ! -d "$profiles_dir" ]]; then
        echo "No profiles directory found. Create profiles in $profiles_dir/" >&2
        return 1
    fi

    local files=("$profiles_dir"/*.json(N))

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "No profiles found. Create .json files in $profiles_dir/" >&2
        return 0
    fi

    # get current symlink target
    local current_target=""
    if [[ -L "$_CC_PROFILE_SETTINGS_FILE" ]]; then
        current_target="$(readlink "$_CC_PROFILE_SETTINGS_FILE")"
    fi

    local name base
    for f in "${files[@]}"; do
        base="${f:t}"
        # skip internal files (prefixed with _)
        [[ "$base" == _* ]] && continue

        name="${base%.json}"
        if [[ "$f" == "$current_target" ]]; then
            if [[ -t 1 ]]; then
                echo "  \033[32m* $name\033[0m"
            else
                echo "  * $name"
            fi
        else
            echo "    $name"
        fi
    done
}

_cc_profile_list_available() {
    local profiles_dir="$_CC_PROFILE_PROFILES_DIR"
    local files=("$profiles_dir"/*.json(N))
    local has_profiles=false

    for f in "${files[@]}"; do
        [[ "${f:t}" == _* ]] && continue
        has_profiles=true
        break
    done

    if $has_profiles; then
        echo "Available profiles:"
        _cc_profile_list
    else
        echo "No profiles found. Create .json files in $profiles_dir/"
    fi
}

_cc_profile_current() {
    if [[ -L "$_CC_PROFILE_SETTINGS_FILE" ]]; then
        local target
        target="$(readlink "$_CC_PROFILE_SETTINGS_FILE")"
        local name="${target:t}"
        name="${name%.json}"
        echo "$name"
    elif [[ -e "$_CC_PROFILE_SETTINGS_FILE" ]]; then
        echo "(not managed by cc-profile)"
    else
        echo "(no settings.json)"
    fi
}

_cc_profile_uninstall() {
    echo "Uninstalling cc-profile..."

    # restore symlink to real file
    if [[ -L "$_CC_PROFILE_SETTINGS_FILE" ]]; then
        local target
        target="$(readlink "$_CC_PROFILE_SETTINGS_FILE")"
        if [[ -f "$target" ]]; then
            cp "$target" "${_CC_PROFILE_SETTINGS_FILE}.tmp"
            rm "$_CC_PROFILE_SETTINGS_FILE"
            mv "${_CC_PROFILE_SETTINGS_FILE}.tmp" "$_CC_PROFILE_SETTINGS_FILE"
            echo "Restored settings.json (copied from profile '${target:t:r}')"
        else
            rm "$_CC_PROFILE_SETTINGS_FILE"
            echo "Removed dangling symlink settings.json"
        fi
    fi

    # remove source line from .zshrc
    local zshrc="$HOME/.zshrc"
    if [[ -f "$zshrc" ]]; then
        local tmp="$(mktemp)"
        # remove the comment line and the for-loop source line
        sed '/^# cckit$/,+1d' "$zshrc" > "$tmp"
        mv "$tmp" "$zshrc"
        echo "Removed cckit lines from ~/.zshrc"
    fi

    # ask about removing directory
    echo ""
    echo -n "Remove ~/.cckit/ directory? (your profiles will be deleted) [y/N] "
    read -r answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        rm -rf "$CCKIT_DIR"
        echo "Removed ~/.cckit/"
    else
        echo "Kept ~/.cckit/ (your profiles are preserved)"
    fi

    # remove function from current session
    unfunction cc-profile 2>/dev/null
    unfunction _cc_profile 2>/dev/null
    echo ""
    echo "Uninstall complete. Restart your shell to finish cleanup."
}

_cc_profile_help() {
    cat <<'EOF'
cc-profile - Claude Code settings.json profile switcher

Usage:
  cc-profile use <name>     Switch to a named profile (creates symlink)
  cc-profile list           List all available profiles
  cc-profile current        Show the currently active profile
  cc-profile uninstall      Uninstall cc-profile
  cc-profile help           Show this help message

Profiles are stored as JSON files in ~/.cckit/profiles/
The active profile is symlinked from ~/.claude/settings.json

Examples:
  cc-profile use bedrock    Switch to Bedrock provider config
  cc-profile use api        Switch to direct API config
  cc-profile ls             List all profiles

Getting started:
  1. Create a JSON config file:  vim ~/.cckit/profiles/myconfig.json
  2. Switch to it:               cc-profile use myconfig
EOF
}

# --- Zsh Completion ---

_cc_profile() {
    local -a subcmds
    subcmds=(
        'use:Switch to a named profile'
        'list:List all available profiles'
        'ls:List all available profiles'
        'current:Show the currently active profile'
        'uninstall:Uninstall cc-profile'
        'help:Show help message'
    )

    _arguments -C \
        '1:subcommand:->subcmd' \
        '*:: :->args'

    case "$state" in
        subcmd)
            _describe 'subcommand' subcmds
            ;;
        args)
            case "${line[1]}" in
                use)
                    _cc_profile_complete_names
                    ;;
            esac
            ;;
    esac
}

_cc_profile_complete_names() {
    local profiles_dir="$HOME/.cckit/profiles"
    local -a names
    local f

    if [[ -d "$profiles_dir" ]]; then
        for f in "$profiles_dir"/*.json(N); do
            [[ "${f:t}" == _* ]] && continue
            names+=("${${f:t}%.json}")
        done
    fi

    if [[ ${#names[@]} -gt 0 ]]; then
        _describe 'profile' names
    fi
}

# register completion (only in interactive shells with compdef available)
if (( $+functions[compdef] )); then
    compdef _cc_profile cc-profile
fi
