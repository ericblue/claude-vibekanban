#!/bin/bash

# PRD-to-Tasks Workflow Installer
# Installs Claude Code commands for PRD/VibeKanban workflow

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_SRC="$SCRIPT_DIR/commands"
COMMANDS_DEST="$HOME/.claude/commands"

# Global flags
FORCE_OVERWRITE=false
OVERWRITE_ALL=false
SKIP_ALL=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     PRD-to-Tasks Workflow Installer for Claude Code        ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Prompt user for overwrite confirmation
# Returns 0 if should overwrite, 1 if should skip
prompt_overwrite() {
    local filename="$1"
    local dest="$2"

    # If force flag is set, always overwrite
    if [ "$FORCE_OVERWRITE" = true ]; then
        return 0
    fi

    # If user chose "all" previously, use that choice
    if [ "$OVERWRITE_ALL" = true ]; then
        return 0
    fi
    if [ "$SKIP_ALL" = true ]; then
        return 1
    fi

    # Check if file exists
    if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        return 0  # File doesn't exist, no need to prompt
    fi

    # Determine what type of existing file
    local existing_type="file"
    if [ -L "$dest" ]; then
        existing_type="symlink"
    fi

    echo ""
    print_warning "File already exists: $filename ($existing_type)"
    echo -n "Overwrite? [y]es / [n]o / [a]ll / [s]kip all: "
    read -r response

    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        [nN]|[nN][oO])
            return 1
            ;;
        [aA]|[aA][lL][lL])
            OVERWRITE_ALL=true
            return 0
            ;;
        [sS]|[sS][kK][iI][pP])
            SKIP_ALL=true
            return 1
            ;;
        *)
            print_warning "Invalid response, skipping..."
            return 1
            ;;
    esac
}

show_help() {
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --link, -l     Create symlinks instead of copying (for development)"
    echo "  --force, -f    Overwrite existing files without prompting"
    echo "  --uninstall    Remove installed commands"
    echo "  --status       Show installation status"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./install.sh              # Copy commands to ~/.claude/commands/"
    echo "  ./install.sh --link       # Symlink commands (changes auto-apply)"
    echo "  ./install.sh --link -f    # Symlink and overwrite without prompting"
    echo "  ./install.sh --status     # Check what's installed"
}

check_source() {
    if [ ! -d "$COMMANDS_SRC" ]; then
        print_error "Commands directory not found: $COMMANDS_SRC"
        exit 1
    fi

    local count=$(ls -1 "$COMMANDS_SRC"/*.md 2>/dev/null | wc -l)
    if [ "$count" -eq 0 ]; then
        print_error "No command files found in $COMMANDS_SRC"
        exit 1
    fi
}

create_dest_dir() {
    if [ ! -d "$COMMANDS_DEST" ]; then
        print_info "Creating commands directory: $COMMANDS_DEST"
        mkdir -p "$COMMANDS_DEST"
    fi
}

install_copy() {
    print_info "Installing commands (copy mode)..."

    local installed=0
    local skipped=0

    for file in "$COMMANDS_SRC"/*.md; do
        local filename=$(basename "$file")
        local dest="$COMMANDS_DEST/$filename"

        # Check if we should overwrite existing file
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            if ! prompt_overwrite "$filename" "$dest"; then
                print_warning "Skipped: $filename"
                ((skipped++))
                continue
            fi
            rm "$dest"
        fi

        cp "$file" "$dest"
        print_success "Installed: $filename"
        ((installed++))
    done

    if [ "$skipped" -gt 0 ]; then
        echo ""
        print_info "Installed: $installed, Skipped: $skipped"
    fi
}

install_link() {
    print_info "Installing commands (symlink mode)..."
    print_warning "Commands will auto-update when you modify files in this repo"

    local installed=0
    local skipped=0

    for file in "$COMMANDS_SRC"/*.md; do
        local filename=$(basename "$file")
        local dest="$COMMANDS_DEST/$filename"

        # Check if we should overwrite existing file
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            if ! prompt_overwrite "$filename" "$dest"; then
                print_warning "Skipped: $filename"
                ((skipped++))
                continue
            fi
            rm "$dest"
        fi

        ln -s "$file" "$dest"
        print_success "Linked: $filename -> $file"
        ((installed++))
    done

    if [ "$skipped" -gt 0 ]; then
        echo ""
        print_info "Installed: $installed, Skipped: $skipped"
    fi
}

uninstall() {
    print_info "Uninstalling commands..."

    local removed=0
    for file in "$COMMANDS_SRC"/*.md; do
        local filename=$(basename "$file")
        local dest="$COMMANDS_DEST/$filename"

        if [ -e "$dest" ] || [ -L "$dest" ]; then
            rm "$dest"
            print_success "Removed: $filename"
            ((removed++))
        fi
    done

    if [ "$removed" -eq 0 ]; then
        print_warning "No commands were installed"
    else
        print_success "Uninstalled $removed command(s)"
    fi
}

show_status() {
    print_info "Installation status:"
    echo ""

    local installed=0
    local linked=0
    local missing=0

    for file in "$COMMANDS_SRC"/*.md; do
        local filename=$(basename "$file")
        local dest="$COMMANDS_DEST/$filename"

        if [ -L "$dest" ]; then
            local target=$(readlink "$dest")
            echo -e "  ${GREEN}●${NC} $filename ${BLUE}(linked → $target)${NC}"
            ((linked++))
            ((installed++))
        elif [ -f "$dest" ]; then
            echo -e "  ${GREEN}●${NC} $filename ${YELLOW}(copied)${NC}"
            ((installed++))
        else
            echo -e "  ${RED}○${NC} $filename ${RED}(not installed)${NC}"
            ((missing++))
        fi
    done

    echo ""
    echo "Summary: $installed installed ($linked linked), $missing missing"
}

# Main script
print_header

# Parse arguments
INSTALL_MODE="copy"
ACTION="install"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --uninstall)
            ACTION="uninstall"
            shift
            ;;
        --status)
            ACTION="status"
            shift
            ;;
        --link|-l)
            INSTALL_MODE="link"
            shift
            ;;
        --force|-f)
            FORCE_OVERWRITE=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Execute action
case "$ACTION" in
    uninstall)
        uninstall
        ;;
    status)
        check_source
        show_status
        ;;
    install)
        check_source
        create_dest_dir
        if [ "$INSTALL_MODE" = "link" ]; then
            install_link
        else
            install_copy
        fi
        ;;
esac

echo ""
print_success "Installation complete!"
echo ""
echo "Core workflow commands:"
echo "  /generate-prd    - Generate a PRD from a project idea"
echo "  /prd-review      - Review PRD and ask clarifying questions"
echo "  /create-plan     - Create development plan with epics from PRD"
echo "  /generate-tasks  - Generate VibeKanban tasks from plan"
echo "  /sync-plan       - Sync plan with VibeKanban status"
echo ""
echo "Plan management commands:"
echo "  /plan-status     - Show progress summary (read-only)"
echo "  /next-task       - Recommend the best next task to work on"
echo "  /add-epic        - Add a new epic to the plan"
echo "  /close-epic      - Mark an epic as complete"
echo ""
print_info "Restart Claude Code or start a new session to use the commands."
