from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "icons"
SIZE = 512
SCALE = 3


def main() -> None:
    size = SIZE * SCALE
    background = Image.new("RGB", (size, size))
    pixels = background.load()
    for y in range(size):
        for x in range(size):
            progress = (x + y) / (2 * (size - 1))
            pixels[x, y] = (
                round(48 - 25 * progress),
                round(32 - 8 * progress),
                round(79 - 40 * progress),
            )

    mask = Image.new("L", (size, size))
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=118 * SCALE, fill=255
    )
    background.putalpha(mask)

    bolt_mask = Image.new("L", (size, size))
    points = [(304, 83), (157, 275), (256, 275), (208, 429), (356, 225), (257, 225)]
    ImageDraw.Draw(bolt_mask).polygon(
        [(x * SCALE, y * SCALE) for x, y in points], fill=255
    )

    bolt = Image.new("RGBA", (size, size))
    bolt_pixels = bolt.load()
    bolt_mask_pixels = bolt_mask.load()
    for y in range(size):
        progress = y / (size - 1)
        color = (
            round(255 - 88 * progress),
            255,
            round(255 - 47 * progress),
            255,
        )
        for x in range(size):
            if bolt_mask_pixels[x, y]:
                bolt_pixels[x, y] = color

    background = background.convert("RGBA")
    background.alpha_composite(bolt)

    draw = ImageDraw.Draw(background)
    draw.ellipse(
        (368 * SCALE, 111 * SCALE, 396 * SCALE, 139 * SCALE),
        fill="#10b981",
    )

    OUTPUT.mkdir(parents=True, exist_ok=True)
    icon = background.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    icon.save(OUTPUT / "bolt.png", optimize=True)
    icon.save(
        ROOT / "windows" / "runner" / "resources" / "app_icon.ico",
        format="ICO",
        sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)],
    )


if __name__ == "__main__":
    main()
