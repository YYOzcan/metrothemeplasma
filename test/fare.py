#!/usr/bin/env python3
"""Gerçek oturumda fare/klavye benzetimi (uinput, python-evdev) — sıcak köşeler, kutucuk tıklama, alt kenar.

    python3 test/fare.py "git 1919 0; bekle 0.5; git 1919 540; bekle 1; foto /tmp/x.png; tik; tus LEFTMETA"

Komutlar: git X Y | kay DX DY (yavaş hareket) | tik | sagtik | bas | birak | tekerlek N |
          tus AD[+AD...] (ör. LEFTMETA, LEFTMETA+C, ESC) | bekle SN | foto DOSYA
Ekran boyutu: 1920x1080 (mutlak işaretçi aygıtı; KWin bütün ekrana eşler).
"""
import subprocess
import sys
import time

from evdev import AbsInfo, UInput, ecodes as e

G, Y = 1920, 1080
yetenek = {
    e.EV_KEY: [e.BTN_LEFT, e.BTN_RIGHT, e.BTN_MIDDLE] + [v for k, v in e.ecodes.items()
                                                        if k.startswith("KEY_") and isinstance(v, int) and v < 256],
    e.EV_ABS: [(e.ABS_X, AbsInfo(0, 0, G - 1, 0, 0, 0)), (e.ABS_Y, AbsInfo(0, 0, Y - 1, 0, 0, 0))],
    e.EV_REL: [e.REL_WHEEL],
}
u = UInput(yetenek, name="metro-sinama-fare", version=0x3)
time.sleep(0.8)
konum = [G // 2, Y // 2]


def git(x, y):
    konum[0], konum[1] = int(x), int(y)
    u.write(e.EV_ABS, e.ABS_X, konum[0])
    u.write(e.EV_ABS, e.ABS_Y, konum[1])
    u.syn()


def dugme(b, deger):
    u.write(e.EV_KEY, b, deger)
    u.syn()


for komut in sys.argv[1].split(";"):
    p = komut.split()
    if not p:
        continue
    k = p[0]
    if k == "git":
        git(p[1], p[2])
    elif k == "kay":
        x0, y0 = konum
        for i in range(1, 21):
            git(x0 + int(p[1]) * i / 20, y0 + int(p[2]) * i / 20)
            time.sleep(0.015)
    elif k in ("tik", "sagtik"):
        b = e.BTN_LEFT if k == "tik" else e.BTN_RIGHT
        dugme(b, 1); time.sleep(0.06); dugme(b, 0)
    elif k == "bas":
        dugme(e.BTN_LEFT, 1)
    elif k == "birak":
        dugme(e.BTN_LEFT, 0)
    elif k == "tekerlek":
        u.write(e.EV_REL, e.REL_WHEEL, int(p[1])); u.syn()
    elif k == "tus":
        adlar = [getattr(e, "KEY_" + a) for a in p[1].split("+")]
        for a in adlar:
            dugme(a, 1); time.sleep(0.03)
        for a in reversed(adlar):
            dugme(a, 0); time.sleep(0.03)
    elif k == "bekle":
        time.sleep(float(p[1]))
    elif k == "foto":
        subprocess.run(["spectacle", "-b", "-n", "-f", "-o", p[1]], capture_output=True)
    time.sleep(0.05)
time.sleep(0.2)
u.close()
