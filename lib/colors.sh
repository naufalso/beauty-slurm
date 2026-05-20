#!/usr/bin/env bash

# beauty-slurm: Terminal color and format utilities
# Handles ANSI coloring, 256-color palette, smart TTY detection, and UTF-8 icons.

# Default configuration
FORCE_COLOR="${BEAUTY_SLURM_COLOR:-auto}" # always, never, auto

# Base ANSI codes
ANSI_RESET="\033[0m"
ANSI_BOLD="\033[1m"
ANSI_DIM="\033[2m"
ANSI_UNDERLINE="\033[4m"

# Standard 16 Colors
CLR_BLACK=""
CLR_RED=""
CLR_GREEN=""
CLR_YELLOW=""
CLR_BLUE=""
CLR_MAGENTA=""
CLR_CYAN=""
CLR_WHITE=""

CLR_GREY=""
CLR_ORANGE=""
CLR_PURPLE=""
CLR_TEAL=""
CLR_GOLD=""

# Semantic Styling Variables
STYLE_RESET=""
STYLE_BOLD=""
STYLE_DIM=""
STYLE_UNDERLINE=""

COLOR_PRIMARY=""
COLOR_SECONDARY=""
COLOR_SUCCESS=""
COLOR_WARNING=""
COLOR_DANGER=""
COLOR_INFO=""
COLOR_MUTED=""

# Unicode Icons / Emojis (with ASCII fallbacks)
ICON_GPU="⚡"
ICON_CPU="💻"
ICON_MEM="💾"
ICON_TIME="🕒"
ICON_NODE="🖥️"
ICON_PENDING="⏳"
ICON_RUNNING="▶"
ICON_CANCEL="❌"
ICON_WARN="⚠️"
ICON_SUCCESS="✔"
ICON_ARROW="➔"

# Initialize colors and icons based on terminal capability and output redirection
init_colors() {
    local tty_check=0
    if [ -t 1 ]; then
        tty_check=1
    fi

    # Determine if we should use colors
    local use_colors=0
    case "$FORCE_COLOR" in
        always)
            use_colors=1
            ;;
        never)
            use_colors=0
            ;;
        auto|*)
            if [ "$tty_check" -eq 1 ]; then
                # Check terminal color capabilities
                local num_colors
                num_colors=$(tput colors 2>/dev/null || echo 8)
                if [ "$num_colors" -ge 8 ]; then
                    use_colors=1
                fi
            else
                use_colors=0
            fi
            ;;
    esac

    # Determine if terminal supports UTF-8
    local use_unicode=1
    case "${LC_ALL:-${LC_CTYPE:-${LANG}}}" in
        *UTF-8*|*utf8*)
            use_unicode=1
            ;;
        *)
            use_unicode=0
            # If standard locale is C, check if terminal still supports emojis
            if [[ "$TERM" == "xterm-256color" || "$TERM" == "alacritty" || "$TERM" == "iterm" ]]; then
                use_unicode=1
            else
                use_unicode=0
            fi
            ;;
    esac

    if [ "$use_colors" -eq 1 ]; then
        # Standard colors
        CLR_BLACK="\033[30m"
        CLR_RED="\033[31m"
        CLR_GREEN="\033[32m"
        CLR_YELLOW="\033[33m"
        CLR_BLUE="\033[34m"
        CLR_MAGENTA="\033[35m"
        CLR_CYAN="\033[36m"
        CLR_WHITE="\033[37m"
        
        # 256-color palette (Premium palette)
        CLR_GREY="\033[38;5;244m"
        CLR_ORANGE="\033[38;5;208m"
        CLR_PURPLE="\033[38;5;99m"
        CLR_TEAL="\033[38;5;44m"
        CLR_GOLD="\033[38;5;214m"

        # Styles
        STYLE_RESET="$ANSI_RESET"
        STYLE_BOLD="$ANSI_BOLD"
        STYLE_DIM="$ANSI_DIM"
        STYLE_UNDERLINE="$ANSI_UNDERLINE"

        # Semantic roles
        COLOR_PRIMARY="$CLR_PURPLE"
        COLOR_SECONDARY="$CLR_TEAL"
        COLOR_SUCCESS="$CLR_GREEN"
        COLOR_WARNING="$CLR_ORANGE"
        COLOR_DANGER="$CLR_RED"
        COLOR_INFO="$CLR_CYAN"
        COLOR_MUTED="$CLR_GREY"
    else
        # Stripped colors
        CLR_BLACK=""
        CLR_RED=""
        CLR_GREEN=""
        CLR_YELLOW=""
        CLR_BLUE=""
        CLR_MAGENTA=""
        CLR_CYAN=""
        CLR_WHITE=""
        CLR_GREY=""
        CLR_ORANGE=""
        CLR_PURPLE=""
        CLR_TEAL=""
        CLR_GOLD=""

        STYLE_RESET=""
        STYLE_BOLD=""
        STYLE_DIM=""
        STYLE_UNDERLINE=""

        COLOR_PRIMARY=""
        COLOR_SECONDARY=""
        COLOR_SUCCESS=""
        COLOR_WARNING=""
        COLOR_DANGER=""
        COLOR_INFO=""
        COLOR_MUTED=""
    fi

    if [ "$use_unicode" -eq 0 ]; then
        # ASCII Fallbacks
        ICON_GPU="GPU"
        ICON_CPU="CPU"
        ICON_MEM="MEM"
        ICON_TIME="TIME"
        ICON_NODE="NODE"
        ICON_PENDING="PD"
        ICON_RUNNING="R"
        ICON_CANCEL="X"
        ICON_WARN="[!]"
        ICON_SUCCESS="[OK]"
        ICON_ARROW="->"
    fi
}

# Print formatted color text helper functions
c_print() {
    local color="$1"
    local text="$2"
    printf "%b%s%b" "$color" "$text" "$STYLE_RESET"
}

# Colored print blocks
info() { printf "%b%s %b%s\n" "$COLOR_INFO" "$ICON_SUCCESS" "$STYLE_RESET" "$1"; }
warn() { printf "%b%s %b%s\n" "$COLOR_WARNING" "$ICON_WARN" "$STYLE_RESET" "$1"; }
error() { printf "%b%s %b%s\n" "$COLOR_DANGER" "$ICON_CANCEL" "$STYLE_RESET" "$1" >&2; }
success() { printf "%b%s %b%s\n" "$COLOR_SUCCESS" "$ICON_SUCCESS" "$STYLE_RESET" "$1"; }

# Progressive bar helper
# Usage: draw_bar percentage width
draw_bar() {
    local pct="$1"
    local width="$2"
    
    # Bound check percentage [0, 100]
    if [ "$pct" -lt 0 ]; then pct=0; fi
    if [ "$pct" -gt 100 ]; then pct=100; fi
    
    local filled=$(( pct * width / 100 ))
    local empty=$(( width - filled ))
    
    local color="$COLOR_SUCCESS"
    if [ "$pct" -gt 90 ]; then
        color="$COLOR_DANGER"
    elif [ "$pct" -gt 75 ]; then
        color="$COLOR_WARNING"
    fi
    
    local bar=""
    if [ "$filled" -gt 0 ]; then
        bar=$(printf "%b" "$color")
        for ((i=0; i<filled; i++)); do
            bar="${bar}█"
        done
    fi
    if [ "$empty" -gt 0 ]; then
        bar="${bar}${CLR_GREY}"
        for ((i=0; i<empty; i++)); do
            bar="${bar}░"
        done
    fi
    bar="${bar}${STYLE_RESET}"
    printf "%s" "$bar"
}

# Initialize colors upon sourcing
init_colors

# ANSI-safe Left Padding Helper
# Pads a string on the left, ignoring ANSI escape sequences in length calculations
pad_left() {
    local str="$1"
    local len="$2"
    local pad_char="${3:- }"
    
    # Strip ANSI escape codes to get raw length
    local clean_str
    clean_str=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g' 2>/dev/null || echo -e "$str")
    local clean_len=${#clean_str}
    
    if [ "$clean_len" -ge "$len" ]; then
        echo -e "$str"
    else
        local pad=$((len - clean_len))
        local padding=""
        for ((i=0; i<pad; i++)); do
            padding="${padding}${pad_char}"
        done
        echo -e "${padding}${str}"
    fi
}

# ANSI-safe Right Padding Helper
# Pads a string on the right, ignoring ANSI escape sequences in length calculations
pad_right() {
    local str="$1"
    local len="$2"
    local pad_char="${3:- }"
    
    local clean_str
    clean_str=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g' 2>/dev/null || echo -e "$str")
    local clean_len=${#clean_str}
    
    if [ "$clean_len" -ge "$len" ]; then
        echo -e "$str"
    else
        local pad=$((len - clean_len))
        local padding=""
        for ((i=0; i<pad; i++)); do
            padding="${padding}${pad_char}"
        done
        echo -e "${str}${padding}"
    fi
}

