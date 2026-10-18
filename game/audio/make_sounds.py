"""音楽と効果音のWAVを作る。ADR-0008。

外部の素材を使わず、このスクリプトで合成する。標準ライブラリだけで動き、乱数の種を固定しているので、
何度回しても同じファイルができる。音を変えたいときは、ここを直して回し直す。

    python game/audio/make_sounds.py

できるもの（このスクリプトと同じフォルダ）
- music.wav: 繰り返して流す曲。終わりの響きを頭に重ねてあるので、つなぎ目で途切れない
- click.wav: ボタンを押したとき
- event.wav: イベントが起きたとき
- fall.wav: 周が終わったとき
- rebirth.wav: 新しい体で目覚めたとき
"""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parent
TAU = 2 * math.pi


def freq(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def saw(phase):
    return 2.0 * (phase - math.floor(phase + 0.5))


def square(phase):
    return 1.0 if phase % 1.0 < 0.5 else -1.0


def envelope(t, length, attack, release):
    if t < attack:
        return t / attack
    if t > length - release:
        return max(0.0, (length - t) / release)
    return 1.0


def add_note(buf, start, length, hz, volume, wave_fn, attack=0.01, release=0.05, cutoff=None, detune=0.0, wrap=False):
    """buf に音を1つ足す。wrap なら、はみ出た分を頭に回す（繰り返す曲のつなぎ目のため）。"""
    n = int(length * RATE)
    first = int(start * RATE)
    alpha = 1.0 if cutoff is None else 1.0 - math.exp(-TAU * cutoff / RATE)
    low = 0.0
    for i in range(n):
        t = i / RATE
        s = wave_fn(hz * t)
        if detune:
            s = 0.5 * (s + wave_fn(hz * (1 + detune) * t))
        low += alpha * (s - low)
        j = first + i
        if wrap:
            j %= len(buf)
        elif j >= len(buf):
            break
        buf[j] += low * volume * envelope(t, length, attack, release)


def add_noise(buf, start, length, volume, rng, decay, wrap=False, smooth=0.0):
    n = int(length * RATE)
    first = int(start * RATE)
    prev = 0.0
    for i in range(n):
        t = i / RATE
        s = rng.uniform(-1, 1)
        prev = smooth * prev + (1 - smooth) * s
        j = first + i
        if wrap:
            j %= len(buf)
        elif j >= len(buf):
            break
        buf[j] += prev * volume * math.exp(-t / decay)


def add_kick(buf, start, volume, wrap=False):
    n = int(0.25 * RATE)
    first = int(start * RATE)
    phase = 0.0
    for i in range(n):
        t = i / RATE
        phase += (45 + 110 * math.exp(-t / 0.03)) / RATE
        j = (first + i) % len(buf) if wrap else first + i
        if j < len(buf):
            buf[j] += math.sin(TAU * phase) * volume * math.exp(-t / 0.08)


def music():
    # 96BPMの4拍子で8小節。Am・F・C・Gを2小節ずつ。
    beat = 60 / 96
    bar = beat * 4
    buf = [0.0] * int(bar * 8 * RATE)
    rng = random.Random(8)
    chords = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]
    for index, chord in enumerate(chords):
        start = index * 2 * bar
        for note in chord:
            add_note(buf, start, 2 * bar + 0.6, freq(note), 0.07, saw, attack=0.6, release=0.9, cutoff=900, detune=0.006, wrap=True)
        root = chord[0] - 12
        for step in range(16):
            note = root + [0, 12, 7, 12][step % 4]
            add_note(buf, start + step * beat / 2, beat / 2 * 0.9, freq(note), 0.16, square, release=0.06, cutoff=500, wrap=True)
        for step in range(16):
            arp = chord[step % 3] + 12 + (12 if step % 8 >= 6 else 0)
            add_note(buf, start + step * beat / 2 + beat / 4, beat / 4, freq(arp), 0.035, square, release=0.08, cutoff=2500, wrap=True)
    for b in range(32):
        add_kick(buf, b * beat, 0.35 if b % 2 == 0 else 0.22, wrap=True)
        add_noise(buf, b * beat + beat / 2, 0.06, 0.05, rng, 0.015, wrap=True)
    return buf


def click():
    buf = [0.0] * int(0.06 * RATE)
    add_note(buf, 0, 0.05, 1400, 0.25, square, attack=0.002, release=0.04, cutoff=3000)
    return buf


def event():
    buf = [0.0] * int(0.4 * RATE)
    add_note(buf, 0, 0.12, freq(81), 0.3, square, attack=0.005, release=0.04, cutoff=3500)
    add_note(buf, 0.13, 0.22, freq(88), 0.3, square, attack=0.005, release=0.12, cutoff=3500)
    return buf


def fall():
    buf = [0.0] * int(1.2 * RATE)
    rng = random.Random(9)
    phase = 0.0
    for i in range(int(1.1 * RATE)):
        t = i / RATE
        phase += (600 * math.exp(-t / 0.35) + 50) / RATE
        buf[i] += saw(phase) * 0.3 * envelope(t, 1.1, 0.01, 0.4)
    add_noise(buf, 0, 1.0, 0.12, rng, 0.3, smooth=0.7)
    return buf


def rebirth():
    buf = [0.0] * int(1.6 * RATE)
    for k, note in enumerate([69, 72, 76, 81, 84, 88]):
        add_note(buf, k * 0.09, 1.0, freq(note), 0.13, saw, attack=0.01, release=0.8, cutoff=3000, detune=0.004)
    return buf


def write(name, buf):
    peak = max(1e-9, max(abs(s) for s in buf))
    scale = min(1.0, 0.89 / peak)
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in buf)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data)


def main():
    for name, make in [("music.wav", music), ("click.wav", click), ("event.wav", event), ("fall.wav", fall), ("rebirth.wav", rebirth)]:
        write(name, make())
        print("wrote", name)


if __name__ == "__main__":
    main()
