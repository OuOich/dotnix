from pathlib import Path
from typing import Annotated

import requests
import typer
from rich import box
from rich.console import Console
from rich.table import Table

app = typer.Typer()

console = Console()
console_err = Console(stderr=True)
print = console.print
eprint = console_err.print

MetaUrl = Annotated[str, "MetaUrl"]
MetaContent = Annotated[str, "MetaContent"]
Codepoint = Annotated[str, "Codepoint"]
CodepointSet = Annotated[set[Codepoint], "CodepointList"]
CodepointRange = Annotated[str, "CodepointRange"]
CodepointRangeSet = Annotated[set[CodepointRange], "CodepointRangeSet"]

DEFAULT_META_URL: MetaUrl = "https://raw.githubusercontent.com/SerenityOS/serenity/refs/heads/master/Meta/emoji-file-list.txt"


def parse_codepoint(codepoint: Codepoint) -> int:
    normalized = codepoint.strip().upper()

    if normalized.startswith("U+"):
        normalized = normalized[2:]
    elif normalized.startswith("0X"):
        normalized = normalized[2:]

    if not normalized:
        raise ValueError(f"Invalid codepoint: {codepoint!r}")

    value = int(normalized, 16)

    if not (0 <= value <= 0x10FFFF):
        raise ValueError(f"Codepoint out of Unicode range: {codepoint!r}")

    return value


def format_codepoint(value: int) -> Codepoint:
    width = max(4, len(f"{value:X}"))
    return f"U+{value:0{width}X}"


def format_codepoints(codepoints: CodepointSet) -> str:
    return ",".join(codepoints)


def format_unicode_ranges(ranges: CodepointRangeSet) -> str:
    return ",".join(ranges)


def fetch_meta(meta_url: MetaUrl) -> MetaContent:
    with console.status("[bold cyan]Fetching emoji metadata..."):
        resp = requests.get(meta_url)

    if resp.status_code == 200:
        body = resp.text
        lines = len(resp.text.splitlines())

        print(f"[green bold]✔ Successfully fetched emoji metadata. ({lines} lines)")
        return body
    else:
        eprint(f"[red]✘ Failed to get emoji meta, status code: {resp.status_code}")
        raise typer.Exit(1)


def resolve_codepoints_from_meta(meta: MetaContent, ascii: bool) -> CodepointSet:
    with console.status("[bold cyan]Resolving unicode codepoints..."):
        codepoints: CodepointSet = set()

        emoji_paths = map(Path, meta.splitlines())

        for emoji_path in emoji_paths:
            emoji_code = emoji_path.stem
            emoji_codepoints = set(emoji_code.split("_"))

            if ascii:
                codepoints.update(emoji_codepoints)
            else:
                for cp in emoji_codepoints:
                    val = parse_codepoint(cp)

                    if val <= 0x7F:
                        continue

                    if val in [0x00A9, 0x00AE, 0x2122]:
                        continue

                    codepoints.add(format_codepoint(val))

        print(f"[green bold]✔ Resolved {len(codepoints)} codepoints from metadata.")
        return codepoints


def get_unicode_ranges(codepoints: CodepointSet) -> CodepointRangeSet:
    if not codepoints:
        return set()

    sorted_values = sorted({parse_codepoint(codepoint) for codepoint in codepoints})

    ranges: CodepointRangeSet = set()
    start = sorted_values[0]
    end = sorted_values[0]

    for value in sorted_values[1:]:
        if value == end + 1:
            end = value
            continue

        if start == end:
            ranges.add(format_codepoint(start))
        else:
            ranges.add(f"{format_codepoint(start)}-{format_codepoint(end)}")

        start = value
        end = value

    if start == end:
        ranges.add(format_codepoint(start))
    else:
        ranges.add(f"{format_codepoint(start)}-{format_codepoint(end)}")

    return ranges


@app.command()
def codepoints(meta_url: MetaUrl = DEFAULT_META_URL):
    params_table = Table(box=box.ROUNDED, border_style="blue dim")
    params_table.add_column("Key")
    params_table.add_column("Value")

    params_table.add_row("meta_url", meta_url)

    print(params_table)
    print()

    meta = fetch_meta(meta_url)
    codepoints = resolve_codepoints_from_meta(meta, ascii=False)

    print()
    print(
        f"[blue bold]Unicode Codepoints (x{len(codepoints)}):[/]\n{format_codepoints(codepoints)}",
        highlight=False,
        overflow="ignore",
        crop=False,
    )

    print()

    ranges = get_unicode_ranges(codepoints)
    print(
        f"[blue bold]Unicode Ranges (x{len(ranges)}):[/]\n{format_unicode_ranges(ranges)}",
        highlight=False,
        overflow="ignore",
        crop=False,
    )


if __name__ == "__main__":
    app()
