#!/usr/bin/env python3
"""secure-coder pre-commit gate — calls the Anthropic API directly, no Claude Code CLI required.
Installed by setup.sh into .git/hooks/pre-commit-api.py (opt-in alternative to hooks/pre-commit).
Requires: ANTHROPIC_API_KEY env var, `pip install anthropic`.
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

MODEL = "claude-sonnet-5"


def repo_root() -> Path:
    out = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True
    )
    return Path(out.stdout.strip())


def staged_diff() -> str:
    out = subprocess.run(["git", "diff", "--cached"], capture_output=True, text=True, check=True)
    return out.stdout


def staged_files() -> list[str]:
    out = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
        capture_output=True,
        text=True,
        check=True,
    )
    return [f for f in out.stdout.splitlines() if f]


def run_deterministic_scans(files: list[str]) -> int:
    """Secret + SAST scanners, independent of LLM judgment. Returns 0 if clean, 1 to block."""
    if shutil.which("gitleaks"):
        print("secure-coder: running gitleaks secret scan (deterministic)...")
        result = subprocess.run(["gitleaks", "protect", "--staged", "--no-banner", "--redact"])
        if result.returncode != 0:
            print(
                "\nsecure-coder: commit blocked — gitleaks detected a likely secret in the staged diff.\n"
                "Fix: remove it, rotate it if already exposed, and use env vars / a secret manager. "
                "Override: git commit --no-verify (not recommended).",
                file=sys.stderr,
            )
            return 1
    else:
        print(
            "secure-coder: gitleaks not found — skipping deterministic secret scan "
            "(install: https://github.com/gitleaks/gitleaks).",
            file=sys.stderr,
        )

    if shutil.which("semgrep") and files:
        print("secure-coder: running semgrep SAST scan (deterministic)...")
        result = subprocess.run(
            ["semgrep", "--config", "p/owasp-top-ten", "--config", "p/secrets", "--error", "--quiet", *files]
        )
        if result.returncode != 0:
            print(
                "\nsecure-coder: commit blocked — semgrep found high-confidence security findings.\n"
                "Fix the findings above, or override with git commit --no-verify (not recommended).",
                file=sys.stderr,
            )
            return 1
    elif not shutil.which("semgrep"):
        print(
            "secure-coder: semgrep not found — skipping deterministic SAST scan "
            "(install: pip install semgrep).",
            file=sys.stderr,
        )

    return 0


def main() -> int:
    diff = staged_diff()
    if not diff.strip():
        return 0

    if run_deterministic_scans(staged_files()) != 0:
        return 1

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print(
            "secure-coder: ANTHROPIC_API_KEY not set — skipping AI review. "
            "Set it, or use hooks/pre-commit (Claude Code CLI) instead.",
            file=sys.stderr,
        )
        return 0

    root = repo_root()
    prompt_template = root / "prompts" / "PRE_COMMIT_REVIEW_PROMPT.md"
    claude_md = root / "CLAUDE.md"
    if not prompt_template.exists():
        print(
            f"secure-coder: prompt template missing at {prompt_template} — skipping AI review.",
            file=sys.stderr,
        )
        return 0

    try:
        import anthropic
    except ImportError:
        print(
            "secure-coder: 'anthropic' package not installed — skipping AI review. "
            "Run 'pip install anthropic' to enable it.",
            file=sys.stderr,
        )
        return 0

    print("secure-coder: running pre-commit security review (Anthropic API)...")

    system_prompt = claude_md.read_text() if claude_md.exists() else ""
    review_prompt = prompt_template.read_text().replace("{{DIFF}}", diff)

    client = anthropic.Anthropic(api_key=api_key)
    response = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        system=system_prompt,
        messages=[{"role": "user", "content": review_prompt}],
    )
    result = "".join(block.text for block in response.content if block.type == "text")
    print(result)

    if "VERDICT: BLOCK" in result:
        print(
            "\nsecure-coder: commit blocked — fix the findings above, "
            "or run 'git commit --no-verify' to override (not recommended).",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
