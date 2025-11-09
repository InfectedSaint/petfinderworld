from PIL import Image, ImageOps, ImageDraw
from PIL.Image import Resampling
from pathlib import Path
import sys, os
from math import sqrt

def parse_hex_rgb(s: str):
    s = s.strip().lstrip("#")
    if len(s) == 3:
        s = "".join(ch * 2 for ch in s)
    if len(s) != 6:
        raise ValueError("HEX color must be like #ff00ff or #f0f")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))

def rgb_dist2(a, b):
    dr = a[0]-b[0]; dg = a[1]-b[1]; db = a[2]-b[2]
    return dr*dr + dg*dg + db*db

# --- CLI args ---
# Usage:
#   python tools/make_icons.py "<source_image>" [outdir] [key_hex] [tolerance]
# Example:
#   python tools/make_icons.py "C:\Users\comal\source\repos\PetPageMaker\dog face\oscar_ico.png" assets/icons #ff00ff 80

src       = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("oscar.png")
outdir    = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("assets/icons")
key_hex   = sys.argv[3] if len(sys.argv) > 3 else "#ff00ff"  # magenta
tolerance = float(sys.argv[4]) if len(sys.argv) > 4 else 80.0

key_rgb = parse_hex_rgb(key_hex)
thr2 = tolerance * tolerance

outdir.mkdir(parents=True, exist_ok=True)

img = Image.open(src).convert("RGBA")
w, h = img.size
px = img.load()

# Chroma key (feathered): remove pixels near key color
for y in range(h):
    for x in range(w):
        r, g, b, a = px[x, y]
        d2 = rgb_dist2((r, g, b), key_rgb)
        if d2 <= thr2:
            dist = sqrt(d2)
            factor = max(0.0, min(1.0, dist / tolerance))  # 0 near key → 1 at threshold
            px[x, y] = (r, g, b, int(a * factor))

# Square center-crop → circle mask
size = min(w, h)
img_sq = ImageOps.fit(img, (size, size), centering=(0.5, 0.5))
mask = Image.new("L", (size, size), 0)
ImageDraw.Draw(mask).ellipse((0, 0, size, size), fill=255)

icon_rgba = Image.new("RGBA", (size, size), (0, 0, 0, 0))
icon_rgba.paste(img_sq, (0, 0), mask)

# PNG set
sizes = [256, 128, 64, 48, 32, 16]
for s in sizes:
    out_path = outdir / f"oscar_icon_{s}.png"
    icon_rgba.resize((s, s), Resampling.LANCZOS).save(out_path, "PNG")

# ICO (multi-size)
ico_path = outdir / "oscar_icon.ico"
icon_rgba.save(ico_path, format="ICO", sizes=[(s, s) for s in sizes])

print(f"✅ Icon pack created in {outdir}")
print(f"   Keyed color: {key_hex}  tolerance: {tolerance}")
print(f"   Source: {src}")
