#!/usr/bin/env python3
import argparse
import hashlib
import os
import sys
import fnmatch
from concurrent.futures import ThreadPoolExecutor, as_completed

# --- Hashing utility ---
def sha256_file(path, bufsize=1024 * 1024):
    """
    Compute SHA-256 of a file by streaming in chunks.
    Returns hex digest string. Raises IOError/OSError on failure.
    """
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        while True:
            chunk = f.read(bufsize)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()

# --- Exclusion checks ---
def is_excluded(path, exclude_globs):
    """
    Return True if the path matches any of the exclude glob patterns.
    Matches against both full path and basename for convenience.
    """
    if not exclude_globs:
        return False
    base = os.path.basename(path)
    for pat in exclude_globs:
        if fnmatch.fnmatch(path, pat) or fnmatch.fnmatch(base, pat):
            return True
    return False

# --- File iterator ---
def iter_files(root, follow_symlinks=False, exclude_globs=None, min_size=0):
    """
    Yield absolute file paths under root that are regular files and pass filters.
    """
    root = os.path.abspath(root)
    for dirpath, dirnames, filenames in os.walk(root, followlinks=follow_symlinks):
        # Optionally prune directories by glob
        if exclude_globs:
            # Modify dirnames in-place to skip walking excluded dirs
            pruned = []
            for d in dirnames:
                full = os.path.join(dirpath, d)
                if is_excluded(full, exclude_globs):
                    continue
                pruned.append(d)
            dirnames[:] = pruned

        for name in filenames:
            full = os.path.join(dirpath, name)
            if exclude_globs and is_excluded(full, exclude_globs):
                continue

            # Only regular files (skip symlinks unless follow_symlinks is True and they resolve to regular files)
            try:
                st = os.stat(full, follow_symlinks=follow_symlinks)
            except (FileNotFoundError, PermissionError) as e:
                print(f"WARNING: cannot stat '{full}': {e}", file=sys.stderr)
                continue

            # stat.S_ISREG not imported; use S_IFMT via os.path
            # Simpler: rely on st.st_mode & check with os.path.isfile if not following symlinks
            if not os.path.isfile(full):
                # If following symlinks, os.path.isfile will resolve; else skip non-regular
                if not follow_symlinks:
                    continue

            # Size filter
            size = st.st_size
            if size < min_size:
                continue

            yield full, size

# --- Worker function ---
def process_file(path, size):
    """
    Return (path, size, sha256) or None on error (logs to stderr).
    """
    try:
        digest = sha256_file(path)
        return (path, size, digest)
    except (OSError, IOError) as e:
        print(f"WARNING: cannot hash '{path}': {e}", file=sys.stderr)
        return None

# --- Main ---
def main():
    parser = argparse.ArgumentParser(
        description="Walk a directory tree and output TSV: path\tsize\tsha256 for each regular file.",
    )
    parser.add_argument('root', help="Root directory to scan")
    parser.add_argument('-o', '--output', help="Output TSV file (default: stdout)")
    parser.add_argument('--follow-symlinks', action='store_true', help="Follow symlinks while walking")
    parser.add_argument('--relative', action='store_true', help="Output paths relative to root")
    parser.add_argument('--min-size', type=int, default=0, help="Minimum file size (bytes) to include")
    parser.add_argument('--exclude-glob', action='append', default=[], help="Glob pattern to exclude (repeatable)")
    parser.add_argument('--workers', type=int, default=0, help="Number of worker threads for hashing (0=single-threaded)")

    args = parser.parse_args()

    root_abs = os.path.abspath(args.root)

    # Prepare output stream
    out = sys.stdout
    if args.output:
        try:
            out = open(args.output, 'w', encoding='utf-8', newline='\n')
        except OSError as e:
            print(f"ERROR: cannot open output '{args.output}': {e}", file=sys.stderr)
            return 2

    # Collect files
    files_iter = iter_files(
        root_abs,
        follow_symlinks=args.follow_symlinks,
        exclude_globs=args.exclude_glob,
        min_size=args.min_size,
    )

    # Header (optional; comment this out if you prefer no header)
    # out.write("path\tsize\tsha256\n")

    # Hash files (optionally in parallel)
    results = []
    if args.workers and args.workers > 0:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            future_map = {ex.submit(process_file, path, size): (path, size) for path, size in files_iter}
            for fut in as_completed(future_map):
                res = fut.result()
                if res is not None:
                    results.append(res)
    else:
        for path, size in files_iter:
            res = process_file(path, size)
            if res is not None:
                results.append(res)

    # Emit TSV
    for path, size, digest in results:
        if args.relative:
            try:
                path_out = os.path.relpath(path, root_abs)
            except ValueError:
                # In rare cases (different drive roots on Windows), fall back to absolute
                path_out = path
        else:
            path_out = path
        out.write(f"{path_out}\t{size}\t{digest}\n")

    # Cleanup
    if out is not sys.stdout:
        out.close()

    return 0

if __name__ == '__main__':
    sys.exit(main())

