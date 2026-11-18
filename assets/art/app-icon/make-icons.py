"""Builds AscendKeep's app icon and the Android adaptive-icon layers from the illustrated tower.

Sources (not packed in the game, docs/ is ignored by Godot):
- docs/art-source/icon-1024.png         the full icon, tower on its dark background
- docs/art-source/tower-transparent.png the same tower alone, transparent background

Outputs, next to this script:
- icon.png                 512, launcher icon for old Android and the project icon
- adaptive-foreground.png  432, the tower: crown inside the 66% safe zone, base running off the bottom like the full icon
- adaptive-background.png  432, the dark backdrop with a soft cyan glow behind the core
- adaptive-monochrome.png  432, white silhouette for themed icons (Android 13+)

The site uses a different, Lucide-style icon (same family as the other apps): this one is the game's own.
Needs Pillow. Run from the repo root: python assets/art/app-icon/make-icons.py
"""
import pathlib
from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parents[3]
HERE = pathlib.Path(__file__).parent
SRC = ROOT / "docs/art-source"
N = 432                # adaptive layer size
SAFE_TOP = 100         # crown top: inside the 264 px safe circle centred in the layer

Image.open(SRC / "icon-1024.png").convert("RGB").resize((512, 512), Image.LANCZOS).save(HERE / "icon.png", optimize=True)

tower = Image.open(SRC / "tower-transparent.png").convert("RGBA")
tower = tower.crop(tower.getbbox())
scale = (N - SAFE_TOP) / tower.height
tower = tower.resize((round(tower.width * scale), N - SAFE_TOP), Image.LANCZOS)
fg = Image.new("RGBA", (N, N), (0, 0, 0, 0))
fg.alpha_composite(tower, ((N - tower.width) // 2, SAFE_TOP))
fg.save(HERE / "adaptive-foreground.png", optimize=True)

# Background: the icon's navy, lighter in the middle, plus a blurred cyan glow where the core sits.
bg = Image.new("RGB", (N, N), (13, 17, 28))
glow = Image.new("L", (N, N), 0)
ImageDraw.Draw(glow).ellipse((N * 0.18, N * 0.12, N * 0.82, N * 0.76), fill=255)
glow = glow.filter(ImageFilter.GaussianBlur(N * 0.12))
bg = Image.composite(Image.new("RGB", (N, N), (24, 46, 62)), bg, glow)
bg.save(HERE / "adaptive-background.png", optimize=True)

mono = Image.new("RGBA", (N, N), (255, 255, 255, 0))
mono.putalpha(fg.getchannel("A"))
mono.save(HERE / "adaptive-monochrome.png", optimize=True)
print("app icon ok")
