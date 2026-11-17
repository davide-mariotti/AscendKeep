"""Builds AscendKeep's app icon from the dm. app-icon template (same family as Sentinel and my site).

Template: 512 rounded square (rx 112), one Lucide glyph in white (here "castle", Lucide 1.74.0, ISC),
the app's own colour (void violet #5b21b6), the dm. dot in the corner.
Also writes the three Android adaptive-icon layers (432 px, glyph inside the 66% safe zone).

Needs Chrome (renders the SVG) and Pillow. Run from the repo root: python assets/art/app-icon/make-icons.py
"""
import base64, pathlib, subprocess, tempfile
from PIL import Image

HERE = pathlib.Path(__file__).parent
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
COLOR = "#5b21b6"
CASTLE = ('<path d="M10 5V3"/><path d="M14 5V3"/><path d="M15 21v-3a3 3 0 0 0-6 0v3"/><path d="M18 3v8"/>'
          '<path d="M18 5H6"/><path d="M22 11H2"/><path d="M22 9v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9"/><path d="M6 3v8"/>')
DOT = '<circle cx="432" cy="432" r="20" fill="#020402"/>'


def glyph(box, stroke, size=512):
    off = (size - box) / 2
    return (f'<g transform="translate({off} {off}) scale({box / 24})" fill="none" stroke="#fff" '
            f'stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round">{CASTLE}</g>')


def svg(inner, size=512):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}">{inner}</svg>'


ICON = svg(f'<rect width="512" height="512" rx="112" fill="{COLOR}"/>{glyph(300, 2.3)}{DOT}')
# adaptive layers, 432 px canvas: the launcher crops to a circle/squircle of ~66%, so the glyph stays inside ~200 px
FOREGROUND = svg(glyph(196, 2.5, 432), 432)
BACKGROUND = svg(f'<rect width="432" height="432" fill="{COLOR}"/>', 432)
MONOCHROME = FOREGROUND


def render(jobs):
    """jobs: list of (svg, px) -> RGBA images, one Chrome screenshot for all."""
    x, cells = 0, []
    for s, px in jobs:
        cells.append(f'<img style="position:absolute;left:{x}px;top:0;width:{px}px;height:{px}px" '
                     f'src="data:image/svg+xml;base64,{base64.b64encode(s.encode()).decode()}">')
        x += px + 8
    with tempfile.TemporaryDirectory() as tmp:
        page, shot = pathlib.Path(tmp, "p.html"), pathlib.Path(tmp, "s.png")
        page.write_text(f'<body style="margin:0;background:transparent">{"".join(cells)}</body>', encoding="utf-8")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        "--default-background-color=00000000", f"--user-data-dir={tmp}/profile",
                        f"--window-size={x},{max(p for _, p in jobs)}", f"--screenshot={shot}", page.as_uri()],
                       check=True, capture_output=True)
        sheet = Image.open(shot).convert("RGBA")
        out, x = [], 0
        for _, px in jobs:
            out.append(sheet.crop((x, 0, x + px, px)))
            x += px + 8
        return out


(HERE / "icon.svg").write_text(ICON, encoding="utf-8")
icon, fg, bg, mono = render([(ICON, 512), (FOREGROUND, 432), (BACKGROUND, 432), (MONOCHROME, 432)])
icon.save(HERE / "icon.png")
fg.save(HERE / "adaptive-foreground.png")
bg.save(HERE / "adaptive-background.png")
mono.save(HERE / "adaptive-monochrome.png")
print("icons ok")
