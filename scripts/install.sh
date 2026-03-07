#!/usr/bin/env bash
set -euo pipefail

# TMC Marketplace Installer
# Usage:
#   Interactive:     curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash
#   All plugins:     curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --all
#   Single plugin:   curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --plugin image-sprout
#   Codex only:      curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --codex-only
#   Claude only:     curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --claude-only
#   Uninstall:       curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --uninstall

# --- Constants ---
VERSION="2.0.0"
REPO="tmchow/tmc-marketplace"
MARKETPLACE_NAME="tmc-marketplace"
ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/main.tar.gz"
ARCHIVE_PREFIX="tmc-marketplace-main"
MAX_RETRIES=3
RETRY_DELAY=2

# All available plugins in the marketplace
ALL_PLUGINS=("iterative-engineering" "image-sprout")

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- State ---
UNINSTALL=false
INSTALL_CLAUDE=true
INSTALL_CODEX=true
INSTALL_TARGET="both"
INSTALL_ALL=false
SELECTED_PLUGINS=()
LAST_DOWNLOAD_ERROR=""

# --- Utility functions ---

log_info() {
    echo -e "${BLUE}[tmc]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_details() {
    local output="$1"
    echo -e "  ${YELLOW}→${NC} Details:" >&2
    while IFS= read -r line; do
        echo "    $line" >&2
    done <<< "$output"
}

die() {
    log_error "$1"
    exit 1
}

download_with_retry() {
    local url="$1"
    local dest="$2"
    local attempt=1

    LAST_DOWNLOAD_ERROR=""
    while [ $attempt -le $MAX_RETRIES ]; do
        local output
        if output=$(curl -fsSL -S "$url" -o "$dest" 2>&1); then
            return 0
        fi
        LAST_DOWNLOAD_ERROR="$output"
        if [ $attempt -lt $MAX_RETRIES ]; then
            log_warn "Download failed, retrying in ${RETRY_DELAY}s... (attempt $attempt/$MAX_RETRIES)"
            sleep $RETRY_DELAY
        fi
        ((attempt++))
    done
    return 1
}

# --- Plugin selection ---

prompt_plugin_selection() {
    # When piped via curl | bash, stdin is the pipe. Read from /dev/tty for user input.
    if ! [ -t 0 ] && ! [ -e /dev/tty ]; then
        log_warn "No interactive terminal available, installing all plugins"
        SELECTED_PLUGINS=("${ALL_PLUGINS[@]}")
        return
    fi

    echo "" >&2
    echo -e "${BOLD}Available plugins:${NC}" >&2
    echo "" >&2

    local i=1
    for plugin in "${ALL_PLUGINS[@]}"; do
        echo -e "  ${BOLD}${i})${NC} ${plugin}" >&2
        ((i++))
    done

    echo "" >&2
    echo -e "Enter plugin numbers separated by spaces (e.g. ${BOLD}1 2${NC}), or ${BOLD}a${NC} for all:" >&2
    read -r selection < /dev/tty

    if [[ "$selection" == "a" || "$selection" == "A" || -z "$selection" ]]; then
        SELECTED_PLUGINS=("${ALL_PLUGINS[@]}")
        return
    fi

    SELECTED_PLUGINS=()
    for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#ALL_PLUGINS[@]} ]; then
            SELECTED_PLUGINS+=("${ALL_PLUGINS[$((num - 1))]}")
        else
            die "Invalid selection: $num"
        fi
    done

    if [ ${#SELECTED_PLUGINS[@]} -eq 0 ]; then
        die "No plugins selected"
    fi
}

# --- Core functions ---

print_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║       TMC Marketplace Installer        ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

install_claude_plugin() {
    local plugin_name="$1"
    log_info "Installing Claude Code plugin: ${plugin_name}..."

    if ! command -v claude &>/dev/null; then
        log_warn "Claude Code CLI not found, skipping plugin install"
        echo -e "  ${YELLOW}→${NC} After installing Claude Code, re-run this script to add the plugin" >&2
        return 0
    fi

    # Add marketplace (idempotent; may return non-zero if already added)
    local marketplace_output
    if ! marketplace_output=$(claude plugin marketplace add "${REPO}" 2>&1); then
        # Ignore — marketplace may already exist
        true
    fi

    # Install plugin (idempotent - reinstalls/updates if exists)
    local install_output
    if ! install_output=$(claude plugin install "${plugin_name}@${MARKETPLACE_NAME}" 2>&1); then
        log_warn "Failed to install ${plugin_name}"
        print_details "$install_output"
        return 0
    fi

    log_success "Installed ${plugin_name}@${MARKETPLACE_NAME} plugin"
}

download_and_extract_archive() {
    CODEX_EXTRACT_DIR=$(mktemp -d)
    local archive_path="${CODEX_EXTRACT_DIR}/archive.tar.gz"

    if ! download_with_retry "$ARCHIVE_URL" "$archive_path"; then
        rm -rf "$CODEX_EXTRACT_DIR"
        CODEX_EXTRACT_DIR=""
        log_warn "Failed to download archive after $MAX_RETRIES attempts"
        if [ -n "$LAST_DOWNLOAD_ERROR" ]; then
            print_details "$LAST_DOWNLOAD_ERROR"
        fi
        return 1
    fi

    tar xzf "$archive_path" -C "$CODEX_EXTRACT_DIR"
    rm -f "$archive_path"
    return 0
}

install_codex_skills() {
    local plugin_name="$1"
    local extract_dir="$2"
    log_info "Installing Codex skills for ${plugin_name}..."

    local codex_home="${CODEX_HOME:-$HOME/.codex}"

    if [ ! -d "$codex_home" ]; then
        if command -v codex &>/dev/null; then
            mkdir -p "$codex_home"
        else
            log_warn "Codex not detected (${codex_home} not found), skipping skill install"
            echo -e "  ${YELLOW}→${NC} After installing Codex, re-run this script to add the skills" >&2
            return 0
        fi
    fi

    local skills_dir="${codex_home}/skills"
    mkdir -p "$skills_dir"

    local source_skills="${extract_dir}/${ARCHIVE_PREFIX}/plugins/${plugin_name}/skills"
    if [ ! -d "$source_skills" ]; then
        log_warn "Skills directory not found in archive for ${plugin_name}"
        return 0
    fi

    # Copy each skill and record in manifest
    local manifest="${skills_dir}/.tmc-marketplace-${plugin_name}"
    local count=0
    local installed_skills=()

    for skill_dir in "$source_skills"/*/; do
        [ -d "$skill_dir" ] || continue
        local skill_name
        skill_name=$(basename "$skill_dir")
        local dest="${skills_dir}/${skill_name}"

        rm -rf "$dest"
        cp -r "$skill_dir" "$dest"
        installed_skills+=("$skill_name")
        ((count++))
    done

    # Write manifest for clean uninstall
    if [ ${#installed_skills[@]} -gt 0 ]; then
        printf '%s\n' "${installed_skills[@]}" > "$manifest"
    fi

    log_success "Installed ${count} skills for ${plugin_name} to ${skills_dir}/"
}

print_success() {
    echo ""
    echo -e "${GREEN}${BOLD}Done!${NC}"
    echo ""
}

# --- Uninstall functions ---

do_uninstall() {
    log_info "Uninstalling TMC Marketplace..."
    echo ""

    # Remove Claude Code plugins
    if command -v claude &>/dev/null; then
        for plugin_name in "${ALL_PLUGINS[@]}"; do
            log_info "Removing Claude Code plugin: ${plugin_name}..."

            local uninstall_output
            if uninstall_output=$(claude plugin uninstall "${plugin_name}@${MARKETPLACE_NAME}" 2>&1); then
                log_success "Removed ${plugin_name}"
            else
                log_warn "${plugin_name} not found or failed to remove"
                print_details "$uninstall_output"
            fi
        done

        local remove_output
        if remove_output=$(claude plugin marketplace remove "${REPO}" 2>&1); then
            log_success "Removed marketplace"
        else
            log_warn "Marketplace not found or failed to remove"
            print_details "$remove_output"
        fi
    fi

    # Remove Codex skills
    local codex_home="${CODEX_HOME:-$HOME/.codex}"
    local skills_dir="${codex_home}/skills"

    for plugin_name in "${ALL_PLUGINS[@]}"; do
        local manifest="${skills_dir}/.tmc-marketplace-${plugin_name}"
        # Also check legacy manifest name
        if [[ "$plugin_name" == "iterative-engineering" ]] && [ ! -f "$manifest" ]; then
            manifest="${skills_dir}/.tmc-marketplace"
        fi

        if [ -f "$manifest" ]; then
            log_info "Removing Codex skills for ${plugin_name}..."
            local removed=0

            while IFS= read -r skill_name; do
                [ -z "$skill_name" ] && continue
                local skill_dir="${skills_dir}/${skill_name}"
                if [ -d "$skill_dir" ]; then
                    rm -rf "$skill_dir"
                    ((removed++))
                fi
            done < "$manifest"

            rm -f "$manifest"
            log_success "Removed ${removed} Codex skills for ${plugin_name}"
        fi
    done

    # Clean up legacy manifest if it exists
    local legacy_manifest="${skills_dir}/.tmc-marketplace"
    [ -f "$legacy_manifest" ] && rm -f "$legacy_manifest"

    echo ""
}

# --- Argument parsing ---

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --all)
                INSTALL_ALL=true
                shift
                ;;
            --plugin)
                if [[ $# -lt 2 ]]; then
                    die "--plugin requires a plugin name"
                fi
                local valid=false
                for p in "${ALL_PLUGINS[@]}"; do
                    if [[ "$p" == "$2" ]]; then
                        valid=true
                        break
                    fi
                done
                if [[ "$valid" != "true" ]]; then
                    die "Unknown plugin: $2. Available: ${ALL_PLUGINS[*]}"
                fi
                SELECTED_PLUGINS+=("$2")
                shift 2
                ;;
            --claude-only)
                if [[ "$INSTALL_TARGET" == "codex" ]]; then
                    die "Cannot combine --claude-only with --codex-only"
                fi
                INSTALL_TARGET="claude"
                shift
                ;;
            --codex-only)
                if [[ "$INSTALL_TARGET" == "claude" ]]; then
                    die "Cannot combine --claude-only with --codex-only"
                fi
                INSTALL_TARGET="codex"
                shift
                ;;
            --help|-h)
                echo "TMC Marketplace Installer v${VERSION}"
                echo ""
                echo "Usage:"
                echo "  Install:       curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash"
                echo "  Install all:   curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --all"
                echo "  One plugin:    curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --plugin <name>"
                echo "  Codex:         curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --codex-only"
                echo "  Claude:        curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --claude-only"
                echo "  Uninstall:     curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --uninstall"
                echo ""
                echo "Options:"
                echo "  --all          Install all plugins (non-interactive)"
                echo "  --plugin NAME  Install a specific plugin (repeatable)"
                echo "  --uninstall    Remove all plugins and skills"
                echo "  --codex-only   Install Codex skills only"
                echo "  --claude-only  Install Claude Code plugin only"
                echo "  --help, -h     Show this help message"
                echo ""
                echo "Available plugins: ${ALL_PLUGINS[*]}"
                exit 0
                ;;
            *)
                die "Unknown option: $1. Use --help for usage."
                ;;
        esac
    done

    if [[ "$UNINSTALL" == "true" && "$INSTALL_TARGET" != "both" ]]; then
        die "--codex-only and --claude-only are install-only options"
    fi

    case "$INSTALL_TARGET" in
        both)
            INSTALL_CLAUDE=true
            INSTALL_CODEX=true
            ;;
        claude)
            INSTALL_CLAUDE=true
            INSTALL_CODEX=false
            ;;
        codex)
            INSTALL_CLAUDE=false
            INSTALL_CODEX=true
            ;;
    esac
}

# --- Main ---

main() {
    parse_args "$@"
    print_banner

    if [[ "$UNINSTALL" == "true" ]]; then
        do_uninstall
        return
    fi

    # Determine which plugins to install
    if [[ "$INSTALL_ALL" == "true" ]]; then
        SELECTED_PLUGINS=("${ALL_PLUGINS[@]}")
    elif [ ${#SELECTED_PLUGINS[@]} -eq 0 ]; then
        # Default: interactive selection
        prompt_plugin_selection
    fi

    log_info "Installing plugins: ${SELECTED_PLUGINS[*]}"
    echo ""

    # Download archive once if Codex install is needed
    CODEX_EXTRACT_DIR=""
    if [[ "$INSTALL_CODEX" == "true" ]]; then
        if ! download_and_extract_archive; then
            INSTALL_CODEX=false
        fi
    fi

    for plugin_name in "${SELECTED_PLUGINS[@]}"; do
        if [[ "$INSTALL_CLAUDE" == "true" ]]; then
            install_claude_plugin "$plugin_name"
        fi
        if [[ "$INSTALL_CODEX" == "true" ]]; then
            install_codex_skills "$plugin_name" "$CODEX_EXTRACT_DIR"
        fi
        echo ""
    done

    # Clean up extracted archive
    if [ -n "$CODEX_EXTRACT_DIR" ] && [ -d "$CODEX_EXTRACT_DIR" ]; then
        rm -rf "$CODEX_EXTRACT_DIR"
    fi

    print_success
}

main "$@"
