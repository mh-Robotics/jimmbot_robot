#!/usr/bin/env python3
import json
import sys
from pathlib import Path


def main() -> int:
    build_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "build").resolve()
    output_path = build_dir / "compile_commands.json"

    compile_databases = sorted(
        path
        for path in build_dir.glob("*/compile_commands.json")
        if path.is_file() and path != output_path
    )

    merged_commands = []
    for database_path in compile_databases:
        try:
            merged_commands.extend(json.loads(database_path.read_text()))
        except (OSError, json.JSONDecodeError) as exc:
            print(f"[merge_compile_commands] Skipping {database_path}: {exc}", file=sys.stderr)

    build_dir.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(merged_commands, indent=2))
    print(
        f"[merge_compile_commands] Wrote {len(merged_commands)} entries from "
        f"{len(compile_databases)} package databases to {output_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())