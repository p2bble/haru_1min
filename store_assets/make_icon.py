# -*- coding: utf-8 -*-
import sys, os, math
sys.stdout.reconfigure(encoding='utf-8')
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.dirname(os.path.abspath(__file__))

def make_icon_v2():
    S = 512

    # ── 1. 대각선 그라디언트 배경 ──────────────────────────
    C1 = (162, 222, 220)   # 좌상단 mint-teal
    C2 = (138, 178, 228)   # 우하단 soft blue-lavender

    bg = Image.new('RGB', (S, S))
    px = bg.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2.0 * (S - 1))
            r = int(C1[0] + (C2[0] - C1[0]) * t)
            g = int(C1[1] + (C2[1] - C1[1]) * t)
            b = int(C1[2] + (C2[2] - C1[2]) * t)
            px[x, y] = (r, g, b)

    # ── 2. 둥근 모서리 마스크 ──────────────────────────────
    mask = Image.new('L', (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S, S], radius=115, fill=255)

    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    img.paste(bg.convert('RGBA'), mask=mask)

    # ── 3. 물방울 (날씬하고 길쭉한 형태) ──────────────────
    # 높이:너비 ≈ 1.9:1 비율로 레퍼런스와 유사하게
    drop_cx   = 215     # 중앙에서 약간 왼쪽
    tip_y     = 58      # 꼭짓점 (상단)
    circle_cy = 318     # 하단 원 중심
    r         = 108     # 하단 원 반지름

    d = circle_cy - tip_y                          # 260
    touch_y  = circle_cy - int(r * r / d)          # ≈ 277
    touch_dx = r * math.sqrt(max(d*d - r*r, 0)) / d  # ≈ 97

    drop_layer = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    drop_draw  = ImageDraw.Draw(drop_layer)
    WHITE = (255, 255, 255, 255)

    for y in range(tip_y, circle_cy + r + 2):
        if y <= touch_y:
            t = (y - tip_y) / max(touch_y - tip_y, 1)
            # 상단 테이퍼: 약간 볼록하게 (레퍼런스와 유사)
            half_w = touch_dx * math.sin(t * math.pi / 2)
        else:
            dy = y - circle_cy
            sq = r * r - dy * dy
            if sq < 0:
                continue
            half_w = math.sqrt(sq)

        if half_w >= 0.5:
            drop_draw.line(
                [(drop_cx - half_w, y), (drop_cx + half_w, y)],
                fill=WHITE
            )

    # 가장자리 부드럽게
    drop_layer = drop_layer.filter(ImageFilter.GaussianBlur(radius=1.0))
    img = Image.alpha_composite(img, drop_layer)

    # 물방울 광택 (좌상단 작은 타원)
    glare = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    gx, gy = drop_cx - 36, tip_y + 58
    ImageDraw.Draw(glare).ellipse([gx, gy, gx + 28, gy + 18],
                                   fill=(255, 255, 255, 100))
    glare = glare.filter(ImageFilter.GaussianBlur(radius=4))
    img = Image.alpha_composite(img, glare)

    # ── 4. 캡슐 (우상단, 물방울과 살짝 오버랩) ────────────
    pill_w, pill_h = 92, 40
    pad = 12
    pill_img = Image.new('RGBA', (pill_w + pad * 2, pill_h + pad * 2), (0, 0, 0, 0))
    ImageDraw.Draw(pill_img).rounded_rectangle(
        [pad, pad, pill_w + pad, pill_h + pad],
        radius=pill_h // 2,
        fill=(255, 255, 255, 255)
    )
    # 캡슐 중앙 분리선 (살짝 투명한 선)
    mid_x = pad + pill_w // 2
    ImageDraw.Draw(pill_img).line(
        [(mid_x, pad + 6), (mid_x, pill_h + pad - 6)],
        fill=(200, 220, 230, 140), width=3
    )

    # 45° 회전
    pill_rotated = pill_img.rotate(45, expand=True, resample=Image.BICUBIC)
    pw, ph = pill_rotated.size

    # 위치: 물방울 우상단 (살짝 겹침)
    pill_cx = drop_cx + 118
    pill_cy = tip_y + 78
    img.alpha_composite(pill_rotated, (pill_cx - pw // 2, pill_cy - ph // 2))

    # ── 5. 저장 ───────────────────────────────────────────
    out_path = os.path.join(OUT, 'icon_512.png')
    img.save(out_path)
    print('OK:', out_path)

if __name__ == '__main__':
    make_icon_v2()
