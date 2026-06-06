# -*- coding: utf-8 -*-
"""
하루 1분 - Play Store 에셋 생성 스크립트
"""
import sys, os
sys.stdout.reconfigure(encoding='utf-8')

from PIL import Image, ImageDraw, ImageFont
OUT = os.path.dirname(os.path.abspath(__file__))
FONT_REG  = "C:/Windows/Fonts/malgun.ttf"
FONT_BOLD = "C:/Windows/Fonts/malgunbd.ttf"

# 색상
C_BLUE_LT  = (79,  195, 247)
C_BLUE_DK  = (2,   136, 209)
C_GREEN_LT = (129, 199, 132)
C_GREEN_DK = (56,  142,  60)
C_BG       = (245, 249, 255)
C_SURFACE  = (255, 255, 255)
C_TEXT_PR  = (26,  26,  46)
C_TEXT_SEC = (107, 114, 128)
C_WHITE    = (255, 255, 255)
C_TAKEN    = (76,  175,  80)
C_TAKEN_BG = (232, 249, 232)
C_BLUE_BG  = (224, 244, 255)


def font(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size)

def grad_v(img, c1, c2):
    W, H = img.size
    draw = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        r = int(c1[0] + (c2[0] - c1[0]) * t)
        g = int(c1[1] + (c2[1] - c1[1]) * t)
        b = int(c1[2] + (c2[2] - c1[2]) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

def circle(draw, cx, cy, r, **kw):
    draw.ellipse([cx-r, cy-r, cx+r, cy+r], **kw)

def txt(draw, x, y, text, f, fill, anchor="mm"):
    draw.text((x, y), text, font=f, fill=fill, anchor=anchor)

def rrect(draw, x0, y0, x1, y1, r, **kw):
    draw.rounded_rectangle([x0, y0, x1, y1], radius=r, **kw)

def water_drop(draw, cx, tip_y, body_cy, r, color):
    """물방울: tip_y=꼭짓점 y, body_cy=원 중심 y, r=원 반지름"""
    draw.ellipse([cx-r, body_cy-r, cx+r, body_cy+r], fill=color)
    spread = int(r * 1.05)
    pts = [(cx, tip_y), (cx - spread, body_cy), (cx + spread, body_cy)]
    draw.polygon(pts, fill=color)

def draw_check(draw, cx, cy, size, color, width=6):
    """체크마크"""
    x1 = cx - size // 2
    y1 = cy + size // 8
    xm = cx - size // 8
    ym = cy + size // 2
    x2 = cx + size // 2
    y2 = cy - size // 3
    draw.line([(x1, y1), (xm, ym), (x2, y2)], fill=color, width=width)

def draw_pill(draw, cx, cy, w, h, color):
    r = h // 2
    draw.rounded_rectangle([cx-w//2, cy-h//2, cx+w//2, cy+h//2], radius=r, fill=color)

def phone_frame(img):
    W, H = img.size
    draw = ImageDraw.Draw(img)
    draw.rectangle([0, 0, W, 70], fill=C_BG)
    txt(draw, 58, 35, "9:41", font(28, True), C_TEXT_PR, anchor="lm")
    # 배터리 바
    rrect(draw, W-110, 18, W-58, 52, 4, outline=C_TEXT_SEC, width=2)
    draw.rectangle([W-108, 20, W-108+42, 50], fill=C_TEXT_SEC)
    draw.rectangle([W-56, 28, W-52, 42], fill=C_TEXT_SEC)
    # 펀치홀
    circle(draw, W//2, 35, 16, fill=(20, 20, 20))
    # 홈 바
    rrect(draw, W//2-60, H-26, W//2+60, H-10, 5, fill=(180, 180, 190))
    return img


# ══════════════════════════════════════════════════════
# 1. 앱 아이콘 512x512
# ══════════════════════════════════════════════════════
def make_icon():
    S = 512
    bg = Image.new("RGBA", (S, S))
    grad_v(bg, C_BLUE_LT, C_BLUE_DK)

    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, S, S], radius=115, fill=255)

    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    img.paste(bg, mask=mask)
    draw = ImageDraw.Draw(img)

    # 물방울 (흰색, 상단)
    drop_r   = 90
    body_cy  = 220
    tip_y    = 58
    water_drop(draw, S//2, tip_y, body_cy, drop_r, (*C_WHITE, 255))

    # 광택
    circle(draw, S//2 - 22, body_cy - 30, 20, fill=(*C_WHITE, 80))

    # 알약 점 2개 (영양제 의미)
    pill_y = body_cy + drop_r + 32
    for px in [S//2 - 48, S//2 + 48]:
        draw_pill(draw, px, pill_y, 56, 28, (*C_WHITE, 220))

    # "1분" 큰 텍스트
    txt(draw, S//2, pill_y + 72, "1분", font(100, True), (*C_WHITE, 255))
    # "하루" 작은 텍스트
    txt(draw, S//2, pill_y + 150, "하루", font(32), (*C_WHITE, 190))

    img.save(os.path.join(OUT, "icon_512.png"))
    print("OK icon_512.png")


# ══════════════════════════════════════════════════════
# 2. Feature Graphic 1024x500
# ══════════════════════════════════════════════════════
def make_feature():
    W, H = 1024, 500
    img = Image.new("RGBA", (W, H))
    grad_v(img, C_BLUE_LT, C_BLUE_DK)
    draw = ImageDraw.Draw(img)

    # 장식 원
    for (cx, cy, r, a) in [(810, 70, 170, 20), (890, 430, 110, 14), (95, 390, 85, 12)]:
        ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(ov).ellipse([cx-r, cy-r, cx+r, cy+r], fill=(*C_WHITE, a))
        img = Image.alpha_composite(img, ov)
    draw = ImageDraw.Draw(img)

    # 왼쪽 텍스트
    txt(draw, 72, 120, "하루 1분", font(82, True), C_WHITE, anchor="lm")
    txt(draw, 74, 185, "물 한 잔, 영양제 한 알", font(32), (*C_WHITE, 215), anchor="lm")
    txt(draw, 74, 228, "1분이면 충분합니다", font(26), (*C_WHITE, 170), anchor="lm")
    draw.line([(74, 262), (390, 262)], fill=(*C_WHITE, 70), width=2)

    tag_items = ["물 섭취 기록", "영양제 체크", "홈 화면 위젯"]
    f_tag = font(24)
    ty = 280
    for t in tag_items:
        # 물방울/알약 작은 도형
        circle(draw, 84, ty, 8, fill=(*C_WHITE, 200))
        txt(draw, 104, ty, t, f_tag, (*C_WHITE, 200), anchor="lm")
        ty += 42

    # 오른쪽 앱 미리보기 카드
    cx0, cy0, cw, ch = 596, 55, 372, 390
    card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle([cx0, cy0, cx0+cw, cy0+ch], radius=28,
                                            fill=(*C_SURFACE, 228))
    img = Image.alpha_composite(img, card)
    draw = ImageDraw.Draw(img)

    # 물 섹션
    cx1 = cx0 + 20
    txt(draw, cx1, cy0 + 26, "오늘의 물", font(20, True), C_TEXT_PR, anchor="lm")
    pb_x, pb_y, pb_w, pb_h = cx1, cy0 + 60, cw - 40, 10
    rrect(draw, pb_x, pb_y, pb_x+pb_w, pb_y+pb_h, 5, fill=C_BLUE_BG)
    rrect(draw, pb_x, pb_y, pb_x+int(pb_w*0.75), pb_y+pb_h, 5, fill=C_BLUE_LT)
    txt(draw, cx1, cy0 + 86, "1500 / 2000ml", font(16), C_TEXT_SEC, anchor="lm")
    txt(draw, cx0+cw-20, cy0 + 86, "75%", font(16), C_BLUE_DK, anchor="rm")

    draw.line([(cx0+14, cy0+108), (cx0+cw-14, cy0+108)], fill=(228, 228, 228), width=1)

    # 영양제 섹션
    txt(draw, cx1, cy0 + 124, "오늘의 영양제", font(20, True), C_TEXT_PR, anchor="lm")
    supps = [("비타민C", True), ("오메가3", True), ("마그네슘", False)]
    for i, (name, taken) in enumerate(supps):
        ry = cy0 + 156 + i * 50
        bg_c = C_TAKEN_BG if taken else (246, 246, 250)
        rrect(draw, cx0+14, ry, cx0+cw-14, ry+40, 10, fill=bg_c)
        circle(draw, cx0+36, ry+20, 10, fill=C_TAKEN if taken else (200, 200, 210))
        if taken:
            draw_check(draw, cx0+36, ry+20, 14, C_WHITE, width=3)
        txt(draw, cx0+56, ry+20, name, font(17), C_TAKEN if taken else C_TEXT_SEC, anchor="lm")

    # 버튼
    btn_y = cy0 + ch - 56
    rrect(draw, cx0+16, btn_y, cx0+cw-16, btn_y+42, 12, fill=C_BLUE_LT)
    txt(draw, cx0+cw//2, btn_y+21, "+ 한 잔 마셨어요", font(19, True), C_WHITE)

    img.save(os.path.join(OUT, "feature_graphic.png"))
    print("OK feature_graphic.png")


# ══════════════════════════════════════════════════════
# 3. 스크린샷 1 - 홈 화면
# ══════════════════════════════════════════════════════
def make_screenshot_1():
    W, H = 1080, 1920
    img = Image.new("RGBA", (W, H), C_BG)
    draw = ImageDraw.Draw(img)

    # 앱바
    txt(draw, 52, 130, "하루 1분", font(46, True), C_TEXT_PR, anchor="lm")
    txt(draw, 52, 182, "6월 6일 토요일", font(28), C_TEXT_SEC, anchor="lm")
    circle(draw, W-80, 152, 38, fill=(228, 236, 250))
    rrect(draw, W-108, 126, W-54, 178, 10, fill=(220, 228, 245))

    # 물 카드
    card = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle([36, 222, W-36, 708], radius=36, fill=(*C_SURFACE, 255))
    img = Image.alpha_composite(img, card)
    draw = ImageDraw.Draw(img)

    # 카드 헤더 - 물방울 도형
    water_drop(draw, 78, 268, 294, 14, C_BLUE_LT)
    txt(draw, 108, 282, "오늘의 물", font(36, True), C_TEXT_PR, anchor="lm")
    rrect(draw, W-210, 268, W-76, 306, 19, fill=C_BLUE_BG)
    txt(draw, W-143, 287, "250ml", font(26), C_BLUE_DK)

    # 원형 프로그레스
    pcx, pcy, pr = W//2, 492, 140
    draw.arc([pcx-pr, pcy-pr, pcx+pr, pcy+pr], 0, 360, fill=C_BLUE_BG, width=22)
    draw.arc([pcx-pr, pcy-pr, pcx+pr, pcy+pr], -90, -90+int(360*0.75), fill=C_BLUE_LT, width=22)
    txt(draw, pcx, pcy-28, "1500", font(80, True), C_BLUE_DK)
    txt(draw, pcx, pcy+34, "ml / 2000ml", font(28), C_TEXT_SEC)

    # 버튼
    rrect(draw, 76, 644, W-196, 692, 22, fill=C_BLUE_LT)
    txt(draw, (76+W-196)//2, 668, "+ 한 잔 마셨어요", font(34, True), C_WHITE)
    rrect(draw, W-182, 644, W-76, 692, 22, fill=(236, 236, 242))

    # 안내
    rrect(draw, 180, 704, W-180, 740, 16, fill=C_BLUE_BG)
    txt(draw, W//2, 722, "오늘 목표까지 500ml 남았어요", font(22), C_BLUE_DK)

    # 영양제 섹션
    txt(draw, 52, 792, "오늘의 영양제", font(36, True), C_TEXT_PR, anchor="lm")
    draw_pill(draw, 76, 800, 20, 12, C_GREEN_LT)
    rrect(draw, W-186, 780, W-80, 816, 18, fill=(228, 248, 228))
    txt(draw, W-133, 798, "2 / 3", font(26), C_GREEN_DK)

    # 영양제 그리드
    cell_w = (W - 80 - 24) // 3
    supp_data = [("비타민C", True), ("오메가3", True), ("마그네슘", False)]
    for i, (name, taken) in enumerate(supp_data):
        gx = 40 + i * (cell_w + 12)
        gy = 840
        gh = 252

        bg = C_TAKEN_BG if taken else C_SURFACE
        border = C_TAKEN if taken else (214, 214, 220)

        card2 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(card2).rounded_rectangle([gx, gy, gx+cell_w, gy+gh], radius=28,
                                                 fill=(*bg, 255), outline=(*border, 255), width=4)
        img = Image.alpha_composite(img, card2)
        draw = ImageDraw.Draw(img)

        # 아이콘
        ic_cx = gx + cell_w // 2
        ic_cy = gy + 88
        ic_r  = 48
        ic_bg = (200, 238, 200) if taken else (236, 236, 244)
        circle(draw, ic_cx, ic_cy, ic_r, fill=ic_bg)
        # 알약 모양
        draw_pill(draw, ic_cx, ic_cy, 44, 22, C_GREEN_DK if taken else (160, 160, 180))
        draw_pill(draw, ic_cx, ic_cy, 44, 22, C_GREEN_DK if taken else (160, 160, 180))

        if taken:
            ov = Image.new("RGBA", (W, H), (0, 0, 0, 0))
            ImageDraw.Draw(ov).ellipse([ic_cx-ic_r, ic_cy-ic_r, ic_cx+ic_r, ic_cy+ic_r],
                                       fill=(76, 175, 80, 90))
            img = Image.alpha_composite(img, ov)
            draw = ImageDraw.Draw(img)
            draw_check(draw, ic_cx, ic_cy, 36, C_TAKEN, width=7)

        txt(draw, ic_cx, gy + 162, name, font(28, True), C_TAKEN if taken else C_TEXT_PR)
        tag_bg = (196, 238, 196) if taken else (236, 236, 244)
        rrect(draw, gx+18, gy+194, gx+cell_w-18, gy+228, 17, fill=tag_bg)
        txt(draw, ic_cx, gy+211, "아침", font(22), C_GREEN_DK if taken else C_TEXT_SEC)

    # 완료 배너
    rrect(draw, 40, 1110, W-40, 1158, 20, fill=C_TAKEN_BG)
    circle(draw, 84, 1134, 14, fill=C_TAKEN)
    draw_check(draw, 84, 1134, 18, C_WHITE, width=4)
    txt(draw, 120, 1134, "오늘 영양제 2/3 완료!", font(30, True), C_TAKEN, anchor="lm")

    img = phone_frame(img)
    img.save(os.path.join(OUT, "screenshot_1.png"))
    print("OK screenshot_1.png")


# ══════════════════════════════════════════════════════
# 4. 스크린샷 2 - 영양제 추가 화면
# ══════════════════════════════════════════════════════
def make_screenshot_2():
    W, H = 1080, 1920
    img = Image.new("RGBA", (W, H), C_BG)
    draw = ImageDraw.Draw(img)

    # 앱바
    txt(draw, 52, 130, "<", font(48, True), C_TEXT_PR, anchor="lm")
    txt(draw, W//2, 130, "영양제 추가", font(44, True), C_TEXT_PR)
    txt(draw, W-72, 130, "저장", font(36, True), C_BLUE_DK, anchor="rm")

    # 사진 선택 원
    circle(draw, W//2, 370, 158, fill=(228, 248, 228))
    draw.arc([W//2-158, 212, W//2+158, 528], 0, 360, fill=C_GREEN_LT, width=4)
    # 카메라 모양 (단순)
    cam_cx, cam_cy = W//2, 350
    rrect(draw, cam_cx-52, cam_cy-36, cam_cx+52, cam_cy+36, 12, fill=C_GREEN_DK)
    circle(draw, cam_cx, cam_cy, 20, fill=C_GREEN_LT)
    draw.rectangle([cam_cx+28, cam_cy-42, cam_cx+50, cam_cy-30], fill=C_GREEN_DK)
    txt(draw, W//2, 464, "사진 추가", font(30), C_GREEN_LT)

    # 이름 입력
    txt(draw, 56, 592, "영양제 이름", font(32, True), C_TEXT_PR, anchor="lm")
    rrect(draw, 40, 634, W-40, 702, 22, fill=C_SURFACE)
    txt(draw, 82, 668, "예: 비타민C, 오메가3", font(30), C_TEXT_SEC, anchor="lm")

    # 복용 시간
    txt(draw, 56, 754, "복용 시간", font(32, True), C_TEXT_PR, anchor="lm")
    chips = [("아침", True), ("점심", False), ("저녁", False), ("자기 전", False)]
    cx2 = 54
    f_chip = font(28)
    for label, selected in chips:
        w_c = int(draw.textlength(label, font=f_chip)) + 52
        bg_c = C_GREEN_LT if selected else C_SURFACE
        bc_c = C_GREEN_LT if selected else (210, 210, 218)
        tc_c = C_WHITE if selected else C_TEXT_SEC
        rrect(draw, cx2, 802, cx2+w_c, 854, 26, fill=bg_c, outline=bc_c, width=2)
        txt(draw, cx2 + w_c//2, 828, label, f_chip, tc_c)
        cx2 += w_c + 16

    # 등록된 영양제 미리보기
    txt(draw, 56, 916, "등록된 영양제", font(32, True), C_TEXT_PR, anchor="lm")
    prev_supps = [("비타민C", "아침"), ("오메가3", "점심")]
    for i, (name, t) in enumerate(prev_supps):
        py = 962 + i * 104
        card3 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(card3).rounded_rectangle([40, py, W-40, py+86], radius=22,
                                                 fill=(*C_SURFACE, 255))
        img = Image.alpha_composite(img, card3)
        draw = ImageDraw.Draw(img)

        circle(draw, 96, py+43, 28, fill=C_TAKEN_BG)
        draw_pill(draw, 96, py+43, 24, 12, C_GREEN_DK)
        txt(draw, 148, py+30, name, font(32, True), C_TEXT_PR, anchor="lm")
        txt(draw, 148, py+62, t, font(26), C_TEXT_SEC, anchor="lm")
        circle(draw, W-84, py+43, 18, fill=C_TAKEN)
        draw_check(draw, W-84, py+43, 20, C_WHITE, width=4)

    # 저장 버튼
    rrect(draw, 40, H-200, W-40, H-128, 28, fill=C_GREEN_LT)
    txt(draw, W//2, H-164, "저장하기", font(40, True), C_WHITE)

    img = phone_frame(img)
    img.save(os.path.join(OUT, "screenshot_2.png"))
    print("OK screenshot_2.png")


# ══════════════════════════════════════════════════════
if __name__ == "__main__":
    print("[시작] 하루 1분 스토어 에셋 생성 중...")
    make_icon()
    make_feature()
    make_screenshot_1()
    make_screenshot_2()
    print("[완료] 저장 위치:", OUT)
