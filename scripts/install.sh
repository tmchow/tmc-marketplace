#!/usr/bin/env bash
set -euo pipefail

# TMC Marketplace Installer
# Usage:
#   Install:   curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash
#   Codex only:  curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --codex-only
#   Claude only: curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --claude-only
#   Uninstall: curl -fsSL "https://raw.githubusercontent.com/tmchow/tmc-marketplace/main/scripts/install.sh?$(date +%s)" | bash -s -- --uninstall

# --- Constants ---
VERSION="1.0.0"
REPO="tmchow/tmc-marketplace"
PLUGIN_NAME="iterative-engineering"
MARKETPLACE_NAME="tmc-marketplace"
ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/main.tar.gz"
ARCHIVE_PREFIX="tmc-marketplace-main"
MAX_RETRIES=3
RETRY_DELAY=2

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

# --- Core functions ---

print_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║       TMC Marketplace Installer        ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
}

install_claude_plugin() {
    log_info "Installing Claude Code plugin..."

    if ! command -v claude &>/dev/null; then
        log_warn "Claude Code CLI not found, skipping plugin install"
        echo -e "  ${YELLOW}→${NC} After installing Claude Code, re-run this script to add the plugin" >&2
        return 0
    fi

    # Add marketplace (idempotent; may return non-zero if already added)
    local marketplace_output
    if ! marketplace_output=$(claude plugin marketplace add "${REPO}" 2>&1); then
        log_warn "Failed to add marketplace (may already exist), continuing"
        print_details "$marketplace_output"
    fi

    # Install plugin (idempotent - reinstalls/updates if exists)
    local install_output
    if ! install_output=$(claude plugin install "${PLUGIN_NAME}@${MARKETPLACE_NAME}" 2>&1); then
        log_warn "Failed to install plugin"
        print_details "$install_output"
        return 0
    fi

    log_success "Installed ${PLUGIN_NAME}@${MARKETPLACE_NAME} plugin"
}

install_codex_skills() {
    log_info "Installing Codex skills..."

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
    local tmp_dir
    tmp_dir=$(mktemp -d)

    # Download archive
    local archive_path="${tmp_dir}/archive.tar.gz"
    if ! download_with_retry "$ARCHIVE_URL" "$archive_path"; then
        rm -rf "$tmp_dir"
        log_warn "Failed to download skills after $MAX_RETRIES attempts"
        if [ -n "$LAST_DOWNLOAD_ERROR" ]; then
            print_details "$LAST_DOWNLOAD_ERROR"
        fi
        return 0
    fi

    # Extract
    local extract_dir="${tmp_dir}/extracted"
    mkdir -p "$extract_dir"
    tar xzf "$archive_path" -C "$extract_dir"

    local source_skills="${extract_dir}/${ARCHIVE_PREFIX}/plugins/${PLUGIN_NAME}/skills"
    if [ ! -d "$source_skills" ]; then
        rm -rf "$tmp_dir"
        log_warn "Skills directory not found in archive"
        return 0
    fi

    # Copy each skill and record in manifest
    local manifest="${skills_dir}/.tmc-marketplace"
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
    printf '%s\n' "${installed_skills[@]}" > "$manifest"

    rm -rf "$tmp_dir"
    log_success "Installed ${count} skills to ${skills_dir}/"
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

    # Remove Claude Code plugin
    if command -v claude &>/dev/null; then
        log_info "Removing Claude Code plugin..."

        local uninstall_output
        if uninstall_output=$(claude plugin uninstall "${PLUGIN_NAME}@${MARKETPLACE_NAME}" 2>&1); then
            log_success "Removed Claude Code plugin"
        else
            log_warn "Claude Code plugin not found or failed to remove"
            print_details "$uninstall_output"
        fi

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
    local manifest="${skills_dir}/.tmc-marketplace"

    if [ -f "$manifest" ]; then
        log_info "Removing Codex skills..."
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
        log_success "Removed ${removed} Codex skills"
    fi

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
                echo "  Install:   curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash"
                echo "  Codex:     curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --codex-only"
                echo "  Claude:    curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --claude-only"
                echo "  Uninstall: curl -fsSL \"https://raw.githubusercontent.com/${REPO}/main/scripts/install.sh?\$(date +%s)\" | bash -s -- --uninstall"
                echo ""
                echo "Options:"
                echo "  --uninstall    Remove plugin and skills"
                echo "  --codex-only   Install Codex skills only"
                echo "  --claude-only  Install Claude Code plugin only"
                echo "  --help, -h     Show this help message"
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
    else
        if [[ "$INSTALL_CLAUDE" == "true" ]]; then
            install_claude_plugin
        fi
        if [[ "$INSTALL_CODEX" == "true" ]]; then
            install_codex_skills
        fi
        print_success
    fi
}

main "$@"
