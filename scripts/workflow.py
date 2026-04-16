#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path
from typing import Optional, Tuple

MAIN_BRANCH = "main"
_PY_NAME = Path(sys.executable).name
PYTHON_CMD = _PY_NAME if _PY_NAME.lower().startswith("python") else "python"
COMMIT_TYPES = [
    ("feat", "New feature"),
    ("fix", "Bug fix"),
    ("docs", "Documentation changes"),
    ("test", "Tests added or updated"),
    ("refactor", "Code restructuring (no behavior change)"),
    ("chore", "Maintenance/build/tooling"),
]

ANSI_RESET = "\033[0m"
ANSI_BOLD = "\033[1m"
ANSI_DIM = "\033[2m"
ANSI_RED = "\033[31m"
ANSI_GREEN = "\033[32m"
ANSI_YELLOW = "\033[33m"
ANSI_BLUE = "\033[34m"
ANSI_CYAN = "\033[36m"
ANSI_TREE_GREEN = "\033[38;5;114m"
# Cold color alternatives you can try manually:
# "\033[94m" (light blue), "\033[96m" (light cyan), "\033[38;5;39m" (vibrant sky blue),
# "\033[38;5;45m" (aqua blue), "\033[36m" (cyan), also "\033[38;5;39m"
ANSI_LIGHT_BLUE = "\033[38;5;45m"
USE_COLOR = sys.stdout.isatty() and os.environ.get("NO_COLOR") is None


def colorize(text: str, *codes: str) -> str:
    if not USE_COLOR or not codes:
        return text
    return f"{''.join(codes)}{text}{ANSI_RESET}"


def print_header(title: str) -> None:
    line = "=" * 64
    print(colorize(line, ANSI_BOLD, ANSI_BLUE))
    print(colorize(title, ANSI_BOLD, ANSI_BLUE))
    print(colorize(line, ANSI_BOLD, ANSI_BLUE))


def print_step(message: str) -> None:
    print(colorize(f"[STEP] {message}", ANSI_CYAN))


def print_ok(message: str) -> None:
    print(colorize(f"[OK] {message}", ANSI_GREEN))


def print_warn(message: str) -> None:
    print(colorize(f"[WARN] {message}", ANSI_YELLOW))


def print_error(message: str) -> None:
    print(colorize(f"[ERROR] {message}", ANSI_RED))


def print_cmd(cmd: list[str]) -> None:
    print(colorize(f"$ {subprocess.list2cmdline(cmd)}", ANSI_DIM))


def run_git(
    args: list[str],
    check: bool = True,
    stream_output: bool = False,
) -> subprocess.CompletedProcess[str]:
    cmd = ["git", *args]
    if stream_output:
        process = subprocess.Popen(
            cmd,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=1,
        )
        output: list[str] = []
        assert process.stdout is not None
        for line in process.stdout:
            print(line, end="")
            output.append(line)
        process.stdout.close()
        result = subprocess.CompletedProcess(
            cmd,
            process.wait(),
            "".join(output),
            "",
        )
    else:
        result = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
        )
    if check and result.returncode != 0:
        detail = (result.stderr or result.stdout).strip() or "Unknown git error"
        raise RuntimeError(f"git {' '.join(args)} failed: {detail}")
    return result


def run_git_action(args: list[str], check: bool = False) -> subprocess.CompletedProcess[str]:
    cmd = ["git", *args]
    print_cmd(cmd)
    return run_git(args, check=check, stream_output=True)


def git_output(args: list[str]) -> str:
    return run_git(args).stdout.strip()


def ensure_git_repo() -> None:
    result = run_git(["rev-parse", "--is-inside-work-tree"], check=False)
    if result.returncode != 0 or result.stdout.strip() != "true":
        raise RuntimeError("This command must be run inside a Git repository.")


def current_branch() -> str:
    branch = git_output(["branch", "--show-current"])
    if not branch:
        raise RuntimeError("Could not determine current branch.")
    return branch


def upstream_branch() -> Optional[str]:
    result = run_git(
        ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"],
        check=False,
    )
    if result.returncode != 0:
        return None
    return result.stdout.strip() or None


def merge_in_progress() -> bool:
    result = run_git(["rev-parse", "-q", "--verify", "MERGE_HEAD"], check=False)
    return result.returncode == 0


def has_conflicts() -> bool:
    return bool(git_output(["diff", "--name-only", "--diff-filter=U"]))


def working_tree_dirty() -> bool:
    return bool(git_output(["status", "--porcelain"]))


def staged_changes_exist() -> bool:
    return bool(git_output(["diff", "--cached", "--name-only"]))


def ahead_behind(left: str, right: str) -> Optional[Tuple[int, int]]:
    result = run_git(["rev-list", "--left-right", "--count", f"{left}...{right}"], check=False)
    if result.returncode != 0:
        return None
    parts = result.stdout.strip().split()
    if len(parts) != 2:
        return None
    return int(parts[0]), int(parts[1])


def prompt_yes_no(question: str, default: bool = False, color: str | None = None) -> bool:
    suffix = "[Y/n]" if default else "[y/N]"
    prompt = f"{question} {suffix}: "
    if color:
        prompt = colorize(prompt, color)
    while True:
        raw = input(prompt).strip().lower()
        if not raw:
            return default
        if raw in {"y", "yes"}:
            return True
        if raw in {"n", "no"}:
            return False
        print("Please answer y or n.")


def prompt_input(prompt: str, color: str = ANSI_TREE_GREEN) -> str:
    return input(colorize(prompt, color))


def prompt_commit_type() -> str:
    block_line = "-" * 56
    print(colorize(block_line, ANSI_LIGHT_BLUE))
    print(colorize("Commit Type Selection", ANSI_BOLD, ANSI_LIGHT_BLUE))
    print(colorize(block_line, ANSI_LIGHT_BLUE))
    print(colorize("Select commit type:", ANSI_LIGHT_BLUE))
    for idx, (name, desc) in enumerate(COMMIT_TYPES, start=1):
        idx_text = colorize(f"  {idx}.", ANSI_YELLOW)
        type_text = colorize(f" {name:<12}", ANSI_YELLOW)
        desc_text = colorize(desc, ANSI_LIGHT_BLUE)
        print(f"{idx_text}{type_text}{desc_text}")

    while True:
        raw = prompt_input("Type number: ").strip()
        if raw.isdigit():
            index = int(raw)
            if 1 <= index <= len(COMMIT_TYPES):
                return COMMIT_TYPES[index - 1][0]
        print_warn("Invalid selection. Choose one of the listed numbers.")


def compose_commit_message(args: argparse.Namespace) -> str:
    commit_type = args.type or prompt_commit_type()
    scope = args.scope
    if scope is None:
        scope = prompt_input("Optional scope (press Enter to skip): ").strip() or ""

    description = args.description
    while not description:
        description = prompt_input("Describe your changes: ").strip()
        if not description:
            print_warn("Description cannot be empty.")

    prefix = commit_type if not scope else f"{commit_type}({scope})"
    return f"{prefix}: {description}"


def print_commit_preview(message: str) -> None:
    block_line = "-" * 56
    print(colorize(block_line, ANSI_LIGHT_BLUE))
    print(colorize("Commit Message Preview", ANSI_BOLD, ANSI_LIGHT_BLUE))
    print(colorize(block_line, ANSI_LIGHT_BLUE))
    print(colorize(message, ANSI_YELLOW))


def print_status_summary(branch: str) -> Optional[Tuple[int, int]]:
    print()
    print_header("Summary")
    print(f"Current branch: {branch}")
    print(f"Working tree: {'dirty (local changes present)' if working_tree_dirty() else 'clean'}")

    ref_check = run_git(["rev-parse", "--verify", f"origin/{MAIN_BRANCH}"], check=False)
    if ref_check.returncode != 0:
        print_warn(f"Behind main: unknown (origin/{MAIN_BRANCH} not found)")
        return None

    counts = ahead_behind("HEAD", f"origin/{MAIN_BRANCH}")
    if counts is None:
        print_warn("Behind main: unknown")
        return None

    ahead, behind = counts
    print(f"Relative to origin/{MAIN_BRANCH}: ahead {ahead}, behind {behind}")
    if behind == 0:
        print_ok("main sync: up to date with origin/main")
    else:
        print_warn(f"main sync: branch is behind origin/main by {behind} commit(s)")
    return counts


def merge_origin_main_into_branch(branch: str, step_message: str) -> int:
    print_step(step_message)
    merge = run_git_action(["merge", "--no-edit", f"origin/{MAIN_BRANCH}"], check=False)
    if merge.returncode != 0:
        if has_conflicts():
            print_merge_conflict_instructions(branch)
            return 2
        detail = (merge.stderr or merge.stdout).strip()
        print_error(f"Merge failed: {detail or 'see command output above'}")
        return 1
    return 0


def print_merge_conflict_instructions(branch: str) -> None:
    print()
    print_error("Merge conflicts detected while merging origin/main.")
    print("Resolve conflicts and then continue with these steps:")
    print("1) Check conflicted files: git status")
    print("2) Edit files and resolve conflict markers")
    print("3) Stage resolved files: git add <file1> <file2> ...")
    print("4) Finish merge commit: git commit")
    print("If you need to cancel the merge: git merge --abort")
    print(f"Current branch remains: {branch}")


def cmd_start(_: argparse.Namespace) -> int:
    ensure_git_repo()
    print_header("Workflow Start")

    if merge_in_progress():
        print_warn("A merge is already in progress.")
        print("Finish it first (git commit) or abort it (git merge --abort).")
        return 1

    print_step("Fetching latest refs from origin...")
    fetch = run_git_action(["fetch", "origin"], check=False)
    if fetch.returncode != 0:
        detail = (fetch.stderr or fetch.stdout).strip()
        print_error(f"Fetch failed: {detail or 'see command output above'}")
        return 1

    branch = current_branch()
    upstream = upstream_branch()
    if upstream:
        print_step(f"Updating '{branch}' from '{upstream}' (fast-forward only)...")
        update = run_git_action(["merge", "--ff-only", upstream], check=False)
        if update.returncode != 0:
            detail = (update.stderr or update.stdout).strip()
            print_error("Could not fast-forward current branch.")
            print(f"Reason: {detail or 'see command output above'}")
            print(f"Resolve manually, then continue working on '{branch}'.")
            print_status_summary(branch)
            return 1
    else:
        print_warn(f"No upstream configured for '{branch}'.")
        print(f"Set one with: git push -u origin {branch}")

    status = print_status_summary(branch)
    if branch != MAIN_BRANCH and status is not None:
        _, behind = status
        if behind > 0:
            should_merge_main = prompt_yes_no(
                f"Merge origin/{MAIN_BRANCH} into '{branch}' now before you start?",
                default=True,
            )
            if should_merge_main:
                if working_tree_dirty():
                    print_warn(
                        f"Cannot merge origin/{MAIN_BRANCH} while local changes are present. "
                        "Commit or stash them first."
                    )
                    return 1
                merge_result = merge_origin_main_into_branch(
                    branch,
                    f"Merging origin/{MAIN_BRANCH} into '{branch}' before you start...",
                )
                if merge_result != 0:
                    return merge_result
                print()
                print_ok(f"'{branch}' now includes the latest changes from origin/{MAIN_BRANCH}.")
                print_status_summary(branch)
    return 0


def cmd_sync_commit(args: argparse.Namespace) -> int:
    ensure_git_repo()
    print_header("Workflow Sync Commit")

    branch = current_branch()
    if branch == MAIN_BRANCH:
        print_error("Refusing to run on 'main'. Switch to your personal branch first.")
        return 1

    if merge_in_progress():
        print_warn("An unfinished merge is in progress.")
        print_merge_conflict_instructions(branch)
        return 1

    print_step("Fetching latest refs from origin...")
    fetch = run_git_action(["fetch", "origin"], check=False)
    if fetch.returncode != 0:
        detail = (fetch.stderr or fetch.stdout).strip()
        print_error(f"Fetch failed: {detail or 'see command output above'}")
        return 1

    if working_tree_dirty():
        should_stage = args.yes_add or prompt_yes_no("Stage all local changes with 'git add -A' before syncing?", default=True)
        if not should_stage:
            print_warn("Sync cancelled (local changes were not staged).")
            return 1

        pre_stage_index = run_git(["write-tree"], check=False)
        if pre_stage_index.returncode != 0 or not pre_stage_index.stdout.strip():
            detail = (pre_stage_index.stderr or pre_stage_index.stdout).strip()
            print_error(f"Could not snapshot current index state: {detail or 'unknown error'}")
            return 1
        pre_stage_tree = pre_stage_index.stdout.strip()

        print_step("Staging local changes...")
        add = run_git_action(["add", "-A"], check=False)
        if add.returncode != 0:
            detail = (add.stderr or add.stdout).strip()
            print_error(f"Staging failed: {detail or 'see command output above'}")
            return 1

        if staged_changes_exist():
            message = compose_commit_message(args)
            print_commit_preview(message)
            should_commit = prompt_yes_no(
                "Finish commit with this message?",
                default=True,
                color=ANSI_LIGHT_BLUE,
            )
            if not should_commit:
                restore = run_git(["read-tree", pre_stage_tree], check=False)
                if restore.returncode != 0:
                    detail = (restore.stderr or restore.stdout).strip()
                    print_error(
                        "Commit cancelled, but failed to restore the previous index state: "
                        f"{detail or 'unknown error'}"
                    )
                    return 1
                print_warn("Commit cancelled by user. Local files and index were restored.")
                return 1
            print_step("Creating local commit...")
            commit = run_git_action(["commit", "-m", message], check=False)
            if commit.returncode != 0:
                detail = (commit.stderr or commit.stdout).strip()
                print_error(f"Commit failed: {detail or 'see command output above'}")
                return 1
            print_ok("Local commit created successfully.")
        else:
            print_warn("No staged changes to commit; continuing to sync with main.")
    else:
        print_warn("No local changes to commit; syncing directly with main.")

    merge_result = merge_origin_main_into_branch(
        branch,
        f"Merging origin/{MAIN_BRANCH} into '{branch}' (no rebase)...",
    )
    if merge_result != 0:
        return merge_result

    print()
    print_ok("Branch synced with origin/main successfully.")
    upstream = upstream_branch()
    push_cmd = "git push" if upstream else f"git push -u origin {branch}"
    print_header("Next Steps")
    print(f"1) Push your branch manually: {push_cmd}")
    print(f"2) Open a Pull Request: {branch} -> {MAIN_BRANCH}")
    print("3) Wait for CI to pass before requesting merge")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Simple team workflow helper (safe Git sync + commit)."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    start_parser = subparsers.add_parser(
        "start",
        help="Fetch and update current branch from upstream, print status summary, and optionally merge origin/main.",
    )
    start_parser.set_defaults(func=cmd_start)

    sync_parser = subparsers.add_parser(
        "sync-commit",
        help="Commit local changes first, then merge origin/main into current branch.",
    )
    sync_parser.add_argument(
        "--yes-add",
        action="store_true",
        help="Skip staging confirmation and always run 'git add -A' before syncing.",
    )
    sync_parser.add_argument(
        "--type",
        choices=[name for name, _ in COMMIT_TYPES],
        help="Conventional Commit type (optional; prompts if omitted).",
    )
    sync_parser.add_argument(
        "--scope",
        help="Optional Conventional Commit scope, e.g. ci, docs, workflow.",
    )
    sync_parser.add_argument(
        "--description",
        help="Commit description after type/scope, e.g. 'add workflow helper script'.",
    )
    sync_parser.set_defaults(func=cmd_sync_commit)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    try:
        return args.func(args)
    except RuntimeError as exc:
        print_error(f"Error: {exc}")
        return 1
    except KeyboardInterrupt:
        print()
        print_warn("Cancelled by user.")
        return 130


if __name__ == "__main__":
    sys.exit(main())
