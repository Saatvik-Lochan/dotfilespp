#!/usr/bin/env python3

from __future__ import annotations

import filecmp
import os
import shutil
import subprocess
import sys
from pathlib import Path


def notify(message: str) -> None:
    subprocess.run(["notify-send", message], check=False)


def resolve_current_wallpaper(base_dir: Path) -> Path | None:
    current_link = base_dir / "current"
    if not current_link.exists() and not current_link.is_symlink():
        notify("current wallpaper link missing")
        return None

    try:
        current_file = current_link.resolve(strict=True)
    except FileNotFoundError:
        notify("current wallpaper target missing")
        return None

    if not current_file.is_file():
        notify("current wallpaper target missing")
        return None

    return current_file


def iter_saved_top_level_files(base_dir: Path) -> list[Path]:
    files: list[Path] = []
    for entry in base_dir.iterdir():
        if entry.name == "current":
            continue
        if entry.is_file() and not entry.is_symlink():
            files.append(entry)
    return files


def files_identical(path_a: Path, path_b: Path) -> bool:
    if path_a.stat().st_size != path_b.stat().st_size:
        return False
    return filecmp.cmp(path_a, path_b, shallow=False)


def prompt_name(default_name: str) -> str | None:
    if shutil.which("zenity") is None:
        notify("zenity not found; cannot prompt for wallpaper name")
        return None

    result = subprocess.run(
        ["zenity", "--entry", "--title=Save Wallpaper", "--text=Save wallpaper as:", f"--entry-text={default_name}"],
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        return ""

    return result.stdout.strip()


def main() -> int:
    base_dir = Path(os.environ.get("BASE_WALLPAPER_DIR", "~/Documents/misc/wallpapers")).expanduser()

    if not base_dir.is_dir():
        notify(f"wallpaper dir missing: {base_dir}")
        return 1

    current_wallpaper = resolve_current_wallpaper(base_dir)
    if current_wallpaper is None:
        return 1

    saved_files = iter_saved_top_level_files(base_dir)
    for saved_file in saved_files:
        if files_identical(current_wallpaper, saved_file):
            notify(f"already saved: {saved_file.name}")
            return 0

    default_name = current_wallpaper.name
    while True:
        chosen_name = prompt_name(default_name)
        if chosen_name is None:
            return 1

        if chosen_name == "":
            notify("save wallpaper cancelled")
            return 0

        if chosen_name in {".", ".."} or "/" in chosen_name:
            notify("invalid name; try again")
            default_name = chosen_name
            continue

        destination = base_dir / chosen_name
        if destination.exists():
            if destination.is_file() and not destination.is_symlink() and files_identical(current_wallpaper, destination):
                notify(f"already exists: {destination.name}")
                return 0

            notify(f"name conflict: {destination.name}; pick another")
            default_name = chosen_name
            continue

        shutil.copy2(current_wallpaper, destination)
        notify(f"saved wallpaper {destination.name}")
        return 0


if __name__ == "__main__":
    sys.exit(main())
