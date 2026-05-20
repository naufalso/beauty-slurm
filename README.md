# ⚡ Beauty SLURM: Interactive & Informative SLURM CLI Beautifier

A premium, dependency-free Bash library and command-suite designed to supercharge the standard SLURM CLI tools (`squeue`, `sinfo`, `sbatch`, `scancel`, `srun`, `sprio`). 

Beauty SLURM transforms cryptic, truncated, and monochrome text outputs into highly readable, colorized, and well-aligned visual summaries. It focuses heavily on **GPU tracking**, **automated script linting**, **safety guards**, **smart date-based logging**, **dual-stream real-time log tracking**, and maintaining **100% pipe friendliness** (zero ANSI codes when piped).

---

## 🛠️ What it Can Do (Capabilities)

### 1. `sjobs` (Smart Job Monitor) — *Wraps `squeue`*
*   **Visual Progress Mapping**: Displays visual indicators for job elapsed runtime relative to partition limits.
*   **Pending Reasons Translated**: Cryptic reasons like `ReqNodeNotAvail`, `Priority`, or `Dependency` are translated instantly into helpful human-readable advice (e.g., `🕒 Queued behind higher-priority jobs`, `⚡ Waiting for free resources`).
*   **GPU Request Highlights**: Spots requested GPU resources (e.g., `8n/256c/15G/⚡4g`) showing CPU, Memory, GPU, and node allocations in active orange color at a single glance.
*   **No Truncation**: Intelligently pads and truncates long job names and usernames to maintain pristine column alignments.
*   **Wide View (`-w` / `--wide`)**: Extends display to expose precise job submission and start times.

### 2. `scluster` (Cluster Status Dashboard) — *Wraps `sinfo`*
*   **Resource Utilization Bars**: Graphical progress bars showing CPU and node occupancy: `[██████░░░░] 60% Allocated`.
*   **GPU Inventory Auditing**: Summarizes exact GPU inventory per partition (e.g. `⚡ 6/16 A100 Free` vs. all cards occupied) by inspecting physical node configurations and active job demands.
*   **Clean Outlines**: Overview of max walltimes, partition online states, and grouped node-lists.

### 3. `sbatch-track` (Interactive Submitter & Log Tracker) — *Wraps `sbatch`*
*   **Pre-Flight Script Linter**: Scans scripts before submission. Warns about missing shebangs, lack of `#SBATCH` configurations, and crashes caused by non-existent log directory paths (with an option to automatically create them).
*   **Smart Date-Based Logging**: Automatically creates chronological directories (`./logs/YYMMDD/`) and assigns `--output` and `--error` parameters to keep workspaces clean if they are not defined in the script or CLI.
*   **Dual-Stream Log Tailing (`-t` / `--track`)**: Submits your job, displays real-time queuing diagnostics, automatically localizes **both** stdout and stderr log files, streams them concurrently directly to your screen (using `tail -f`), and exits cleanly when the job terminates.

### 4. `slogs` (Smart Log Streamer) — *Wraps `tail -f`*
*   **Index-Based Log Tailing**: Streams standard output and standard error files of running jobs via simple indices (e.g. `slogs 0` tails the logs of your earliest running job).
*   **Job Listing Dash**: If no index is provided, prints a numbered list of all your active running jobs (`JOBID`, `NAME`, `PARTITION`, `STATE`, `TIME`) to easily locate targets.
*   **Earliest Running Order**: Automatically sorts active jobs chronologically so index `0` always points to the oldest active run.

### 5. `scancel-safe` (Guarded Job Canceller) — *Wraps `scancel`*
*   **Pre-Cancellation Summaries**: Before terminating a job, prints its name, partition, resources (CPUs/Mem/GPUs), and elapsed runtime.
*   **Accident Protection**: Interactive prompts asking for explicit confirmation (`y/N`) before stopping execution.
*   **Bulk Safety Guards**: Warns in bright bold red if you attempt a bulk cancellation (e.g., `scancel-safe -u username`), displaying a list of all affected jobs first.

### 6. `srun-quick` (Interactive Compute Session Launcher) — *Wraps `srun`*
*   **Boilerplate Elimination**: Replaces lengthy commands like `srun --pty -p gpu --gres=gpu:a100:1 --cpus-per-task=4 --mem=16G bash -i` with intuitive shorthand profiles.
*   **Shorthand Profiles**: Run `srun-quick --gpu a100` or `srun-quick --cpu 8 --mem 32G` and let the utility auto-resolve partition routing and resource binds.

### 7. `spriority` (Smart Priority Inspector) — *Wraps `sprio`*
*   **Weight Breakdown Matrix**: Displays a gorgeous, aligned grid showing exact priority calculation details for queuing jobs.
*   **Dominant Driver Highlight**: Automatically identifies the dominant priority factor (e.g., Fairshare or QOS) and highlights it with a `★` marker so you know exactly why your job is queued.

---

## 🚀 Quickstart

Get up and running in under a minute!

### 1. Clone the Repository
Clone this repository to your cluster home directory:
```bash
git clone https://github.com/naufalso/beauty-slurm.git ~/beauty-slurm
cd ~/beauty-slurm
```

### 2. Run the Installer
Run the interactive installation script:
```bash
./install.sh
```
*The installer configures permissions, links commands, detects your active shell profile (`~/.zshrc` or `~/.bashrc`), and appends a safe path integration block.*

### 3. Reload Your Shell
Apply the environment updates to your current terminal session:
```bash
source ~/.zshrc    # If using Zsh
# OR
source ~/.bashrc   # If using Bash
```

### 4. Verify the Installation
Run a quick status test:
```bash
sjobs --me
```

---

## 🧪 Local Mocking & Offline Development

Developing on a workstation or laptop without access to a live SLURM cluster? No problem! 

Beauty SLURM includes a **built-in local mocking layer** under `mock/` which emulates a live cluster partition inventory, node allocation states (including drained/down reasons), and a dynamic background sbatch simulator.

### Running in Mock Mode
You can force the mocking layer at any time by appending `--mock` to any command, or setting the environment variable:
```bash
# Display mock job queue
sjobs --mock

# Display mock cluster status
scluster --mock

# Inspect mock priorities
spriority --mock
```

---

## 📖 Sample Usage & Workflows

### Dynamic Job Submission with Dual Log Tracking
Submit an interactive job and track stdout and stderr outputs concurrently in real-time:
```bash
sbatch-track -t run_training.sbatch
```
**What happens behind the scenes:**
1.  **Lints** `run_training.sbatch` for directive errors.
2.  If `--output` or `--error` are not defined, it auto-creates a chronological directory `./logs/YYMMDD/` and routes stdout and stderr there.
3.  Submits the job and displays: `⏳ State: PENDING (⚡ Waiting for free resources)`
4.  As soon as the job starts on a compute node, it locates the active logs and launches a dual-tail stream:
    ```
    ✔ Streaming StdOut: ./logs/260520/run_training-106366.out
    ✔ Streaming StdErr: ./logs/260520/run_training-106366.err
    ------------------------------------------------------------------------
    
    ==> ./logs/260520/run_training-106366.out <==
    [1/4] Loading CUDA and Anaconda environments...
    [2/4] Initializing deep learning model...
    
    ==> ./logs/260520/run_training-106366.err <==
    [INFO] CUDA initialized successfully. Device 0: NVIDIA Tesla V100
    [WARNING] UserWarning: PyTorch was compiled without GPU support...
    ```
5.  Exits automatically with a green `✔ Job finished successfully!` indicator when the job terminates.

### Guarded Job Terminations
Safely terminate jobs without risking bulk execution errors:
```bash
scancel-safe -u naufalsuryanto
```
**Visual Safety Screen:**
```
⚠️  WARNING: You are about to cancel MULTIPLE jobs matching: -u naufalsuryanto

The following 3 jobs will be terminated:
JOB ID    PARTITION  JOB NAME         STATE      RESOURCES    ELAPSED
100234    gpu        train_bert       RUNNING    4x A100      12:34:56
100235    gpu        preprocess       RUNNING    1x A100      02:15:00
100238    gpu        deep_rl          PENDING    2x V100      00:00:00

Are you absolutely sure you want to cancel these 3 jobs? [y/N] 
```

### High-Speed Priority Auditing
Find out exactly why your job is queued:
```bash
spriority
```
**Dominant factor analysis matrix:**
```
JOB ID    JOB NAME         PRIORITY        AGE      FAIRSHARE    PARTITION   QOS     TRES/CPU
100238    deep_rl          4294901758      1200     50000        100         5000★   0
100239    eval_bert        4294901890      1200     85000★       100         500     0
```
*(The dominant weight factor is automatically highlighted with a `★` marker and gold styling).*

---

## 🛠️ Advanced: UNIX Pipe Friendliness

All utilities incorporate **Smart TTY checks**.
*   **Interactive Terminal**: Outputs premium rich colors, load progress bars, and Unicode styling.
*   **Pipes & Redirects**: Automatically strips all ANSI color codes, emojis, and styling details when standard output is redirected or piped (e.g. `sjobs | grep myjob` or `sjobs > queue.txt`). Output falls back instantly to clean, space-aligned tab-separated columns, making it 100% pipe-friendly!

Force a specific color layout by specifying the `--color` option:
*   `--color=always`: Force beautiful ANSI color maps even inside file streams.
*   `--color=never`: Force plain-text monochrome mode.
*   `--color=auto` (Default): Terminals get colors; pipes get plain-text.

---

## 📂 Project Structure

```
beauty-slurm/
├── bin/                 # User executables (sjobs, scluster, sbatch-track, slogs, scancel-safe, srun-quick, spriority)
├── lib/                 # Shared library core modules
│   ├── colors.sh        # ANSI styling engine, padders, & TTY checks
│   ├── core.sh          # Environment bootstrap & command router
│   └── slurm_api.sh     # GRES regex parsers, pending translators, and log detectors
├── mock/                # Standalone mocks representing SLURM client binaries
├── install.sh           # Automated interactive installation script
└── uninstall.sh         # Graceful clean-up script
```

---

## 🛡️ License

This project is open-source and free to customize. Enjoy speed, readability, and peace of mind on your SLURM cluster!
