#!/usr/bin/env -S uv python3
"""Utilities for creating and merging FuzzIL corpora."""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator, Sequence


@dataclass
class CompilationResult:
    source: Path
    output: Path
    success: bool
    error: str | None = None


def iter_js_files(root: Path) -> Iterator[Path]:
    for path in root.rglob("*.js"):
        if path.is_file():
            yield path


def compilation_output_path(source: Path, input_root: Path, output_root: Path) -> Path:
    relative = source.relative_to(input_root)
    return (output_root / relative).with_suffix(".protobuf")


def ensure_parent_directory(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)


def compile_js_file(source: Path, input_root: Path, output_root: Path) -> CompilationResult:
    output_path = compilation_output_path(source, input_root, output_root)
    ensure_parent_directory(output_path)

    command = [
        "FuzzILTool",
        "--compile",
        str(source),
        "--output",
        str(output_path),
    ]

    try:
        subprocess.run(command, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return CompilationResult(source=source, output=output_path, success=True)
    except subprocess.CalledProcessError as exc:  # pragma: no cover - subprocess failure branch
        return CompilationResult(
            source=source,
            output=output_path,
            success=False,
            error=exc.stderr.decode(errors="replace"),
        )


def run_compilations(sources: Sequence[Path], input_root: Path, output_root: Path) -> tuple[int, int]:
    max_workers = min(32, (os.cpu_count() or 1) + 4)
    successes = 0
    failures = 0

    # Use a thread pool to overlap subprocess executions without spawning excessive threads.
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        future_to_source = {
            executor.submit(compile_js_file, source, input_root, output_root): source
            for source in sources
        }
        for future in as_completed(future_to_source):
            result = future.result()
            if result.success:
                successes += 1
            else:
                failures += 1
    return successes, failures


def handle_create(args: argparse.Namespace) -> None:
    input_dir = Path(args.input_dir).resolve()
    output_dir = Path(args.output_dir).resolve()

    if not input_dir.is_dir():
        raise SystemExit(f"Input directory not found: {input_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)

    sources = list(iter_js_files(input_dir))
    if not sources:
        print("No JavaScript files found.")
        return

    successes, failures = run_compilations(sources, input_dir, output_dir)
    print(f"Compiled {successes} file(s), {failures} failed.")


def iter_corpus_files(corpus_dir: Path) -> Iterator[Path]:
    for path in corpus_dir.rglob("*"):
        if path.is_file() and path.suffix in {".protobuf", ".fil"}:
            yield path


def unique_destination(path: Path, destination_dir: Path) -> Path:
    target = destination_dir / path.name
    if not target.exists():
        return target

    stem = path.stem
    suffix = path.suffix
    counter = 1
    while True:
        candidate = destination_dir / f"{stem}_{counter}{suffix}"
        if not candidate.exists():
            return candidate
        counter += 1


def copy_unique_files(sources: Iterable[Path], destination_dir: Path) -> tuple[int, int]:
    seen_hashes: set[str] = set()
    copied = 0
    skipped = 0

    for source in sources:
        # Hash file contents to detect duplicates regardless of filename.
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        if digest in seen_hashes:
            skipped += 1
            continue

        seen_hashes.add(digest)
        destination = unique_destination(source, destination_dir)
        shutil.copy2(source, destination)
        copied += 1

    return copied, skipped


def handle_merge(args: argparse.Namespace) -> None:
    corpora = [Path(path).resolve() for path in args.corpora]
    output_dir = Path(args.output_dir).resolve()

    for corpus in corpora:
        if not corpus.is_dir():
            raise SystemExit(f"Corpus directory not found: {corpus}")

    output_dir.mkdir(parents=True, exist_ok=True)

    sources: list[Path] = []
    for corpus in corpora:
        sources.extend(iter_corpus_files(corpus))

    if not sources:
        print("No corpus files found.")
        return

    copied, skipped = copy_unique_files(sources, output_dir)
    print(f"Copied {copied} file(s), skipped {skipped} duplicate(s).")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Helpers for managing FuzzIL corpora.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    create_parser = subparsers.add_parser("create", help="Compile JavaScript files into FuzzIL protobuf format.")
    create_parser.add_argument("--input-dir", required=True, help="Directory containing JavaScript inputs.")
    create_parser.add_argument("--output-dir", required=True, help="Directory to store compiled protobuf files.")
    create_parser.set_defaults(func=handle_create)

    merge_parser = subparsers.add_parser("merge", help="Merge existing corpora into a single directory.")
    merge_parser.add_argument("--corpora", nargs="+", required=True, help="One or more corpus directories to merge.")
    merge_parser.add_argument("--output-dir", required=True, help="Directory to write the merged corpus.")
    merge_parser.set_defaults(func=handle_merge)

    return parser


def main(argv: Sequence[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)


if __name__ == "__main__":
    main()
