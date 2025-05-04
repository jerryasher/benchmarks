#!/usr/bin/env python
"""
parse_pytorch.py

Usage:
    python parse_pytorch.py <path_to_log_file>

Description:
    Parses the output of pytorch_benchmark.py and extracts the matrix size,
    total time, and estimated throughput in GFLOP/s. Outputs CSV-style data.

Example output:
    1024,3.45,62.35

"""

import sys
import re

log_file = sys.argv[1] if len(sys.argv) > 1 else "results/pytorch_benchmark.log"

with open(log_file, "r") as f:
    log = f.read()

size = re.search(r"matmul (\d+)x\1", log)
time = re.search(r"Total time:\s+([\d.]+)", log)
gflops = re.search(r"throughput:\s+([\d.]+)", log)

if size and time and gflops:
    print(f"{size.group(1)},{time.group(1)},{gflops.group(1)}")
else:
    print("?, ?, ?")

"""
------------------------------------------------------------
NOTES

This parser is designed for use in an automated pipeline where the
pytorch benchmark log file is parsed to extract key numeric metrics.

Expected format in log file:
    Benchmark: matmul 1024x1024 for 100 iterations
    Total time: 3.45 seconds
    Estimated throughput: 62.35 GFLOP/s

This parser is rege
