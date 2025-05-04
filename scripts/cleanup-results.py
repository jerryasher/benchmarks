# cleanup_results.py
# Moves non-latest benchmark result logs to an archive directory

import os
import shutil
from datetime import datetime

RESULTS_DIR = r"C:\beelink\benchmarks\results"
ARCHIVE_DIR = os.path.join(RESULTS_DIR, "archive")

os.makedirs(ARCHIVE_DIR, exist_ok=True)

def should_archive(filename):
    return not filename.endswith("latest.txt")

def archive_tool_folder(tool_dir):
    for fname in os.listdir(tool_dir):
        fpath = os.path.join(tool_dir, fname)
        if os.path.isfile(fpath) and should_archive(fname):
            timestamp = datetime.now().strftime("%Y-%m-%d %H-%M")
            base = os.path.basename(fpath)
            tool_name = os.path.basename(tool_dir)
            archived_name = f"{timestamp} {tool_name} {base}"
            dst_path = os.path.join(ARCHIVE_DIR, archived_name)
            print(f"Archiving {fpath} -> {dst_path}")
            shutil.move(fpath, dst_path)

if __name__ == "__main__":
    print("🔍 Scanning for logs to archive...")
    for tool_name in os.listdir(RESULTS_DIR):
        tool_path = os.path.join(RESULTS_DIR, tool_name)
        if os.path.isdir(tool_path) and tool_name != "archive":
            archive_tool_folder(tool_path)
    print("✅ Archive complete. Old logs moved to:", ARCHIVE_DIR)
