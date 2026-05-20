#!/usr/bin/env bash

# beauty-slurm: Mock Cluster State Data
# This file provides a consistent database of jobs, partitions, and nodes for mock utilities.

# Define partitions
# Format: Name | State | TimeLimit | Nodes(Alloc/Idle/Down/Total) | CPUs(Alloc/Idle/Other/Total) | NodesList
MOCK_PARTITIONS=(
    "compute|up|24:00:00|2/4/1/7|64/128/32/224|node[01-07]"
    "gpu|up|48:00:00|2/1/1/4|48/16/16/80|gnode[01-04]"
    "highmem|up|7-00:00:00|1/0/0/1|40/8/0/48|memnode01"
)

# Define nodes detail
# Format: Name | State | CPUs(Alloc/Total) | MemAlloc/Total(MB) | GRES | Reason(if Down/Drain)
MOCK_NODES=(
    "node01|ALLOCATED|32/32|128000/128000|none|"
    "node02|ALLOCATED|32/32|128000/128000|none|"
    "node03|IDLE|0/32|0/128000|none|"
    "node04|IDLE|0/32|0/128000|none|"
    "node05|MIXED|16/32|64000/128000|none|"
    "node06|DRAIN|0/32|0/128000|none|CPU Fan speed failure"
    "node07|DOWN|0/32|0/128000|none|Failed to mount cluster filesystem /scratch"
    "gnode01|ALLOCATED|24/24|192000/192000|gpu:a100:4(S:0-1)|"
    "gnode02|MIXED|16/24|128000/192000|gpu:a100:4(S:0-1)|"
    "gnode03|IDLE|0/24|0/192000|gpu:v100:4(S:0-1)|"
    "gnode04|DRAIN|0/24|0/192000|gpu:v100:2(S:0)|GPU board thermal throttling"
    "memnode01|MIXED|40/48|512000/1024000|none|"
)

# Define jobs detail
# Format: JobID | Partition | Name | User | State | TimeUsed | TimeLimit | NodeCount | NodeList | CPUs | Memory | GRES | Reason
MOCK_JOBS=(
    "100234|gpu|train_bert|naufalsuryanto|RUNNING|12:34:56|1-00:00:00|1|gnode01|16|64G|gpu:a100:4|None"
    "100235|gpu|preprocess|naufalsuryanto|RUNNING|02:15:00|04:00:00|1|gnode02|8|32G|gpu:a100:1|None"
    "100236|compute|sim_x_12|alice|RUNNING|20:45:12|24:00:00|2|node[01-02]|64|128G|none|None"
    "100237|compute|compile_libs|bob|RUNNING|00:12:30|01:00:00|1|node05|16|32G|none|None"
    "100238|gpu|deep_rl|naufalsuryanto|PENDING|00:00:00|2-00:00:00|1||8|64G|gpu:v100:2|Resources"
    "100239|gpu|eval_bert|naufalsuryanto|PENDING|00:00:00|12:00:00|1||16|64G|gpu:a100:4|Priority"
    "100240|compute|blast_alignment|charlie|PENDING|00:00:00|08:00:00|1||32|64G|none|Dependency"
    "100241|compute|big_sim|bob|PENDING|00:00:00|2-00:00:00|4||128|256G|none|ReqNodeNotAvail"
)
