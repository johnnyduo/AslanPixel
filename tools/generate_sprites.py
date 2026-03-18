#!/usr/bin/env python3
"""
Aslan Pixel — Sprite Sheet Generator
Generates all placeholder PNG sprites using the 16-color master palette.
Run from project root: python3 tools/generate_sprites.py
"""

from PIL import Image
import os

# ── Master 16-color palette ────────────────────────────────────────────────────
PAL = [
    (0x0A, 0x16, 0x28, 0),    # 00 Deep Navy → transparent
    (0x0D, 0x1F, 0x3C, 255),  # 01 Shadow Navy
    (0x16, 0x20, 0x40, 255),  # 02 Surface Navy
    (0x1C, 0x2A, 0x4E, 255),  # 03 Elevated Navy
    (0x3D, 0x5A, 0x78, 255),  # 04 Muted Steel
    (0xA8, 0xC4, 0xE0, 255),  # 05 Ice Blue
    (0xE8, 0xF4, 0xFF, 255),  # 06 Pixel White
    (0x00, 0xF5, 0xA0, 255),  # 07 Neon Green
    (0x00, 0xC7, 0x7D, 255),  # 08 Deep Green
    (0xF5, 0xC5, 0x18, 255),  # 09 Gold
    (0xC9, 0x94, 0x0A, 255),  # 10 Dark Gold
    (0x7B, 0x2F, 0xFF, 255),  # 11 Cyber Purple
    (0x5A, 0x1F, 0xCC, 255),  # 12 Deep Purple
    (0x00, 0xD9, 0xFF, 255),  # 13 Cyan
    (0x00, 0x9B, 0xB5, 255),  # 14 Deep Cyan
    (0xFF, 0x4D, 0x4F, 255),  # 15 Alert Red
]

# Helper to get RGBA tuple from palette index
def p(i): return PAL[i]
T = p(0)   # transparent


# ── Canvas helpers ─────────────────────────────────────────────────────────────

def new_canvas(w, h):
    """Create RGBA canvas filled with transparent."""
    img = Image.new('RGBA', (w, h), T)
    return img

def put_pixel(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)

def draw_rect(img, x, y, w, h, color):
    for dy in range(h):
        for dx in range(w):
            put_pixel(img, x + dx, y + dy, color)

def outline_rect(img, x, y, w, h, outline, fill=None):
    if fill:
        draw_rect(img, x + 1, y + 1, w - 2, h - 2, fill)
    for dx in range(w):
        put_pixel(img, x + dx, y, outline)
        put_pixel(img, x + dx, y + h - 1, outline)
    for dy in range(h):
        put_pixel(img, x, y + dy, outline)
        put_pixel(img, x + w - 1, y + dy, outline)

def strip(frames):
    """Combine list of 16×16 frames into a horizontal strip."""
    w = 16 * len(frames)
    strip_img = new_canvas(w, 16)
    for i, frame in enumerate(frames):
        strip_img.paste(frame, (i * 16, 0))
    return strip_img

def save(img, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, 'PNG')
    print(f'  ✓ {path}')


# ── Base character builder ─────────────────────────────────────────────────────

def draw_character(primary, secondary, head_detail=None, body_detail=None, offset_x=0):
    """
    Draw a 16×16 character with:
    - Outline in shadow navy
    - Body in primary color
    - Accent in secondary color
    - Optional head/body detail pixels
    offset_x: horizontal body sway (for animation)
    """
    img = new_canvas(16, 16)
    ox = offset_x

    # Outline color
    out = p(1)

    # Head (4×4 centered at top)
    hx = 6 + ox
    hy = 1
    outline_rect(img, hx, hy, 4, 4, out, fill=p(5))  # Ice blue skin

    # Eyes (2 pixels)
    put_pixel(img, hx + 1, hy + 1, p(6))
    put_pixel(img, hx + 2, hy + 1, p(6))

    # Body (6×5)
    bx = 5 + ox
    by = 5
    outline_rect(img, bx, by, 6, 5, out, fill=primary)

    # Arms (1×3 each side)
    # Left arm
    draw_rect(img, bx - 1, by, 1, 3, primary)
    put_pixel(img, bx - 1, by, out)
    put_pixel(img, bx - 1, by + 2, out)
    # Right arm
    draw_rect(img, bx + 6, by, 1, 3, primary)
    put_pixel(img, bx + 6, by, out)
    put_pixel(img, bx + 6, by + 2, out)

    # Legs (2×4 each)
    # Left leg
    outline_rect(img, bx, by + 5, 2, 4, out, fill=secondary)
    # Right leg
    outline_rect(img, bx + 3, by + 5, 2, 4, out, fill=secondary)

    # Head accessory detail
    if head_detail:
        for (dx, dy, ci) in head_detail:
            put_pixel(img, hx + dx, hy + dy, p(ci))

    # Body detail
    if body_detail:
        for (dx, dy, ci) in body_detail:
            put_pixel(img, bx + dx, by + dy, p(ci))

    return img


def animate_idle(primary, secondary, head_detail=None, body_detail=None, frames=4):
    """4-frame idle: subtle head bob and arm sway."""
    result = []
    bobs = [0, -1, 0, -1]  # y-offsets for head bob (not used in simple version)
    sways = [0, 0, 0, 0]   # body x offset
    for i in range(frames):
        f = draw_character(primary, secondary, head_detail, body_detail, sways[i])
        result.append(f)
    # Frame 1 & 3: blink
    for i in [1, 3]:
        f = result[i]
        hx = 6
        hy = 1
        put_pixel(f, hx + 1, hy + 1, p(5))  # close eyes (same as skin)
        put_pixel(f, hx + 2, hy + 1, p(5))
    return strip(result)


def animate_working(primary, secondary, head_detail=None, body_detail=None):
    """4-frame working: arms raised alternating."""
    result = []
    for i in range(4):
        f = draw_character(primary, secondary, head_detail, body_detail)
        # Raise left arm on frames 0,2; right on 1,3
        bx, by = 5, 5
        if i % 2 == 0:
            put_pixel(f, bx - 1, by - 1, primary)  # left arm up
            put_pixel(f, bx - 1, by - 2, primary)
        else:
            put_pixel(f, bx + 6, by - 1, primary)  # right arm up
            put_pixel(f, bx + 6, by - 2, primary)
        result.append(f)
    return strip(result)


# ── Agent sprites ──────────────────────────────────────────────────────────────

AGENTS = {
    'analyst':   (p(7),  p(8),   # neon green body, deep green legs
                  [(1, -1, 9), (2, -1, 9)],  # gold glasses above eyes
                  [(2, 1, 7), (3, 1, 7)]),   # glowing tablet
    'scout':     (p(9),  p(10),  # gold body, dark gold legs
                  [(1, -1, 9)],              # hood tip (gold dot above head)
                  [(1, 2, 13), (2, 2, 13)]), # binoculars (cyan)
    'guardian':  (p(11), p(12),  # cyber purple body, deep purple legs
                  [],
                  [(0, 1, 9), (0, 2, 9)]),  # gold shield on left
    'social':    (p(13), p(14),  # cyan body, deep cyan legs
                  [(2, -2, 6), (2, -3, 6)], # speech bubble above head
                  [(2, 0, 6)]),              # waving highlight
    'oracle':    (p(12), p(11),  # deep purple body, cyber purple legs
                  [(0, -2, 11), (3, -2, 11)],  # wizard hat brim
                  [(2, 1, 11), (3, 1, 11)]),   # crystal ball
}

STATES = ['idle', 'working', 'celebrating', 'returning', 'fail']


def make_agent_sprites(name, primary, secondary, head_detail, body_detail):
    out_dir = 'assets/sprites/agents'

    # idle (4 frames = 64×16)
    save(animate_idle(primary, secondary, head_detail, body_detail),
         f'{out_dir}/agent_{name}_idle.png')

    # working (4 frames = 64×16)
    save(animate_working(primary, secondary, head_detail, body_detail),
         f'{out_dir}/agent_{name}_working.png')

    # celebrating (6 frames = 96×16) — jump frames
    frames = []
    for i in range(6):
        f = draw_character(primary, secondary, head_detail, body_detail)
        # All arms raised
        bx, by = 5, 5
        put_pixel(f, bx - 1, by - 1, primary)
        put_pixel(f, bx + 6, by - 1, primary)
        if i % 2 == 0:
            # Add sparkle dot
            put_pixel(f, 0, 0, p(9))
            put_pixel(f, 15, 0, p(9))
        frames.append(f)
    save(strip(frames), f'{out_dir}/agent_{name}_celebrating.png')

    # returning (4 frames = 64×16) — walking frames
    walk_frames = []
    for i in range(4):
        f = draw_character(primary, secondary, head_detail, body_detail, offset_x=i % 2)
        walk_frames.append(f)
    save(strip(walk_frames), f'{out_dir}/agent_{name}_returning.png')

    # fail (3 frames = 48×16)
    fail_frames = []
    for i in range(3):
        f = draw_character(primary, secondary, head_detail, body_detail)
        # Red X on body
        bx, by = 5, 5
        put_pixel(f, bx + 1, by + 1, p(15))
        put_pixel(f, bx + 4, by + 1, p(15))
        put_pixel(f, bx + 2, by + 2, p(15))
        put_pixel(f, bx + 3, by + 2, p(15))
        put_pixel(f, bx + 1, by + 3, p(15))
        put_pixel(f, bx + 4, by + 3, p(15))
        fail_frames.append(f)
    save(strip(fail_frames), f'{out_dir}/agent_{name}_fail.png')


# ── Avatar sprites ─────────────────────────────────────────────────────────────

AVATARS = {
    'A1_NEXUS':    (p(7),  p(8)),   # neon green
    'A2_VALEN':    (p(9),  p(10)),  # gold
    'A3_LYRA':     (p(11), p(12)),  # cyber purple
    'A4_SORA':     (p(13), p(14)),  # cyan
    'A5_RIVEN':    (p(4),  p(3)),   # muted steel / elevated navy
    'A6_KAI':      (p(12), p(11)),  # deep purple
    'A7_SPECTER':  (p(5),  p(4)),   # ice blue / muted steel
    'A8_DRAKO':    (p(15), p(1)),   # alert red / shadow navy
}


def make_avatar(name, primary, secondary):
    img = draw_character(primary, secondary)
    save(img, f'assets/sprites/avatars/avatar_{name.lower()}_front.png')


# ── NPC sprites ────────────────────────────────────────────────────────────────

NPCS = {
    'banker':    (p(9),  p(10), [(1, -1, 9)],  [(2, 1, 9)]),   # gold + coin
    'trader':    (p(11), p(12), [(0, -1, 11)], [(2, 2, 13)]),  # purple + screen
    'champion':  (p(13), p(14), [(1, -1, 13)], [(2, 1, 6)]),   # cyan + trophy
    'merchant':  (p(9),  p(10), [(2, -2, 9)],  [(1, 3, 9)]),   # gold pack
    'sysbot':    (p(7),  p(8),  [(1, -1, 7)],  [(1, 2, 7)]),   # neon green
    'pixelcat':  (p(4),  p(3),  [],            []),             # steel cat
}


def make_npc_sprites(name, primary, secondary, head_detail, body_detail):
    out_dir = 'assets/sprites/npcs'
    save(animate_idle(primary, secondary, head_detail, body_detail),
         f'{out_dir}/npc_{name}_idle.png')


# ── Room item sprites ──────────────────────────────────────────────────────────

def make_room_item(name, w_tiles, h_tiles, primary, secondary, subdir='furniture'):
    """Generate a simple room item placeholder."""
    pw = w_tiles * 16
    ph = h_tiles * 16
    img = new_canvas(pw, ph)
    out = p(1)
    outline_rect(img, 0, 0, pw, ph, out, fill=primary)
    # Add accent stripe
    draw_rect(img, 2, 2, pw - 4, 2, secondary)
    # Label dot in center
    cx = pw // 2 - 1
    cy = ph // 2 - 1
    draw_rect(img, cx, cy, 2, 2, p(6))
    save(img, f'assets/sprites/room_items/{subdir}/{name}.png')


ROOM_ITEMS_FURNITURE = [
    ('desk_01', 2, 1, p(3), p(4)),
    ('desk_02', 2, 1, p(3), p(9)),
    ('desk_03', 2, 1, p(2), p(7)),
    ('chair_01', 1, 1, p(3), p(4)),
    ('bed_01', 2, 2, p(2), p(11)),
    ('sofa_01', 2, 1, p(3), p(11)),
    ('bookshelf_01', 1, 2, p(3), p(9)),
    ('cabinet_01', 1, 2, p(2), p(4)),
    ('rug_01', 2, 2, p(12), p(11)),
    ('chest_01', 1, 1, p(10), p(9)),
]

ROOM_ITEMS_DECOR = [
    ('plant_01', 1, 1, p(8), p(3)),
    ('plant_02', 1, 1, p(7), p(3)),
    ('plant_03', 1, 1, p(8), p(10)),
    ('lamp_01', 1, 1, p(9), p(3)),
    ('clock_01', 1, 1, p(4), p(6)),
    ('poster_finance', 1, 1, p(2), p(9)),
    ('poster_neon', 1, 1, p(2), p(7)),
]

ROOM_ITEMS_TECH = [
    ('monitor_01', 1, 1, p(3), p(13)),
    ('tv_01', 2, 1, p(1), p(13)),
    ('server_rack_01', 1, 2, p(2), p(7)),
    ('workstation_01', 2, 2, p(2), p(13)),
]

ROOM_ITEMS_SPECIAL = [
    ('hologram_01', 1, 1, p(12), p(11)),
    ('neon_sign_aslan', 2, 1, p(1), p(7)),
    ('pixel_cat_pet', 1, 1, p(4), p(3)),
    ('trophy_shelf_01', 2, 1, p(3), p(9)),
    ('golden_throne', 2, 2, p(10), p(9)),
    ('crystal_ball_desk', 1, 1, p(12), p(11)),
]


# ── UI icons ───────────────────────────────────────────────────────────────────

def make_ui_icons():
    out_dir = 'assets/sprites/ui'

    icons = {
        'coin_icon':    (p(9),  p(10), p(6)),
        'xp_icon':      (p(13), p(14), p(6)),
        'quest_icon':   (p(7),  p(8),  p(6)),
        'lock_icon':    (p(4),  p(3),  p(6)),
        'star_icon':    (p(9),  p(10), p(6)),
        'arrow_right':  (p(7),  p(8),  p(6)),
    }

    for name, (primary, secondary, highlight) in icons.items():
        img = new_canvas(16, 16)
        # Circle base
        cx, cy, r = 8, 8, 6
        for y in range(16):
            for x in range(16):
                dx, dy = x - cx, y - cy
                dist = (dx*dx + dy*dy) ** 0.5
                if dist <= r:
                    if dist >= r - 1:
                        img.putpixel((x, y), p(1))   # outline
                    elif dist <= 2:
                        img.putpixel((x, y), highlight)  # center highlight
                    else:
                        img.putpixel((x, y), primary)
        save(img, f'{out_dir}/{name}.png')


# ── Effects ────────────────────────────────────────────────────────────────────

def make_effects():
    out_dir = 'assets/sprites/effects'
    effects = [
        ('effect_analyst_data', p(7), p(8)),
        ('effect_scout_beam', p(13), p(14)),
        ('effect_guardian_shield', p(9), p(10)),
        ('effect_social_heart', p(13), p(14)),
        ('effect_oracle_ring', p(11), p(13)),
    ]

    for name, primary, secondary in effects:
        # 8-frame horizontal strip: 128×16
        frames = []
        for i in range(8):
            f = new_canvas(16, 16)
            alpha = max(50, 255 - i * 28)
            # Expanding ring effect
            r = 2 + i
            cx, cy = 8, 8
            for y in range(16):
                for x in range(16):
                    dx, dy = x - cx, y - cy
                    dist = (dx*dx + dy*dy) ** 0.5
                    if r - 1 <= dist <= r:
                        color = primary if i % 2 == 0 else secondary
                        f.putpixel((x, y), (*color[:3], alpha))
            frames.append(f)
        save(strip(frames), f'{out_dir}/{name}.png')


# ── Palette file ───────────────────────────────────────────────────────────────

def write_palette():
    lines = ['JASC-PAL', '0100', '16']
    for r, g, b, _ in PAL:
        lines.append(f'{r} {g} {b}')
    path = 'assets/aslan_16color.pal'
    os.makedirs(os.path.dirname(path) if os.path.dirname(path) else '.', exist_ok=True)
    with open(path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print(f'  ✓ {path}')


# ── Main ───────────────────────────────────────────────────────────────────────

def main():
    print('\n=== Aslan Pixel Sprite Generator ===\n')

    print('→ Agent sprites...')
    for name, (primary, secondary, head, body) in AGENTS.items():
        make_agent_sprites(name, primary, secondary, head, body)

    print('\n→ Avatar sprites...')
    for name, (primary, secondary) in AVATARS.items():
        make_avatar(name, primary, secondary)

    print('\n→ NPC sprites...')
    for name, (primary, secondary, head, body) in NPCS.items():
        make_npc_sprites(name, primary, secondary, head, body)

    print('\n→ Room items — furniture...')
    for name, w, h, primary, secondary in ROOM_ITEMS_FURNITURE:
        make_room_item(name, w, h, primary, secondary, 'furniture')

    print('\n→ Room items — decorations...')
    for name, w, h, primary, secondary in ROOM_ITEMS_DECOR:
        make_room_item(name, w, h, primary, secondary, 'decorations')

    print('\n→ Room items — technology...')
    for name, w, h, primary, secondary in ROOM_ITEMS_TECH:
        make_room_item(name, w, h, primary, secondary, 'technology')

    print('\n→ Room items — special...')
    for name, w, h, primary, secondary in ROOM_ITEMS_SPECIAL:
        make_room_item(name, w, h, primary, secondary, 'special')

    print('\n→ UI icons...')
    make_ui_icons()

    print('\n→ Effects...')
    make_effects()

    print('\n→ Palette file...')
    write_palette()

    print('\n✅ All sprites generated!\n')
    # Count files
    total = 0
    for root, _, files in os.walk('assets/sprites'):
        total += sum(1 for f in files if f.endswith('.png'))
    print(f'   Total PNGs: {total}')


if __name__ == '__main__':
    main()
