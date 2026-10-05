#!/usr/bin/env python3
"""Placeholder sounds for Fiat, synthesised: python3 tools/make_sounds.py writes art/sound/*.wav
(44.1 kHz, mono, 16-bit). Replace any file with a real recording of the same name; the game
loads whatever is there and plays nothing where a file is missing.

  ambient_estate.wav   wind over an estate, 6 s loop
  ambient_town.wav     a town's hum and a dripping gutter, 6 s loop
  ambient_city.wav     a city's low roar, 6 s loop
  rain.wav             rain, 6 s loop, over the ambient when it rains
  tick_improvised.wav  the nail gun's clack        tick_shotgun.wav  the shotgun's thump
  tick_rifle.wav       the rifle's crack           tick_smg.wav      the SMG's rattle
  tick_pistol.wav      the pistol's snap           tick_melee.wav    the bat's thud
  sting.wav            a gang arriving: two low notes
  door.wav             the boss's door: a slam and its tail
  found.wav            a rare landing in the pack: a short bright note
"""
import os, struct, math
import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "art", "sound")
rng = np.random.default_rng(7)


def write(name, x):
    x = np.clip(x, -1.0, 1.0)
    data = (x * 32767).astype("<i2").tobytes()
    with open(os.path.join(OUT, name), "wb") as f:
        f.write(b"RIFF" + struct.pack("<I", 36 + len(data)) + b"WAVE")
        f.write(b"fmt " + struct.pack("<IHHIIHH", 16, 1, 1, SR, SR * 2, 2, 16))
        f.write(b"data" + struct.pack("<I", len(data)) + data)


def env(n, a, d, level=1.0):
    t = np.arange(n) / SR
    e = np.minimum(t / max(a, 1e-4), 1.0) * np.exp(-np.maximum(t - a, 0) / d)
    return e * level


def lowpass(x, cutoff):
    rc = 1.0 / (2 * math.pi * cutoff)
    alpha = (1.0 / SR) / (rc + 1.0 / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha * (x[i] - acc)
        y[i] = acc
    return y


def loopable(x, fade=0.4):
    n = int(fade * SR)
    ramp = np.linspace(0, 1, n)
    x = x.copy()
    x[:n] = x[:n] * ramp + x[-n:] * (1 - ramp)
    return x[: len(x) - n]


def noise(seconds):
    return rng.standard_normal(int(seconds * SR))


def ambient(kind):
    n = noise(6.4)
    if kind == "estate":   # wind: slow-swelling low noise
        x = lowpass(n, 400) * 0.9
        t = np.arange(len(x)) / SR
        x *= 0.5 + 0.5 * np.sin(2 * math.pi * 0.17 * t) ** 2
    elif kind == "town":   # a hum and a drip
        t = np.arange(len(n)) / SR
        x = lowpass(n, 250) * 0.35 + 0.08 * np.sin(2 * math.pi * 50 * t) + 0.04 * np.sin(2 * math.pi * 100 * t)
        for k in range(5):
            at = int((0.7 + 1.1 * k + rng.random() * 0.3) * SR)
            drip = np.sin(2 * math.pi * 1800 * np.arange(1200) / SR) * env(1200, 0.002, 0.01)
            x[at:at + 1200] += drip * 0.25
    else:                  # the city's roar
        x = lowpass(n, 180) * 1.2
        t = np.arange(len(x)) / SR
        x += 0.05 * np.sin(2 * math.pi * 61 * t)
    return loopable(x * 0.6)


def rain():
    n = noise(6.4)
    x = lowpass(n, 2500) - lowpass(n, 600)
    return loopable(x * 0.7)


def tick(kind):
    if kind == "melee":
        n = int(0.18 * SR)
        x = lowpass(noise(0.18), 300) * env(n, 0.003, 0.05, 1.2)
    elif kind == "shotgun":
        n = int(0.25 * SR)
        x = lowpass(noise(0.25), 900) * env(n, 0.002, 0.07, 1.5)
    elif kind == "rifle":
        n = int(0.16 * SR)
        x = lowpass(noise(0.16), 3000) * env(n, 0.001, 0.035, 1.3)
    elif kind == "smg":
        n = int(0.09 * SR)
        x = lowpass(noise(0.09), 2200) * env(n, 0.001, 0.02, 1.0)
    elif kind == "pistol":
        n = int(0.12 * SR)
        x = lowpass(noise(0.12), 2600) * env(n, 0.001, 0.025, 1.1)
    else:                  # improvised: the nail gun's clack
        n = int(0.08 * SR)
        t = np.arange(n) / SR
        x = (lowpass(noise(0.08), 4000) * 0.6 + 0.4 * np.sin(2 * math.pi * 1400 * t)) * env(n, 0.001, 0.015, 1.0)
    return x


def sting():
    n = int(1.4 * SR)
    t = np.arange(n) / SR
    a = np.sin(2 * math.pi * 98 * t) + 0.5 * np.sin(2 * math.pi * 196 * t) + 0.2 * np.sin(2 * math.pi * 294 * t)
    b = np.sin(2 * math.pi * 73.4 * t) + 0.5 * np.sin(2 * math.pi * 146.8 * t)
    x = a * env(n, 0.02, 0.35) * (t < 0.5) + np.roll(b * env(n, 0.02, 0.6), int(0.45 * SR)) * (t >= 0.45)
    return x * 0.5


def door():
    n = int(1.6 * SR)
    t = np.arange(n) / SR
    thud = lowpass(noise(1.6), 120) * env(n, 0.004, 0.12, 2.0)
    tail = lowpass(noise(1.6), 500) * env(n, 0.05, 0.5, 0.5)
    ring = np.sin(2 * math.pi * 55 * t) * env(n, 0.01, 0.4, 0.4)
    return thud + tail + ring


def found():
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * math.pi * 880 * t) * env(n, 0.005, 0.12, 0.5) + np.sin(2 * math.pi * 1320 * t) * np.roll(env(n, 0.005, 0.15, 0.4), int(0.08 * SR))
    return x


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    write("ambient_estate.wav", ambient("estate"))
    write("ambient_town.wav", ambient("town"))
    write("ambient_city.wav", ambient("city"))
    write("rain.wav", rain())
    for k in ["improvised", "shotgun", "rifle", "smg", "pistol", "melee"]:
        write("tick_%s.wav" % k, tick(k))
    write("sting.wav", sting())
    write("door.wav", door())
    write("found.wav", found())
    print("wrote", len(os.listdir(OUT)), "files to", OUT)
