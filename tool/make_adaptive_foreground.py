"""Build an Android adaptive-icon foreground from the app icon.

Takes assets/icon/app_icon.png (artwork on a solid red rounded-rect) and
produces assets/icon/app_icon_foreground.png: the mannequin + leaf on a fully
transparent background, centered inside the adaptive-icon safe zone so Android's
launcher mask never clips the artwork.

The red background is removed by color-keying (any pixel close to the sampled
background red becomes transparent), then the remaining opaque content is
trimmed to its bounding box and scaled to ~62% of the canvas (leaving the ~25%
safe-zone margin the adaptive-icon spec reserves on every side).
"""

from PIL import Image

SRC = "assets/icon/app_icon.png"
DST = "assets/icon/app_icon_foreground.png"

# Fraction of the canvas the artwork should occupy (adaptive icons clip the
# outer ~1/4 on each edge for round/squircle masks). Lowered from 0.62 to 0.52
# to add a bit of breathing room so the mannequin no longer touches the circle.
CONTENT_SCALE = 0.52
# Color-key tolerance: squared-distance threshold from the background color.
TOLERANCE = 60  # per-channel-ish; compared against max channel delta


def main() -> None:
    im = Image.open(SRC).convert("RGBA")
    w, h = im.size

    # Sample the background color from a corner (well inside the rounded rect
    # edge so we hit the solid red, not the transparent rounding).
    bg = im.getpixel((int(w * 0.06), int(h * 0.5)))
    br, bgc, bb = bg[0], bg[1], bg[2]

    px = im.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            # Max per-channel distance from the background red.
            if max(abs(r - br), abs(g - bgc), abs(b - bb)) <= TOLERANCE:
                px[x, y] = (r, g, b, 0)

    # Trim to the bounding box of the remaining (artwork) pixels.
    bbox = im.getbbox()
    if bbox is None:
        raise SystemExit("No foreground content found after keying; aborting.")
    art = im.crop(bbox)

    # Compose onto a square transparent canvas at CONTENT_SCALE.
    canvas_size = max(w, h)
    target = int(canvas_size * CONTENT_SCALE)
    aw, ah = art.size
    scale = target / max(aw, ah)
    new_size = (max(1, int(aw * scale)), max(1, int(ah * scale)))
    art = art.resize(new_size, Image.LANCZOS)

    out = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    ox = (canvas_size - art.size[0]) // 2
    oy = (canvas_size - art.size[1]) // 2
    out.paste(art, (ox, oy), art)
    out.save(DST)
    print(f"Wrote {DST} ({out.size[0]}x{out.size[1]}), bg key = {bg}")


if __name__ == "__main__":
    main()
