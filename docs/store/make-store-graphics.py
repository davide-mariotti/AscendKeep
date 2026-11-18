"""Play Store graphics for AscendKeep, built from the game's own assets.

- icon-512.png      512x512, the illustrated tower icon, full square (Google rounds the corners itself)
- feature-1024x500.png  the Keep artwork on the right, name and tagline on the left

Needs Chrome (renders the HTML) and Pillow. Run from the repo root: python docs/store/make-store-graphics.py
"""
import base64, pathlib, subprocess, tempfile
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).parent
CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"


def b64(path):
    return base64.b64encode(pathlib.Path(path).read_bytes()).decode()


def shot(html, w, h, out):
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp, "p.html")
        page.write_text(html, encoding="utf-8")
        png = pathlib.Path(tmp, "s.png")
        subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        f"--user-data-dir={tmp}/profile", f"--window-size={w},{h}", "--virtual-time-budget=4000",
                        f"--screenshot={png}", page.as_uri()], check=True, capture_output=True)
        Image.open(png).convert("RGB").crop((0, 0, w, h)).save(out, optimize=True)


# icon: the game's own illustrated icon
Image.open(ROOT / "docs/art-source/icon-1024.png").convert("RGB").resize((512, 512), Image.LANCZOS).save(HERE / "icon-512.png", optimize=True)

# feature graphic
splash = b64(ROOT / "docs/art-source/home-splash.png")
logo = b64(ROOT / "assets/art/logo.png")
feature = f'''<!doctype html><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Geist:wght@400;600&display=block" rel="stylesheet">
<style>
  * {{ margin: 0; box-sizing: border-box; }}
  body {{ width: 1024px; height: 500px; overflow: hidden; position: relative; font-family: Geist, sans-serif;
         background: radial-gradient(circle at 75% 55%, #1d1446 0%, #0a0c18 55%, #05060c 100%); color: #eef2ff; }}
  .art {{ position: absolute; right: -40px; top: -150px; height: 820px; -webkit-mask-image: radial-gradient(ellipse 55% 50% at 50% 52%, #000 45%, transparent 75%); }}
  .glow {{ position: absolute; right: 120px; top: 120px; width: 360px; height: 360px; border-radius: 50%; background: rgba(91,33,182,.35); filter: blur(90px); }}
  .txt {{ position: absolute; left: 64px; top: 50%; transform: translateY(-50%); width: 470px; }}
  .logo {{ width: 420px; filter: drop-shadow(0 6px 24px rgba(0,0,0,.6)); }}
  p {{ margin-top: 26px; font-size: 30px; line-height: 1.25; letter-spacing: -.01em; color: #c9d1e6; }}
  p b {{ color: #fff; font-weight: 600; }}
</style>
<div class="glow"></div><img class="art" src="data:image/png;base64,{splash}">
<div class="txt"><img class="logo" src="data:image/png;base64,{logo}"><p>A tower defense where <b>losing is part of the plan.</b></p></div>'''
shot(feature, 1024, 500, HERE / "feature-1024x500.png")
print("store graphics ok")
