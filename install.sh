#!/usr/bin/env bash

# beauty-slurm: Automated Installer
# Resolves path, configures executable permissions, and integrates into ~/.bashrc or ~/.zshrc.

# Color variables for standard printouts
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
PURPLE='\033[35m'
CYAN='\033[36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${PURPLE}${BOLD}========================================================================${NC}"
echo -e "                   ${PURPLE}${BOLD}Beauty SLURM Automated Installer${NC}"
echo -e "${PURPLE}${BOLD}========================================================================${NC}"

# 1. Resolve absolute repository path
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "📂 Repository Path: ${CYAN}${INSTALL_DIR}${NC}"

# 2. Make all binaries executable
echo -e "⚙️  Setting file permissions..."
chmod +x "$INSTALL_DIR"/bin/* "$INSTALL_DIR"/mock/* 2>/dev/null
echo -e "   ${GREEN}✔ Executable permissions configured for bin/ and mock/ scripts.${NC}"

# 3. Detect Shell configuration file
SHELL_NAME=$(basename "$SHELL")
SHELL_RC=""

case "$SHELL_NAME" in
    zsh)
        SHELL_RC="$HOME/.zshrc"
        ;;
    bash)
        if [ -f "$HOME/.bashrc" ]; then
            SHELL_RC="$HOME/.bashrc"
        else
            SHELL_RC="$HOME/.bash_profile"
        fi
        ;;
    *)
        SHELL_RC="$HOME/.profile"
        ;;
esac

echo -e "🐚 Shell Detected: ${CYAN}$SHELL_NAME${NC} ➔ Target Config: ${CYAN}$SHELL_RC${NC}"

# 4. Check for existing SLURM binaries
MOCK_FLAG=""
if ! command -v squeue &>/dev/null; then
    echo -e "${YELLOW}⚠️  No live SLURM binaries (squeue/sinfo) detected on PATH.${NC}"
    echo -e "   Enabling local offline mocking layer automatically for local testing."
    MOCK_FLAG="export BEAUTY_SLURM_MOCK=1"
fi

# 5. Add integration lines to shell config
INTEGRATION_BLOCK=$(cat <<EOF

# >>> beauty-slurm initialize >>>
# Added by beauty-slurm installer on $(date)
export PATH="$INSTALL_DIR/bin:\$PATH"
$MOCK_FLAG
# <<< beauty-slurm initialize <<<
EOF
)

# Remove any existing initialization blocks first to avoid duplication
if [ -f "$SHELL_RC" ]; then
    # Clean up old block if present
    sed -i.bak '/# >>> beauty-slurm initialize >>>/,/# <<< beauty-slurm initialize <<</d' "$SHELL_RC" 2>/dev/null || \
    sed -i '' '/# >>> beauty-slurm initialize >>>/,/# <<< beauty-slurm initialize <<</d' "$SHELL_RC" 2>/dev/null
    sed -i.bak '/# >>> slurm-utils initialize >>>/,/# <<< slurm-utils initialize <<</d' "$SHELL_RC" 2>/dev/null || \
    sed -i '' '/# >>> slurm-utils initialize >>>/,/# <<< slurm-utils initialize <<</d' "$SHELL_RC" 2>/dev/null
    rm -f "${SHELL_RC}.bak"
fi

# Append new integration block
echo "$INTEGRATION_BLOCK" >> "$SHELL_RC"
echo -e "   ${GREEN}✔ Added PATH configuration block to $SHELL_RC.${NC}"

echo -e "${PURPLE}${BOLD}========================================================================${NC}"
echo -e "        ${GREEN}${BOLD}🎉 Beauty SLURM successfully installed!${NC}"
echo -e "${PURPLE}${BOLD}========================================================================${NC}"
echo -e "To start using the beautified utilities in your current terminal, run:"
echo -e "   ${CYAN}${BOLD}source $(basename "$SHELL_RC")${NC}"
echo -e ""
echo -e "Available commands:"
echo -e "  • ${CYAN}sjobs${NC}         Smart, colorized job monitor (squeue wrapper)"
echo -e "  • ${CYAN}scluster${NC}      Partition CPU & GPU status dashboard (sinfo wrapper)"
echo -e "  • ${CYAN}sbatch-track${NC}  Interactive submission linter & log tracker (sbatch wrapper)"
echo -e "  • ${CYAN}slogs${NC}         Smart log streamer (tail -f by running job index)"
echo -e "  • ${CYAN}scancel-safe${NC}  Safe job canceller with confirmation dialogs"
echo -e "  • ${CYAN}srun-quick${NC}    Quick interactive compute resource allocator"
echo -e "${PURPLE}${BOLD}========================================================================${NC}"
