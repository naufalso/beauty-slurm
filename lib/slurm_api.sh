#!/usr/bin/env bash

# beauty-slurm: SLURM commands API wrapper & parser helper
# Standardizes execution of squeue, sinfo, scontrol, sbatch and handles regex parsing.

# Load base environment if not already loaded
if [ -z "$BEAUTY_SLURM_CORE_DIR" ]; then
    CORE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$CORE_DIR/core.sh"
fi

# Prettifies SLURM Generic Resources (GRES) strings, focusing heavily on GPUs
# Examples:
#   gpu:a100:2(S:0)      -> 2x A100
#   gpu:tesla_v100:4     -> 4x V100
#   gpu:8                -> 8x GPU
#   (null)               -> ""
parse_gres() {
    local gres="$1"
    if [[ -z "$gres" || "$gres" == "(null)" || "$gres" == "N/A" || "$gres" == "none" ]]; then
        echo ""
        return
    fi

    # Replace = with : for consistent parsing (e.g. gpu=4 -> gpu:4)
    gres="${gres//=/:}"

    # Strip prefixes like "gres:" or "gres/" if present
    gres="${gres#gres:}"
    gres="${gres#gres/}"

    # Format 1: gpu:model:count(extra) or gpu:model:count
    if [[ "$gres" =~ gpu:([a-zA-Z0-9_-]+):([0-9]+) ]]; then
        local model="${BASH_REMATCH[1]}"
        local count="${BASH_REMATCH[2]}"
        
        # Clean up model name for premium display (e.g. tesla_v100 -> V100, nvidia_a100 -> A100)
        local display_model
        display_model=$(echo "$model" | tr '[:lower:]' '[:upper:]' | sed -E 's/TESLA_//g; s/NVIDIA_//g; s/GEFORCE_//g; s/GTX_//g; s/RTX_//g; s/_//g')
        echo "$count""x $display_model"

    # Format 2: gpu:count(extra) or gpu:count
    elif [[ "$gres" =~ gpu:([0-9]+) ]]; then
        local count="${BASH_REMATCH[1]}"
        echo "$count""x GPU"

    # Format 3: gpu:model
    elif [[ "$gres" =~ gpu:([a-zA-Z0-9_-]+) ]]; then
        local model="${BASH_REMATCH[1]}"
        local display_model
        display_model=$(echo "$model" | tr '[:lower:]' '[:upper:]' | sed -E 's/TESLA_//g; s/NVIDIA_//g; s/_//g')
        echo "1x $display_model"

    # Format 4: gpu (exact or with parentheses like gpu(S:0))
    elif [[ "$gres" =~ ^gpu(\(.*\))?$ ]]; then
        echo "1x GPU"
        
    else
        # Fallback to outputting the original GRES string if it's not a GPU, but cleaned up
        echo "$gres"
    fi
}

# Translates raw SLURM pending reasons into colorful, highly descriptive, friendly warnings
translate_pending_reason() {
    local reason="$1"
    
    # Strip parentheses if they exist, e.g. (Resources) -> Resources
    reason="${reason#(}"
    reason="${reason%)}"
    
    case "$reason" in
        ReqNodeNotAvail*)
            echo -e "${CLR_ORANGE}⚠️  Unavailable nodes (reservation/maintenance)${STYLE_RESET}"
            ;;
        Priority)
            echo -e "${CLR_GREY}🕒 Queued behind higher-priority jobs${STYLE_RESET}"
            ;;
        Resources)
            echo -e "${CLR_YELLOW}⚡ Waiting for free resources (CPUs/Mem/GPUs)${STYLE_RESET}"
            ;;
        Dependency)
            echo -e "${CLR_CYAN}🔄 Waiting for dependency jobs to finish${STYLE_RESET}"
            ;;
        AssociationJobLimit)
            echo -e "${CLR_RED}🛑 Account queue job limit reached${STYLE_RESET}"
            ;;
        AssociationResourceLimit)
            echo -e "${CLR_RED}🛑 Account resource limit reached${STYLE_RESET}"
            ;;
        QOSJobLimit)
            echo -e "${CLR_RED}🛑 QOS maximum job limit reached${STYLE_RESET}"
            ;;
        QOSResourceLimit)
            echo -e "${CLR_RED}🛑 QOS resource allocation limit reached${STYLE_RESET}"
            ;;
        PartitionTimeLimit)
            echo -e "${CLR_RED}⏳ Job request exceeds partition max walltime${STYLE_RESET}"
            ;;
        PartitionNodeLimit)
            echo -e "${CLR_RED}🛑 Job request exceeds partition node size limit${STYLE_RESET}"
            ;;
        JobLaunchFailure)
            echo -e "${CLR_RED}💥 Failed to launch (node communication error)${STYLE_RESET}"
            ;;
        Reservation)
            echo -e "${CLR_CYAN}📅 Waiting for reservation window to open${STYLE_RESET}"
            ;;
        None)
            echo -e "${CLR_GREEN}✔ None (Ready to run)${STYLE_RESET}"
            ;;
        *)
            echo -e "${CLR_GREY}⏳ $reason${STYLE_RESET}"
            ;;
    esac
}

# Parses standard SLURM memory strings (e.g. "4000M", "16G", "2T", "5000000K") and converts them to GB
parse_memory_to_gb() {
    local raw_mem="$1"
    if [[ -z "$raw_mem" || "$raw_mem" == "N/A" ]]; then
        echo "0"
        return
    fi
    
    # Strip any trailing 'n' or 'c' (per node, per cpu)
    local cleaned_mem
    cleaned_mem=$(echo "$raw_mem" | sed 's/[nc]$//I')
    
    # Extract number and unit
    if [[ "$cleaned_mem" =~ ^([0-9.]+)([a-zA-Z]?)$ ]]; then
        local val="${BASH_REMATCH[1]}"
        local unit=$(echo "${BASH_REMATCH[2]}" | tr '[:lower:]' '[:upper:]')
        
        case "$unit" in
            T) awk -v v="$val" 'BEGIN { printf "%.0f", v * 1024 }' ;;
            G) printf "%.0f" "$val" ;;
            M) awk -v v="$val" 'BEGIN { printf "%.1f", v / 1024 }' ;;
            K) awk -v v="$val" 'BEGIN { printf "%.3f", v / 1048576 }' ;;
            *) printf "%.0f" "$val" ;;
        esac
    else
        echo "0"
    fi
}

# Resolves the absolute path of the standard output log of a job using scontrol
# Returns path to log file, or empty string if not found or not written yet.
get_job_log_file() {
    local job_id="$1"
    if [ -z "$job_id" ]; then
        return 1
    fi
    
    # Run scontrol show job
    local details
    details=$(scontrol show job "$job_id" 2>/dev/null)
    if [ -z "$details" ]; then
        return 1
    fi
    
    # Extract WorkDir and StdOut
    # Example fields:
    #   WorkDir=/home/user/project
    #   StdOut=/home/user/project/slurm-123.out
    local work_dir
    work_dir=$(echo "$details" | grep -E -o "WorkDir=[^ ]+" | cut -d= -f2)
    local std_out
    std_out=$(echo "$details" | grep -E -o "StdOut=[^ ]+" | cut -d= -f2)
    
    if [ -z "$std_out" ]; then
        return 1
    fi
    
    # If StdOut is relative, combine with WorkDir
    if [[ "$std_out" != /* && -n "$work_dir" ]]; then
        std_out="$work_dir/$std_out"
    fi
    
    echo "$std_out"
}

# Resolves both standard output and standard error log paths of a job using scontrol
# Prints stdout path on the first line and stderr path on the second line.
get_job_log_files() {
    local job_id="$1"
    if [ -z "$job_id" ]; then
        return 1
    fi
    
    # Run scontrol show job
    local details
    details=$(scontrol show job "$job_id" 2>/dev/null)
    if [ -z "$details" ]; then
        return 1
    fi
    
    # Extract WorkDir, StdOut, and StdErr
    local work_dir
    work_dir=$(echo "$details" | grep -E -o "WorkDir=[^ ]+" | cut -d= -f2)
    local std_out
    std_out=$(echo "$details" | grep -E -o "StdOut=[^ ]+" | cut -d= -f2)
    local std_err
    std_err=$(echo "$details" | grep -E -o "StdErr=[^ ]+" | cut -d= -f2)
    
    # If StdOut is relative, combine with WorkDir
    if [[ -n "$std_out" && "$std_out" != /* && -n "$work_dir" ]]; then
        std_out="$work_dir/$std_out"
    fi
    
    # If StdErr is relative, combine with WorkDir
    if [[ -n "$std_err" && "$std_err" != /* && -n "$work_dir" ]]; then
        std_err="$work_dir/$std_err"
    fi
    
    echo "$std_out"
    echo "$std_err"
}

