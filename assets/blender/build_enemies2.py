# Pulsebreak 2.0 enemies + boss, Mk2: smooth subdivision/lathe construction
# (same language as the Courier Mk3 hero), keeping the exact node contract
# scripts/art.gd expects: flat MeshInstance children under Body (flinch rig
# groups them by origin height/x), plus root-level Reactor/Shield/Ring.
# Godot coords (Y up, +Z forward) -> Blender (x, -z, y).
# Usage: Blender -b --factory-startup --python-exit-code 1 -P build_enemies2.py -- [--render]
import sys, os, math
sys.path.insert(0, "/Users/xinboonchen/.local/share/muse/skills/bundled/muse-core--exact-minimal-literal-tests/skills/blender/scripts")
import bpy
import bpy_helpers as H

ROOT = "/Users/xinboonchen/Projects/pulsebreak"
MODELS = os.path.join(ROOT, "assets", "models")
PREVIEW = "/tmp/pb-assets"
os.makedirs(MODELS, exist_ok=True); os.makedirs(PREVIEW, exist_ok=True)
COL = None

def make_mats():
    m = {}
    m["ceramic"]  = H.material("Ceramic",  "#E8E6DE", roughness=0.30, metallic=0.05, coat=0.7, coat_roughness=0.25)
    m["white"]    = H.material("WarmWhite", "#F2EDE2", roughness=0.38, metallic=0.05, coat=0.4, coat_roughness=0.3)
    m["dark"]     = H.material("DarkFrame", "#15171B", roughness=0.52, metallic=0.65)
    m["gunmetal"] = H.material("Gunmetal",  "#2A2721", roughness=0.36, metallic=0.85)
    m["titanium"] = H.material("Titanium",  "#9AA7B4", roughness=0.24, metallic=0.9)
    m["brass"]    = H.material("Brass",     "#B08A45", roughness=0.30, metallic=1.0)
    m["visor"]    = H.material("Visor",     "#0A0F14", roughness=0.08, metallic=0.9, coat=1.0, coat_roughness=0.06)
    m["rubber"]   = H.material("Rubber",    "#14181F", roughness=0.95, metallic=0.0)
    m["steel"]    = H.material("Steel",     "#3A4249", roughness=0.42, metallic=0.85)
    m["edge"]     = H.material("EdgeSteel", "#565F68", roughness=0.38, metallic=0.85)
    m["rust_dark"]  = H.material("RustDark",  "#5F2A1C", roughness=0.50, metallic=0.35, coat=0.3, coat_roughness=0.4)
    m["rust_plate"] = H.material("RustPlate", "#9C4028", roughness=0.42, metallic=0.30, coat=0.45, coat_roughness=0.35)
    m["orange"]   = H.material("HostileOrange", "#C85A26", roughness=0.46, metallic=0.3)
    m["copper"]   = H.material("Copper", "#B56B45", roughness=0.34, metallic=1.0)
    m["glow_amber"]  = H.material("GlowAmber",  "#3A1E00", roughness=0.4, metallic=0.0, emission="#FFB35C", emission_strength=2.8)
    m["glow_orange"] = H.material("GlowOrange", "#3A1500", roughness=0.4, metallic=0.0, emission="#FF8A1A", emission_strength=3.4)
    m["glow_hot"]    = H.material("GlowHot",    "#401A00", roughness=0.4, metallic=0.0, emission="#FFE4A2", emission_strength=3.6)
    m["glow_red"]    = H.material("GlowRed",    "#2A0505", roughness=0.4, metallic=0.0, emission="#FF4A3A", emission_strength=3.0)
    return m

def P(g): return (g[0], -g[2], g[1])
def R(g): return (g[0], -g[2], g[1])

def grp(name, parent, loc_g=(0, 0, 0)):
    e = bpy.data.objects.new(name, None)
    COL.objects.link(e)
    e.empty_display_size = 0.05
    if parent is not None:
        H.parent(e, parent, keep_transform=False)
    e.location = P(loc_g)
    return e

def place(obj, parent, loc_g, rot_g=(0, 0, 0)):
    H.parent(obj, parent, keep_transform=False)
    obj.location = P(loc_g)
    obj.rotation_euler = R(rot_g)
    return obj

def _smooth(o, levels=1):
    if levels > 0:
        H.add_modifier(o, "SUBSURF", levels=levels, render_levels=levels)
    H.shade_smooth(o, angle=55)
    return o

def plate(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0), bevel=0.012):
    sx, sy, sz = size_g
    o = H.add_box(name, size=(sx, sz, sy), bevel=min(bevel, min(sx, sy, sz) * 0.32), mat=mat, collection=COL)
    H.shade_smooth(o, angle=42)
    return place(o, parent, center_g, rot_g)

def shell(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0), bevel=0.02, levels=1):
    sx, sy, sz = size_g
    o = H.add_box(name, size=(sx, sz, sy), bevel=min(bevel, min(sx, sy, sz) * 0.32), mat=mat, collection=COL)
    _smooth(o, levels)
    return place(o, parent, center_g, rot_g)

def ball(parent, name, center_g, radii_g, mat, rot_g=(0, 0, 0), levels=0):
    # Spheres are already smooth; subdivision would only bloat swarm enemies.
    o = H.add_sphere(name, radius=1.0, scale=(radii_g[0], radii_g[2], radii_g[1]), mat=mat,
                     segments=32, rings=20, collection=COL)
    _smooth(o, levels)
    return place(o, parent, center_g, rot_g)

def cyl(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0), top_ratio=1.0, verts=28):
    o = H.add_cylinder(name, radius=size_g[0], depth=size_g[1], radius_top=size_g[0] * top_ratio,
                       vertices=verts, bevel=size_g[0] * 0.08, mat=mat, collection=COL)
    H.shade_smooth(o, angle=50)
    return place(o, parent, center_g, rot_g)

def cone(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0)):
    return cyl(parent, name, center_g, size_g, mat, rot_g, top_ratio=0.08, verts=24)

def lathe(parent, name, center_g, profile, mat, scale_g=(1, 1, 1), rot_g=(0, 0, 0), segments=28):
    o = H.add_lathe(name, profile, segments=segments, mat=mat, collection=COL, close_ends=True)
    o.scale = (scale_g[0], scale_g[2], scale_g[1])
    H.shade_smooth(o, angle=55)
    return place(o, parent, center_g, rot_g)

def beam(parent, name, a_g, b_g, radius, mat):
    o = H.add_tube(name, [P(a_g), P(b_g)], radius=radius, mat=mat, collection=COL, resolution=1, bevel_resolution=10)
    H.parent(o, parent, keep_transform=False)
    o.location = (0, 0, 0)
    return o

def cable(parent, name, pts_g, radius, mat):
    o = H.add_tube(name, [P(p) for p in pts_g], radius=radius, mat=mat, collection=COL, bevel_resolution=8)
    H.parent(o, parent, keep_transform=False)
    o.location = (0, 0, 0)
    return o

def vents(parent, name, center_g, size_g, mat, rows=3):
    for i in range(rows):
        dy = (i - (rows - 1) / 2) * size_g[1] * 0.95
        plate(parent, f"{name}Vent{i}", (center_g[0], center_g[1] + dy, center_g[2]),
              (size_g[0], size_g[1] * 0.42, size_g[2]), mat, bevel=0.002)

def bolts(parent, name, center_g, spread_g, mat, count=4, r=0.009):
    for i in range(count):
        a = (i / count) * math.tau + math.pi / 4
        c = (center_g[0] + math.cos(a) * spread_g[0], center_g[1] + math.sin(a) * spread_g[1], center_g[2] + spread_g[2])
        cyl(parent, f"{name}Bolt{i}", c, (r, 0.012, r), mat, (math.pi / 2, 0, 0), verts=6)

def enemy_root(name):
    root = grp(name, None)
    body = grp("Body", root)
    return root, body


def build_gunner(M):
    root, body = enemy_root("GunnerModel")
    for i in range(3):
        a = math.tau * i / 3.0 + math.pi
        sx, cz = math.sin(a), math.cos(a)
        foot = (sx * 0.46, 0.085, cz * 0.46)
        knee = (sx * 0.39, 0.44, cz * 0.39)
        hip = (sx * 0.17, 0.76, cz * 0.17)
        beam(body, f"LegUpper{i}", hip, knee, 0.052, M["rust_plate"])
        beam(body, f"LegLower{i}", knee, foot, 0.040, M["titanium"])
        beam(body, f"LegPiston{i}", (sx * 0.20, 0.62, cz * 0.20), (sx * 0.36, 0.30, cz * 0.36), 0.016, M["brass"])
        ball(body, f"KneeBall{i}", knee, (0.085, 0.085, 0.085), M["gunmetal"])
        cyl(body, f"KneeDisc{i}", (knee[0] * 1.16, knee[1], knee[2] * 1.16), (0.05, 0.025, 0.05), M["brass"], (0, a, math.pi / 2), verts=20)
        shell(body, f"Foot{i}", foot, (0.20, 0.13, 0.30), M["dark"], (0, a, 0), bevel=0.025)
        cone(body, f"ToeClaw{i}", (sx * 0.60, 0.05, cz * 0.60), (0.03, 0.14, 0.03), M["titanium"], (math.pi / 2 * (1 if cz >= 0 else -1), a, 0))
        shell(body, f"ShinGuard{i}", (sx * 0.42, 0.26, cz * 0.42), (0.13, 0.22, 0.13), M["rust_plate"], (0.35 if cz > 0 else -0.35, a, 0), bevel=0.02)
    lathe(body, "HipPod", (0, 0.72, 0), [(0.001, -0.12), (0.16, -0.10), (0.23, 0.0), (0.20, 0.09), (0.001, 0.12)], M["dark"])
    cyl(body, "WaistRing", (0, 0.80, 0), (0.21, 0.045, 0.21), M["brass"], verts=32)
    ball(body, "TurretDome", (0, 1.02, -0.02), (0.33, 0.26, 0.33), M["rust_plate"])
    shell(body, "TurretSkirt", (0, 0.88, 0), (0.60, 0.16, 0.60), M["rust_dark"], bevel=0.035)
    shell(body, "TurretTop", (0, 1.24, -0.03), (0.38, 0.09, 0.40), M["gunmetal"], (-0.08, 0, 0), bevel=0.025)
    shell(body, "Faceplate", (0, 1.08, 0.26), (0.36, 0.17, 0.18), M["visor"], (-0.12, 0, 0), bevel=0.03)
    plate(body, "Brow", (0, 1.17, 0.30), (0.40, 0.05, 0.12), M["brass"], (-0.12, 0, 0), bevel=0.01)
    plate(body, "EyeSlit", (0, 1.11, 0.355), (0.26, 0.038, 0.02), M["glow_hot"], bevel=0.002)
    ball(body, "EyeCore", (0, 0.99, 0.32), (0.055, 0.055, 0.055), M["glow_orange"])
    for s in (-1, 1):
        shell(body, f"Cheek{s}", (s * 0.24, 1.02, 0.16), (0.14, 0.22, 0.26), M["rust_plate"], (0, s * 0.35, 0), bevel=0.025)
        cyl(body, f"AmmoDrum{s}", (s * 0.30, 0.90, -0.10), (0.11, 0.09, 0.11), M["gunmetal"], (0, 0, math.pi / 2), verts=24)
        cyl(body, f"DrumCore{s}", (s * 0.352, 0.90, -0.10), (0.045, 0.02, 0.045), M["glow_amber"], (0, 0, math.pi / 2), verts=16)
        vents(body, f"SideVent{s}", (s * 0.325, 1.05, 0.02), (0.018, 0.035, 0.20), M["dark"], rows=3)
        cable(body, f"FeedBelt{s}", [(s * 0.28, 0.86, -0.10), (s * 0.20, 0.84, 0.08), (s * 0.10, 0.88, 0.22)], 0.020, M["copper"])
    lathe(body, "Barrel", (0, 0.92, 0.42), [(0.001, -0.20), (0.075, -0.19), (0.058, -0.05), (0.055, 0.10), (0.070, 0.18), (0.001, 0.20)], M["titanium"], rot_g=(math.pi / 2, 0, 0), segments=24)
    cyl(body, "MuzzleBrake", (0, 0.92, 0.60), (0.085, 0.09, 0.085), M["brass"], (math.pi / 2, 0, 0), verts=24)
    cyl(body, "MuzzleCore", (0, 0.92, 0.65), (0.042, 0.02, 0.042), M["glow_hot"], (math.pi / 2, 0, 0), verts=16)
    cyl(body, "Antenna", (-0.18, 1.38, -0.10), (0.012, 0.26, 0.012), M["titanium"], verts=10)
    ball(body, "AntennaTip", (-0.18, 1.52, -0.10), (0.030, 0.030, 0.030), M["glow_red"])
    shell(body, "SensorFin", (0.16, 1.30, -0.14), (0.02, 0.14, 0.10), M["rust_dark"], (0.2, 0, -0.25), bevel=0.006, levels=0)
    reactor = grp("Reactor", root, (0, 0.92, -0.30))
    cyl(reactor, "ReactorCell", (0, 0, 0), (0.10, 0.10, 0.10), M["glow_amber"], (math.pi / 2, 0, 0), verts=6)
    cyl(reactor, "ReactorRing", (0, 0, 0.03), (0.13, 0.03, 0.13), M["brass"], (math.pi / 2, 0, 0), verts=24)
    return root


def build_charger(M):
    root, body = enemy_root("ChargerModel")
    for s in (-1, 1):
        for f in (-1, 1):
            z = f * 0.25
            hip = (s * 0.21, 0.66, z)
            knee = (s * 0.29, 0.30, z - 0.10)
            foot = (s * 0.28, 0.09, z + 0.10)
            beam(body, f"LegU{s}{f}", hip, knee, 0.058, M["rust_dark"])
            beam(body, f"LegL{s}{f}", knee, foot, 0.040, M["dark"])
            ball(body, f"Knee{s}{f}", knee, (0.065, 0.065, 0.065), M["gunmetal"])
            shell(body, f"Hoof{s}{f}", foot, (0.18, 0.14, 0.27), M["rust_plate"], (0.15, 0, 0), bevel=0.025)
            shell(body, f"ThighGuard{s}{f}", (s * 0.26, 0.50, z - 0.04), (0.12, 0.24, 0.16), M["rust_plate"], (0.4, 0, s * 0.1), bevel=0.02)
    shell(body, "HullFrame", (0, 0.68, -0.08), (0.44, 0.32, 0.72), M["dark"], (-0.10, 0, 0), bevel=0.05)
    shell(body, "HullBack", (0, 0.84, -0.28), (0.48, 0.24, 0.34), M["rust_dark"], (-0.16, 0, 0), bevel=0.04)
    shell(body, "HullMid", (0, 0.87, -0.06), (0.52, 0.24, 0.36), M["rust_plate"], (-0.12, 0, 0), bevel=0.04)
    shell(body, "HullFront", (0, 0.84, 0.16), (0.50, 0.22, 0.32), M["orange"], (-0.08, 0, 0), bevel=0.04)
    for i, zz in enumerate((-0.34, -0.12, 0.10)):
        cyl(body, f"SpineCell{i}", (0, 0.97 - abs(zz) * 0.06, zz), (0.055, 0.03, 0.055), M["glow_red"], verts=6)
        cyl(body, f"SpineRing{i}", (0, 0.955 - abs(zz) * 0.06, zz), (0.075, 0.018, 0.075), M["brass"], verts=20)
    shell(body, "RamHead", (0, 0.72, 0.34), (0.42, 0.28, 0.34), M["rust_plate"], (-0.18, 0, 0), bevel=0.04)
    shell(body, "RamBrow", (0, 0.82, 0.44), (0.40, 0.08, 0.16), M["brass"], (-0.25, 0, 0), bevel=0.02)
    cone(body, "RamSpike", (0, 0.70, 0.58), (0.075, 0.36, 0.075), M["titanium"], (math.pi / 2, 0, 0))
    cyl(body, "SpikeCollar", (0, 0.70, 0.44), (0.10, 0.06, 0.10), M["gunmetal"], (math.pi / 2, 0, 0), verts=20)
    for s in (-1, 1):
        plate(body, f"Eye{s}", (s * 0.125, 0.76, 0.50), (0.085, 0.038, 0.02), M["glow_red"], bevel=0.002)
        cone(body, f"Horn{s}", (s * 0.19, 0.94, 0.28), (0.055, 0.30, 0.055), M["titanium"], (-0.5, 0, s * -0.35))
        shell(body, f"Cheek{s}", (s * 0.20, 0.68, 0.36), (0.10, 0.18, 0.24), M["rust_dark"], (-0.15, 0, s * 0.1), bevel=0.025)
        cyl(body, f"Exhaust{s}", (s * 0.17, 0.92, -0.34), (0.045, 0.22, 0.045), M["gunmetal"], (0.35, 0, s * -0.12), verts=16)
        cyl(body, f"ExhaustTip{s}", (s * 0.185, 1.02, -0.38), (0.038, 0.025, 0.038), M["glow_orange"], (0.35, 0, s * -0.12), verts=14)
        vents(body, f"FlankVent{s}", (s * 0.25, 0.72, -0.05), (0.018, 0.035, 0.24), M["dark"], rows=3)
        cable(body, f"FlankCable{s}", [(s * 0.20, 0.60, 0.28), (s * 0.26, 0.58, 0.0), (s * 0.20, 0.64, -0.30)], 0.016, M["rubber"])
    shell(body, "TailFin", (0, 0.90, -0.46), (0.05, 0.34, 0.22), M["rust_dark"], (-0.45, 0, 0), bevel=0.015)
    plate(body, "TailLight", (0, 0.99, -0.53), (0.06, 0.03, 0.015), M["glow_red"], bevel=0.002)
    reactor = grp("Reactor", root, (0, 1.0, -0.10))
    cyl(reactor, "SpineGlow", (0, 0, 0), (0.045, 0.045, 0.045), M["glow_red"], verts=12)
    return root


def build_bruiser(M):
    root, body = enemy_root("BruiserModel")
    for s in (-1, 1):
        shell(body, f"Boot{s}", (s * 0.24, 0.11, 0.05), (0.32, 0.20, 0.46), M["dark"], bevel=0.04)
        shell(body, f"BootToe{s}", (s * 0.24, 0.09, 0.26), (0.28, 0.14, 0.16), M["gunmetal"], (0.1, 0, 0), bevel=0.03)
        lathe(body, f"Leg{s}", (s * 0.24, 0.40, 0), [(0.001, -0.20), (0.10, -0.18), (0.13, 0.0), (0.11, 0.18), (0.001, 0.20)], M["rust_dark"], scale_g=(1, 1, 0.9))
        shell(body, f"KneePlate{s}", (s * 0.24, 0.46, 0.13), (0.22, 0.16, 0.10), M["titanium"], (-0.15, 0, 0), bevel=0.03)
        cyl(body, f"KneeDisc{s}", (s * 0.36, 0.44, 0.02), (0.055, 0.025, 0.055), M["brass"], (0, 0, math.pi / 2), verts=20)
        cable(body, f"LegCable{s}", [(s * 0.20, 0.62, -0.12), (s * 0.28, 0.42, -0.16), (s * 0.22, 0.20, -0.10)], 0.018, M["rubber"])
    shell(body, "Hips", (0, 0.72, 0), (0.60, 0.24, 0.36), M["dark"], bevel=0.04)
    shell(body, "TorsoBlock", (0, 1.00, 0), (0.68, 0.46, 0.46), M["rust_dark"], bevel=0.055)
    shell(body, "ChestPlate", (0, 1.04, 0.20), (0.52, 0.34, 0.14), M["rust_plate"], (-0.10, 0, 0), bevel=0.04)
    bolts(body, "Chest", (0, 1.04, 0.20), (0.20, 0.12, 0.075), M["titanium"])
    vents(body, "ChestVent", (0.18, 1.00, 0.27), (0.14, 0.035, 0.02), M["dark"], rows=3)
    plate(body, "ChestCell", (-0.16, 1.06, 0.275), (0.10, 0.14, 0.015), M["glow_red"], bevel=0.002)
    for s in (-1, 1):
        # Arm anchors |x|>0.32, y>0.66: _rig_enemy gives these the arm pivots.
        ball(body, f"Pauldron{s}", (s * 0.41, 1.22, 0), (0.17, 0.15, 0.19), M["rust_plate"])
        cyl(body, f"ShoulderDisc{s}", (s * 0.50, 1.18, 0), (0.07, 0.03, 0.07), M["brass"], (0, 0, math.pi / 2), verts=20)
        lathe(body, f"ArmGuard{s}", (s * 0.40, 1.00, 0.02), [(0.001, -0.16), (0.10, -0.14), (0.135, 0.02), (0.10, 0.15), (0.001, 0.16)], M["rust_dark"], scale_g=(1, 1, 1.15))
        shell(body, f"ForePlate{s}", (s * 0.40, 0.98, 0.14), (0.20, 0.24, 0.08), M["rust_plate"], (-0.08, 0, 0), bevel=0.03)
        plate(body, f"ArmLight{s}", (s * 0.40, 1.02, 0.19), (0.05, 0.12, 0.015), M["glow_red"], bevel=0.002)
        shell(body, f"Fist{s}", (s * 0.40, 0.80, 0.10), (0.20, 0.18, 0.26), M["gunmetal"], bevel=0.035)
        for ki, kx in enumerate((-0.05, 0.05)):
            shell(body, f"Knuckle{s}{ki}", (s * 0.40 + kx, 0.76, 0.20), (0.07, 0.10, 0.08), M["titanium"], (0.3, 0, 0), bevel=0.015)
    shell(body, "HeadBlock", (0, 1.34, 0.02), (0.38, 0.24, 0.32), M["gunmetal"], (-0.06, 0, 0), bevel=0.04)
    shell(body, "HeadCrest", (0, 1.47, -0.02), (0.30, 0.07, 0.26), M["rust_dark"], (-0.15, 0, 0), bevel=0.02)
    plate(body, "EyeBar", (0, 1.37, 0.185), (0.28, 0.040, 0.025), M["glow_red"], bevel=0.002)
    for s in (-1, 1):
        cyl(body, f"EarStack{s}", (s * 0.21, 1.34, -0.02), (0.05, 0.04, 0.05), M["titanium"], (0, 0, math.pi / 2), verts=16)
    shield = grp("Shield", root, (0, 0.75, 0.33))
    shell(shield, "ShieldBack", (0, 0, 0), (0.72, 0.96, 0.14), M["dark"], (0.10, 0, 0), bevel=0.04)
    shell(shield, "ShieldFace", (0, 0, 0.09), (0.56, 0.86, 0.10), M["rust_plate"], (0.10, 0, 0), bevel=0.035)
    for s in (-1, 1):
        shell(shield, f"ShieldWing{s}", (s * 0.33, 0, 0.05), (0.16, 0.80, 0.10), M["rust_dark"], (0.10, s * -0.45, 0), bevel=0.03)
        plate(shield, f"ShieldEdge{s}", (s * 0.27, 0.02, 0.145), (0.028, 0.74, 0.02), M["glow_red"], bevel=0.002)
    plate(shield, "ShieldBar", (0, 0.24, 0.15), (0.40, 0.035, 0.02), M["glow_red"], bevel=0.002)
    cyl(shield, "ShieldBoss", (0, -0.08, 0.15), (0.11, 0.05, 0.11), M["brass"], (math.pi / 2 + 0.10, 0, 0), verts=6)
    bolts(shield, "Shield", (0, 0, 0.09), (0.22, 0.34, 0.06), M["titanium"])
    reactor = grp("Reactor", root, (0, 1.02, -0.28))
    cyl(reactor, "ReactorCell", (0, 0, 0), (0.13, 0.10, 0.13), M["glow_red"], (math.pi / 2, 0, 0), verts=6)
    cyl(reactor, "ReactorRing", (0, 0, 0.04), (0.16, 0.03, 0.16), M["gunmetal"], (math.pi / 2, 0, 0), verts=24)
    return root


def build_splitter(M):
    root, body = enemy_root("SplitterModel")
    for s in (-1, 1):
        ball(body, f"Core{s}", (s * 0.24, 0.72, 0), (0.30, 0.30, 0.30), M["rust_plate"])
        shell(body, f"CoreCap{s}", (s * 0.26, 0.86, -0.06), (0.34, 0.20, 0.34), M["rust_dark"], (0.2, 0, s * -0.25), bevel=0.04)
        ball(body, f"CoreDark{s}", (s * 0.24, 0.72, 0.17), (0.14, 0.14, 0.14), M["visor"])
        plate(body, f"Eye{s}", (s * 0.24, 0.77, 0.305), (0.15, 0.035, 0.02), M["glow_hot"], bevel=0.002)
        ball(body, f"Pupil{s}", (s * 0.24, 0.70, 0.30), (0.035, 0.035, 0.035), M["glow_orange"])
        for leg in range(2):
            z = -0.18 + leg * 0.36
            knee = (s * 0.34, 0.30, z + 0.02)
            foot = (s * 0.44, 0.07, z + 0.10)
            beam(body, f"LegU{s}{leg}", (s * 0.20, 0.56, z), knee, 0.042, M["steel"])
            beam(body, f"LegL{s}{leg}", knee, foot, 0.030, M["dark"])
            ball(body, f"Knee{s}{leg}", knee, (0.050, 0.050, 0.050), M["brass"])
            cone(body, f"Foot{s}{leg}", foot, (0.035, 0.10, 0.035), M["titanium"], (math.pi, 0, 0))
        for k in range(3):
            cone(body, f"Spike{s}{k}", (s * (0.24 + (k - 1) * 0.10), 0.97, -0.10 + k * 0.10), (0.042, 0.24, 0.042), M["rust_dark"], (0.30, 0, s * -0.20))
    plate(body, "Crack", (0, 0.72, 0), (0.05, 0.52, 0.44), M["rubber"], bevel=0.004)
    plate(body, "CrackGlow", (0, 0.72, 0.10), (0.018, 0.40, 0.26), M["glow_orange"], bevel=0.001)
    shell(body, "CrownPlate", (0, 1.03, -0.05), (0.30, 0.08, 0.30), M["brass"], (0.1, 0.4, 0), bevel=0.02)
    reactor = grp("Reactor", root, (0, 0.72, -0.36))
    ball(reactor, "ReactorCell", (0, 0, 0), (0.11, 0.11, 0.11), M["glow_amber"])
    cyl(reactor, "ReactorCage", (0, 0, 0.02), (0.14, 0.05, 0.14), M["gunmetal"], (math.pi / 2, 0, 0), verts=6)
    return root


def build_mite(M):
    root, body = enemy_root("MiteModel")
    ball(body, "Core", (0, 0.38, 0), (0.26, 0.26, 0.26), M["rust_plate"])
    shell(body, "CoreCap", (0, 0.48, -0.06), (0.34, 0.18, 0.34), M["rust_dark"], (0.25, 0.3, 0), bevel=0.04)
    ball(body, "Face", (0, 0.38, 0.16), (0.15, 0.15, 0.15), M["visor"])
    plate(body, "Eye", (0, 0.43, 0.29), (0.17, 0.038, 0.02), M["glow_hot"], bevel=0.002)
    cone(body, "SpikeTop", (0, 0.60, -0.06), (0.045, 0.22, 0.045), M["rust_dark"], (0.3, 0, 0))
    cone(body, "SpikeBack", (0, 0.44, -0.24), (0.035, 0.16, 0.035), M["titanium"], (-1.1, 0, 0))
    for s in (-1, 1):
        plate(body, f"CheekLight{s}", (s * 0.15, 0.34, 0.22), (0.05, 0.025, 0.015), M["glow_amber"], bevel=0.002)
        for leg in range(2):
            z = -0.12 + leg * 0.24
            knee = (s * 0.24, 0.20, z + 0.02)
            foot = (s * 0.32, 0.05, z + 0.08)
            beam(body, f"LegU{s}{leg}", (s * 0.14, 0.32, z), knee, 0.032, M["steel"])
            beam(body, f"LegL{s}{leg}", knee, foot, 0.024, M["dark"])
            ball(body, f"Knee{s}{leg}", knee, (0.040, 0.040, 0.040), M["brass"])
            cone(body, f"Foot{s}{leg}", foot, (0.028, 0.08, 0.028), M["titanium"], (math.pi, 0, 0))
    reactor = grp("Reactor", root, (0, 0.38, -0.26))
    ball(reactor, "ReactorCell", (0, 0, 0), (0.08, 0.08, 0.08), M["glow_amber"])
    return root


def build_boss(M):
    root, body = enemy_root("ReactorGuardianModel")
    for s in (-1, 1):
        shell(body, f"Track{s}", (s * 0.56, 0.20, 0.10), (0.66, 0.38, 1.05), M["dark"], bevel=0.06)
        shell(body, f"TrackGuard{s}", (s * 0.56, 0.38, 0.30), (0.60, 0.14, 0.55), M["rust_dark"], (-0.12, 0, 0), bevel=0.04)
        shell(body, f"TrackNose{s}", (s * 0.56, 0.18, 0.62), (0.52, 0.26, 0.30), M["gunmetal"], (0.35, 0, 0), bevel=0.05)
        for w in range(4):
            z = -0.32 + w * 0.30
            cyl(body, f"Wheel{s}{w}", (s * 0.90, 0.19, z), (0.155, 0.07, 0.155), M["steel"], (0, 0, math.pi / 2), verts=24)
            cyl(body, f"WheelHub{s}{w}", (s * 0.94, 0.19, z), (0.07, 0.03, 0.07), M["brass"], (0, 0, math.pi / 2), verts=16)
        lathe(body, f"LegTower{s}", (s * 0.54, 0.78, -0.02), [(0.001, -0.40), (0.24, -0.36), (0.28, -0.10), (0.23, 0.22), (0.18, 0.38), (0.001, 0.40)], M["steel"], scale_g=(1, 1, 1.05))
        shell(body, f"LegPlate{s}", (s * 0.54, 0.86, 0.24), (0.42, 0.50, 0.12), M["rust_plate"], (-0.08, 0, 0), bevel=0.04)
        plate(body, f"LegGlow{s}", (s * 0.54, 0.92, 0.31), (0.30, 0.07, 0.02), M["glow_amber"], bevel=0.002)
        cable(body, f"HipCable{s}", [(s * 0.40, 1.10, -0.20), (s * 0.62, 0.80, -0.30), (s * 0.50, 0.48, -0.20)], 0.035, M["rubber"])
        # Arm anchors |x|>0.8, y>1.1 (boss flinch pivots). Head pieces use y>2.28.
        ball(body, f"Shoulder{s}", (s * 1.02, 1.96, 0), (0.38, 0.34, 0.42), M["brass"])
        shell(body, f"ShoulderCap{s}", (s * 1.06, 2.12, 0), (0.52, 0.22, 0.62), M["rust_plate"], (0, 0, s * -0.20), bevel=0.05)
        cyl(body, f"ShoulderDisc{s}", (s * 1.32, 1.92, 0), (0.16, 0.06, 0.16), M["gunmetal"], (0, 0, math.pi / 2), verts=24)
        lathe(body, f"ArmCannon{s}", (s * 1.12, 1.48, 0.12), [(0.001, -0.34), (0.20, -0.30), (0.26, -0.05), (0.22, 0.22), (0.001, 0.34)], M["rust_dark"], scale_g=(1, 1, 1.1))
        shell(body, f"ArmShroud{s}", (s * 1.12, 1.58, 0.30), (0.42, 0.30, 0.34), M["rust_plate"], (-0.15, 0, 0), bevel=0.04)
        cyl(body, f"CannonBarrel{s}", (s * 1.12, 1.52, 0.66), (0.10, 0.58, 0.10), M["titanium"], (math.pi / 2, 0, 0), verts=24)
        cyl(body, f"CannonBrake{s}", (s * 1.12, 1.52, 0.95), (0.135, 0.12, 0.135), M["brass"], (math.pi / 2, 0, 0), verts=24)
        cyl(body, f"CannonCore{s}", (s * 1.12, 1.52, 1.02), (0.07, 0.03, 0.07), M["glow_hot"], (math.pi / 2, 0, 0), verts=16)
        plate(body, f"ArmLight{s}", (s * 1.12, 1.72, 0.44), (0.26, 0.06, 0.025), M["glow_orange"], bevel=0.002)
        cable(body, f"ArmFeed{s}", [(s * 0.95, 1.85, -0.25), (s * 1.18, 1.60, -0.15), (s * 1.10, 1.40, 0.10)], 0.030, M["copper"])
        shell(body, f"CrestFin{s}", (s * 0.68, 2.30, -0.10), (0.28, 0.54, 0.42), M["steel"], (0, 0, s * -0.28), bevel=0.04)
    lathe(body, "Waist", (0, 1.20, 0), [(0.001, -0.16), (0.58, -0.12), (0.66, 0.02), (0.55, 0.14), (0.001, 0.16)], M["dark"], scale_g=(1.1, 1, 0.9), segments=32)
    cyl(body, "WaistRing", (0, 1.30, 0), (0.60, 0.05, 0.60), M["brass"], verts=32)
    shell(body, "TorsoCore", (0, 1.74, 0), (1.28, 0.88, 0.92), M["rust_dark"], (0, 0, 0), bevel=0.08)
    shell(body, "ChestPlate", (0, 2.02, 0.28), (1.24, 0.42, 0.30), M["rust_plate"], (-0.10, 0, 0), bevel=0.05)
    shell(body, "ChestTrim", (0, 1.80, 0.42), (0.90, 0.10, 0.14), M["brass"], (-0.10, 0, 0), bevel=0.03)
    bolts(body, "Torso", (0, 2.02, 0.28), (0.50, 0.14, 0.16), M["titanium"], count=4, r=0.02)
    vents(body, "TorsoVent", (0.44, 1.70, 0.46), (0.28, 0.045, 0.025), M["dark"], rows=4)
    for s in (-1, 1):
        cyl(body, f"Smokestack{s}", (s * 0.45, 2.42, -0.42), (0.12, 0.86, 0.12), M["gunmetal"], verts=20)
        cyl(body, f"StackCollar{s}", (s * 0.45, 2.66, -0.42), (0.145, 0.07, 0.145), M["rust_dark"], verts=20)
        cyl(body, f"StackGlow{s}", (s * 0.45, 2.87, -0.42), (0.095, 0.05, 0.095), M["glow_orange"], verts=16)
        shell(body, f"BackTank{s}", (s * 0.30, 1.70, -0.50), (0.30, 0.70, 0.26), M["copper"], bevel=0.05)
    cyl(body, "BackStack", (0, 1.66, -0.62), (0.40, 0.30, 0.40), M["steel"], (math.pi / 2, 0, 0), verts=28)
    shell(body, "HeadBlock", (0, 2.44, 0.02), (0.80, 0.44, 0.58), M["gunmetal"], (-0.05, 0, 0), bevel=0.06)
    ball(body, "HeadDome", (0, 2.58, -0.04), (0.36, 0.22, 0.30), M["rust_plate"])
    shell(body, "HeadCrest", (0, 2.76, 0.0), (0.84, 0.16, 0.52), M["steel"], (0.12, 0, 0), bevel=0.04)
    plate(body, "EyeBand", (0, 2.48, 0.32), (0.62, 0.10, 0.04), M["glow_orange"], bevel=0.004)
    plate(body, "EyeCore", (0, 2.49, 0.35), (0.36, 0.035, 0.018), M["glow_hot"], bevel=0.002)
    for s in (-1, 1):
        cone(body, f"HeadHorn{s}", (s * 0.44, 2.66, 0.02), (0.06, 0.34, 0.06), M["brass"], (0, 0, s * -0.55))
        cyl(body, f"JawPiston{s}", (s * 0.30, 2.28, 0.22), (0.035, 0.20, 0.035), M["titanium"], (0.3, 0, 0), verts=12)
    reactor = grp("Reactor", root, (0, 1.78, 0.58))
    cyl(reactor, "ReactorHousing", (0, 0, 0), (0.42, 0.14, 0.42), M["gunmetal"], (math.pi / 2, 0, 0), verts=6)
    cyl(reactor, "ReactorMid", (0, 0, 0.08), (0.33, 0.07, 0.33), M["glow_orange"], (math.pi / 2, 0, 0), verts=6)
    cyl(reactor, "ReactorCore", (0, 0, 0.13), (0.23, 0.045, 0.23), M["glow_hot"], (math.pi / 2, 0, 0), verts=6)
    cyl(reactor, "ReactorRing", (0, 0, 0.02), (0.48, 0.04, 0.48), M["brass"], (math.pi / 2, 0, 0), verts=32)
    ring = grp("Ring", root, (0, 2.26, -0.08))
    for i in range(16):
        a = i / 16 * math.tau
        plate(ring, f"RingSeg{i}", (math.sin(a) * 1.34, 0, math.cos(a) * 1.34), (0.20, 0.05, 0.07), M["glow_orange"], (0, a, 0), bevel=0.002)
    return root


def tree(o):
    yield o
    for c in o.children:
        yield from tree(c)


def ground(root):
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    min_z, max_z, tris = 1e9, -1e9, 0
    for o in tree(root):
        if o.type != 'MESH':
            continue
        eo = o.evaluated_get(dg)
        tris += sum(len(p.vertices) - 2 for p in eo.to_mesh().polygons)
        for c in eo.bound_box:
            z = (eo.matrix_world @ H.Vector(c)).z
            min_z = min(min_z, z); max_z = max(max_z, z)
    root.location.z -= min_z
    bpy.context.view_layer.update()
    print(f"GROUND {root.name} height={max_z - min_z:.2f} tris~{tris}")


def export_glb(root, filename):
    bpy.ops.object.select_all(action='DESELECT')
    for o in tree(root):
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(filepath=os.path.join(MODELS, filename), export_format='GLB',
                              export_apply=True, use_selection=True, export_yup=True)
    print("EXPORTED", filename, os.path.getsize(os.path.join(MODELS, filename)))


BUILDERS = [("gunner", build_gunner), ("charger", build_charger), ("bruiser", build_bruiser),
            ("splitter", build_splitter), ("mite", build_mite), ("boss", build_boss)]


def main():
    global COL
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    H.reset_scene()
    COL = H.collection("Enemies2")
    M = make_mats()
    roots = []
    for name, fn in BUILDERS:
        r = fn(M)
        ground(r)
        roots.append((name, r))
    if "--render" in args:
        offsets = [-6.4, -4.1, -1.9, 0.2, 1.7, 4.6]
        for (name, r), x in zip(roots, offsets):
            r.location.x = x
        bpy.context.view_layer.update()
        meshes = [o for _, r in roots for o in tree(r) if o.type == 'MESH']
        cam = H.add_camera("LineupCam", (4, -10, 3.4), (0, 0, 1.0), lens=50)
        H.frame_objects(cam, meshes, azimuth=24, elevation=12, margin=1.06)
        H.studio_lighting(target=meshes, key_azimuth=-40, key_elevation=50, intensity=1.1, contrast=0.6, softness=0.5)
        w = bpy.data.worlds.new("LW"); bpy.context.scene.world = w
        w.use_nodes = True
        w.node_tree.nodes["Background"].inputs[0].default_value = (0.10, 0.16, 0.20, 1)
        w.node_tree.nodes["Background"].inputs[1].default_value = 0.85
        H.add_plane("LG", size=(40, 40), location=(0, 0, -0.001),
                    mat=H.material("LGM", "#232a30", roughness=0.45, metallic=0.6), collection=COL)
        H.set_render(engine="BLENDER_EEVEE_NEXT", resolution=(1800, 800), samples=32, percentage=100, view_transform="AgX")
        H.render_still(os.path.join(PREVIEW, "enemies2_lineup.png"))
        for _, r in roots:
            r.location.x = 0
        bpy.context.view_layer.update()
    for name, r in roots:
        export_glb(r, name + ".glb")
    print("ENEMIES2 DONE")


main()
