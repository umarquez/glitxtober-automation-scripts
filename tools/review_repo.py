#!/usr/bin/env python3
"""Structural code-review gate for glitxtober-automation-scripts.

This script uses only the Python standard library. It checks repository
architecture/documentation invariants that do not require macOS, Hammerspoon or
Sonic Pi. Lua syntax and runner-model checks are handled by tests/review.lua in
CI.
"""

from __future__ import annotations

from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
EPISODES = {
    "01-codigo-sonido": {"runner": True, "phases": ["1", "2", "3", "4", "5A", "5B", "5C", "6", "7", "8", "9"]},
    "02-maquina-decide-ritmo": {"runner": True, "phases": ["1", "2", "3", "4", "5"]},
    "03-controlando-sinte": {"runner": True, "phases": ["1", "2", "3", "4", "5", "5B"]},
    "04-secuenciador": {"runner": True, "phases": ["1", "2", "3", "4", "5", "6"]},
    "05-ritmos-euclidianos": {"runner": True, "phases": ["1", "2", "3", "4", "5", "6", "7"]},
    "06-un-sample-cien-sonidos": {"runner": True, "phases": ["1", "2", "3", "4", "5", "6", "7", "8", "9"]},
    "07-imagen-musica": {"runner": False, "phases": ["1", "2", "3", "4", "5"]},
    "08-trackpad-instrumento": {"runner": False, "phases": ["1", "2", "3", "4", "5", "6"]},
    "09-computadora-escucha-responde": {"runner": False, "phases": ["1", "2", "3", "4", "5", "6"]},
    "10-maquina-musica-sola": {"runner": True, "phases": ["1", "2", "3", "4", "5", "6", "7", "8"]},
}

failures: list[str] = []
passes: list[str] = []


def check(condition: bool, message: str) -> None:
    (passes if condition else failures).append(message)


def text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return ""


def check_documented_code(original: Path, slug: str) -> None:
    source = text(original)

    # Python snippets are syntax-checked without importing third-party modules.
    for index, match in enumerate(re.finditer(r"```python\n(.*?)\n```", source, re.DOTALL), start=1):
        try:
            compile(match.group(1) + "\n", f"{original}#python-{index}", "exec")
            check(True, f"{slug}: Python source block {index} parses")
        except SyntaxError as exc:
            check(False, f"{slug}: Python source block {index} syntax error: {exc.msg}")

    # Sonic Pi code is Ruby syntax. `ruby -c` validates parsing without running
    # Sonic Pi DSL calls. CI installs Ruby; local review skips this layer only
    # when Ruby is unavailable.
    ruby = shutil.which("ruby")
    if ruby:
        for index, match in enumerate(re.finditer(r"```ruby\n(.*?)\n```", source, re.DOTALL), start=1):
            proc = subprocess.run(
                [ruby, "-c", "-"],
                input=match.group(1) + "\n",
                text=True,
                capture_output=True,
            )
            check(proc.returncode == 0, f"{slug}: Ruby/Sonic Pi source block {index} parses")


def main() -> int:
    episodes_root = ROOT / "hammerspoon" / "episodes"

    # Legacy path must remain removed everywhere.
    legacy = "ep01_codigo_sonido.lua"
    check(not (episodes_root / legacy).exists(), "legacy Episode 01 shim is absent")
    stale_refs = []
    for path in ROOT.rglob("*"):
        if path == Path(__file__).resolve():
            continue
        if path.is_file() and path.suffix in {".lua", ".md", ".py", ".yml", ".yaml"}:
            if legacy in text(path):
                stale_refs.append(str(path.relative_to(ROOT)))
    check(not stale_refs, "no references to the removed Episode 01 shim")

    root_readme = text(ROOT / "README.md")
    check(bool(root_readme), "root README exists")
    check("Inventario" in root_readme, "root README contains an inventory")
    check("Code review" in root_readme or "code review" in root_readme.lower(), "root README documents the code-review loop")

    for slug, meta in EPISODES.items():
        directory = episodes_root / slug
        readme = directory / "README.md"
        original = directory / "ORIGINAL.md"
        runner = directory / "runner.lua"

        check(directory.is_dir(), f"{slug}: directory exists")
        check(readme.is_file(), f"{slug}: README.md exists")
        check(original.is_file(), f"{slug}: ORIGINAL.md exists")
        check(runner.is_file() == meta["runner"], f"{slug}: runner presence matches dependency classification")

        readme_text = text(readme)
        original_text = text(original)
        check("## Arquitectura" in readme_text, f"{slug}: README documents architecture")
        check("ORIGINAL.md" in readme_text, f"{slug}: README links canonical phase code")
        check("```mermaid" in readme_text, f"{slug}: README contains a Mermaid diagram")

        if not meta["runner"]:
            check("TODO" in readme_text, f"{slug}: external-code work is marked TODO")

        for phase in meta["phases"]:
            pattern = re.compile(rf"^###+\s+(?:Snapshot|Fase)\s+{re.escape(phase)}\b", re.MULTILINE)
            check(bool(pattern.search(original_text)), f"{slug}: original phase {phase} is documented")

        check_documented_code(original, slug)

        if meta["runner"]:
            runner_text = text(runner)
            check("sonic_pi_runner.lua" in runner_text, f"{slug}: runner uses shared engine")
            check("Runner.new" in runner_text, f"{slug}: runner declares a reviewed specification")
            check("hs.alert.show" not in runner_text, f"{slug}: runner does not draw alerts directly")
            check("Canonical source: ORIGINAL.md" in runner_text, f"{slug}: runner points to canonical source")

    engine = text(ROOT / "hammerspoon" / "lib" / "sonic_pi_runner.lua")
    check("function Runner.reviewSpec" in engine, "shared runner exposes static spec review")
    check("replace_line sólo admite una línea" in engine, "shared runner rejects unsafe multiline replace_line")
    check("sample y sleep están en la misma línea" in engine, "shared runner keeps the dropped-Return regression guard")

    status_router = text(ROOT / "hammerspoon" / "glitx_status.lua")
    check("showAlerts = userConfig.showAlerts == true" in status_router, "alerts are opt-in")
    check("hs.printf" in status_router, "console logging is always available")

    init_example = text(ROOT / "hammerspoon" / "init.lua.example")
    check("/hammerspoon/episodes/" in init_example and "/runner.lua" in init_example, "init example uses per-episode runner paths")
    check(legacy not in init_example, "init example has no legacy path")

    check((ROOT / "tests" / "review.lua").is_file(), "headless Lua review exists")
    check((ROOT / ".github" / "workflows" / "code-review.yml").is_file(), "GitHub Actions review workflow exists")
    check((ROOT / "docs" / "CODE_REVIEW.md").is_file(), "code-review documentation exists")

    # Cheap formatting regression checks.
    trailing = []
    for path in ROOT.rglob("*"):
        if path.is_file() and path.suffix in {".lua", ".md", ".py", ".yml", ".yaml"}:
            for number, line in enumerate(text(path).splitlines(), start=1):
                if line.rstrip() != line:
                    trailing.append(f"{path.relative_to(ROOT)}:{number}")
    check(not trailing, "tracked text files contain no trailing whitespace")

    print("Glitxtober repository review")
    print("=" * 29)
    for message in passes:
        print(f"PASS  {message}")

    if failures:
        print("\nFailures:")
        for message in failures:
            print(f"FAIL  {message}")
        return 1

    print(f"\nPASS  {len(passes)} structural checks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
