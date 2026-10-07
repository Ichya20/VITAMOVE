"""Membuat ikon aplikasi dan gambar splash VITAMOVE (semua < 2000 px)."""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
FONT = os.path.join(ROOT, "assets", "fonts", "LilitaOne-Regular.ttf")
TEAL = (15, 76, 74)
TEAL2 = (31, 111, 106)
TERRA = (200, 85, 61)
SAFFRON = (242, 177, 52)
CREAM = (255, 246, 229)
LEAF = (79, 138, 60)
LEAF2 = (140, 192, 99)


def figure(d, cx, base, s, col):
    # lansia mengangkat tangan (siluet sederhana)
    head_r = 34 * s
    d.ellipse([cx - head_r, base - 330 * s, cx + head_r, base - 262 * s], fill=col)
    d.polygon([(cx - 50 * s, base - 250 * s), (cx + 50 * s, base - 250 * s), (cx + 40 * s, base - 110 * s), (cx - 40 * s, base - 110 * s)], fill=col)
    w = int(26 * s)
    d.line([(cx - 44 * s, base - 240 * s), (cx - 120 * s, base - 360 * s)], fill=col, width=w)
    d.line([(cx + 44 * s, base - 240 * s), (cx + 120 * s, base - 360 * s)], fill=col, width=w)
    for x in (cx - 120 * s, cx + 120 * s):
        d.ellipse([x - 16 * s, base - 376 * s, x + 16 * s, base - 344 * s], fill=col)
    d.line([(cx - 22 * s, base - 120 * s), (cx - 34 * s, base)], fill=col, width=int(30 * s))
    d.line([(cx + 22 * s, base - 120 * s), (cx + 34 * s, base)], fill=col, width=int(30 * s))


def icon(size=512):
    sc = 4
    S = size * sc
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    r = int(S * 0.22)
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=r, fill=TEAL)
    # matahari
    d.ellipse([S * 0.18, S * 0.12, S * 0.82, S * 0.76], fill=SAFFRON)
    # bukit berlapis
    d.ellipse([-S * 0.3, S * 0.62, S * 0.9, S * 1.4], fill=LEAF2)
    d.ellipse([S * 0.25, S * 0.68, S * 1.4, S * 1.5], fill=LEAF)
    figure(d, S * 0.5, S * 0.86, S / 512 * 1.05, CREAM)
    # daun
    d.ellipse([S * 0.66, S * 0.16, S * 0.86, S * 0.3], fill=LEAF2)
    img = img.resize((size, size), Image.LANCZOS)
    # sudut membulat ikut terpotong; pastikan sudut transparan tetap rapi
    return img


def splash():
    W, H = 900, 420
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ic = icon(220)
    img.paste(ic, (40, 100), ic)
    f = ImageFont.truetype(FONT, 132)
    d.text((290, 120), "VITA", font=f, fill=CREAM)
    w = d.textlength("VITA", font=f)
    d.text((290 + w, 120), "MOVE", font=f, fill=SAFFRON)
    f2 = ImageFont.truetype(FONT, 40)
    d.text((294, 268), "Jelajah Sehat Desa", font=f2, fill=CREAM)
    return img


if __name__ == "__main__":
    os.makedirs(os.path.join(ROOT, "assets"), exist_ok=True)
    icon(512).save(os.path.join(ROOT, "icon.png"))
    icon(192).save(os.path.join(ROOT, "assets", "icon_192.png"))
    # ikon adaptif Android: latar dan latar depan terpisah (432 px)
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    inner = icon(300)
    fg.paste(inner, (66, 66), inner)
    fg.save(os.path.join(ROOT, "assets", "icon_adaptive_fg.png"))
    Image.new("RGBA", (432, 432), TEAL + (255,)).save(os.path.join(ROOT, "assets", "icon_adaptive_bg.png"))
    splash().save(os.path.join(ROOT, "assets", "splash.png"))
    print("ok")
