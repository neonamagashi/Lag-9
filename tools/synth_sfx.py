import os
import sys

import numpy as np
import wave

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/sfx"
SR = 44100
rng = np.random.default_rng(7)


def save(name, x, vol=0.8):
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * vol
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, a, d):
    e = np.ones(n)
    ai = max(1, int(a * SR))
    e[:ai] = np.linspace(0, 1, ai)
    e[ai:] = np.exp(-np.arange(n - ai) / (d * SR))
    return e


def lowpass(x, k):
    y = np.zeros_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += k * (v - acc)
        y[i] = acc
    return y


def band(x, lo, hi):
    """Smooth band-pass in the frequency domain (Hz)."""
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / SR)
    gain = 1 / (1 + (lo / np.maximum(f, 1)) ** 4) / (1 + (f / hi) ** 4)
    return np.fft.irfft(X * gain, len(x))


def snap():
    """A finger snap: a breath of skin friction, a sharp crack peaking around 2-4 kHz, and the hollow pop of the palm."""
    pre_n = int(SR * 0.02)
    pre = band(rng.standard_normal(pre_n), 2500, 7000) * np.linspace(0.0, 0.1, pre_n) ** 1.5
    n = int(SR * 0.09)
    tt = np.arange(n) / SR
    crack = band(rng.standard_normal(n), 1800, 4500) * np.exp(-tt / 0.004) * 2.2
    air = band(rng.standard_normal(n), 4500, 9000) * np.exp(-tt / 0.0015) * 0.5
    pop = np.sin(2 * np.pi * 330 * tt) * np.exp(-tt / 0.028) * 0.5
    knock = np.sin(2 * np.pi * 1200 * tt) * np.exp(-tt / 0.008) * 0.35
    out = np.concatenate([pre, crack + air + pop + knock])
    return out / np.max(np.abs(out))


def syllable(f0, dur, vowel):
    tt = t(dur)
    f = f0 * (1 + 0.06 * np.sin(2 * np.pi * 5 * tt))
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = sum(np.sin(ph * h) / h for h in range(1, 12))
    formants = {"a": (730, 1090), "o": (570, 840), "u": (440, 1020), "e": (530, 1840)}[vowel]
    out = np.zeros_like(src)
    for fm in formants:
        out += src * (0.6 + 0.4 * np.sin(2 * np.pi * fm * tt))
    return out * env(len(tt), 0.01, dur * 0.35)


def babble():
    return syllable(220, 0.09, "a")


def mumble():
    parts = []
    for i in range(6):
        parts.append(syllable(rng.uniform(95, 130), rng.uniform(0.08, 0.16), rng.choice(["o", "u", "a"])) * rng.uniform(0.5, 1.0))
        parts.append(np.zeros(int(SR * rng.uniform(0.02, 0.08))))
    return lowpass(np.concatenate(parts), 0.25)


def flash():
    tt = t(1.6)
    n = len(tt)
    noise = lowpass(rng.standard_normal(n), 0.08)
    sweep = np.sin(2 * np.pi * np.cumsum(200 + 1800 * np.exp(-tt * 3)) / SR)
    shimmer = sum(np.sin(2 * np.pi * f * tt) for f in (880, 1320, 1760, 2640)) * 0.2
    return (noise * 0.6 + sweep * 0.5 + shimmer) * env(n, 0.005, 0.5)


def whoosh(inward):
    tt = t(0.55)
    n = len(tt)
    noise = rng.standard_normal(n)
    k = np.linspace(0.02, 0.25, n) if inward else np.linspace(0.25, 0.02, n)
    y = np.zeros(n)
    acc = 0.0
    for i in range(n):
        acc += k[i] * (noise[i] - acc)
        y[i] = acc
    e = np.sin(np.pi * np.clip(tt / 0.55, 0, 1)) ** (0.7 if inward else 1.6)
    if not inward:
        e = env(n, 0.01, 0.18)
    sub = np.sin(2 * np.pi * 55 * tt) * e * 0.5
    return y * e + sub


def grab():
    tt = t(0.35)
    n = len(tt)
    return (np.sin(2 * np.pi * np.cumsum(500 - 300 * tt / 0.35) / SR) * 0.6 + lowpass(rng.standard_normal(n), 0.15) * 0.5) * env(n, 0.005, 0.12)


def beam():
    tt = t(0.45)
    n = len(tt)
    core = np.sin(2 * np.pi * 660 * tt + 3 * np.sin(2 * np.pi * 37 * tt))
    hiss = (rng.standard_normal(n) - lowpass(rng.standard_normal(n), 0.3)) * 0.3
    return (core * 0.6 + hiss) * env(n, 0.005, 0.18)


def jump():
    tt = t(0.25)
    n = len(tt)
    return lowpass(rng.standard_normal(n), 0.2) * env(n, 0.003, 0.06) + np.sin(2 * np.pi * np.cumsum(180 + 400 * tt) / SR) * env(n, 0.003, 0.08) * 0.4


def land():
    tt = t(0.2)
    n = len(tt)
    return lowpass(rng.standard_normal(n), 0.1) * env(n, 0.002, 0.04)


def meow():
    tt = t(0.6)
    n = len(tt)
    f = 520 + 380 * np.sin(np.pi * np.clip(tt / 0.6, 0, 1)) ** 0.8 - 120 * tt
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = sum(np.sin(ph * h) / h ** 1.2 for h in range(1, 10))
    vowel = 0.5 + 0.5 * np.sin(np.pi * np.clip(tt / 0.6, 0, 1))
    shaped = src * (0.55 + 0.45 * np.sin(2 * np.pi * (700 + 900 * vowel) * tt))
    return lowpass(shaped, 0.35) * env(n, 0.04, 0.25)


def warden_voice():
    """Deep, reversed and layered: a low syllable played backwards with an octave-down double."""
    a = syllable(rng.uniform(62, 70), 0.22, str(rng.choice(["o", "u", "a"])))
    b = syllable(33, 0.22, "u") * 0.8
    c = syllable(98, 0.22, "o") * 0.25
    x = (a + b + c)[::-1]
    return lowpass(x, 0.12)


def groan():
    tt = t(1.4)
    n = len(tt)
    f = 58 + 10 * np.sin(2 * np.pi * 0.7 * tt) - 8 * tt
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = sum(np.sin(ph * h) / h for h in range(1, 16))
    rasp = lowpass(rng.standard_normal(n), 0.05) * 0.3
    return lowpass(src + rasp, 0.08) * env(n, 0.25, 0.7)


def burp():
    tt = t(0.45)
    n = len(tt)
    f = 110 + 25 * np.sin(2 * np.pi * 9 * tt) + 40 * rng.standard_normal(n) * 0.05
    ph = 2 * np.pi * np.cumsum(f) / SR
    src = np.sign(np.sin(ph)) * 0.6 + np.sin(ph * 2) * 0.4
    return lowpass(src, 0.1) * env(n, 0.02, 0.2)


def retch():
    parts = []
    for i in range(3):
        d = 0.35 if i < 2 else 0.6
        tt = t(d)
        n = len(tt)
        noise = lowpass(rng.standard_normal(n), 0.12 if i < 2 else 0.2)
        f = 130 - 50 * tt / d
        gurgle = np.sin(2 * np.pi * np.cumsum(f) / SR) * (0.5 + 0.5 * np.sin(2 * np.pi * 23 * tt))
        splash = (rng.standard_normal(n) - lowpass(rng.standard_normal(n), 0.4)) * (0.6 if i == 2 else 0.0) * np.clip((tt - d * 0.3) * 4, 0, 1)
        parts.append((noise * 0.6 + gurgle * 0.5 + splash) * env(n, 0.03, d * 0.4))
        parts.append(np.zeros(int(SR * 0.18)))
    return np.concatenate(parts)


def laugh():
    parts = []
    for i in range(5):
        parts.append(syllable(260 - i * 12, 0.1, "a") * (1.0 - i * 0.12))
        parts.append(np.zeros(int(SR * 0.06)))
    return np.concatenate(parts)


def pop():
    tt = t(0.12)
    n = len(tt)
    return np.sin(2 * np.pi * np.cumsum(400 + 900 * tt / 0.12) / SR) * env(n, 0.002, 0.04)


save("snap_click", snap(), 0.5)
save("babble", babble(), 0.6)
save("mumble", mumble(), 0.5)
save("arrive_flash", flash(), 0.8)
save("push_wave", whoosh(False), 0.8)
save("pull_wave", whoosh(True), 0.8)
save("grab", grab(), 0.7)
save("beam", beam(), 0.6)
save("jump", jump(), 0.6)
save("land", land(), 0.6)
print("ok")
save("meow", meow(), 0.6)
save("warden", warden_voice(), 0.8)
save("groan", groan(), 0.8)
save("burp", burp(), 0.7)
save("retch", retch(), 0.7)
save("laugh", laugh(), 0.6)
save("pop", pop(), 0.5)
