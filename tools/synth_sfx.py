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


def snap():
    n = len(t(0.12))
    noise = rng.standard_normal(n)
    hp = noise - lowpass(noise, 0.35)
    click = hp * env(n, 0.0005, 0.012)
    tone = np.sin(2 * np.pi * 2300 * t(0.12)) * env(n, 0.0005, 0.008) * 0.4
    return click + tone


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
