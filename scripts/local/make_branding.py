#!/usr/bin/env python3
"""Genera los PNG de marca de RPG-LBA desde el emblema oficial.

Fuente de verdad: assets/branding/rpg-lba-logo.svg (corona, arco de palmas y
ave de fuego del logotipo, SIN modificar sus trazos). Se rasterizan con
cairosvg, se componen con Pillow sobre fondos propios y se escriben:

  - assets/branding/boot_splash.png        (pantalla de arranque del motor)
  - assets/branding/icon_foreground.png    (adaptive foreground 432x432)
  - assets/branding/icon_background.png    (adaptive background 432x432)
  - assets/branding/icon_full_*.png        (launcher heredado 36..192)
  - icon.png                               (icono del proyecto)

Uso: python3 scripts/local/make_branding.py   (desde la raíz del proyecto)
"""
from __future__ import annotations

import math
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "assets" / "branding"
FONTS = ROOT / "assets" / "ui" / "fonts"

GOLD_LIGHT = (255, 240, 176)
GOLD = (201, 149, 67)
GOLD_DARK = (104, 64, 30)
INK = (11, 13, 18)
NIGHT = (16, 20, 28)
PANEL = (21, 24, 32)
BONE = (232, 210, 164)

# Solo los elementos graficos del emblema oficial (paths exactos del SVG).
EMBLEM_ELEMENTS_SVG = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 420">
<defs><linearGradient id="gold" x2="0" y2="1">
<stop stop-color="#fff0b0"/><stop offset=".45" stop-color="#c99543"/>
<stop offset="1" stop-color="#68401e"/></linearGradient>
<linearGradient id="red" x2="0" y2="1">
<stop stop-color="#ff704d"/><stop offset="1" stop-color="#690d18"/></linearGradient></defs>
<path d="M190 265 Q260 120 400 130 Q500 80 600 92 Q700 80 800 130 Q940 120 1010 265"
 fill="none" stroke="#47704d" stroke-width="20" stroke-linecap="round"/>
<path d="M420 152 L480 60 L545 125 L600 24 L655 125 L720 60 L780 152" fill="none"
 stroke="url(#gold)" stroke-width="13" stroke-linejoin="round"/>
<path d="M600 85 C525 92 500 160 535 205 C560 235 590 230 600 200 C610 230 640 235 665 205
 C700 160 675 92 600 85Z" fill="url(#red)" stroke="#e4a64b" stroke-width="5"/>
<path d="M600 105 C585 135 590 160 600 180 C610 160 615 135 600 105Z" fill="#ffe3a0"/>
</svg>
"""


def render_emblem() -> Image.Image:
    """Rasteriza corona + palmas + ave del logo oficial y recorta su caja."""
    png = cairosvg.svg2png(bytestring=EMBLEM_ELEMENTS_SVG.encode(), output_width=2400, output_height=840)
    import io

    image = Image.open(io.BytesIO(png)).convert("RGBA")
    bbox = image.getbbox()
    return image.crop(bbox)


def emblem_core(emblem: Image.Image) -> Image.Image:
    """Recorte cuadrado del corazon del emblema (corona + ave + palma central).

    Para iconos de 36/48 px, donde el arco completo queda en una linea ilegible.
    """
    w, h = emblem.size
    return emblem.crop((int(w * 0.28), 0, int(w * 0.71), h))


def cinzel(size: int, weight: int = 700, tracking: int = 0) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONTS / "Cinzel.ttf"), size)
    try:
        font.set_variation_by_axes([weight])
    except OSError:
        pass
    if tracking:
        font.tracking = tracking  # Pillow >= 9.2 soporta espaciado en getlength/draw
    return font


def draw_tracked(
    draw: ImageDraw.ImageDraw, xy, text: str, font, fill, tracking: int = 0, anchor_center: bool = True
) -> None:
    """Dibuja texto con espaciado manual (compatibel con fuentes variables)."""
    widths = [draw.textlength(ch, font=font) for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x, y = xy
    if anchor_center:
        x -= total / 2.0
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=font, fill=fill)
        x += w + tracking


def gold_gradient_text(size: tuple[int, int], text: str, font, tracking: int) -> Image.Image:
    """Texto con degradado vertical oro (como el emblema) sobre transparente."""
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw_tracked(draw, (size[0] / 2, size[1] / 2 - font.size / 2), text, font, 255, tracking)
    gradient = Image.new("RGBA", size)
    top, mid, bottom = GOLD_LIGHT, GOLD, GOLD_DARK
    for y in range(size[1]):
        t = y / max(size[1] - 1, 1)
        if t < 0.45:
            k = t / 0.45
            color = tuple(int(top[i] + (mid[i] - top[i]) * k) for i in range(3))
        else:
            k = (t - 0.45) / 0.55
            color = tuple(int(mid[i] + (bottom[i] - mid[i]) * k) for i in range(3))
        for x in range(size[0]):
            gradient.putpixel((x, y), color + (255,))
    gradient.putalpha(mask)
    return gradient


def vertical_gradient(size: tuple[int, int], top, bottom) -> Image.Image:
    image = Image.new("RGB", size)
    for y in range(size[1]):
        k = y / max(size[1] - 1, 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * k) for i in range(3))
        for x in range(size[0]):
            image.putpixel((x, y), color)
    return image


def radial_glow(size: tuple[int, int], color, alpha: float, reach: float = 0.5) -> Image.Image:
    w, h = size
    small = Image.new("L", (160, 160), 0)
    d = ImageDraw.Draw(small)
    cx, cy = 80, 80
    max_r = 80 * reach
    for r in range(int(max_r), 0, -1):
        a = int(alpha * 255 * (1 - r / max(max_r, 1)) ** 2)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=a)
    mask = small.resize((w, h), Image.LANCZOS)
    layer = Image.new("RGBA", (w, h), color + (0,))
    layer.putalpha(mask)
    return layer


def compose_icon(size: int, with_frame: bool = True) -> Image.Image:
    """Icono cuadrado completo: fondo, marco, motivo del emblema y tipografia.

    Layout adaptado al tamano: en 36/48 px el motivo domina (legibilidad del
    launcher); desde 96 px entra la composicion completa con subtitulo.
    """
    scale = size / 1200.0
    image = vertical_gradient((size, size), NIGHT, INK).convert("RGBA")
    # Halo calido detras del motivo (el "eco" de Valdeluz).
    glow = radial_glow((size, size), (255, 120, 60), 0.16, 0.62)
    image = Image.alpha_composite(image, glow)

    small = size < 96
    tiny = size < 72
    emblem = EMBLEM_CORE if tiny else EMBLEM
    # Motivo: dominante en iconos pequenos, ~63% del ancho en grandes.
    motif_w = int((900 if tiny else 760 if small else 760) * scale)
    motif_h = int(emblem.height * motif_w / emblem.width)
    motif = emblem.resize((motif_w, motif_h), Image.LANCZOS)
    motif_y = 240 if tiny else 190
    image.paste(motif, ((size - motif_w) // 2, int(motif_y * scale)), motif)

    draw = ImageDraw.Draw(image)
    if not tiny:
        # Titulo RPG LBA con degradado oro.
        title_size = int((200 if small else 168) * scale)
        font = cinzel(title_size, 700)
        track = int(6 * scale)
        title = gold_gradient_text((size, int(title_size * 1.35)), "RPG LBA", font, track)
        title_y = 520 if small else 560
        image.paste(title, (0, int(title_y * scale)), title)

    if not small:
        # Linea divisoria y subtitulo hueso.
        line_w = int(430 * scale)
        y_line = int(790 * scale)
        for offset in range(int(2 * scale) or 1):
            draw.line(
                [(size - line_w) // 2, y_line + offset, (size + line_w) // 2, y_line + offset],
                fill=GOLD_DARK + (220,),
            )
        sub_size = int(44 * scale)
        sub_font = cinzel(sub_size, 400)
        draw_tracked(
            draw,
            (size / 2, int(830 * scale)),
            "LAS CENIZAS DE LYTHARA",
            sub_font,
            BONE + (235,),
            int(3 * scale),
        )

    if with_frame and size >= 96:
        # Doble marco dorado del emblema, adaptado al cuadrado.
        margin = int(28 * scale)
        inner = int(52 * scale)
        draw.rounded_rectangle(
            [margin, margin, size - margin, size - margin], radius=int(56 * scale),
            outline=GOLD + (255,), width=max(int(10 * scale), 1),
        )
        draw.rounded_rectangle(
            [inner, inner, size - inner, size - inner], radius=int(40 * scale),
            outline=GOLD_DARK + (200,), width=max(int(4 * scale), 1),
        )
    return image


def make_adaptive_foreground(size: int = 432) -> Image.Image:
    """Foreground adaptativo: motivo + titulo DENTRO del circulo seguro (66%).

    La zona segura es un circulo de radio 33% centrado; las puntas anchas del
    arco de palmas se colocan cerca del centro vertical para no salir de el.
    """
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    emblem = EMBLEM
    motif_w = int(size * 0.42)
    motif_h = int(emblem.height * motif_w / emblem.width)
    motif = emblem.resize((motif_w, motif_h), Image.LANCZOS)
    motif_y = int(size * 0.28)
    image.paste(motif, ((size - motif_w) // 2, motif_y), motif)
    title_size = int(size * 0.13)
    font = cinzel(title_size, 700)
    track = int(size * 0.008)
    title = gold_gradient_text((size, int(title_size * 1.4)), "RPG LBA", font, track)
    image.paste(title, (0, int(size * 0.56)), title)
    return image


def make_adaptive_background(size: int = 432) -> Image.Image:
    image = vertical_gradient((size, size), NIGHT, INK).convert("RGBA")
    glow = radial_glow((size, size), (255, 120, 60), 0.10, 0.7)
    return Image.alpha_composite(image, glow)


def make_boot_splash(width: int = 1024, height: int = 512) -> Image.Image:
    image = vertical_gradient((width, height), INK, NIGHT).convert("RGBA")
    glow = radial_glow((width, height), (255, 120, 60), 0.14, 0.55)
    image = Image.alpha_composite(image, glow)
    emblem = EMBLEM
    motif_w = int(width * 0.52)
    motif_h = int(emblem.height * motif_w / emblem.width)
    motif = emblem.resize((motif_w, motif_h), Image.LANCZOS)
    image.paste(motif, ((width - motif_w) // 2, int(height * 0.16)), motif)
    draw = ImageDraw.Draw(image)
    title_size = int(height * 0.11)
    font = cinzel(title_size, 700)
    draw_tracked(
        draw, (width / 2, height * 0.66), "LAS CENIZAS DE LYTHARA", font, BONE + (240,), int(title_size * 0.10)
    )
    sub = cinzel(int(height * 0.05), 400)
    draw_tracked(
        draw, (width / 2, height * 0.84), "CUBA · 1953", sub, (189, 135, 80, 255), int(height * 0.02)
    )
    return image


if __name__ == "__main__":
    EMBLEM = render_emblem()
    EMBLEM_CORE = emblem_core(EMBLEM)
    print(f"emblema renderizado: {EMBLEM.size} (nucleo: {EMBLEM_CORE.size})")

    splash = make_boot_splash()
    splash.save(BRAND / "boot_splash.png")
    print("boot_splash.png", splash.size)

    fg = make_adaptive_foreground()
    fg.save(BRAND / "icon_foreground.png")
    bg = make_adaptive_background()
    bg.save(BRAND / "icon_background.png")
    print("adaptive fg/bg", fg.size, bg.size)

    for legacy in (36, 48, 72, 96, 144, 192):
        icon = compose_icon(legacy)
        icon.save(BRAND / f"icon_full_{legacy}.png")
    print("iconos heredados 36..192")

    full = compose_icon(256, with_frame=True)
    full.save(ROOT / "icon.png")
    print("icon.png del proyecto", full.size)
