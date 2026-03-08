from __future__ import annotations

import base64
import hashlib
import html
import json
import mimetypes
import re
import shutil
import subprocess
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Annotated, Any, TypedDict, cast
from urllib.parse import urlparse

import requests
import typer
from rich import box
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

app = typer.Typer(add_completion=False, no_args_is_help=True, rich_markup_mode="rich")

console = Console()
console_err = Console(stderr=True)
print = console.print
eprint = console_err.print

ROOT_DIR = Path(__file__).resolve().parent.parent
METADATA_PATH = ROOT_DIR / "packages" / "wallpapers" / "metadata.json"

DEFAULT_TIMEOUT = 30
PIXIV_REFERER = "https://www.pixiv.net/"
USER_AGENT = "Mozilla/5.0 (compatible; dotnix-add-wallpaper/1.0)"

WALLHAVEN_HOSTS = {"wallhaven.cc", "www.wallhaven.cc", "whvn.cc"}
PIXIV_HOSTS = {"pixiv.net", "www.pixiv.net"}

WALLHAVEN_PATH_RE = re.compile(r"^/w/(?P<id>[a-z0-9]+)$")
PIXIV_PATH_RE = re.compile(r"^/(?:en/)?artworks/(?P<id>\d+)$")


class WallpaperError(RuntimeError):
    pass


@dataclass(frozen=True)
class DownloadMetadata:
    file_type: str
    file_size: int
    hash: str


@dataclass(frozen=True)
class ResolvedWallpaper:
    source: str
    source_id: str
    page_url: str
    image_url: str
    resolution: str
    ratio: int | float
    file_type: str
    file_size: int
    hash: str
    default_key: str
    default_description: str
    default_category: str
    default_refs: list[str]
    title: str | None = None
    artist: str | None = None
    note: str | None = None


@dataclass(frozen=True)
class ManualOverrides:
    keys: list[str] | None = None
    descriptions: list[str] | None = None
    categories: list[str] | None = None
    refs: list[str] | None = None


class WallpaperEntry(TypedDict):
    description: str | None
    category: str
    refs: list[str]
    source: str
    resolution: str
    ratio: int | float
    file_type: str
    file_size: int
    url: str
    hash: str


MetadataDocument = TypedDict(
    "MetadataDocument",
    {
        "$schema": str,
        "wallpapers": dict[str, WallpaperEntry],
    },
)


def load_metadata() -> MetadataDocument:
    with METADATA_PATH.open("r", encoding="utf-8") as file:
        loaded: object = json.load(file)

    if not isinstance(loaded, dict):
        raise WallpaperError(f"Invalid metadata file: {METADATA_PATH}")

    data = cast(dict[str, object], loaded)
    schema = data.get("$schema")
    wallpapers = data.get("wallpapers")

    if not isinstance(schema, str) or not isinstance(wallpapers, dict):
        raise WallpaperError(f"Invalid metadata file: {METADATA_PATH}")

    return {
        "$schema": schema,
        "wallpapers": cast(dict[str, WallpaperEntry], wallpapers),
    }


def render_json_property(name: str, value: Any, indent: int) -> str:
    indent_prefix = " " * indent
    serialized = json.dumps(value, indent=2, ensure_ascii=True).splitlines()

    lines = [f"{indent_prefix}{json.dumps(name, ensure_ascii=True)}: {serialized[0]}"]
    lines.extend(f"{indent_prefix}{line}" for line in serialized[1:])
    return "\n".join(lines)


def render_metadata_json(data: MetadataDocument) -> str:
    blocks = [render_json_property("$schema", data["$schema"], 2) + ","]
    wallpaper_items = list(data["wallpapers"].items())

    if not wallpaper_items:
        blocks.append('  "wallpapers": {}')
        return "{\n" + "\n\n".join(blocks) + "\n}\n"

    wallpaper_lines = ['  "wallpapers": {']

    for index, (wallpaper_name, wallpaper_value) in enumerate(wallpaper_items):
        entry_lines = render_json_property(
            wallpaper_name,
            wallpaper_value,
            4,
        ).splitlines()

        if index < len(wallpaper_items) - 1:
            entry_lines[-1] = f"{entry_lines[-1]},"

        wallpaper_lines.extend(entry_lines)

        if index < len(wallpaper_items) - 1:
            wallpaper_lines.append("")

    wallpaper_lines.append("  }")
    blocks.append("\n".join(wallpaper_lines))
    return "{\n" + "\n\n".join(blocks) + "\n}\n"


def write_metadata(data: MetadataDocument) -> None:
    METADATA_PATH.write_text(render_metadata_json(data), encoding="utf-8")


def format_metadata_file() -> str | None:
    commands: list[tuple[list[str], str]] = []

    prettier = shutil.which("prettier")

    if prettier is not None:
        commands.append(([prettier, "--write", str(METADATA_PATH)], "prettier"))
    elif shutil.which("nix") is not None:
        commands.append(
            (
                ["nix", "develop", "-c", "prettier", "--write", str(METADATA_PATH)],
                "nix develop -c prettier",
            )
        )

    for command, label in commands:
        result = subprocess.run(
            command,
            cwd=ROOT_DIR,
            capture_output=True,
            text=True,
            check=False,
        )

        if result.returncode == 0:
            return label

    return None


def slugify(value: str, fallback: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_only = normalized.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", ascii_only).strip("-").lower()
    return slug or fallback


def clean_text(value: str) -> str:
    line_breaks = re.sub(r"<br\s*/?>", "\n", value, flags=re.IGNORECASE)
    stripped = re.sub(r"<[^>]+>", "", line_breaks)
    normalized = re.sub(r"\s+", " ", html.unescape(stripped))
    return normalized.strip()


def normalize_ratio(width: int, height: int) -> int | float:
    ratio = round(width / height, 2)
    return int(ratio) if ratio.is_integer() else ratio


def normalize_refs(refs: list[str]) -> list[str]:
    unique_refs: list[str] = []

    for ref in refs:
        normalized = ref.strip()

        if normalized and normalized not in unique_refs:
            unique_refs.append(normalized)

    return unique_refs


def parse_refs(value: str) -> list[str]:
    refs = normalize_refs([segment for segment in value.split(",")])

    if not refs:
        raise WallpaperError("`refs` cannot be empty")

    return refs


def describe_bytes(size: int) -> str:
    units = ["B", "KiB", "MiB", "GiB"]
    value = float(size)

    for unit in units:
        if value < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(value)} {unit}"

            return f"{value:.2f} {unit}"

        value /= 1024

    return f"{size} B"


def run_with_status(message: str, action: Any) -> Any:
    with console.status(f"[bold cyan]{message}"):
        return action()


def validate_override_count(
    label: str,
    values: list[str] | None,
    total_urls: int,
    *,
    allow_broadcast: bool,
) -> None:
    if not values:
        return

    valid_counts = {total_urls}

    if allow_broadcast:
        valid_counts.add(1)

    if len(values) not in valid_counts:
        valid_text = " or ".join(str(count) for count in sorted(valid_counts))
        raise WallpaperError(
            f"{label} expects {valid_text} value(s) for {total_urls} URL(s), got {len(values)}"
        )


def get_override_value(
    values: list[str] | None,
    index: int,
    *,
    allow_broadcast: bool,
) -> str | None:
    if not values:
        return None

    if allow_broadcast and len(values) == 1:
        return values[0]

    if index < len(values):
        return values[index]

    return None


def normalize_optional_text(value: str) -> str | None:
    normalized = value.strip()

    if normalized.lower() in {"", "null", "none"}:
        return None

    return normalized


def optional_str(value: object) -> str | None:
    if not isinstance(value, str):
        return None

    normalized = value.strip()
    return normalized or None


def render_resolved_wallpaper(
    index: int, total: int, resolved: ResolvedWallpaper
) -> None:
    table = Table(box=box.ROUNDED, border_style="blue dim", show_header=False)
    table.add_column("Field", style="bold cyan", no_wrap=True)
    table.add_column("Value", overflow="fold")

    table.add_row("Source", resolved.source)
    table.add_row("Artwork ID", resolved.source_id)
    table.add_row("Page", resolved.page_url)

    if resolved.title:
        table.add_row("Title", resolved.title)

    if resolved.artist:
        table.add_row("Artist", resolved.artist)

    table.add_row("Image", resolved.image_url)
    table.add_row(
        "File",
        f"{resolved.resolution} | {resolved.file_type} | {describe_bytes(resolved.file_size)}",
    )
    table.add_row("Suggested key", resolved.default_key)
    table.add_row("Suggested category", resolved.default_category)
    table.add_row("Suggested refs", "\n".join(resolved.default_refs))

    if resolved.note:
        table.add_row("Note", resolved.note)

    console.print(
        Panel.fit(
            table,
            title=f"Wallpaper {index}/{total}",
            border_style="cyan dim",
        )
    )


def make_session() -> requests.Session:
    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})
    return session


def get_json(
    session: requests.Session, url: str, *, headers: dict[str, str] | None = None
) -> dict[str, Any]:
    response = session.get(url, headers=headers, timeout=DEFAULT_TIMEOUT)
    response.raise_for_status()
    return response.json()


def download_image_metadata(
    session: requests.Session,
    image_url: str,
    *,
    headers: dict[str, str] | None = None,
) -> DownloadMetadata:
    digest = hashlib.sha256()
    file_size = 0
    file_type: str | None = None

    with session.get(
        image_url, headers=headers, timeout=DEFAULT_TIMEOUT, stream=True
    ) as response:
        response.raise_for_status()

        content_type = response.headers.get("Content-Type", "")
        file_type = content_type.split(";", 1)[0].strip() or None

        for chunk in response.iter_content(chunk_size=1024 * 1024):
            if not chunk:
                continue

            digest.update(chunk)
            file_size += len(chunk)

    if file_type is None:
        guessed_type, _ = mimetypes.guess_type(image_url)
        file_type = guessed_type

    if file_type is None:
        raise WallpaperError(f"Unable to determine MIME type for {image_url}")

    sri_hash = base64.b64encode(digest.digest()).decode("ascii")
    return DownloadMetadata(
        file_type=file_type, file_size=file_size, hash=f"sha256-{sri_hash}"
    )


def parse_wallhaven_id(url: str) -> str | None:
    parsed = urlparse(url)
    host = parsed.netloc.lower()

    if host not in WALLHAVEN_HOSTS:
        return None

    if host == "whvn.cc":
        short_id = parsed.path.strip("/")
        return short_id or None

    match = WALLHAVEN_PATH_RE.match(parsed.path)
    return match.group("id") if match else None


def parse_pixiv_id(url: str) -> str | None:
    parsed = urlparse(url)
    host = parsed.netloc.lower()

    if host not in PIXIV_HOSTS:
        return None

    match = PIXIV_PATH_RE.match(parsed.path)
    return match.group("id") if match else None


def fetch_wallhaven(session: requests.Session, original_url: str) -> ResolvedWallpaper:
    wallpaper_id = parse_wallhaven_id(original_url)

    if wallpaper_id is None:
        raise WallpaperError(f"Unsupported Wallhaven URL: {original_url}")

    page_url = f"https://wallhaven.cc/w/{wallpaper_id}"
    payload = get_json(session, f"https://wallhaven.cc/api/v1/w/{wallpaper_id}")
    data = payload["data"]

    width = int(data["dimension_x"])
    height = int(data["dimension_y"])
    image_url = data["path"]
    download = download_image_metadata(session, image_url)

    refs = [page_url]
    source_ref = data.get("source") or ""
    artist = None

    uploader = data.get("uploader")

    if isinstance(uploader, dict):
        uploader_data = cast(dict[str, object], uploader)
        artist = optional_str(uploader_data.get("username"))

    if source_ref:
        refs.append(source_ref)

    return ResolvedWallpaper(
        source="wallhaven",
        source_id=wallpaper_id,
        page_url=page_url,
        image_url=image_url,
        resolution=f"{width}x{height}",
        ratio=normalize_ratio(width, height),
        file_type=download.file_type,
        file_size=download.file_size,
        hash=download.hash,
        default_key=f"wallhaven-{wallpaper_id}",
        default_description="",
        default_category=str(data.get("category") or "wallpaper"),
        default_refs=normalize_refs(refs),
        title=None,
        artist=artist,
    )


def fetch_pixiv(session: requests.Session, original_url: str) -> ResolvedWallpaper:
    illust_id = parse_pixiv_id(original_url)

    if illust_id is None:
        raise WallpaperError(f"Unsupported Pixiv URL: {original_url}")

    page_url = f"https://www.pixiv.net/artworks/{illust_id}"
    api_headers = {"Referer": PIXIV_REFERER}

    illust_payload = get_json(
        session, f"https://www.pixiv.net/ajax/illust/{illust_id}", headers=api_headers
    )

    if illust_payload.get("error"):
        raise WallpaperError(f"Pixiv API returned an error for {page_url}")

    illust = illust_payload["body"]
    pages_payload = get_json(
        session,
        f"https://www.pixiv.net/ajax/illust/{illust_id}/pages?lang=en",
        headers=api_headers,
    )

    if pages_payload.get("error"):
        raise WallpaperError(f"Pixiv pages API returned an error for {page_url}")

    pages = pages_payload["body"]

    if not pages:
        raise WallpaperError(f"Pixiv artwork has no pages: {page_url}")

    first_page = pages[0]
    width = int(first_page["width"])
    height = int(first_page["height"])
    image_url = first_page["urls"]["original"]
    download = download_image_metadata(session, image_url, headers=api_headers)

    page_count = int(illust.get("pageCount") or len(pages))
    title = str(illust.get("title") or "").strip() or None
    description = clean_text(str(illust.get("description") or ""))

    note = None

    if page_count > 1:
        note = (
            f"Pixiv artwork has {page_count} pages; the script uses page 1 by default."
        )

    return ResolvedWallpaper(
        source="pixiv",
        source_id=illust_id,
        page_url=page_url,
        image_url=image_url,
        resolution=f"{width}x{height}",
        ratio=normalize_ratio(width, height),
        file_type=download.file_type,
        file_size=download.file_size,
        hash=download.hash,
        default_key=slugify(title or f"pixiv-{illust_id}", f"pixiv-{illust_id}"),
        default_description=description,
        default_category="anime",
        default_refs=[page_url],
        title=title,
        artist=optional_str(illust.get("userName")),
        note=note,
    )


def resolve_wallpaper(session: requests.Session, url: str) -> ResolvedWallpaper:
    if parse_wallhaven_id(url) is not None:
        return fetch_wallhaven(session, url)

    if parse_pixiv_id(url) is not None:
        return fetch_pixiv(session, url)

    raise WallpaperError(f"Unsupported wallpaper URL: {url}")


def prompt_key(
    default_key: str,
    used_keys: set[str],
    override_key: str | None,
) -> str:
    while True:
        used_option = override_key is not None

        if override_key is not None:
            key = override_key.strip()
            console.print(f"[green]Using --key[/]: [bold]{key}[/]")
        else:
            key = typer.prompt("Entry key", default=default_key).strip()

        if not key:
            message = "Entry key cannot be empty."
        elif key in used_keys:
            message = f"Entry key `{key}` already exists, choose another one."
        else:
            return key

        if used_option:
            raise WallpaperError(message)

        eprint(f"[red]{message}[/]")


def prompt_description(
    default_description: str,
    override_description: str | None,
) -> str | None:
    if override_description is not None:
        description = normalize_optional_text(override_description)
        preview = description if description is not None else "null"
        console.print(f"[green]Using --description[/]: {preview}")
        return description

    value = typer.prompt(
        "Description (empty/null = null)",
        default=default_description,
        show_default=bool(default_description),
    ).strip()

    if value.lower() in {"", "null", "none"}:
        return None

    return value


def prompt_category(default_category: str, override_category: str | None) -> str:
    if override_category is not None:
        category = override_category.strip()

        if not category:
            raise WallpaperError("`category` cannot be empty")

        console.print(f"[green]Using --category[/]: {category}")
        return category

    category = typer.prompt("Category", default=default_category).strip()

    if not category:
        raise WallpaperError("`category` cannot be empty")

    return category


def prompt_refs(default_refs: list[str], override_refs: str | None) -> list[str]:
    default_value = ", ".join(default_refs)

    if override_refs is not None:
        refs = parse_refs(override_refs)
        console.print(f"[green]Using --refs[/]: {', '.join(refs)}")
        return refs

    while True:
        raw_refs = typer.prompt("Refs (comma-separated)", default=default_value).strip()

        try:
            return parse_refs(raw_refs)
        except WallpaperError as error:
            eprint(f"[red]{error}[/]")


def prompt_manual_fields(
    resolved: ResolvedWallpaper,
    used_keys: set[str],
    index: int,
    total: int,
    overrides: ManualOverrides,
) -> tuple[str, str | None, str, list[str]]:
    console.line()
    render_resolved_wallpaper(index, total, resolved)

    key = prompt_key(
        resolved.default_key,
        used_keys,
        get_override_value(overrides.keys, index - 1, allow_broadcast=False),
    )
    description = prompt_description(
        resolved.default_description,
        get_override_value(overrides.descriptions, index - 1, allow_broadcast=True),
    )
    category = prompt_category(
        resolved.default_category,
        get_override_value(overrides.categories, index - 1, allow_broadcast=True),
    )
    refs = prompt_refs(
        resolved.default_refs,
        get_override_value(overrides.refs, index - 1, allow_broadcast=True),
    )

    return key, description, category, refs


def build_entry(
    resolved: ResolvedWallpaper, description: str | None, category: str, refs: list[str]
) -> WallpaperEntry:
    return {
        "description": description,
        "category": category,
        "refs": refs,
        "source": resolved.source,
        "resolution": resolved.resolution,
        "ratio": resolved.ratio,
        "file_type": resolved.file_type,
        "file_size": resolved.file_size,
        "url": resolved.image_url,
        "hash": resolved.hash,
    }


def ensure_not_duplicate(
    data: MetadataDocument,
    pending_entries: dict[str, WallpaperEntry],
    resolved: ResolvedWallpaper,
) -> None:
    for name, wallpaper in data["wallpapers"].items():
        refs = wallpaper["refs"]

        if resolved.page_url in refs or resolved.image_url == wallpaper.get("url"):
            raise WallpaperError(f"Wallpaper already exists in metadata as `{name}`")

    for name, wallpaper in pending_entries.items():
        refs = wallpaper["refs"]

        if resolved.page_url in refs or resolved.image_url == wallpaper.get("url"):
            raise WallpaperError(f"Wallpaper already queued in this run as `{name}`")


@app.command()
def main(
    urls: Annotated[
        list[str],
        typer.Argument(help="One or more Wallhaven or Pixiv artwork URLs."),
    ],
    key: Annotated[
        list[str] | None,
        typer.Option(
            "--key",
            help="Entry key overrides, in URL order. Repeat once per URL.",
            rich_help_panel="Entry overrides",
        ),
    ] = None,
    description: Annotated[
        list[str] | None,
        typer.Option(
            "--description",
            help=(
                "Description overrides, in URL order. Repeat once per URL, or provide a single "
                "value to reuse for all URLs. Use `null` for JSON null."
            ),
            rich_help_panel="Entry overrides",
        ),
    ] = None,
    category: Annotated[
        list[str] | None,
        typer.Option(
            "--category",
            help=(
                "Category overrides, in URL order. Repeat once per URL, or provide a single "
                "value to reuse for all URLs."
            ),
            rich_help_panel="Entry overrides",
        ),
    ] = None,
    refs: Annotated[
        list[str] | None,
        typer.Option(
            "--refs",
            help=(
                "Refs overrides, in URL order. Each value is a comma-separated URL list. "
                "Repeat once per URL, or provide a single value to reuse for all URLs."
            ),
            rich_help_panel="Entry overrides",
        ),
    ] = None,
) -> None:
    overrides = ManualOverrides(
        keys=key,
        descriptions=description,
        categories=category,
        refs=refs,
    )

    try:
        validate_override_count(
            "--key", overrides.keys, len(urls), allow_broadcast=False
        )
        validate_override_count(
            "--description", overrides.descriptions, len(urls), allow_broadcast=True
        )
        validate_override_count(
            "--category", overrides.categories, len(urls), allow_broadcast=True
        )
        validate_override_count(
            "--refs", overrides.refs, len(urls), allow_broadcast=True
        )

        metadata = run_with_status("Loading wallpaper metadata...", load_metadata)
        used_keys = set(metadata["wallpapers"].keys())
        pending_entries: dict[str, WallpaperEntry] = {}

        with make_session() as session:
            for index, url in enumerate(urls, start=1):
                resolved = run_with_status(
                    f"Fetching wallpaper {index}/{len(urls)} metadata...",
                    lambda current_url=url: resolve_wallpaper(session, current_url),
                )
                ensure_not_duplicate(metadata, pending_entries, resolved)

                key_value, description_value, category_value, refs_value = (
                    prompt_manual_fields(
                        resolved,
                        used_keys,
                        index,
                        len(urls),
                        overrides,
                    )
                )
                entry = build_entry(
                    resolved,
                    description_value,
                    category_value,
                    refs_value,
                )

                pending_entries[key_value] = entry
                used_keys.add(key_value)

        metadata["wallpapers"].update(pending_entries)
        run_with_status(
            f"Writing {len(pending_entries)} wallpaper(s) to metadata...",
            lambda: write_metadata(metadata),
        )

        formatter = run_with_status("Formatting metadata...", format_metadata_file)

        console.line()
        console.print(
            f"[green bold]Added {len(pending_entries)} wallpaper(s)[/] to [cyan]{METADATA_PATH}[/]"
        )
        console.print(f"[dim]Keys:[/] {', '.join(pending_entries)}")

        if formatter:
            console.print(f"[green]Formatted metadata with {formatter}.[/]")
        else:
            console.print(
                "[yellow]Optional formatter unavailable or failed; kept the built-in JSON formatting.[/]"
            )
    except WallpaperError as error:
        eprint(f"[red]{error}[/]")
        raise typer.Exit(1) from error
    except requests.HTTPError as error:
        eprint(f"[red]HTTP request failed:[/] {error}")
        raise typer.Exit(1) from error
    except requests.RequestException as error:
        eprint(f"[red]Network request failed:[/] {error}")
        raise typer.Exit(1) from error


if __name__ == "__main__":
    app()
