"""Tekstur efek (partikel, serat kertas) dan efek suara tambahan untuk VITAMOVE v2.

Semua gambar berukuran kecil (<= 256 px) dan dibuat prosedural.
"""
import math
import os
import random
import struct
import wave

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
FX = os.path.join(ROOT, "assets", "fx")
AUDIO = os.path.join(ROOT, "assets", "audio")
os.makedirs(FX, exist_ok=True)
os.makedirs(AUDIO, exist_ok=True)


def leaf(size=64):
    s = size * 4
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = []
    for i in range(41):
        t = i / 40
        x = s * (0.12 + 0.76 * t)
        y = s * 0.5 - math.sin(t * math.pi) * s * 0.26
        pts.append((x, y))
    for i in range(40, -1, -1):
        t = i / 40
        x = s * (0.12 + 0.76 * t)
        y = s * 0.5 + math.sin(t * math.pi) * s * 0.26
        pts.append((x, y))
    d.polygon(pts, fill=(255, 255, 255, 255))
    d.line([(s * 0.08, s * 0.5), (s * 0.86, s * 0.5)], fill=(205, 205, 205, 255), width=int(s * 0.04))
    return img.resize((size, size), Image.LANCZOS)


def confetti(size=24):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([2, 6, size - 3, size - 7], radius=3, fill=(255, 255, 255, 255))
    return img


def sparkle(size=64):
    s = size * 4
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = s / 2
    pts = []
    for i in range(8):
        a = i * math.pi / 4 - math.pi / 2
        r = s * 0.48 if i % 2 == 0 else s * 0.13
        pts.append((c + math.cos(a) * r, c + math.sin(a) * r))
    d.polygon(pts, fill=(255, 255, 255, 255))
    return img.resize((size, size), Image.LANCZOS)


def soft_dot(size=64):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    c = (size - 1) / 2
    for y in range(size):
        for x in range(size):
            dist = math.hypot(x - c, y - c) / c
            a = max(0.0, 1.0 - dist) ** 1.6
            px[x, y] = (255, 255, 255, int(a * 255))
    return img


def paper_grain(size=256):
    random.seed(21)
    img = Image.new("L", (size, size), 128)
    px = img.load()
    for y in range(size):
        for x in range(size):
            px[x, y] = int(128 + random.gauss(0, 22))
    img = img.filter(ImageFilter.GaussianBlur(0.6))
    # serat panjang
    d = ImageDraw.Draw(img)
    for _ in range(90):
        x = random.uniform(0, size)
        y = random.uniform(0, size)
        a = random.uniform(0, math.pi)
        ln = random.uniform(6, 22)
        v = random.choice([96, 160])
        d.line([(x, y), (x + math.cos(a) * ln, y + math.sin(a) * ln)], fill=v, width=1)
    out = Image.new("RGBA", (size, size))
    op = out.load()
    gp = img.load()
    for y in range(size):
        for x in range(size):
            v = gp[x, y]
            if v >= 128:
                op[x, y] = (255, 255, 255, min(255, int((v - 128) * 1.1)))
            else:
                op[x, y] = (60, 40, 20, min(255, int((128 - v) * 1.1)))
    return out


# ------------------------------------------------------------------ audio
SR = 22050


def write(name, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 0.8 / peak
    with wave.open(os.path.join(AUDIO, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * gain)) * 32767)) for s in samples))


def tone(freq, dur, decay=8.0, partials=((1, 1.0), (2.0, 0.25), (3.0, 0.08))):
    n = int(dur * SR)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t) * min(1.0, t * 300)
        out.append(env * sum(a * math.sin(2 * math.pi * freq * r * t) for r, a in partials))
    return out


def mix(a, b, offset):
    n = max(len(a), offset + len(b))
    out = a + [0.0] * (n - len(a))
    for i, s in enumerate(b):
        out[offset + i] += s
    return out


def noise_sweep(dur, f0, f1, amp=1.0, seed=3):
    random.seed(seed)
    n = int(dur * SR)
    out = []
    lp = 0.0
    for i in range(n):
        p = i / n
        k = f0 + (f1 - f0) * p
        lp += k * (random.uniform(-1, 1) - lp)
        env = math.sin(math.pi * p) ** 1.3
        out.append(lp * env * amp)
    return out


def pop():
    n = int(0.12 * SR)
    out = []
    for i in range(n):
        t = i / SR
        f = 900 - 3000 * t
        out.append(math.sin(2 * math.pi * f * t) * math.exp(-30 * t))
    return out


def page():
    a = noise_sweep(0.22, 0.25, 0.05, 1.0, 5)
    return a


def whoosh():
    return noise_sweep(0.45, 0.02, 0.12, 1.0, 8)


def cheer():
    base = 293.0 * 2
    ratios = [1.0, 1.149, 1.320, 1.516, 1.741, 2.0]
    out = [0.0] * int(1.6 * SR)
    for k, r in enumerate([0, 2, 3, 4, 5, 4, 5]):
        out = mix(out, tone(base * ratios[r], 0.6, 5.0), int(k * 0.085 * SR))
    out = mix(out, tone(base * 2, 1.0, 3.0), int(0.6 * SR))
    return out


if __name__ == "__main__":
    leaf().save(os.path.join(FX, "leaf.png"))
    confetti().save(os.path.join(FX, "confetti.png"))
    sparkle().save(os.path.join(FX, "sparkle.png"))
    soft_dot().save(os.path.join(FX, "soft_dot.png"))
    paper_grain().save(os.path.join(FX, "paper_grain.png"))
    write("pop.wav", pop())
    write("page.wav", page())
    write("whoosh.wav", whoosh())
    write("cheer.wav", cheer())
    print("ok")


# ------------------------------------------------------------------ suara splash
def gong():
    """Gong ageng lembut: nada rendah dengan parsial inharmonik dan peluruhan panjang."""
    base = 293.0 / 4
    out = [0.0] * int(4.2 * SR)
    partials = ((1.0, 1.0), (1.48, 0.42), (2.05, 0.26), (2.78, 0.16), (3.9, 0.08))
    n = len(out)
    for i in range(n):
        t = i / SR
        env = math.exp(-0.95 * t) * min(1.0, t * 160)
        s = 0.0
        for r, a in partials:
            s += a * math.sin(2 * math.pi * base * r * t + 0.4 * math.sin(2 * math.pi * 1.7 * t))
        out[i] = s * env
    # desir pukulan di awal
    random.seed(11)
    lp = 0.0
    for i in range(int(0.12 * SR)):
        lp += 0.08 * (random.uniform(-1, 1) - lp)
        out[i] += lp * 0.5 * math.exp(-28 * i / SR)
    return out


def chirp():
    """Kicau jalak: dua siulan naik yang singkat."""
    out = [0.0] * int(0.55 * SR)
    for k, (t0, f0, f1, dur) in enumerate([(0.0, 1500, 2600, 0.11), (0.17, 1800, 3100, 0.13), (0.37, 1600, 2300, 0.09)]):
        n = int(dur * SR)
        for i in range(n):
            t = i / SR
            p = i / n
            f = f0 + (f1 - f0) * p
            env = math.sin(math.pi * p) ** 1.2
            j = int(t0 * SR) + i
            if j < len(out):
                out[j] += math.sin(2 * math.pi * f * t) * env * 0.8
    return out


if True:
    write("gong.wav", gong())
    write("chirp.wav", chirp())
    print("ok splash sounds")
