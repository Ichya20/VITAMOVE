"""Membuat aset audio VITAMOVE secara prosedural (tanpa sampel berhak cipta).

Nuansa gamelan sederhana: nada slendro dengan parsial inharmonik dan peluruhan lembut.
"""
import math
import random
import struct
import wave
import os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)


def write(name, samples, sr=SR):
    peak = max(1e-9, max(abs(s) for s in samples))
    gain = 0.85 / peak
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        frames = bytearray()
        for s in samples:
            v = int(max(-1.0, min(1.0, s * gain)) * 32767)
            frames += struct.pack("<h", v)
        w.writeframes(bytes(frames))


def metal(freq, dur, amp=1.0, decay=3.0, partials=((1, 1.0), (2.76, 0.35), (5.40, 0.12))):
    n = int(dur * SR)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t) * min(1.0, t * 400)
        s = 0.0
        for ratio, a in partials:
            s += a * math.sin(2 * math.pi * freq * ratio * t) * math.exp(-decay * (ratio - 1) * 0.35 * t)
        out[i] = s * env * amp
    return out


def mix_into(buf, src, start, wrap=False):
    n = len(buf)
    for i, s in enumerate(src):
        j = start + i
        if j >= n:
            if not wrap:
                break
            j %= n
        buf[j] += s


def silence(sec):
    return [0.0] * int(sec * SR)


# Slendro kira-kira (rasio dari nada dasar)
SLENDRO = [1.0, 1.149, 1.320, 1.516, 1.741, 2.0, 2.297, 2.640]
BASE = 293.0


def note(idx):
    return BASE * SLENDRO[idx]


def bgm():
    bpm = 72
    beat = 60.0 / bpm
    bars = 16
    total = int(bars * 4 * beat * SR)
    buf = [0.0] * total
    melody = [
        0, 2, 3, 2, 4, 3, 2, 1,
        2, 3, 4, 5, 4, 3, 2, 3,
        5, 4, 3, 2, 3, 2, 1, 0,
        1, 2, 3, 4, 3, 2, 1, 0,
    ]
    # saron (melodi) tiap setengah ketukan pada paruh kedua
    for i, m in enumerate(melody * 2):
        t = i * beat
        mix_into(buf, metal(note(m), 1.6, 0.30, 2.6), int(t * SR), wrap=True)
    # bonang pola imbal lembut
    for i in range(bars * 4 * 2):
        if i % 2 == 1:
            m = melody[(i // 2) % len(melody)]
            mix_into(buf, metal(note(min(7, m + 2)), 0.6, 0.12, 6.0), int(i * beat / 2 * SR), wrap=True)
    # kempul tiap 4 ketukan dan gong tiap 16 ketukan
    for b in range(bars):
        t = b * 4 * beat
        if b % 4 == 0:
            mix_into(buf, metal(BASE / 4, 6.0, 0.55, 0.6, ((1, 1.0), (1.5, 0.2), (2.0, 0.3))), int(t * SR), wrap=True)
        else:
            mix_into(buf, metal(BASE / 2 * SLENDRO[(b * 2) % 5], 2.5, 0.25, 1.4), int(t * SR), wrap=True)
    # pad angin lembut
    random.seed(4)
    lp = 0.0
    for i in range(total):
        lp += 0.02 * (random.uniform(-1, 1) - lp)
        buf[i] += lp * 0.05
    return buf


def tick(freq=1400, dur=0.08, amp=1.0):
    return metal(freq, dur, amp, 40.0, ((1, 1.0), (2.0, 0.2)))


def chime_up():
    buf = silence(1.4)
    for k, idx in enumerate([0, 2, 4, 5]):
        mix_into(buf, metal(note(idx) * 2, 1.0, 0.6, 3.5), int(k * 0.11 * SR))
    return buf


def leaf_star():
    buf = silence(1.6)
    for k, idx in enumerate([2, 4, 5, 7]):
        mix_into(buf, metal(note(idx) * 2, 1.2, 0.5, 3.0), int(k * 0.08 * SR))
    mix_into(buf, metal(note(5) * 4, 1.0, 0.25, 4.0), int(0.4 * SR))
    return buf


def soft_no():
    buf = silence(0.7)
    mix_into(buf, metal(note(2), 0.5, 0.5, 6.0), 0)
    mix_into(buf, metal(note(0) * 0.84, 0.6, 0.5, 5.0), int(0.14 * SR))
    return buf


def tap():
    return metal(note(4) * 2, 0.18, 0.6, 22.0)


def whoosh(rising=True, dur=2.5):
    random.seed(7 if rising else 9)
    n = int(dur * SR)
    out = []
    lp = 0.0
    for i in range(n):
        p = i / n
        cutoff = 0.01 + 0.06 * (p if rising else 1 - p)
        lp += cutoff * (random.uniform(-1, 1) - lp)
        env = math.sin(math.pi * p) ** 1.5
        out.append(lp * env)
    return out


def unlock():
    buf = silence(2.2)
    mix_into(buf, metal(BASE / 2, 2.0, 0.5, 1.2), 0)
    for k, idx in enumerate([0, 2, 3, 5, 7]):
        mix_into(buf, metal(note(idx) * 2, 1.0, 0.45, 3.0), int((0.15 + k * 0.09) * SR))
    return buf


if __name__ == "__main__":
    write("bgm_desa.wav", bgm())
    write("tick.wav", tick(1500, 0.09))
    write("tick_accent.wav", tick(1000, 0.14))
    write("tap.wav", tap())
    write("success.wav", chime_up())
    write("leaf.wav", leaf_star())
    write("soft_no.wav", soft_no())
    write("breath_in.wav", whoosh(True))
    write("breath_out.wav", whoosh(False))
    write("unlock.wav", unlock())
    print("ok", sorted(os.listdir(OUT)))
