#!/usr/bin/env python3
"""Build Sprout Focus launcher icons from the AI-generated source artwork.

iOS and legacy Android use sprout_logo_source.png as-is -- neither crops hard
enough to need padding, and using the original avoids resampling the artwork.

Android adaptive icons do need rebuilding: the source puts the phone at 79% of
the canvas height, well outside the region adaptive masks guarantee. This
script lifts the phone off its background and recomposites it at a safe size
over a regenerated gradient, emitting the foreground/background pair.

Run:  python3 branding/build_icons.py
"""
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).parent
SRC = HERE / "sprout_logo_source.png"
CANVAS = 1024

# Phone silhouette inside the source image, measured by scanning for the white
# body. It is a plain rounded rect, so a generated mask gives cleaner edges
# than colour-keying (no green fringe from the antialiased border).
PHONE_BOX = (281, 105, 743, 919)  # left, top, right, bottom
PHONE_RADIUS = 58

# Background gradient sampled from the source image's top and bottom corners.
GRAD_TOP = (106, 183, 92)
GRAD_BOTTOM = (36, 135, 80)

# The adaptive foreground is bound by a tighter rule: Android guarantees the
# inscribed CIRCLE of the centre 66%, not the square. This phone is tall
# (aspect 0.57), so a square-fitting size still loses its corners under a
# circular mask and degrades into a plain white bar. 0.595 is the largest
# fill whose rounded corners stay inside that circle -- see assert_fits().
ADAPTIVE_FILL = 0.595


def gradient() -> Image.Image:
    """Vertical gradient matching the source artwork's background."""
    g = Image.new("RGB", (1, CANVAS))
    for y in range(CANVAS):
        t = y / (CANVAS - 1)
        g.putpixel(
            (0, y),
            tuple(round(a + (b - a) * t) for a, b in zip(GRAD_TOP, GRAD_BOTTOM)),
        )
    return g.resize((CANVAS, CANVAS), Image.NEAREST).convert("RGBA")


def phone() -> Image.Image:
    """The phone lifted off its background, with a clean rounded-rect alpha."""
    crop = Image.open(SRC).convert("RGBA").crop(PHONE_BOX)
    mask = Image.new("L", crop.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, crop.size[0] - 1, crop.size[1] - 1], radius=PHONE_RADIUS, fill=255
    )
    crop.putalpha(mask)
    return crop


def place(subject: Image.Image, fill: float, background: Image.Image | None):
    """Scale the subject to `fill` of the canvas height and centre it."""
    h = round(CANVAS * fill)
    w = round(subject.size[0] * h / subject.size[1])
    scaled = subject.resize((w, h), Image.LANCZOS)
    out = background.copy() if background else Image.new(
        "RGBA", (CANVAS, CANVAS), (0, 0, 0, 0)
    )
    out.paste(scaled, ((CANVAS - w) // 2, (CANVAS - h) // 2), scaled)
    return out


def assert_fits(subject: Image.Image) -> None:
    """Fail loudly if the adaptive foreground would clip under a circle mask.

    Measures the rounded rect's furthest corner from centre and compares it to
    the radius of the guaranteed circle, so tweaking ADAPTIVE_FILL or swapping
    the source artwork cannot silently reintroduce the clipping.
    """
    h = CANVAS * ADAPTIVE_FILL
    scale = h / subject.size[1]
    half_w, half_h = subject.size[0] * scale / 2, h / 2
    r = PHONE_RADIUS * scale
    corner = ((half_w - r) ** 2 + (half_h - r) ** 2) ** 0.5 + r
    safe_r = CANVAS * 0.66 / 2
    if corner > safe_r:
        raise SystemExit(
            f"adaptive foreground clips: corner at {corner:.0f}px exceeds the "
            f"{safe_r:.0f}px safe radius. Lower ADAPTIVE_FILL."
        )
    print(f"circle check: corner {corner:.0f}px / {safe_r:.0f}px safe radius")


if __name__ == "__main__":
    bg, subject = gradient(), phone()
    assert_fits(subject)
    outputs = {
        "sprout_logo_v4_foreground.png": place(subject, ADAPTIVE_FILL, None),
        "sprout_logo_v4_background.png": bg,
    }
    for name, img in outputs.items():
        img.convert("RGBA").save(HERE / name)
        print("wrote", name)
