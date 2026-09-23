from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

import typer
from rich.console import Console

from .bites import build_bite_pack
from .models import Catalog, CourseRecord
from .yale import YaleOYCClient, save_json

app = typer.Typer(add_completion=False, no_args_is_help=True, help="aBit open-course scraper")
console = Console()

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


@app.command()
def catalog(
    source: str = typer.Option("yale", help="Catalog source: yale"),
    out: Optional[Path] = typer.Option(None, help="Output JSON path"),
) -> None:
    """Scrape the university open-course catalog."""
    if source != "yale":
        raise typer.BadParameter("Only yale is implemented in v1")
    out_path = out or DATA / "yale" / "catalog.json"
    with YaleOYCClient() as client:
        cat = client.fetch_catalog()
    save_json(cat, out_path)
    console.print(f"[bold]{cat.course_count}[/bold] courses")


@app.command()
def course(
    source: str = typer.Option("yale"),
    slug: str = typer.Option(..., help="Course path slug, e.g. philosophy/phil-176"),
    max_lectures: Optional[int] = typer.Option(None, help="Limit lectures (useful for smoke tests)"),
    out: Optional[Path] = typer.Option(None),
) -> None:
    """Scrape one course: about + lecture overviews."""
    if source != "yale":
        raise typer.BadParameter("Only yale is implemented in v1")

    catalog_path = DATA / "yale" / "catalog.json"
    if catalog_path.exists():
        cat = Catalog.model_validate_json(catalog_path.read_text(encoding="utf-8"))
        match = next((c for c in cat.courses if c.path.strip("/") == slug.strip("/")), None)
    else:
        match = None

    if match is None:
        # Minimal stub from slug
        number = slug.split("/")[-1].upper().replace("-", " ")
        match = CourseRecord(
            id=f"yale:{slug.split('/')[-1]}",
            source="yale",
            department="",
            number=number,
            title=number,
            professor="",
            path=f"/{slug.strip('/')}",
            url=f"https://oyc.yale.edu/{slug.strip('/')}",
        )

    with YaleOYCClient() as client:
        enriched = client.enrich_course(match, max_lectures=max_lectures)

    out_path = out or DATA / "yale" / "courses" / f"{enriched.id.replace(':', '_')}.json"
    save_json(enriched, out_path)
    console.print(f"[bold]{len(enriched.lectures)}[/bold] lectures with overviews")


@app.command()
def bites(
    course_id: str = typer.Option(..., help="e.g. yale:phil-176"),
    course_file: Optional[Path] = typer.Option(None),
    out: Optional[Path] = typer.Option(None),
) -> None:
    """Build bite + quiz packs from a scraped course JSON."""
    path = course_file or DATA / "yale" / "courses" / f"{course_id.replace(':', '_')}.json"
    if not path.exists():
        raise typer.BadParameter(f"Missing course file: {path}")
    course = CourseRecord.model_validate_json(path.read_text(encoding="utf-8"))
    pack = build_bite_pack(course)
    out_path = out or DATA / "bites" / f"{course_id.replace(':', '_')}.json"
    save_json(pack, out_path)
    console.print(f"[bold]{len(pack.bites)}[/bold] bites · [bold]{len(pack.quizzes)}[/bold] quizzes")


@app.command("export-ios")
def export_ios(
    bites_file: Path = typer.Option(...),
    out: Path = typer.Option(Path(__file__).resolve().parents[2] / "ios" / "ABit" / "Resources" / "SampleBites.json"),
) -> None:
    """Copy a bite pack into the iOS sample bundle path."""
    data = json.loads(bites_file.read_text(encoding="utf-8"))
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2), encoding="utf-8")
    console.print(f"[green]Exported[/green] {out}")


def main() -> None:
    app()


if __name__ == "__main__":
    main()
