"""Generate expressive illustrated anime-fantasy bust portraits (256x256) for all 8 Aethelgard NPCs."""

import math
import os
from PIL import Image, ImageDraw, ImageFilter

OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "ui")
SIZE = 512  # Render at 2x and downsample to 256x256 for crisp anti-aliasing


def lerp_col(c1, c2, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(round(c1[i] + (c2[i] - c1[i]) * t)) for i in range(len(c1)))


def draw_radial_bg(img, top_col, bot_col, glow_col, accent_stars=True):
    px = img.load()
    cx, cy = SIZE * 0.5, SIZE * 0.44
    max_r = SIZE * 0.56
    for y in range(SIZE):
        vy = y / float(SIZE)
        base = lerp_col(top_col, bot_col, vy)
        for x in range(SIZE):
            dx = x - cx
            dy = y - cy
            d = math.sqrt(dx * dx + dy * dy) / max_r
            g = max(0.0, 1.0 - d) ** 1.8
            c = lerp_col(base, glow_col, g * 0.65)
            # Vignette edges
            vig = max(0.0, (d - 0.65) / 0.45)
            c = lerp_col(c, (8, 10, 22), min(0.75, vig * 0.7))
            px[x, y] = (*c, 255)

    draw = ImageDraw.Draw(img, "RGBA")
    if accent_stars:
        # Subtle astrolabe orbit rings in background
        draw.arc([44, 44, SIZE - 44, SIZE - 44], 0, 360, fill=(*glow_col, 55), width=2)
        draw.arc([70, 70, SIZE - 70, SIZE - 70], 15, 210, fill=(244, 205, 115, 95), width=2)
        for sx, sy, sr in [(92, 108, 4), (415, 130, 5), (120, 388, 3), (402, 366, 4), (256, 56, 5)]:
            draw.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 244, 205, 190))


def draw_star(draw, cx, cy, r, col):
    pts = [
        (cx, cy - r),
        (cx + r * 0.28, cy - r * 0.28),
        (cx + r, cy),
        (cx + r * 0.28, cy + r * 0.28),
        (cx, cy + r),
        (cx - r * 0.28, cy + r * 0.28),
        (cx - r, cy),
        (cx - r * 0.28, cy - r * 0.28),
    ]
    draw.polygon(pts, fill=col)


def draw_character(cfg):
    img = Image.new("RGBA", (SIZE, SIZE), (10, 12, 26, 255))
    draw_radial_bg(img, cfg["bg_top"], cfg["bg_bot"], cfg["bg_glow"])

    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer, "RGBA")

    skin = cfg["skin"]
    skin_shadow = cfg["skin_shadow"]
    hair = cfg["hair"]
    hair_dark = cfg["hair_dark"]
    hair_hi = cfg["hair_hi"]
    outfit = cfg["outfit"]
    outfit_dark = cfg["outfit_dark"]
    trim = cfg["trim"]
    eye_col = cfg["eye"]
    eye_dark = cfg["eye_dark"]

    # 1. Back hair mass
    bh_w = cfg.get("back_hair_w", 126)
    bh_bot = cfg.get("back_hair_bot", 440)
    d.rounded_rectangle([256 - bh_w, 96, 256 + bh_w, bh_bot], radius=82, fill=(*hair_dark, 255))
    if cfg.get("ponytail"):
        d.polygon([(310, 175), (412, 235), (424, 385), (344, 415), (305, 290)], fill=(*hair_dark, 255))
        d.polygon([(318, 186), (392, 245), (396, 360), (336, 378)], fill=(*hair, 255))
        d.ellipse([306, 172, 336, 202], fill=(*trim, 255))
    if cfg.get("curls"):
        for cx, cy, cr in [(140, 290, 48), (372, 290, 48), (130, 368, 52), (382, 368, 52), (146, 435, 44), (366, 435, 44)]:
            d.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(*hair_dark, 255))
            d.ellipse([cx - cr + 8, cy - cr + 6, cx + cr - 10, cy + cr - 8], fill=(*hair, 255))

    # 2. Shoulders / Cloak / Collar / Armor
    d.polygon([(82, 512), (118, 368), (195, 338), (317, 338), (394, 368), (430, 512)], fill=(*outfit_dark, 255))
    d.polygon([(102, 512), (132, 378), (200, 348), (312, 348), (380, 378), (410, 512)], fill=(*outfit, 255))

    # Outfit details
    style = cfg.get("outfit_style", "coat")
    if style == "scholar":
        # High sapphire coat + cravat + brass brooch
        d.polygon([(205, 348), (256, 468), (307, 348)], fill=(238, 242, 252, 255))
        d.polygon([(234, 386), (256, 485), (278, 386), (256, 368)], fill=(*trim, 255))
        d.ellipse([242, 368, 270, 396], fill=(95, 224, 242, 255), outline=(244, 208, 120, 255), width=3)
    elif style == "armor":
        # Pauldrons + knight cape clasp
        d.pieslice([82, 340, 225, 455], 180, 360, fill=(195, 208, 226, 255), outline=(*trim, 255), width=4)
        d.pieslice([287, 340, 430, 455], 180, 360, fill=(195, 208, 226, 255), outline=(*trim, 255), width=4)
        d.polygon([(210, 348), (256, 430), (302, 348)], fill=(38, 52, 88, 255))
        d.ellipse([198, 362, 224, 388], fill=(*trim, 255))
        d.ellipse([288, 362, 314, 388], fill=(*trim, 255))
        d.line([(212, 375), (300, 375)], fill=(*trim, 255), width=5)
    elif style == "street":
        # Hooded collar + teal scarf
        d.rounded_rectangle([162, 336, 350, 404], radius=26, fill=(48, 86, 74, 255), outline=(*trim, 255), width=3)
        d.polygon([(215, 396), (242, 498), (275, 492), (256, 396)], fill=(62, 118, 98, 255))
    elif style == "prince":
        # Gold epaulets + royal cravat + crimson sash
        d.rounded_rectangle([108, 346, 202, 386], radius=14, fill=(*trim, 255))
        d.rounded_rectangle([310, 346, 404, 386], radius=14, fill=(*trim, 255))
        d.polygon([(214, 348), (256, 472), (298, 348)], fill=(250, 246, 236, 255))
        d.polygon([(140, 512), (336, 352), (376, 368), (195, 512)], fill=(158, 34, 58, 220))
        d.polygon([(238, 380), (256, 412), (274, 380), (256, 364)], fill=(*trim, 255))
    elif style == "oracle":
        # Draped lilac shawl + gold crescent brooch
        d.polygon([(130, 362), (256, 466), (382, 362), (338, 346), (256, 412), (174, 346)], fill=(214, 194, 246, 235))
        d.arc([234, 396, 278, 440], 25, 315, fill=(*trim, 255), width=6)
    elif style == "mirror":
        # High obsidian-violet astral robe + golden chains on collar
        d.polygon([(165, 330), (208, 392), (256, 475), (304, 392), (347, 330), (322, 362), (256, 348), (190, 362)], fill=(58, 34, 96, 255))
        d.line([(168, 382), (256, 434), (344, 382)], fill=(*trim, 255), width=5)
        draw_star(d, 256, 434, 15, (*trim, 255))
    elif style == "lady":
        # Pearl neckline + lace sweetheart bodice + rose gold ribbon
        d.polygon([(180, 348), (256, 444), (332, 348), (312, 342), (256, 384), (200, 342)], fill=(252, 238, 242, 255))
        d.polygon([(218, 392), (256, 446), (294, 392), (256, 376)], fill=(224, 152, 174, 255), outline=(*trim, 255), width=3)
        draw_star(d, 256, 408, 11, (*trim, 255))
        for px in range(202, 312, 16):
            py = 364 + int(12 * math.sin((px - 200) / 110.0 * math.pi))
            d.ellipse([px - 5, py - 5, px + 5, py + 5], fill=(255, 250, 246, 255), outline=(222, 198, 178, 255), width=1)
        # Folding court fan peeking at lower right
        d.pieslice([294, 392, 466, 558], 218, 298, fill=(248, 214, 224, 245), outline=(*trim, 255), width=4)
    elif style == "mercenary":
        # Fur-trimmed grey cloak + weathered steel pauldron + crimson clasp
        d.rounded_rectangle([146, 326, 366, 394], radius=28, fill=(102, 108, 122, 255), outline=(72, 76, 90, 255), width=3)
        d.pieslice([82, 348, 218, 458], 180, 355, fill=(128, 138, 154, 255), outline=(185, 194, 208, 255), width=4)
        d.polygon([(218, 368), (256, 458), (294, 368)], fill=(48, 52, 62, 255))
        d.line([(206, 364), (306, 392)], fill=(*trim, 255), width=6)
        d.ellipse([284, 378, 314, 408], fill=(178, 44, 58, 255), outline=(228, 190, 125, 255), width=3)

    # 3. Neck & clean neck shadow (tight on neck width so no horns protrude)
    d.polygon([(228, 302), (284, 302), (292, 378), (220, 378)], fill=(*skin, 255))
    d.ellipse([226, 292, 286, 336], fill=(*skin_shadow, 255))

    # 4. Ears
    d.ellipse([156, 224, 182, 268], fill=(*skin_shadow, 255))
    d.ellipse([330, 224, 356, 268], fill=(*skin_shadow, 255))
    if cfg.get("earring"):
        d.ellipse([162, 260, 174, 276], fill=(*trim, 255))
        d.ellipse([338, 260, 350, 276], fill=(*trim, 255))

    # 5. Face shape (soft anime oval + tapered jaw with subtle rim outline)
    face_pts = [
        (168, 185), (174, 136), (256, 118), (338, 136), (344, 185),
        (336, 254), (306, 304), (256, 324), (206, 304), (176, 254)
    ]
    d.polygon(face_pts, fill=(*skin, 255), outline=(*skin_shadow, 220), width=2)
    # Subtle blush
    blush = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(blush, "RGBA")
    bd.ellipse([180, 250, 222, 270], fill=(242, 146, 152, 95))
    bd.ellipse([290, 250, 332, 270], fill=(242, 146, 152, 95))
    blush = blush.filter(ImageFilter.GaussianBlur(7))
    layer.alpha_composite(blush)
    d = ImageDraw.Draw(layer, "RGBA")

    # 6. Eyes
    if cfg.get("blindfold"):
        # Mirari wears an ornate translucent lilac silk ribbon across eyes
        d.polygon([(164, 206), (348, 206), (342, 246), (170, 246)], fill=(198, 178, 238, 235), outline=(*trim, 255), width=3)
        d.line([(168, 226), (344, 226)], fill=(244, 210, 130, 170), width=2)
        draw_star(d, 256, 226, 9, (*trim, 255))
    else:
        for side, ex in [(-1, 214), (1, 298)]:
            # Eye white
            d.ellipse([ex - 22, 206, ex + 22, 246], fill=(248, 250, 255, 255))
            # Iris
            d.ellipse([ex - 13, 208, ex + 13, 244], fill=(*eye_col, 255))
            d.pieslice([ex - 13, 208, ex + 13, 244], 190, 350, fill=(*eye_dark, 255))
            # Pupil
            d.ellipse([ex - 6, 218, ex + 6, 234], fill=(20, 18, 34, 255))
            # Catchlights
            d.ellipse([ex - 9, 212, ex - 2, 220], fill=(255, 255, 255, 245))
            d.ellipse([ex + 4, 231, ex + 9, 236], fill=(255, 255, 255, 210))
            # Upper lash line
            lash_w = 5 if cfg.get("fem") else 4
            d.arc([ex - 25, 202, ex + 25, 240], 195, 345, fill=(32, 24, 42, 255), width=lash_w)
            # Eyebrow
            brow_y = 192 if not cfg.get("fierce_brow") else (196 if side == -1 else 196)
            if cfg.get("fierce_brow"):
                d.line([(ex - 20 * side, brow_y + 4), (ex + 18 * side, brow_y - 3)], fill=(*hair_dark, 255), width=4)
            else:
                d.arc([ex - 20, 186, ex + 20, 206], 200, 340, fill=(*hair_dark, 255), width=3)

    # 7. Glasses (Soren) or Cheek Scar (Caelum)
    if cfg.get("glasses"):
        d.ellipse([186, 201, 242, 249], outline=(228, 236, 248, 235), width=3)
        d.ellipse([270, 201, 326, 249], outline=(228, 236, 248, 235), width=3)
        d.line([(242, 222), (270, 222)], fill=(228, 236, 248, 235), width=3)
    if cfg.get("scar"):
        d.line([(286, 244), (324, 282)], fill=(198, 126, 122, 220), width=4)
        d.line([(295, 260), (305, 250)], fill=(198, 126, 122, 180), width=2)
        d.line([(306, 272), (316, 262)], fill=(198, 126, 122, 180), width=2)

    # 8. Nose & Mouth
    d.line([(256, 244), (253, 262), (259, 264)], fill=(*skin_shadow, 220), width=2)
    expr = cfg.get("expr", "calm")
    if expr == "smile":
        d.arc([238, 272, 274, 294], 15, 165, fill=(176, 86, 94, 255), width=3)
    elif expr == "smirk":
        d.arc([238, 274, 276, 294], 5, 130, fill=(166, 84, 88, 255), width=3)
    else:
        d.line([(242, 284), (270, 284)], fill=(168, 92, 96, 255), width=3)

    # 9. Front hair crown & locks
    d.pieslice([144, 78, 368, 240], 172, 368, fill=(*hair, 255))
    # Bangs locks
    bang_locks = cfg.get("bangs", [
        [(164, 152), (178, 235), (206, 165)],
        [(194, 126), (218, 212), (240, 140)],
        [(234, 118), (254, 210), (276, 132)],
        [(270, 124), (296, 214), (316, 138)],
        [(306, 146), (332, 236), (348, 154)],
    ])
    for poly in bang_locks:
        d.polygon(poly, fill=(*hair, 255))
    # Side framing strands
    d.polygon([(148, 175), (176, 180), (180, 340), (154, 376)], fill=(*hair, 255))
    d.polygon([(336, 180), (364, 175), (358, 376), (332, 340)], fill=(*hair, 255))
    # Hair glossy highlight arc
    d.arc([172, 112, 340, 198], 205, 335, fill=(*hair_hi, 175), width=8)

    # 10. Headgear / Hair accessory
    if cfg.get("headpiece") == "tiara":
        d.arc([204, 92, 308, 144], 195, 345, fill=(*trim, 255), width=5)
        draw_star(d, 256, 98, 12, (*trim, 255))
        d.ellipse([226, 102, 238, 114], fill=(255, 250, 246, 255))
        d.ellipse([274, 102, 286, 114], fill=(255, 250, 246, 255))
    elif cfg.get("headpiece") == "bandana":
        d.arc([158, 102, 354, 182], 185, 355, fill=(72, 158, 126, 255), width=16)
        d.rounded_rectangle([182, 110, 232, 138], radius=9, fill=(214, 176, 92, 255), outline=(42, 48, 56, 255), width=3)
        d.rounded_rectangle([280, 110, 330, 138], radius=9, fill=(214, 176, 92, 255), outline=(42, 48, 56, 255), width=3)
    elif cfg.get("headpiece") == "circlet":
        d.arc([168, 120, 344, 186], 200, 340, fill=(*trim, 255), width=6)
        draw_star(d, 256, 124, 11, (*trim, 255))

    # Composite character cleanly inside framed portrait medallion
    img.alpha_composite(layer)

    # 11. Ornate circular/rounded medallion vignette border
    frame = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame, "RGBA")
    fd.rectangle([0, 0, SIZE, SIZE], outline=(*cfg["frame_col"], 255), width=10)
    fd.rectangle([12, 12, SIZE - 12, SIZE - 12], outline=(244, 206, 118, 220), width=4)
    # Corner stars
    for cx, cy in [(22, 22), (SIZE - 22, 22), (22, SIZE - 22), (SIZE - 22, SIZE - 22)]:
        draw_star(fd, cx, cy, 10, (248, 218, 136, 255))
    img.alpha_composite(frame)

    final_img = img.resize((256, 256), Image.Resampling.LANCZOS)
    out_path = os.path.join(OUT_DIR, f"npc_{cfg['id']}.png")
    final_img.save(out_path, "PNG")
    print(f"Generated {out_path} ({os.path.getsize(out_path)} bytes)")


CHARACTERS = [
    {
        "id": "soren",
        "bg_top": (14, 34, 68), "bg_bot": (8, 18, 42), "bg_glow": (73, 214, 200),
        "frame_col": (34, 88, 112),
        "skin": (250, 228, 214), "skin_shadow": (222, 186, 168),
        "hair": (46, 78, 136), "hair_dark": (26, 44, 86), "hair_hi": (124, 178, 242),
        "outfit": (32, 54, 104), "outfit_dark": (18, 30, 64), "trim": (78, 186, 198),
        "eye": (64, 198, 214), "eye_dark": (26, 102, 138),
        "outfit_style": "scholar", "glasses": True, "expr": "calm",
        "back_hair_w": 116, "back_hair_bot": 350,
    },
    {
        "id": "vespera",
        "bg_top": (32, 36, 78), "bg_bot": (16, 18, 42), "bg_glow": (255, 159, 90),
        "frame_col": (118, 76, 56),
        "skin": (252, 232, 220), "skin_shadow": (224, 190, 175),
        "hair": (186, 208, 236), "hair_dark": (116, 140, 178), "hair_hi": (236, 246, 255),
        "outfit": (42, 62, 112), "outfit_dark": (24, 34, 68), "trim": (238, 184, 92),
        "eye": (106, 162, 242), "eye_dark": (42, 74, 152),
        "outfit_style": "armor", "ponytail": True, "fierce_brow": True, "fem": True, "expr": "calm",
        "back_hair_w": 114, "back_hair_bot": 355,
    },
    {
        "id": "kaelen",
        "bg_top": (16, 48, 52), "bg_bot": (8, 24, 30), "bg_glow": (134, 227, 166),
        "frame_col": (52, 112, 82),
        "skin": (240, 206, 182), "skin_shadow": (204, 162, 136),
        "hair": (76, 52, 42), "hair_dark": (46, 30, 24), "hair_hi": (146, 104, 82),
        "outfit": (38, 52, 64), "outfit_dark": (22, 30, 40), "trim": (118, 214, 154),
        "eye": (78, 202, 134), "eye_dark": (28, 108, 66),
        "outfit_style": "street", "headpiece": "bandana", "earring": True, "expr": "smirk",
        "back_hair_w": 118, "back_hair_bot": 355,
    },
    {
        "id": "cassian",
        "bg_top": (54, 42, 74), "bg_bot": (24, 18, 42), "bg_glow": (247, 227, 161),
        "frame_col": (134, 104, 52),
        "skin": (252, 232, 218), "skin_shadow": (226, 192, 174),
        "hair": (236, 198, 112), "hair_dark": (176, 134, 62), "hair_hi": (255, 242, 198),
        "outfit": (48, 62, 114), "outfit_dark": (26, 36, 74), "trim": (242, 202, 104),
        "eye": (218, 156, 58), "eye_dark": (134, 78, 22),
        "outfit_style": "prince", "headpiece": "circlet", "expr": "smile",
        "back_hair_w": 116, "back_hair_bot": 352,
    },
    {
        "id": "mirari",
        "bg_top": (48, 28, 78), "bg_bot": (20, 12, 44), "bg_glow": (171, 128, 247),
        "frame_col": (104, 74, 158),
        "skin": (252, 236, 228), "skin_shadow": (224, 194, 186),
        "hair": (182, 154, 234), "hair_dark": (122, 92, 178), "hair_hi": (234, 218, 255),
        "outfit": (236, 232, 248), "outfit_dark": (182, 172, 212), "trim": (238, 198, 108),
        "eye": (174, 134, 244), "eye_dark": (96, 58, 168),
        "outfit_style": "oracle", "blindfold": True, "earring": True, "fem": True, "expr": "smile",
        "back_hair_w": 136, "back_hair_bot": 465,
    },
    {
        "id": "zephyr",
        "bg_top": (36, 16, 66), "bg_bot": (12, 8, 30), "bg_glow": (255, 107, 152),
        "frame_col": (138, 64, 118),
        "skin": (242, 226, 238), "skin_shadow": (204, 182, 206),
        "hair": (212, 206, 244), "hair_dark": (122, 108, 168), "hair_hi": (255, 245, 255),
        "outfit": (38, 22, 68), "outfit_dark": (20, 12, 40), "trim": (246, 204, 112),
        "eye": (196, 98, 238), "eye_dark": (98, 32, 148),
        "outfit_style": "mirror", "fierce_brow": True, "expr": "smirk",
        "back_hair_w": 130, "back_hair_bot": 430,
    },
    {
        "id": "lyra",
        "bg_top": (72, 34, 58), "bg_bot": (28, 14, 34), "bg_glow": (245, 162, 204),
        "frame_col": (162, 92, 128),
        "skin": (254, 236, 226), "skin_shadow": (228, 194, 182),
        "hair": (238, 182, 168), "hair_dark": (178, 118, 108), "hair_hi": (255, 234, 224),
        "outfit": (196, 108, 142), "outfit_dark": (136, 62, 94), "trim": (246, 212, 134),
        "eye": (74, 198, 146), "eye_dark": (28, 112, 78),
        "outfit_style": "lady", "headpiece": "tiara", "curls": True, "earring": True, "fem": True, "expr": "smirk",
        "back_hair_w": 134, "back_hair_bot": 445,
    },
    {
        "id": "caelum",
        "bg_top": (38, 44, 58), "bg_bot": (16, 18, 28), "bg_glow": (182, 198, 222),
        "frame_col": (116, 124, 144),
        "skin": (238, 212, 192), "skin_shadow": (198, 164, 142),
        "hair": (152, 160, 174), "hair_dark": (92, 98, 112), "hair_hi": (218, 226, 238),
        "outfit": (56, 62, 76), "outfit_dark": (34, 38, 48), "trim": (194, 86, 94),
        "eye": (236, 168, 56), "eye_dark": (146, 86, 18),
        "outfit_style": "mercenary", "scar": True, "fierce_brow": True, "expr": "smirk",
        "back_hair_w": 122, "back_hair_bot": 365,
        "bangs": [
            [(160, 148), (172, 242), (202, 168)],
            [(192, 124), (208, 222), (236, 142)],
            [(228, 116), (254, 218), (274, 134)],
            [(266, 122), (298, 224), (318, 142)],
            [(308, 142), (338, 240), (352, 152)],
        ]
    },
]

if __name__ == "__main__":
    os.makedirs(OUT_DIR, exist_ok=True)
    for ch in CHARACTERS:
        draw_character(ch)
