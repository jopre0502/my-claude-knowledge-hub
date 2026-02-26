#!/bin/bash

#------------------------------------------------------------------------------
# CLAUDE CODE STATUS LINE CONFIGURATION
# Global statusline for WSL2 Ubuntu - Works in any directory
#------------------------------------------------------------------------------

# Read JSON input from Claude Code
INPUT=$(cat)

#------------------------------------------------------------------------------
# CONFIGURATION PARAMETERS
#------------------------------------------------------------------------------

# Color codes (ANSI escape sequences)
COLOR_CYAN='\033[96m'
COLOR_BLUE='\033[94m'
COLOR_MAGENTA='\033[95m'
COLOR_GREEN='\033[92m'
COLOR_YELLOW='\033[93m'
COLOR_RED='\033[91m'
COLOR_WHITE='\033[97m'
COLOR_GRAY='\033[90m'
COLOR_RESET='\033[0m'

# Features to show (true/false)
SHOW_MODEL=true
SHOW_DIRECTORY=true
SHOW_GIT_BRANCH=true
SHOW_TOKEN_USAGE=true
SHOW_OUTPUT_STYLE=true
SHOW_VIM_MODE=true

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

# Extract JSON values (works with or without jq)
get_json_value() {
    local key="$1"
    local input="$2"

    if command -v jq >/dev/null 2>&1; then
        # Use jq if available (more reliable)
        echo "$input" | jq -r "$key // empty"
    else
        # Fallback: simple grep-based extraction
        echo "$input" | grep -o "\"${key##*.}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | sed 's/.*: *"\([^"]*\)".*/\1/' | head -1
    fi
}

# Get git branch and status
get_git_info() {
    local cwd="$1"
    local git_info=""

    if git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
        local branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

        if [ -n "$branch" ]; then
            # Check if there are uncommitted changes
            if ! git -C "$cwd" --no-optional-locks diff --quiet 2>/dev/null || \
               ! git -C "$cwd" --no-optional-locks diff --cached --quiet 2>/dev/null; then
                # Dirty: yellow branch name with red asterisk
                git_info=$(printf " ${COLOR_MAGENTA}[git:${COLOR_YELLOW}%s${COLOR_RED}*${COLOR_MAGENTA}]${COLOR_RESET}" "$branch")
            else
                # Clean: green branch name
                git_info=$(printf " ${COLOR_MAGENTA}[git:${COLOR_GREEN}%s${COLOR_MAGENTA}]${COLOR_RESET}" "$branch")
            fi
        fi
    fi

    echo "$git_info"
}

# Get token usage with color coding
get_token_usage() {
    local input="$1"

    if command -v jq >/dev/null 2>&1; then
        local usage=$(echo "$input" | jq '.context_window.current_usage')

        if [ "$usage" != "null" ] && [ -n "$usage" ]; then
            local input_tok=$(echo "$usage" | jq '.input_tokens')
            local cache_cr=$(echo "$usage" | jq '.cache_creation_input_tokens')
            local cache_rd=$(echo "$usage" | jq '.cache_read_input_tokens')
            local curr=$((input_tok + cache_cr + cache_rd))
            local size=$(echo "$input" | jq '.context_window.context_window_size')

            if [ "$size" -gt 0 ]; then
                local pct=$((curr * 100 / size))
                local curr_k=$((curr / 1000))
                local size_k=$((size / 1000))

                # Color code based on usage percentage
                local token_color
                if [ $pct -lt 50 ]; then
                    token_color="$COLOR_GREEN"
                elif [ $pct -lt 75 ]; then
                    token_color="$COLOR_YELLOW"
                else
                    token_color="$COLOR_RED"
                fi

                printf "${token_color}%dK/%dK (%d%%)${COLOR_RESET}" "$curr_k" "$size_k" "$pct"
                return
            fi
        fi
    fi

    # Fallback if jq is not available or no usage data
    printf "${COLOR_GRAY}No tokens yet${COLOR_RESET}"
}

# Get vim mode indicator
get_vim_mode() {
    local input="$1"

    if command -v jq >/dev/null 2>&1; then
        local vim_val=$(echo "$input" | jq -r '.vim.mode // empty')

        if [ -n "$vim_val" ]; then
            if [ "$vim_val" = "INSERT" ]; then
                printf " ${COLOR_GREEN}[INSERT]${COLOR_RESET}"
            else
                printf " ${COLOR_BLUE}[NORMAL]${COLOR_RESET}"
            fi
        fi
    fi
}

#------------------------------------------------------------------------------
# MAIN STATUS LINE BUILDER
#------------------------------------------------------------------------------

STATUS=""

# 1. Model Name
if [ "$SHOW_MODEL" = true ]; then
    if command -v jq >/dev/null 2>&1; then
        MODEL=$(echo "$INPUT" | jq -r '.model.display_name')
        if [ -n "$MODEL" ] && [ "$MODEL" != "null" ]; then
            STATUS="${STATUS}${COLOR_CYAN}${MODEL}${COLOR_RESET}"
        fi
    else
        STATUS="${STATUS}${COLOR_CYAN}Claude${COLOR_RESET}"
    fi
fi

# 2. Working Directory
if [ "$SHOW_DIRECTORY" = true ]; then
    if command -v jq >/dev/null 2>&1; then
        CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir')
    else
        CWD=$(pwd)
    fi

    # Replace home directory with ~
    DISPLAY_DIR="${CWD/#$HOME/~}"

    if [ -n "$STATUS" ]; then
        STATUS="${STATUS} ${COLOR_GRAY}|${COLOR_RESET} "
    fi
    STATUS="${STATUS}${COLOR_BLUE}${DISPLAY_DIR}${COLOR_RESET}"
fi

# 3. Git Branch and Status
if [ "$SHOW_GIT_BRANCH" = true ]; then
    if command -v jq >/dev/null 2>&1; then
        CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir')
    else
        CWD=$(pwd)
    fi

    GIT_INFO=$(get_git_info "$CWD")
    if [ -n "$GIT_INFO" ]; then
        STATUS="${STATUS}${GIT_INFO}"
    fi
fi

# 4. Token Usage
if [ "$SHOW_TOKEN_USAGE" = true ]; then
    if [ -n "$STATUS" ]; then
        STATUS="${STATUS} ${COLOR_GRAY}|${COLOR_RESET} "
    fi
    TOKEN_INFO=$(get_token_usage "$INPUT")
    STATUS="${STATUS}${TOKEN_INFO}"
fi

# 5. Output Style
if [ "$SHOW_OUTPUT_STYLE" = true ]; then
    if command -v jq >/dev/null 2>&1; then
        STYLE=$(echo "$INPUT" | jq -r '.output_style.name // "default"')

        if [ -n "$STATUS" ]; then
            STATUS="${STATUS} ${COLOR_GRAY}|${COLOR_RESET} "
        fi
        STATUS="${STATUS}${COLOR_WHITE}Style: ${STYLE}${COLOR_RESET}"
    fi
fi

# 6. Vim Mode
if [ "$SHOW_VIM_MODE" = true ]; then
    VIM_MODE=$(get_vim_mode "$INPUT")
    if [ -n "$VIM_MODE" ]; then
        STATUS="${STATUS}${VIM_MODE}"
    fi
fi

#------------------------------------------------------------------------------
# SIDECAR: Write token budget to /tmp for SATE Budget Intelligence
# The task-orchestrator reads this file between actions for budget checks.
#------------------------------------------------------------------------------
if [ "$SHOW_TOKEN_USAGE" = true ] && command -v jq >/dev/null 2>&1; then
    SIDECAR_FILE="/tmp/claude-token-budget.json"
    USAGE_DATA=$(echo "$INPUT" | jq '.context_window.current_usage')

    if [ "$USAGE_DATA" != "null" ] && [ -n "$USAGE_DATA" ]; then
        INPUT_TOK=$(echo "$USAGE_DATA" | jq '.input_tokens')
        CACHE_CR=$(echo "$USAGE_DATA" | jq '.cache_creation_input_tokens')
        CACHE_RD=$(echo "$USAGE_DATA" | jq '.cache_read_input_tokens')
        CURR=$((INPUT_TOK + CACHE_CR + CACHE_RD))
        SIZE=$(echo "$INPUT" | jq '.context_window.context_window_size')

        if [ "$SIZE" -gt 0 ]; then
            PCT=$((CURR * 100 / SIZE))
            CURR_K=$((CURR / 1000))
            SIZE_K=$((SIZE / 1000))
            AVAILABLE_K=$(( (SIZE * 70 / 100 - CURR) / 1000 ))
            [ "$AVAILABLE_K" -lt 0 ] && AVAILABLE_K=0

            cat > "$SIDECAR_FILE" <<SIDECAR_EOF
{
  "pct": $PCT,
  "curr_k": $CURR_K,
  "size_k": $SIZE_K,
  "available_k": $AVAILABLE_K,
  "timestamp": "$(date -Iseconds)"
}
SIDECAR_EOF
        fi
    fi
fi

# Output the final status line
printf "%b\n" "$STATUS"
