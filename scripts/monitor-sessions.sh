#!/usr/bin/env bash
#
# monitor-sessions.sh - Live monitoring dashboard for parallel Claude Code sessions
#
# Usage: ./scripts/monitor-sessions.sh [refresh_interval]
#
# Arguments:
#   refresh_interval  Seconds between refreshes (default: 30)
#
# Run this in a separate terminal while /work-parallel-loop is active.
# Press Ctrl+C to exit.

set -euo pipefail

REFRESH_INTERVAL="${1:-30}"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"
WORKTREES_DIR="../${PROJECT_NAME}-worktrees"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Box drawing
HLINE="─"
VLINE="│"
TL="┌"
TR="┐"
BL="└"
BR="┘"
LT="├"
RT="┤"

draw_line() {
    local width=$1
    local left="${2:-$HLINE}"
    local right="${3:-$HLINE}"
    printf "%s" "$left"
    printf "%0.s$HLINE" $(seq 1 $((width - 2)))
    printf "%s\n" "$right"
}

center_text() {
    local text="$1"
    local width="$2"
    local text_len=${#text}
    local pad=$(( (width - text_len) / 2 ))
    printf "%*s%s%*s" $pad "" "$text" $((width - text_len - pad)) ""
}

get_session_manager() {
    if command -v screen &>/dev/null; then
        echo "screen"
    elif command -v tmux &>/dev/null; then
        echo "tmux"
    else
        echo "none"
    fi
}

get_sessions() {
    local mgr
    mgr=$(get_session_manager)
    case "$mgr" in
        screen)
            screen -ls 2>/dev/null | grep "claude-task-" | awk '{print $1}' | sed 's/.*\.//' | sed 's/\t.*//'
            ;;
        tmux)
            tmux list-sessions 2>/dev/null | grep "claude-task-" | cut -d: -f1
            ;;
        *)
            echo ""
            ;;
    esac
}

get_session_state() {
    local session_name="$1"
    local mgr
    mgr=$(get_session_manager)
    case "$mgr" in
        screen)
            local state
            state=$(screen -ls 2>/dev/null | grep "$session_name" | grep -o "(Attached)\|(Detached)" | tr -d '()')
            echo "${state:-Dead}"
            ;;
        tmux)
            if tmux has-session -t "$session_name" 2>/dev/null; then
                local attached
                attached=$(tmux list-sessions -F "#{session_name}:#{session_attached}" 2>/dev/null | grep "^${session_name}:" | cut -d: -f2)
                if [ "$attached" = "1" ]; then
                    echo "Attached"
                else
                    echo "Detached"
                fi
            else
                echo "Dead"
            fi
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

get_log_age() {
    local log_file="$1"
    if [ ! -f "$log_file" ]; then
        echo "no log"
        return
    fi
    local now
    now=$(date +%s)
    local mod
    mod=$(stat -f %m "$log_file" 2>/dev/null || stat -c %Y "$log_file" 2>/dev/null)
    if [ -z "$mod" ]; then
        echo "unknown"
        return
    fi
    local diff=$((now - mod))
    if [ $diff -lt 60 ]; then
        echo "${diff}s ago"
    elif [ $diff -lt 3600 ]; then
        echo "$((diff / 60))m ago"
    else
        echo "$((diff / 3600))h ago"
    fi
}

get_log_status() {
    local log_file="$1"
    if [ ! -f "$log_file" ]; then
        echo "NO_LOG"
        return
    fi
    local marker
    marker=$(tail -10 "$log_file" 2>/dev/null | grep "SESSION_STATUS:" | tail -1)
    if echo "$marker" | grep -q "COMPLETED"; then
        echo "COMPLETED"
    elif echo "$marker" | grep -q "FAILED"; then
        echo "FAILED"
    else
        echo "RUNNING"
    fi
}

get_commit_count() {
    local worktree_path="$1"
    local default_branch="$2"
    if [ ! -d "$worktree_path" ]; then
        echo "0"
        return
    fi
    git -C "$worktree_path" rev-list --count "${default_branch}..HEAD" 2>/dev/null || echo "0"
}

get_last_commit_age() {
    local worktree_path="$1"
    if [ ! -d "$worktree_path" ]; then
        echo "none"
        return
    fi
    git -C "$worktree_path" log -1 --format="%cr" 2>/dev/null || echo "none"
}

get_default_branch() {
    local branch
    branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    if [ -z "$branch" ]; then
        branch=$(git branch --list main master 2>/dev/null | head -1 | tr -d ' *')
    fi
    echo "${branch:-main}"
}

determine_status() {
    local session_state="$1"
    local log_status="$2"
    local log_age_raw="$3"
    local commits="$4"

    if [ "$log_status" = "COMPLETED" ]; then
        echo "DONE"
        return
    fi
    if [ "$log_status" = "FAILED" ]; then
        echo "FAIL"
        return
    fi
    if [ "$session_state" = "Dead" ] && [ "$log_status" = "NO_LOG" ] && [ "$commits" = "0" ]; then
        echo "DEAD"
        return
    fi
    if [ "$session_state" = "Dead" ] && [ "$commits" -gt 0 ]; then
        echo "DONE?"
        return
    fi
    if [ "$session_state" = "Attached" ]; then
        echo "WATCH"
        return
    fi
    # Check staleness - extract minutes from age
    if echo "$log_age_raw" | grep -q "m ago"; then
        local mins
        mins=$(echo "$log_age_raw" | sed 's/m ago//')
        if [ "$mins" -gt 10 ]; then
            echo "STUCK?"
            return
        fi
    fi
    if echo "$log_age_raw" | grep -q "h ago"; then
        echo "STUCK?"
        return
    fi
    echo "ACTIVE"
}

status_color() {
    local status="$1"
    case "$status" in
        ACTIVE) echo "$GREEN" ;;
        DONE)   echo "$GREEN" ;;
        "DONE?") echo "$YELLOW" ;;
        WATCH)  echo "$CYAN" ;;
        "STUCK?") echo "$YELLOW" ;;
        FAIL)   echo "$RED" ;;
        DEAD)   echo "$RED" ;;
        *)      echo "$NC" ;;
    esac
}

render_dashboard() {
    local width=90
    local default_branch
    default_branch=$(get_default_branch)
    local now
    now=$(date "+%Y-%m-%d %H:%M:%S")

    # Clear screen
    clear

    # Header
    echo -e "${BOLD}${CYAN}"
    draw_line $width "$TL" "$TR"
    printf "${VLINE}$(center_text "VIBEKANBAN SESSION MONITOR" $((width - 2)))${VLINE}\n"
    printf "${VLINE}$(center_text "$PROJECT_NAME | $now | refresh: ${REFRESH_INTERVAL}s" $((width - 2)))${VLINE}\n"
    draw_line $width "$BL" "$BR"
    echo -e "${NC}"

    # Detect worktrees
    local worktrees=()
    local task_ids=()
    local branches=()

    if [ -d "$WORKTREES_DIR" ]; then
        while IFS= read -r line; do
            local wt_path
            wt_path=$(echo "$line" | awk '{print $1}')
            local wt_branch
            wt_branch=$(echo "$line" | awk '{print $3}' | tr -d '[]')

            # Only include task worktrees
            if echo "$wt_branch" | grep -q "^task/"; then
                worktrees+=("$wt_path")
                branches+=("$wt_branch")
                # Extract task ID from branch name (e.g., task/2.3-add-user-api -> 2.3)
                local tid
                tid=$(echo "$wt_branch" | sed 's|^task/||' | sed 's/-.*//')
                task_ids+=("$tid")
            fi
        done < <(git worktree list 2>/dev/null | grep -v "$(pwd)")
    fi

    # Also check for screen/tmux sessions without worktrees
    local all_sessions
    all_sessions=$(get_sessions)

    # Session table
    echo -e "${BOLD} Sessions${NC}"
    echo ""

    if [ ${#worktrees[@]} -eq 0 ] && [ -z "$all_sessions" ]; then
        echo -e "  ${DIM}No active sessions or worktrees detected.${NC}"
        echo -e "  ${DIM}Run /work-parallel or /work-parallel-loop to start.${NC}"
    else
        # Table header
        printf "  ${BOLD}%-8s %-30s %-10s %-10s %-8s %-8s %-10s${NC}\n" \
            "TASK" "BRANCH" "SESSION" "LOG" "COMMITS" "LAST" "STATUS"
        printf "  ${DIM}%-8s %-30s %-10s %-10s %-8s %-8s %-10s${NC}\n" \
            "--------" "------------------------------" "----------" "----------" "--------" "--------" "----------"

        for i in "${!worktrees[@]}"; do
            local tid="${task_ids[$i]}"
            local branch="${branches[$i]}"
            local wt_path="${worktrees[$i]}"
            local session_name="claude-task-${tid}"
            local log_file="${WORKTREES_DIR}/task-${tid}.log"

            local session_state
            session_state=$(get_session_state "$session_name")
            local log_age
            log_age=$(get_log_age "$log_file")
            local log_status
            log_status=$(get_log_status "$log_file")
            local commits
            commits=$(get_commit_count "$wt_path" "$default_branch")
            local last_commit
            last_commit=$(get_last_commit_age "$wt_path")

            local status
            status=$(determine_status "$session_state" "$log_status" "$log_age" "$commits")
            local color
            color=$(status_color "$status")

            # Truncate branch name if too long
            local short_branch="${branch}"
            if [ ${#short_branch} -gt 28 ]; then
                short_branch="${short_branch:0:25}..."
            fi

            printf "  %-8s %-30s %-10s %-10s %-8s %-8s ${color}%-10s${NC}\n" \
                "$tid" "$short_branch" "$session_state" "$log_age" "$commits" "$last_commit" "$status"
        done
    fi

    echo ""

    # Summary bar
    local total=${#worktrees[@]}
    local active=0 done=0 failed=0 stuck=0
    for i in "${!worktrees[@]}"; do
        local tid="${task_ids[$i]}"
        local wt_path="${worktrees[$i]}"
        local log_file="${WORKTREES_DIR}/task-${tid}.log"
        local session_name="claude-task-${tid}"
        local session_state
        session_state=$(get_session_state "$session_name")
        local log_age
        log_age=$(get_log_age "$log_file")
        local log_status
        log_status=$(get_log_status "$log_file")
        local commits
        commits=$(get_commit_count "$wt_path" "$default_branch")
        local status
        status=$(determine_status "$session_state" "$log_status" "$log_age" "$commits")
        case "$status" in
            ACTIVE|WATCH) ((active++)) ;;
            DONE|"DONE?") ((done++)) ;;
            FAIL|DEAD) ((failed++)) ;;
            "STUCK?") ((stuck++)) ;;
        esac
    done

    echo -e "${BOLD} Summary${NC}"
    printf "  ${GREEN}Active: %d${NC}  ${GREEN}Done: %d${NC}  ${YELLOW}Stuck: %d${NC}  ${RED}Failed: %d${NC}  Total: %d\n" \
        $active $done $stuck $failed $total
    echo ""

    # Quick actions
    echo -e "${BOLD} Quick Actions${NC}"
    echo -e "  ${DIM}Attach to session:${NC}  screen -r claude-task-<id>"
    echo -e "  ${DIM}Watch logs:${NC}         tail -f ${WORKTREES_DIR}/task-*.log"
    echo -e "  ${DIM}Check VK status:${NC}    Run /session-status in Claude Code"
    echo ""

    # Legend
    echo -e "${BOLD} Legend${NC}"
    printf "  ${GREEN}ACTIVE${NC}=working  ${GREEN}DONE${NC}=completed  ${CYAN}WATCH${NC}=attached  "
    printf "${YELLOW}STUCK?${NC}=stale 10m+  ${RED}FAIL${NC}=crashed  ${RED}DEAD${NC}=no output\n"
    echo ""
    echo -e "  ${DIM}Press Ctrl+C to exit${NC}"
}

# Main loop
trap 'echo -e "\n${NC}Dashboard stopped."; exit 0' INT TERM

while true; do
    render_dashboard
    sleep "$REFRESH_INTERVAL"
done
