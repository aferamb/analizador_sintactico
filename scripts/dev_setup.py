#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def run(
    cmd: list[str],
    cwd: Path | None = None,
    check: bool = True,
    capture_output: bool = False,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        text=True,
        capture_output=capture_output,
        check=check,
    )


def detect_venv_python(venv_dir: Path) -> Path:
    candidates = [
        venv_dir / "bin" / "python",
        venv_dir / "Scripts" / "python.exe",
        venv_dir / "Scripts" / "python",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise RuntimeError(f"Could not find Python interpreter inside virtual environment: {venv_dir}")


def python_works(python_cmd: Path) -> bool:
    result = run(
        [str(python_cmd), "-c", "import sys"],
        check=False,
        capture_output=True,
    )
    return result.returncode == 0


def ensure_pip_available(venv_python: Path) -> None:
    run([str(venv_python), "-m", "ensurepip", "--upgrade"])


def upgrade_pip(venv_python: Path) -> None:
    result = run(
        [str(venv_python), "-m", "pip", "install", "--upgrade", "pip"],
        check=False,
        capture_output=True,
    )
    if result.returncode == 0:
        if result.stdout:
            print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
        return

    details = (result.stderr or result.stdout or "").strip()
    print("Warning: pip upgrade failed. Restoring bundled pip and continuing...")
    if details:
        print(details)
    ensure_pip_available(venv_python)


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")


def create_activation_helpers(repo_root: Path) -> None:
    sh_script = """#!/usr/bin/env bash
set -euo pipefail

if [[ \"${BASH_SOURCE[0]}\" == \"$0\" ]]; then
  echo \"Run this script with 'source' so activation affects your current shell:\"
  echo \"  source scripts/activate_venv.sh\"
  exit 1
fi

SCRIPT_DIR=\"$(cd \"$(dirname \"${BASH_SOURCE[0]}\")\" && pwd)\"
ROOT_DIR=\"$(cd \"$SCRIPT_DIR/..\" && pwd)\"
ACTIVATE_SCRIPT=\"$ROOT_DIR/.venv/bin/activate\"

if [[ ! -f \"$ACTIVATE_SCRIPT\" ]]; then
  echo \"Virtual environment not found at $ROOT_DIR/.venv\"
  echo \"Run setup first: python3 scripts/dev_setup.py\"
  return 1
fi

# shellcheck source=/dev/null
source \"$ACTIVATE_SCRIPT\"
echo \"Virtual environment activated (.venv).\"
"""

    ps_script = """$ScriptDir = Split-Path -Parent $PSCommandPath
$RootDir = Split-Path -Parent $ScriptDir
$ActivateScript = Join-Path $RootDir ".venv\\Scripts\\Activate.ps1"

if (-not (Test-Path $ActivateScript)) {
    Write-Host "Virtual environment not found at $RootDir\\.venv" -ForegroundColor Red
    Write-Host "Run setup first: python scripts/dev_setup.py" -ForegroundColor Yellow
    exit 1
}

. $ActivateScript
Write-Host "Virtual environment activated (.venv)." -ForegroundColor Green
"""

    sh_path = repo_root / "scripts" / "activate_venv.sh"
    ps_path = repo_root / "scripts" / "activate_venv.ps1"

    write_file(sh_path, sh_script)
    write_file(ps_path, ps_script)

    sh_path.chmod(0o755)


def configure_hooks(repo_root: Path) -> None:
    run(["git", "config", "--local", "core.hooksPath", ".githooks"], cwd=repo_root)


def ensure_pre_push_hook(repo_root: Path) -> None:
    hook_content = """#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=\"$(git rev-parse --show-toplevel)\"
cd \"$ROOT_DIR\"

if [[ -t 1 && -z \"${NO_COLOR:-}\" ]]; then
  C_RESET=$'\\033[0m'
  C_CYAN=$'\\033[36m'
  C_GREEN=$'\\033[32m'
  C_YELLOW=$'\\033[33m'
  C_RED=$'\\033[31m'
else
  C_RESET=\"\"
  C_CYAN=\"\"
  C_GREEN=\"\"
  C_YELLOW=\"\"
  C_RED=\"\"
fi

say_step() {
  printf \"%s[pre-push][STEP]%s %s\\n\" \"$C_CYAN\" \"$C_RESET\" \"$1\"
}

say_ok() {
  printf \"%s[pre-push][OK]%s %s\\n\" \"$C_GREEN\" \"$C_RESET\" \"$1\"
}

say_warn() {
  printf \"%s[pre-push][WARN]%s %s\\n\" \"$C_YELLOW\" \"$C_RESET\" \"$1\"
}

say_error() {
  printf \"%s[pre-push][ERROR]%s %s\\n\" \"$C_RED\" \"$C_RESET\" \"$1\"
}

run_check() {
  local label=\"$1\"
  shift
  say_step \"$label\"
  echo \"[pre-push][CMD] $*\"
  \"$@\"
}

can_run_python() {
  \"$1\" -c \"import sys\" >/dev/null 2>&1
}

if [[ -x \"$ROOT_DIR/.venv/bin/python\" ]] && can_run_python \"$ROOT_DIR/.venv/bin/python\"; then
  PYTHON_CMD=\"$ROOT_DIR/.venv/bin/python\"
elif [[ -x \"$ROOT_DIR/.venv/Scripts/python.exe\" ]] && can_run_python \"$ROOT_DIR/.venv/Scripts/python.exe\"; then
  PYTHON_CMD=\"$ROOT_DIR/.venv/Scripts/python.exe\"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_CMD=\"python3\"
elif command -v python >/dev/null 2>&1; then
  PYTHON_CMD=\"python\"
else
  say_error \"Python interpreter not found.\"
  say_warn \"Run the setup script first: python3 scripts/dev_setup.py\"
  exit 1
fi

if ! \"$PYTHON_CMD\" -m ruff --version >/dev/null 2>&1; then
  say_error \"Ruff is not available for '$PYTHON_CMD'.\"
  say_warn \"Run the setup script first: $PYTHON_CMD scripts/dev_setup.py\"
  exit 1
fi

if ! run_check \"Running lint: ruff check .\" \"$PYTHON_CMD\" -m ruff check .; then
  say_error \"Lint failed. Push cancelled. Fix issues and push again.\"
  exit 1
fi

if [[ -f \"$ROOT_DIR/tests.pl\" ]]; then
  if command -v swipl >/dev/null 2>&1; then
    if ! run_check \"Running tests: swipl -q -s tests.pl -g run_tests -t halt\" swipl -q -s tests.pl -g run_tests -t halt; then
      say_error \"Tests failed. Push cancelled. Fix issues and push again.\"
      exit 1
    fi
    say_ok \"Tests passed.\"
  else
    say_warn \"swipl not found. Skipping local Prolog tests.\"
  fi
fi

say_ok \"All pre-push checks passed. Continuing push.\"
"""

    hook_path = repo_root / ".githooks" / "pre-push"
    write_file(hook_path, hook_content)
    hook_path.chmod(0o755)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create or update local dev environment (.venv), install requirements, and configure Git hooks."
    )
    parser.add_argument(
        "--recreate",
        action="store_true",
        help="Delete and recreate the virtual environment from scratch.",
    )
    parser.add_argument(
        "--venv-dir",
        default=".venv",
        help="Virtual environment directory relative to repository root (default: .venv).",
    )
    parser.add_argument(
        "--skip-hooks",
        action="store_true",
        help="Do not configure Git hooks.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[1]
    venv_dir = (repo_root / args.venv_dir).resolve()
    req_file = repo_root / "requirements-dev.txt"
    venv_python: Path | None = None

    if args.recreate and venv_dir.exists():
        print(f"Removing existing virtual environment: {venv_dir}")
        shutil.rmtree(venv_dir)

    if venv_dir.exists():
        try:
            venv_python = detect_venv_python(venv_dir)
            if python_works(venv_python):
                print(f"Using existing virtual environment: {venv_dir}")
            else:
                print(f"Broken virtual environment detected at: {venv_dir}")
                print(f"Interpreter is not runnable anymore: {venv_python}")
                print("Recreating virtual environment from scratch...")
                shutil.rmtree(venv_dir)
                venv_python = None
        except RuntimeError:
            print(f"Incomplete virtual environment detected at: {venv_dir}")
            print("Recreating virtual environment from scratch...")
            shutil.rmtree(venv_dir)

    if venv_python is None:
        print(f"Creating virtual environment at: {venv_dir}")
        print("This may take a few minutes on first run, especially on Windows.")
        run([sys.executable, "-m", "venv", str(venv_dir)])
        venv_python = detect_venv_python(venv_dir)

    print("Ensuring pip is available in the virtual environment...")
    ensure_pip_available(venv_python)

    print("Upgrading pip in the virtual environment...")
    upgrade_pip(venv_python)

    if req_file.exists():
        print(f"Installing dev dependencies from: {req_file}")
        run([str(venv_python), "-m", "pip", "install", "-r", str(req_file)])
    else:
        print("requirements-dev.txt not found. Skipping dependency installation.")

    create_activation_helpers(repo_root)
    ensure_pre_push_hook(repo_root)

    if not args.skip_hooks:
        configure_hooks(repo_root)
        hooks_msg = "Git hooks configured (core.hooksPath=.githooks)."
    else:
        hooks_msg = "Git hook files created, but core.hooksPath was not configured (--skip-hooks)."

    print("\nSetup complete.")
    print(f"- Virtual env: {venv_dir}")
    print(f"- Python: {venv_python}")
    print(f"- {hooks_msg}")
    print("- Activation helper (bash): source scripts/activate_venv.sh")
    print("- Activation helper (PowerShell): . scripts/activate_venv.ps1")

    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except subprocess.CalledProcessError as exc:
        details = (exc.stderr or exc.stdout or "").strip()
        if details:
            print(details)
        print(f"Setup failed while running: {' '.join(exc.cmd)}")
        raise SystemExit(exc.returncode)
    except RuntimeError as exc:
        print(f"Setup failed: {exc}")
        raise SystemExit(1)
    except KeyboardInterrupt:
        print("\nSetup cancelled by user.")
        raise SystemExit(130)
