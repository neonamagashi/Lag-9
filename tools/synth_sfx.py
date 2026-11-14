import numpy as np, wave, sys, os
SR = 44100
OUT = sys.argv[1]
rng = np.random.default_rng(7)

def t(d): return np.arange(int(SR * d)) / SR
def env(n, a=0.005, r=None, curve=3.0):
    x = np.linspace(0, 1, n)
    e = np.minimum(1.0, x * (n / SR) / max(a, 1e-4))
    e *= (1 - x) ** curve if r is None else np.clip((1 - x) / r, 0, 1) ** curve
    return e
def sweep(f0, f1, d, wave_fn=np.sin, exp=True):
    tt = t(d)
    f = f0 * (f1 / f0) ** (tt / d) if exp else np.linspace(f0, f1, len(tt))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return wave_fn(ph)
def saw(ph): return 2 * ((ph / (2 * np.pi)) % 1.0) - 1
def sq(ph): return np.sign(np.sin(ph))
def noise(d): return rng.uniform(-1, 1, int(SR * d))
def lp(x, cutoff):
    cut = np.broadcast_to(np.asarray(cutoff, float), x.shape)
    a = 1 - np.exp(-2 * np.pi * cut / SR)
    y = np.zeros_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc); y[i] = acc
    return y
def hp(x, cutoff): return x - lp(x, cutoff)
def crush(x, bits=6):
    q = 2 ** bits; return np.round(x * q) / q
def pad(x, d): return np.concatenate([x, np.zeros(int(SR * d))])
def mix(*parts):
    n = max(len(p) for p in parts); out = np.zeros(n)
    for p in parts: out[:len(p)] += p
    return out
def save(name, x, peak=0.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())

d = 0.14; save("pierce", mix(sweep(2400, 500, d) * env(int(SR*d), 0.002, curve=2), hp(noise(0.03), 3000) * env(int(SR*0.03)) * 0.5))
d = 0.2; n = noise(d); save("snap", lp(n, np.linspace(800, 7000, len(n))) * env(len(n), 0.01, curve=1.5) + sweep(300, 1400, d) * env(int(SR*d), 0.01) * 0.25)
d = 0.7; tt = t(d); x = sweep(110, 330, d, saw) * (0.6 + 0.4 * np.sin(2*np.pi*14*tt)); save("jump_charge", lp(x, 1500) * np.minimum(1, tt / 0.1), 0.6)
d = 0.35; save("jump_release", mix(sweep(180, 50, 0.2) * env(int(SR*0.2), 0.002), lp(noise(d), np.linspace(5000, 600, int(SR*d))) * env(int(SR*d), 0.005, curve=2) * 0.7))
d = 0.6; tt = t(d); save("flight_on", mix(*[np.sin(2*np.pi*f*tt) * env(len(tt), 0.01 + i*0.04, curve=2) * 0.4 for i, f in enumerate([523, 784, 1047])], lp(noise(d), 2500) * env(len(tt), 0.05) * 0.3))
d = 0.45; save("flip_crush", mix(sweep(320, 60, d, saw) * env(int(SR*d), 0.003, curve=1.5), lp(noise(d), 300) * env(int(SR*d), 0.01) * 0.8))
d = 0.45; tt = t(d); save("flip_lift", mix(sweep(140, 620, d) * env(len(tt), 0.01, curve=1.5), np.sin(2*np.pi*1568*tt) * np.sin(2*np.pi*9*tt) * env(len(tt), 0.05, curve=2) * 0.25))
d = 0.4; save("crush_kill", crush(mix(sweep(90, 35, d) * env(int(SR*d), 0.002, curve=2.5), lp(noise(0.18), 1800) * env(int(SR*0.18), 0.001, curve=3) * 0.9), 7))
d = 0.12; save("enemy_hit", mix(lp(noise(d), 2500) * env(int(SR*d), 0.001, curve=4), sweep(420, 180, d, sq) * env(int(SR*d), 0.001, curve=4) * 0.35))
d = 0.3; save("impact", mix(sweep(120, 40, d) * env(int(SR*d), 0.001, curve=2.5), lp(noise(0.12), 900) * env(int(SR*0.12), 0.001) * 0.9))
d = 0.5; n = noise(d); save("send", mix(lp(n, np.linspace(6000, 400, len(n))) * env(len(n), 0.004, curve=1.8), sweep(160, 45, 0.3) * env(int(SR*0.3), 0.002, curve=2) * 0.8))
d = 0.55; n = noise(d); e = np.linspace(0, 1, len(n)) ** 2.2; e[-int(SR*0.04):] *= np.linspace(1, 0, int(SR*0.04)); save("draw", mix(lp(n, np.linspace(400, 5000, len(n))) * e, sweep(60, 220, d) * e * 0.6))
d = 0.8; tt = t(d); n = noise(d); crackle = (rng.random(len(n)) < np.linspace(0.002, 0.03, len(n))) * rng.uniform(-1, 1, len(n))
save("rend", mix(hp(n, 900) * (0.4 + 0.6 * np.abs(np.sin(2*np.pi*23*tt))) * np.linspace(0.3, 1, len(n)) * env(len(n), 0.02, curve=0.6), crackle * 1.5, sweep(80, 40, d, saw) * np.linspace(0.2, 1, len(tt)) * 0.4))
d = 2.0; tt = t(d); save("singularity", mix(sweep(70, 22, d) * env(len(tt), 0.01, curve=1.2), lp(noise(d), np.linspace(3000, 120, len(tt))) * env(len(tt), 0.002, curve=1.4) * 0.7, np.sin(2*np.pi*55*tt + 3*np.sin(2*np.pi*0.7*tt)) * env(len(tt), 0.3, curve=1) * 0.5))
d = 0.3; tt = t(d); a = np.sin(2*np.pi*1319*tt) * env(len(tt), 0.002, curve=3); b = pad(np.zeros(int(SR*0.07)), 0)
b = np.concatenate([np.zeros(int(SR*0.07)), (np.sin(2*np.pi*1976*t(0.23)) * env(int(SR*0.23), 0.002, curve=3))]); save("mana_pickup", mix(a, b * 0.8), 0.7)
parts = []
for k in range(3):
    dd = 0.16; tt = t(dd); g = np.sin(2*np.pi*(140 + 40*k) * tt * (1 + 2*tt)) * env(len(tt), 0.01, curve=2)
    parts.append(np.concatenate([np.zeros(int(SR * 0.17 * k)), lp(g + noise(dd) * 0.15, 900)]))
save("whisky", mix(*parts), 0.75)
d = 0.22; tt = t(d); save("witch_hurt", lp(saw(2*np.pi*190*tt) + saw(2*np.pi*203*tt) + noise(d)*0.3, 2200) * env(len(tt), 0.002, curve=2))
d = 0.35; tt = t(d); save("dodge", mix(np.sin(2*np.pi*2093*tt) * env(len(tt), 0.002, curve=3), np.sin(2*np.pi*3136*tt) * env(len(tt), 0.002, curve=4) * 0.5), 0.6)
d = 0.35; tt = t(d); save("enemy_attack", lp(saw(2*np.pi*(95 + 25*np.sin(2*np.pi*11*tt)) * tt) + noise(d) * 0.4, 1200) * env(len(tt), 0.03, curve=1.5))
d = 0.05; save("ui_click", sweep(1800, 900, d, sq) * env(int(SR*d), 0.001, curve=4), 0.5)
d = 0.25; save("whiff", lp(noise(d), np.linspace(1500, 5000, int(SR*d))) * env(int(SR*d), 0.01, curve=2), 0.6)
d = 0.45; n = noise(d); save("fireball_cast", mix(lp(n, np.linspace(900, 3000, len(n))) * env(len(n), 0.02, curve=1.5), sweep(90, 160, d, saw) * env(int(SR*d), 0.02) * 0.3 * 0.5))
d = 0.6; tt = t(d); save("void_cast", lp(np.sin(2*np.pi*(220 + 80*np.sin(2*np.pi*7*tt))*tt) + np.sin(2*np.pi*331*tt)*0.5, 2500) * env(len(tt), 0.03, curve=1.8) * (0.7 + 0.3*np.sin(2*np.pi*13*tt)))
d = 0.22; tt = t(d); save("arrow_shot", mix(np.sin(2*np.pi*190*tt) * np.exp(-tt*18), hp(noise(d), 2500) * env(len(tt), 0.002, curve=3) * 0.6))
d = 0.3; save("projectile_crushed", crush(mix(lp(noise(d), np.linspace(4000, 300, int(SR*d))) * env(int(SR*d), 0.001, curve=2.5), sweep(400, 70, 0.2) * env(int(SR*0.2), 0.001, curve=2) * 0.7), 6))
L = 8.0; tt = t(L)
drone = np.sin(2*np.pi*55*tt) * 0.5 + np.sin(2*np.pi*55.5*tt) * 0.4 + np.sin(2*np.pi*82.5*tt) * 0.2
wind_raw = noise(L + 1.0)
wind = lp(wind_raw, 350 + 250 * (0.5 + 0.5 * np.sin(2*np.pi*np.arange(len(wind_raw))/SR/ L)))
fade = int(SR * 1.0)
w = wind[:len(tt)].copy(); w[:fade] = w[:fade] * np.linspace(0, 1, fade) + wind[len(tt):len(tt)+fade] * np.linspace(1, 0, fade)
amb = drone * (0.75 + 0.25 * np.sin(2*np.pi*tt/L*2)) + w * 3.5
os.makedirs(os.path.join(OUT, "../ambient"), exist_ok=True)
save("../ambient/limbo_loop", amb, 0.5)
print("done", sorted(os.listdir(OUT)))
