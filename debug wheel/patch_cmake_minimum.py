# instructions: drop to pytorch folder, then run python patch_cmake_minimum.py --root . --dry THEN IF GOOD, WITHOUT dry
# or run from anywhere via python patch_cmake_minimum.py --root C:\Users\Admin\source\pytorch

# patch_cmake_minimum.py
import re
from pathlib import Path
import shutil
import argparse
import sys

parser = argparse.ArgumentParser(description="Recursively patch cmake_minimum_required(...) to 3.5 FATAL_ERROR")
parser.add_argument("--root", "-r", default="third_party", help="Root directory to scan (default: third_party)")
parser.add_argument("--backup-ext", default=".bak", help="Backup extension (default: .bak)")
parser.add_argument("--min", default="3.5 FATAL_ERROR", help="Minimum version string to insert")
parser.add_argument("--dry", action="store_true", help="Dry run (show files, do not modify)")
args = parser.parse_args()

root = Path(args.root)
if not root.exists():
    print(f"Root not found: {root}", file=sys.stderr)
    sys.exit(2)

pattern1 = re.compile(r'cmake_minimum_required\s*\(\s*VERSION\s*[0-9\.]+\s*(FATAL_ERROR)?\s*\)', re.IGNORECASE)
pattern2 = re.compile(r'cmake_minimum_required\s*\(\s*[0-9\.]+\s*(FATAL_ERROR)?\s*\)', re.IGNORECASE)

patched = []
for p in root.rglob("CMakeLists.txt"):
    text = p.read_text(encoding='utf-8', errors='ignore')
    if pattern1.search(text) or pattern2.search(text):
        print(f"Found candidate: {p}")
        preview_lines = text.splitlines()[:12]
        for ln in preview_lines:
            print("  " + ln)
        if args.dry:
            print("  (dry-run, not modifying)\n")
            continue
        bak = p.with_suffix(p.suffix + args.backup_ext)
        shutil.copy2(p, bak)
        new = pattern1.sub(f"cmake_minimum_required(VERSION {args.min})", text)
        new = pattern2.sub(f"cmake_minimum_required(VERSION {args.min})", new)
        p.write_text(new, encoding='utf-8')
        patched.append((p, bak))
        print(f"  Patched -> backup: {bak}\n")

print(f"Done. Patched {len(patched)} file(s). Backups: {args.backup_ext}")
