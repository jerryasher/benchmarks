#!/usr/bin/env python
"""
pytorch_benchmark.py

Usage:
    python pytorch_benchmark.py

Description:
    Performs a CPU-bound matrix multiplication benchmark using PyTorch.
    Designed for use in the Windows Benchmark Suite for evaluating numeric
    performance over time.

"""

import torch
import time

def run_benchmark(size=1024, iterations=100):
    a = torch.randn(size, size)
    b = torch.randn(size, size)

    start = time.time()
    for _ in range(iterations):
        _ = torch.matmul(a, b)
    duration = time.time() - start

    total_ops = iterations * (2 * size ** 3)  # Approximate FLOPs for matmul
    gflops = total_ops / duration / 1e9

    print(f"Benchmark: matmul {size}x{size} for {iterations} iterations")
    print(f"Total time: {duration:.4f} seconds")
    print(f"Estimated throughput: {gflops:.2f} GFLOP/s")

if __name__ == "__main__":
    run_benchmark()

"""
------------------------------------------------------------
EXPLANATORY NOTES

This benchmark performs repeated dense matrix multiplications using
PyTorch tensors to evaluate CPU floating point performance. Each
multiplication of two NxN matrices performs roughly 2 * N^3
operations. Running this in a tight loop simulates a numeric workload
similar to what PyTorch might perform during machine learning training
or inference.

Why is this reasonable?
- Matrix multiply is a core operation in neural networks (linear layers, attention).
- It's deterministic, portable, and hits CPU cache and memory bandwidth hard.
- PyTorch uses optimized libraries under the hood (e.g., MKL, OpenBLAS), so performance reflects real-world behavior.

OFFICIAL SUITE
There is an official PyTorch benchmark repo (much more complex):
  https://github.com/pytorch/benchmark

This script is intentionally simple, but the official benchmark includes
training loops, TorchScript, dynamic shape tests, and CUDA coverage.

INSTALLATION INSTRUCTIONS

If you get an import error, install PyTorch for CPU like this:

Windows + WinPython (slim):
    set PYTHON=C:\winpy\python.exe
    %PYTHON% -m pip install torch --index-url https://download.pytorch.org/whl/cpu

Or globally:
    python -m pip install torch --index-url https://download.pytorch.org/whl/cpu

Note: this script does **not require CUDA** or any GPU support.
-----------------------------------------------------
