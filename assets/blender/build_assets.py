# Pulsebreak 2.0 real modeled assets.
# Builds game actors as segmented glTF models whose node hierarchy, pivots and
# part coordinates match the code-built rigs in scripts/art.gd exactly, so the
# existing animation logic (Art.animate_player / animate_enemy) drives them
# unchanged. Godot coords (Y up, +Z forward) -> Blender (x, -z, y).
# Usage: Blender -b --factory-startup --python-exit-code 1 -P build_assets.py -- [--only courier|enemies|deck|all] [--render]
import sys, os, math, random
sys.path.insert(0, "/Users/xinboonchen/.local/share/muse/skills/bundled/muse-core--exact-minimal-literal-tests/skills/blender/scripts")
import bpy
import bpy_helpers as H

ROOT = "/Users/xinboonchen/Projects/pulsebreak"
MODELS = os.path.join(ROOT, "assets", "models")
TEXTURES = os.path.join(ROOT, "assets", "textures")
PREVIEW = "/tmp/pb-assets"
os.makedirs(MODELS, exist_ok=True); os.makedirs(TEXTURES, exist_ok=True); os.makedirs(PREVIEW, exist_ok=True)
RNG = random.Random(20261025)

# ---------- materials (plain Principled only: must survive glTF export) ----------
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
    m["rust_dark"]  = H.material("RustDark",  "#6E3020", roughness=0.55, metallic=0.35)
    m["rust_plate"] = H.material("RustPlate", "#9C4028", roughness=0.48, metallic=0.30)
    m["orange"]   = H.material("HostileOrange", "#C85A26", roughness=0.5, metallic=0.3)
    m["glow_amber"]  = H.material("GlowAmber",  "#3A1E00", roughness=0.4, metallic=0.0, emission="#FFB35C", emission_strength=2.6)
    m["glow_orange"] = H.material("GlowOrange", "#3A1500", roughness=0.4, metallic=0.0, emission="#FF8A1A", emission_strength=3.2)
    m["glow_hot"]    = H.material("GlowHot",    "#401A00", roughness=0.4, metallic=0.0, emission="#FFE4A2", emission_strength=3.4)
    m["glow_red"]    = H.material("GlowRed",    "#2A0505", roughness=0.4, metallic=0.0, emission="#FF4A3A", emission_strength=2.8)
    return m

# ---------- coordinate + hierarchy helpers ----------
def P(g):  return (g[0], -g[2], g[1])                 # godot pos -> blender pos
def R(g):  return (g[0], -g[2], g[1])                 # godot euler(rad) -> blender euler(rad)

def grp(name, parent, loc_g=(0, 0, 0)):
    e = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(e)
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

def plate(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0), bevel=0.012):
    sx, sy, sz = size_g
    bev = min(bevel, min(sx, sy, sz) * 0.32)
    o = H.add_box(name, size=(sx, sz, sy), bevel=bev, mat=mat)
    H.shade_smooth(o, angle=38)
    return place(o, parent, center_g, rot_g)

def ball(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0)):
    o = H.add_sphere(name, radius=1.0, scale=(size_g[0], size_g[2], size_g[1]), mat=mat)
    H.shade_smooth(o, angle=60)
    return place(o, parent, center_g, rot_g)

def cyl(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0), top_ratio=1.0, verts=28):
    # godot cylinder size = (radius, height, radius), axis Y -> blender axis Z
    o = H.add_cylinder(name, radius=size_g[0], depth=size_g[1], radius_top=size_g[0] * top_ratio, vertices=verts, mat=mat)
    H.shade_smooth(o, angle=45)
    return place(o, parent, center_g, rot_g)

def cone(parent, name, center_g, size_g, mat, rot_g=(0, 0, 0)):
    return cyl(parent, name, center_g, size_g, mat, rot_g, top_ratio=0.12, verts=24)

def beam(parent, name, a_g, b_g, radius, mat):
    o = H.add_tube(name, [P(a_g), P(b_g)], radius=radius, mat=mat, resolution=1, bevel_resolution=10)
    H.parent(o, parent, keep_transform=False)
    o.location = (0, 0, 0)
    return o

def bolts(parent, name, center_g, spread_g, mat, count=4, r=0.009):
    # small bolt heads near plate corners on the +Z face
    for i in range(count):
        a = (i / count) * math.tau + math.pi / 4
        off = (math.cos(a) * spread_g[0], math.sin(a) * spread_g[1], spread_g[2])
        c = (center_g[0] + off[0], center_g[1] + off[1], center_g[2] + off[2])
        cyl(parent, f"{name}Bolt{i}", c, (r, 0.012, r), mat, (math.pi / 2, 0, 0), verts=6)

def vents(parent, name, center_g, size_g, mat, rows=3):
    for i in range(rows):
        dy = (i - (rows - 1) / 2) * size_g[1] * 0.9
        plate(parent, f"{name}Vent{i}", (center_g[0], center_g[1] + dy, center_g[2]),
              (size_g[0], size_g[1] * 0.42, size_g[2]), mat, bevel=0.002)

def armor(parent, name, center_g, size_g, mat, trim_mat, rot_g=(0, 0, 0), face=1, detail=True):
    """Layered armor plate: main shell + proud inset panel + corner bolts."""
    main = plate(parent, name, center_g, size_g, mat, rot_g)
    if detail:
        sx, sy, sz = size_g
        inset = plate(parent, name + "Inset",
                      (center_g[0], center_g[1] + sy * 0.06, center_g[2] + face * sz * 0.36),
                      (sx * 0.72, sy * 0.62, sz * 0.30), trim_mat, rot_g, bevel=0.008)
        bolts(parent, name, center_g, (sx * 0.36, sy * 0.36, face * sz * 0.52), trim_mat)
    return main

def build_courier(M):
    root = grp("CourierModel", None)
    body = grp("Body", root)
    # pelvis
    armor(body, "Pelvis", (0, 0.88, 0), (0.41, 0.23, 0.31), M["dark"], M["titanium"])
    plate(body, "PelvisPlate", (0, 0.92, 0.165), (0.34, 0.12, 0.085), M["titanium"])
    plate(body, "PelvisLight", (0, 0.925, 0.216), (0.12, 0.045, 0.025), M["glow_amber"], bevel=0.004)
    for s in (-1, 1):  # skirt armor
        plate(body, f"Skirt{s}", (s * 0.20, 0.76, 0.06), (0.20, 0.26, 0.24), M["ceramic"], (0.30, 0, s * -0.18))
    plate(body, "SkirtFront", (0, 0.77, 0.17), (0.24, 0.24, 0.06), M["ceramic"], (0.38, 0, 0))

    torso = grp("Torso", body, (0, 0.97, 0))
    plate(torso, "TorsoFrame", (0, 0.21, 0), (0.50, 0.47, 0.32), M["dark"], (-0.06, 0, 0))
    armor(torso, "Cuirass", (0, 0.28, 0.07), (0.62, 0.41, 0.38), M["ceramic"], M["white"], (-0.10, 0, 0))
    armor(torso, "AbPlate", (0, 0.08, 0.16), (0.35, 0.20, 0.13), M["gunmetal"], M["brass"], (-0.16, 0, 0))
    cyl(torso, "ReactorHousing", (0, 0.33, 0.26), (0.10, 0.04, 0.10), M["brass"], (math.pi / 2, 0, 0), verts=6)
    cyl(torso, "ReactorCore", (0, 0.33, 0.285), (0.068, 0.035, 0.068), M["glow_hot"], (math.pi / 2, 0, 0), verts=6)
    plate(torso, "Stripe", (-0.19, 0.31, 0.272), (0.047, 0.16, 0.016), M["glow_amber"], bevel=0.002)
    for s in (-1, 1):
        armor(torso, f"Pec{s}", (s * 0.16, 0.33, 0.25), (0.20, 0.22, 0.09), M["white"], M["titanium"], (-0.14, s * -0.10, s * -0.06), detail=False)
        plate(torso, f"PecLight{s}", (s * 0.17, 0.405, 0.255), (0.14, 0.025, 0.025), M["glow_amber"], bevel=0.002)
        armor(torso, f"Rib{s}", (s * 0.23, 0.16, -0.08), (0.105, 0.23, 0.30), M["titanium"], M["dark"], detail=False)
        plate(torso, f"Collar{s}", (s * 0.20, 0.48, -0.015), (0.15, 0.085, 0.28), M["titanium"], (0, 0, -s * 0.22))
        armor(torso, f"Waist{s}", (s * 0.22, -0.04, -0.07), (0.13, 0.27, 0.22), M["gunmetal"], M["dark"], (-0.16, 0, s * 0.10), detail=False)
        plate(torso, f"WaistLight{s}", (s * 0.15, 0.015, 0.22), (0.11, 0.025, 0.025), M["glow_amber"], bevel=0.002)
        vents(torso, f"ChestVent{s}", (s * 0.24, 0.30, 0.20), (0.07, 0.035, 0.02), M["dark"], rows=3)
    for y in (0.16, 0.42):
        plate(torso, f"Seam{y}", (0, y, 0.262), (0.44, 0.012, 0.012), M["rubber"], bevel=0.001)
    beam(torso, "CableR", (0.12, 0.05, -0.12), (0.10, 0.30, -0.24), 0.022, M["brass"])
    beam(torso, "CableL", (-0.12, 0.05, -0.12), (-0.10, 0.30, -0.24), 0.022, M["rubber"])
    cyl(torso, "PistonL", (-0.08, 0.02, 0.10), (0.028, 0.20, 0.028), M["titanium"], verts=12)
    cyl(torso, "PistonR", (0.08, 0.02, 0.10), (0.028, 0.20, 0.028), M["titanium"], verts=12)

    head = grp("Head", torso, (0, 0.63, 0.015))
    cyl(head, "Neck", (0, -0.09, 0), (0.086, 0.12, 0.086), M["dark"], verts=16)
    ball(head, "HelmCore", (0, 0.07, -0.02), (0.19, 0.19, 0.17), M["dark"])
    armor(head, "HelmShell", (0, 0.11, -0.01), (0.40, 0.30, 0.40), M["ceramic"], M["white"], (-0.08, 0, 0))
    plate(head, "HelmCrown", (0, 0.26, -0.04), (0.26, 0.10, 0.30), M["ceramic"], (-0.22, 0, 0))
    armor(head, "Faceplate", (0, 0.088, 0.168), (0.34, 0.16, 0.13), M["visor"], M["visor"], (-0.15, 0, 0), detail=False)
    plate(head, "Brow", (0, 0.154, 0.175), (0.415, 0.065, 0.14), M["brass"], (-0.12, 0, 0))
    plate(head, "EyeSlit", (0, 0.108, 0.238), (0.28, 0.031, 0.023), M["glow_amber"], bevel=0.002)
    armor(head, "Jaw", (0, -0.024, 0.151), (0.21, 0.12, 0.16), M["titanium"], M["dark"], (-0.29, 0, 0), detail=False)
    plate(head, "Crest", (0, 0.31, -0.03), (0.02, 0.09, 0.32), M["brass"], (-0.18, 0, 0))
    plate(head, "CrestStripe", (-0.07, 0.299, -0.015), (0.060, 0.019, 0.15), M["glow_amber"], bevel=0.002)
    for s in (-1, 1):
        armor(head, f"Cheek{s}", (s * 0.166, -0.025, 0.102), (0.074, 0.17, 0.23), M["ceramic"], M["white"], (-0.25, 0, -s * 0.16), detail=False)
        cyl(head, f"EarDisc{s}", (s * 0.211, 0.08, -0.008), (0.083, 0.055, 0.083), M["titanium"], (0, 0, math.pi / 2), verts=20)
        cyl(head, f"EarLight{s}", (s * 0.243, 0.08, -0.008), (0.042, 0.016, 0.042), M["glow_amber"], (0, 0, math.pi / 2), verts=12)
        plate(head, f"AntennaFin{s}", (s * 0.19, 0.30, -0.10), (0.015, 0.16, 0.06), M["gunmetal"], (0.2, 0, -s * 0.3))

    for idx, s in enumerate((-1, 1)):
        suf = "Left" if s < 0 else "Right"
        hip = grp("Hip" + suf, body, (s * 0.165, 0.85, 0))
        ball(hip, "HipJoint", (0, 0, 0), (0.112, 0.112, 0.112), M["titanium"])
        cyl(hip, "HipRing", (s * 0.10, 0, 0), (0.07, 0.03, 0.07), M["brass"], (0, 0, math.pi / 2), verts=20)
        plate(hip, "ThighFrame", (0, -0.18, -0.005), (0.185, 0.30, 0.20), M["dark"])
        armor(hip, "ThighArmor", (s * 0.018, -0.16, 0.064), (0.20, 0.26, 0.15), M["ceramic"], M["white"], (-0.06, 0, s * 0.045))
        plate(hip, "ThighLight", (s * 0.112, -0.16, 0.02), (0.027, 0.16, 0.075), M["glow_orange"], bevel=0.002)
        knee = grp("Knee" + suf, hip, (0, -0.34, 0))
        cyl(knee, "KneeAxle", (0, 0, 0), (0.09, 0.20, 0.09), M["dark"], (0, 0, math.pi / 2), verts=20)
        cyl(knee, "KneeDiscOut", (s * 0.105, 0, 0), (0.065, 0.025, 0.065), M["brass"], (0, 0, math.pi / 2), verts=24)
        cyl(knee, "KneeDiscIn", (-s * 0.105, 0, 0), (0.05, 0.025, 0.05), M["titanium"], (0, 0, math.pi / 2), verts=20)
        armor(knee, "KneeGuard", (0, -0.02, 0.10), (0.18, 0.16, 0.09), M["titanium"], M["brass"], detail=False)
        plate(knee, "ShinFrame", (0, -0.19, -0.005), (0.17, 0.27, 0.19), M["dark"])
        armor(knee, "ShinArmor", (0, -0.19, 0.075), (0.195, 0.28, 0.12), M["ceramic"], M["white"], (0.04, 0, 0))
        plate(knee, "ShinLight", (0, -0.18, 0.145), (0.041, 0.17, 0.022), M["glow_orange"], bevel=0.002)
        beam(knee, "CalfCable", (s * 0.05, -0.05, -0.10), (s * 0.04, -0.32, -0.08), 0.016, M["rubber"])
        ankle = grp("Ankle" + suf, knee, (0, -0.37, 0))
        armor(ankle, "Foot", (0, -0.035, 0.09), (0.245, 0.19, 0.40), M["dark"], M["gunmetal"])
        armor(ankle, "ToeCap", (0, 0.012, 0.16), (0.225, 0.13, 0.24), M["ceramic"], M["brass"], (-0.08, 0, 0))
        plate(ankle, "Sole", (0, -0.115, 0.09), (0.22, 0.021, 0.32), M["titanium"])
        plate(ankle, "HeelLight", (0, -0.065, -0.114), (0.14, 0.039, 0.023), M["glow_amber"], bevel=0.002)
        for tx in (-0.06, 0.06):
            cone(ankle, f"ToeClaw{tx}", (tx, -0.06, 0.30), (0.035, 0.16, 0.035), M["titanium"], (math.pi / 2 + 0.35, 0, 0))

        sh = grp("Shoulder" + suf, torso, (s * 0.40, 0.36, 0))
        ball(sh, "ShoulderJoint", (0, 0, 0), (0.105, 0.105, 0.105), M["dark"])
        armor(sh, "Pauldron", (s * 0.025, 0.032, 0), (0.26, 0.20, 0.32), M["ceramic"], M["brass"], (0, 0, -s * 0.15))
        plate(sh, "PauldronStripe", (s * 0.148, 0.025, 0.035), (0.025, 0.063, 0.13), M["glow_amber"] if s > 0 else M["brass"], bevel=0.002)
        plate(sh, "UpperArm", (s * 0.025, -0.15, 0), (0.135, 0.23, 0.15), M["dark"])
        el = grp("Elbow" + suf, sh, (s * 0.025, -0.27, 0))
        ball(el, "ElbowJoint", (0, 0, 0), (0.077, 0.077, 0.077), M["titanium"])
        armor(el, "Forearm", (0, -0.12, 0.024), (0.18, 0.26, 0.21), M["ceramic"], M["white"], (-0.10, 0, 0))
        plate(el, "ForearmPlate", (0, -0.12, 0.137), (0.068, 0.10, 0.018), M["visor"], bevel=0.002)
        plate(el, "ForearmLight", (0, -0.10, 0.151), (0.045, 0.04, 0.012), M["glow_amber"], bevel=0.001)
        armor(el, "Fist", (0, -0.287, 0.041), (0.15, 0.13, 0.17), M["dark"], M["gunmetal"], detail=False)
        for fx in (-0.045, 0.0, 0.045):
            plate(el, f"Knuckle{fx}", (fx, -0.30, 0.115), (0.035, 0.07, 0.05), M["titanium"], bevel=0.004)

    reactor = grp("Reactor", root, (0, 1.22, -0.28))
    armor(reactor, "Pack", (0, 0.02, -0.04), (0.43, 0.43, 0.22), M["dark"], M["gunmetal"], face=-1)
    plate(reactor, "PackPlate", (0, 0.10, -0.14), (0.30, 0.30, 0.08), M["titanium"])
    cyl(reactor, "Exhaust", (0, 0.085, -0.205), (0.128, 0.075, 0.128), M["dark"], (math.pi / 2, 0, 0), verts=20)
    cyl(reactor, "ExhaustGlow", (0, 0.085, -0.252), (0.091, 0.028, 0.091), M["glow_amber"], (math.pi / 2, 0, 0), verts=16)
    vents(reactor, "PackVent", (0, 0.26, -0.16), (0.20, 0.03, 0.02), M["gunmetal"], rows=3)
    plume_hot = H.material("PlumeHot", "#401A00", roughness=0.5, metallic=0.0, emission="#FFE4A2", emission_strength=2.6, alpha=0.55)
    plume_amber = H.material("PlumeAmber", "#3A1E00", roughness=0.5, metallic=0.0, emission="#FFB35C", emission_strength=2.0, alpha=0.5)
    for s in (-1, 1):
        suf = "Left" if s < 0 else "Right"
        wing = grp("Wing" + suf, reactor, (s * 0.19, 0.15, -0.11))
        panels = grp("Panels" + suf, wing)
        panels.scale = (float(s), 1.0, 1.0)
        outline = [(0.0, -0.18), (0.55, -0.12), (1.25, 0.16), (1.55, 0.36), (1.44, 0.58), (0.60, 0.56), (0.12, 0.32), (0.0, 0.20)]
        blade = H.add_extrusion("WingBlade", outline, depth=0.045, bevel=0.008, mat=M["ceramic"])
        H.shade_smooth(blade, angle=40)
        place(blade, panels, (0, -0.0225, 0), (0, 0, 0.30))
        blade2 = H.add_extrusion("WingBladeInner", outline, depth=0.03, bevel=0.006, mat=M["white"])
        place(blade2, panels, (0.04, 0.045, -0.012), (0, 0, 0.30))
        blade2.scale = (0.94, 1.0, 0.62)  # blender scale axes (x, y=-z_g, z=y_g)
        blade2.location = (0.04, 0.012, 0.045 - 0.015)
        edge = plate(panels, "WingEdge", (0.72, 0.0, -0.02), (1.05, 0.018, 0.035), M["brass"], (0, -0.31, 0), bevel=0.002)
        strip = plate(panels, "WingGlow", (0.62, 0.028, -0.14), (0.85, 0.012, 0.03), M["glow_amber"], (0, -0.31, 0), bevel=0.001)
        for i in range(3):
            plate(panels, f"WingVent{i}", (0.35 + i * 0.18, 0.03, -0.12), (0.08, 0.026, 0.16), M["visor"], (0, -0.25, 0), bevel=0.002)
        thr = grp("Thruster" + suf, reactor, (s * 0.205, -0.17, -0.035))
        cyl(thr, "Bell", (0, 0, 0), (0.12, 0.25, 0.12), M["titanium"], top_ratio=0.45, verts=24)
        cyl(thr, "Nozzle", (0, -0.13, 0), (0.093, 0.06, 0.093), M["dark"], verts=20)
        cyl(thr, "NozzleGlow", (0, -0.166, 0), (0.068, 0.021, 0.068), M["glow_amber"], verts=16)
        plume = grp("Plume" + suf, thr, (0, -0.18, 0))
        cyl(plume, "PlumeOuter", (0, -0.21, 0), (0.055, 0.42, 0.055), plume_amber, top_ratio=1.9, verts=16)
        cyl(plume, "PlumeCore", (0, -0.30, 0), (0.030, 0.60, 0.030), plume_hot, top_ratio=1.9, verts=14)

    ring = grp("Ring", root, (0, 1.02, 0))
    for i in range(10):
        a = i / 10 * math.tau
        plate(ring, f"RingSeg{i}", (math.sin(a) * 0.49, 0, math.cos(a) * 0.49), (0.17, 0.02, 0.05), M["glow_amber"], (0, a, 0), bevel=0.002)
    return root


def export_glb(root_obj, filename):
    bpy.ops.object.select_all(action='DESELECT')
    def select_tree(o):
        o.select_set(True)
        for c in o.children: select_tree(c)
    select_tree(root_obj)
    bpy.context.view_layer.objects.active = root_obj
    bpy.ops.export_scene.gltf(filepath=os.path.join(MODELS, filename), export_format='GLB',
                              export_apply=True, use_selection=True, export_yup=True)
    print("EXPORTED", filename)


def enemy_root(name):
    root = grp(name, None)
    body = grp("Body", root)
    return root, body


def build_gunner(M):
    root, body = enemy_root("GunnerModel")
    for i in range(3):
        a = math.tau * i / 3.0 + math.pi
        foot = (math.sin(a) * 0.44, 0.10, math.cos(a) * 0.44)
        knee = (math.sin(a) * 0.38, 0.42, math.cos(a) * 0.38)
        beam(body, f"LegUpper{i}", (math.sin(a) * 0.17, 0.76, math.cos(a) * 0.17), knee, 0.065, M["rust_plate"])
        beam(body, f"LegLower{i}", knee, foot, 0.052, M["edge"])
        armor(body, f"Foot{i}", foot, (0.19, 0.14, 0.27), M["dark"], M["gunmetal"], (0, a, 0), detail=False)
        ball(body, f"KneeBall{i}", knee, (0.091, 0.091, 0.091), M["brass"])
    cyl(body, "HipPod", (0, 0.73, 0), (0.23, 0.20, 0.23), M["dark"], verts=24)
    armor(body, "Turret", (0, 0.98, 0), (0.62, 0.48, 0.62), M["rust_plate"], M["rust_dark"], (0, math.pi * 0.125, 0))
    plate(body, "TurretTop", (0, 1.235, 0), (0.46, 0.055, 0.46), M["dark"], (0, math.pi * 0.125, 0))
    armor(body, "Faceplate", (0, 1.1, 0.323), (0.32, 0.115, 0.10), M["dark"], M["visor"], detail=False)
    ball(body, "EyeCore", (0, 0.98, 0.345), (0.052, 0.052, 0.052), M["glow_hot"])
    plate(body, "EyeSlit", (0, 1.115, 0.383), (0.23, 0.040, 0.017), M["glow_hot"], bevel=0.002)
    cyl(body, "Barrel", (0, 0.9, 0.33), (0.13, 0.33, 0.13), M["steel"], (math.pi / 2, 0, 0), verts=20)
    cyl(body, "Muzzle", (0, 0.9, 0.505), (0.105, 0.035, 0.105), M["gunmetal"], (math.pi / 2, 0, 0), verts=20)
    cyl(body, "MuzzleCore", (0, 0.9, 0.525), (0.042, 0.02, 0.042), M["glow_hot"], (math.pi / 2, 0, 0), verts=12)
    vents(body, "SideVent", (0.30, 0.98, 0.05), (0.02, 0.04, 0.22), M["dark"], rows=3)
    plate(body, "Antenna", (-0.18, 1.36, -0.09), (0.034, 0.23, 0.034), M["edge"])
    ball(body, "AntennaTip", (-0.18, 1.455, -0.09), (0.036, 0.036, 0.036), M["glow_hot"])
    reactor = grp("Reactor", root, (0, 0.9, -0.30))
    plate(reactor, "ReactorCell", (0, 0, 0), (0.18, 0.20, 0.10), M["glow_amber"])
    return root


def build_charger(M):
    root, body = enemy_root("ChargerModel")
    for s in (-1, 1):
        for f in (-1, 1):
            z = f * 0.25
            beam(body, f"LegU{s}{f}", (s * 0.21, 0.65, z), (s * 0.28, 0.29, z - 0.10), 0.073, M["rust_dark"])
            beam(body, f"LegL{s}{f}", (s * 0.28, 0.29, z - 0.10), (s * 0.28, 0.10, z + 0.08), 0.05, M["dark"])
            plate(body, f"Hoof{s}{f}", (s * 0.28, 0.09, z + 0.11), (0.17, 0.15, 0.25), M["rust_plate"], (0.2, 0, 0))
    plate(body, "HullFrame", (0, 0.69, -0.09), (0.41, 0.30, 0.69), M["dark"], (-0.13, 0, 0))
    armor(body, "HullTop", (0, 0.86, -0.14), (0.51, 0.34, 0.65), M["rust_plate"], M["rust_dark"], (-0.13, 0, 0))
    armor(body, "RamHead", (0, 0.75, 0.30), (0.40, 0.28, 0.30), M["rust_plate"], M["brass"], (-0.22, 0, 0))
    cone(body, "RamSpike", (0, 0.72, 0.52), (0.09, 0.34, 0.09), M["titanium"], (math.pi / 2, 0, 0))
    for s in (-1, 1):
        plate(body, f"Eye{s}", (s * 0.12, 0.79, 0.448), (0.08, 0.045, 0.025), M["glow_red"], bevel=0.002)
        plate(body, f"Horn{s}", (s * 0.15, 0.96, 0.24), (0.10, 0.27, 0.17), M["rust_dark"], (-0.28, 0, s * -0.12))
    plate(body, "TailFin", (0, 0.87, -0.41), (0.08, 0.35, 0.24), M["rust_dark"], (-0.4, 0, 0))
    reactor = grp("Reactor", root, (0, 1.026, -0.10))
    plate(reactor, "SpineCell", (0, 0, 0), (0.055, 0.04, 0.37), M["glow_red"], bevel=0.002)
    return root


def build_bruiser(M):
    root, body = enemy_root("BruiserModel")
    for s in (-1, 1):
        armor(body, f"Boot{s}", (s * 0.24, 0.12, 0.045), (0.30, 0.23, 0.43), M["dark"], M["gunmetal"], detail=False)
        armor(body, f"Leg{s}", (s * 0.24, 0.40, 0), (0.23, 0.37, 0.25), M["rust_dark"], M["rust_plate"], (0, 0, s * -0.1))
        plate(body, f"KneePlate{s}", (s * 0.24, 0.45, 0.15), (0.19, 0.13, 0.07), M["edge"])
        armor(body, f"ArmGuard{s}", (s * 0.39, 1.075, 0), (0.26, 0.28, 0.40), M["rust_dark"], M["rust_plate"], (0, 0, s * -0.15))
        armor(body, f"Fist{s}", (s * 0.40, 0.84, 0.12), (0.19, 0.30, 0.25), M["steel"], M["titanium"], detail=False)
    plate(body, "Hips", (0, 0.73, 0), (0.59, 0.23, 0.34), M["dark"])
    armor(body, "TorsoBlock", (0, 0.99, 0), (0.67, 0.48, 0.44), M["rust_dark"], M["rust_plate"])
    vents(body, "ChestVent", (0.20, 1.02, 0.23), (0.16, 0.04, 0.02), M["dark"], rows=3)
    armor(body, "HeadBlock", (0, 1.33, 0.02), (0.40, 0.25, 0.31), M["steel"], M["titanium"], detail=False)
    plate(body, "EyeBar", (0, 1.37, 0.185), (0.28, 0.043, 0.025), M["glow_red"], bevel=0.002)
    shield = grp("Shield", root, (0, 0.75, 0.33))
    armor(shield, "ShieldBack", (0, 0, 0), (0.70, 0.94, 0.15), M["dark"], M["gunmetal"], (0.10, 0, 0))
    armor(shield, "ShieldFace", (0, 0, 0.096), (0.59, 0.84, 0.09), M["rust_dark"], M["rust_plate"], (0.10, 0, 0))
    for s in (-1, 1):
        plate(shield, f"ShieldEdge{s}", (s * 0.30, 0, 0.14), (0.035, 0.73, 0.025), M["glow_red"], bevel=0.002)
    plate(shield, "ShieldBar", (0, 0.23, 0.157), (0.40, 0.04, 0.023), M["glow_red"], bevel=0.002)
    plate(shield, "ShieldBoss", (0, -0.09, 0.169), (0.23, 0.28, 0.032), M["edge"])
    reactor = grp("Reactor", root, (0, 1.02, -0.26))
    cyl(reactor, "ReactorCell", (0, 0, 0), (0.14, 0.10, 0.14), M["glow_red"], (math.pi / 2, 0, 0), verts=20)
    return root


def build_splitter(M):
    root, body = enemy_root("SplitterModel")
    for s in (-1, 1):
        ball(body, f"Core{s}", (s * 0.24, 0.72, 0), (0.30, 0.30, 0.30), M["rust_plate"])
        ball(body, f"CoreDark{s}", (s * 0.24, 0.72, 0.16), (0.13, 0.13, 0.13), M["dark"])
        plate(body, f"Eye{s}", (s * 0.24, 0.76, 0.30), (0.14, 0.035, 0.02), M["glow_hot"], bevel=0.002)
        for leg in range(2):
            z = -0.18 + leg * 0.36
            beam(body, f"Leg{s}{leg}", (s * 0.20, 0.55, z), (s * 0.42, 0.10, z + 0.08), 0.045, M["steel"])
        for k in range(3):
            cone(body, f"Spike{s}{k}", (s * (0.24 + (k - 1) * 0.1), 0.98, -0.10 + k * 0.1), (0.045, 0.22, 0.045), M["rust_dark"], (0.3, 0, s * -0.2))
    plate(body, "Crack", (0, 0.72, 0), (0.055, 0.5, 0.42), M["rubber"])
    plate(body, "CrownPlate", (0, 1.02, -0.05), (0.30, 0.09, 0.30), M["brass"])
    reactor = grp("Reactor", root, (0, 0.72, -0.34))
    ball(reactor, "ReactorCell", (0, 0, 0), (0.11, 0.11, 0.11), M["glow_amber"])
    return root


def build_mite(M):
    root, body = enemy_root("MiteModel")
    ball(body, "Core", (0, 0.38, 0), (0.26, 0.26, 0.26), M["rust_plate"])
    plate(body, "Eye", (0, 0.42, 0.22), (0.16, 0.04, 0.02), M["glow_hot"], bevel=0.002)
    cone(body, "SpikeTop", (0, 0.58, -0.05), (0.05, 0.2, 0.05), M["rust_dark"], (0.25, 0, 0))
    for s in (-1, 1):
        for leg in range(2):
            z = -0.12 + leg * 0.24
            beam(body, f"Leg{s}{leg}", (s * 0.14, 0.30, z), (s * 0.30, 0.06, z + 0.06), 0.035, M["steel"])
    reactor = grp("Reactor", root, (0, 0.38, -0.24))
    ball(reactor, "ReactorCell", (0, 0, 0), (0.08, 0.08, 0.08), M["glow_amber"])
    return root


def build_boss(M):
    root, body = enemy_root("ReactorGuardianModel")
    for s in (-1, 1):
        armor(body, f"Track{s}", (s * 0.56, 0.20, 0.16), (0.70, 0.36, 0.95), M["dark"], M["gunmetal"])
        plate(body, f"TrackGuard{s}", (s * 0.56, 0.29, 0.44), (0.58, 0.15, 0.34), M["edge"])
        for w in range(4):
            cyl(body, f"Wheel{s}{w}", (s * 0.93, 0.20, -0.28 + w * 0.30), (0.16, 0.06, 0.16), M["steel"], (0, 0, math.pi / 2), verts=20)
        armor(body, f"LegTower{s}", (s * 0.54, 0.76, 0), (0.47, 0.77, 0.50), M["steel"], M["titanium"], (0, 0, s * -0.08))
        plate(body, f"LegGlow{s}", (s * 0.55, 0.90, 0.30), (0.41, 0.09, 0.04), M["glow_amber"], bevel=0.004)
        armor(body, f"Shoulder{s}", (s * 1.0, 1.93, 0), (0.72, 0.66, 0.82), M["brass"], M["gunmetal"], (0, 0, s * -0.24), detail=False)
        armor(body, f"ArmCannon{s}", (s * 1.12, 1.43, 0.10), (0.46, 0.67, 0.61), M["rust_dark"], M["rust_plate"], (-0.20, 0, s * -0.08))
        plate(body, f"ArmBase{s}", (s * 1.12, 1.24, 0.33), (0.40, 0.32, 0.33), M["dark"])
        cyl(body, f"CannonBarrel{s}", (s * 1.12, 1.50, 0.62), (0.11, 0.55, 0.11), M["gunmetal"], (math.pi / 2, 0, 0), verts=20)
        plate(body, f"ArmLight{s}", (s * 1.12, 1.68, 0.44), (0.25, 0.06, 0.032), M["glow_hot"], bevel=0.002)
        plate(body, f"CrestFin{s}", (s * 0.68, 2.30, -0.08), (0.32, 0.56, 0.45), M["steel"], (0, 0, s * -0.3))
    cyl(body, "Waist", (0, 1.18, 0), (0.72, 0.29, 0.58), M["dark"], verts=24)
    armor(body, "TorsoCore", (0, 1.72, 0), (1.25, 0.92, 0.90), M["rust_dark"], M["rust_plate"], (0, math.pi * 0.125, 0))
    armor(body, "ChestPlate", (0, 2.14, 0.15), (1.42, 0.20, 0.86), M["rust_plate"], M["brass"], detail=False)
    vents(body, "TorsoVent", (0.42, 1.72, 0.42), (0.3, 0.05, 0.03), M["dark"], rows=4)
    armor(body, "HeadBlock", (0, 2.43, 0.02), (0.83, 0.47, 0.57), M["dark"], M["gunmetal"])
    plate(body, "HeadCrest", (0, 2.75, 0.01), (0.89, 0.32, 0.58), M["steel"], (0.15, 0, 0))
    plate(body, "EyeBand", (0, 2.48, 0.317), (0.65, 0.105, 0.044), M["glow_orange"], bevel=0.004)
    plate(body, "EyeCore", (0, 2.49, 0.345), (0.39, 0.038, 0.019), M["glow_hot"], bevel=0.002)
    cyl(body, "BackStack", (0, 1.65, -0.65), (0.53, 0.32, 0.53), M["steel"], (math.pi / 2, 0, 0), verts=24)
    for s in (-1, 1):
        cyl(body, f"Smokestack{s}", (s * 0.45, 2.45, -0.42), (0.13, 0.85, 0.13), M["gunmetal"], verts=16)
        cyl(body, f"StackGlow{s}", (s * 0.45, 2.90, -0.42), (0.10, 0.06, 0.10), M["glow_orange"], verts=14)
    reactor = grp("Reactor", root, (0, 1.77, 0.65))
    cyl(reactor, "ReactorHousing", (0, 0, 0), (0.45, 0.13, 0.45), M["dark"], (math.pi / 2, 0, 0), verts=8)
    cyl(reactor, "ReactorMid", (0, 0, 0.08), (0.34, 0.07, 0.34), M["glow_orange"], (math.pi / 2, 0, 0), verts=8)
    cyl(reactor, "ReactorCore", (0, 0, 0.126), (0.24, 0.045, 0.24), M["glow_hot"], (math.pi / 2, 0, 0), verts=8)
    plate(reactor, "ReactorBar", (0, 0, 0.16), (0.05, 0.42, 0.03), M["brass"], bevel=0.002)
    ring = grp("Ring", root, (0, 2.26, -0.08))
    for i in range(16):
        a = i / 16 * math.tau
        plate(ring, f"RingSeg{i}", (math.sin(a) * 1.34, 0, math.cos(a) * 1.34), (0.20, 0.05, 0.07), M["glow_orange"], (0, a, 0), bevel=0.002)
    return root


def build_deck_textures():
    import numpy as np
    S = 1024
    rng = np.random.default_rng(7712)
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float32)
    # height field: 2x2 panels with bevelled seams, bolt dimples, scratches
    h = np.ones((S, S), np.float32) * 0.72
    panel = S // 2
    for axis in (xx, yy):
        d = np.abs((axis % panel) - panel / 2)
        seam = np.clip((d - (panel / 2 - 14)) / 14, 0, 1)
        h -= seam * 0.30
        bevel = np.clip((d - (panel / 2 - 34)) / 20, 0, 1)
        h -= bevel * 0.10
    scratch_mask = np.zeros((S, S), np.float32)
    for i in range(90):  # scratches
        x0, y0 = rng.integers(0, S, 2); ln = rng.integers(20, 180); ang = rng.uniform(0, math.tau)
        xs = (x0 + np.cos(ang) * np.arange(ln)).astype(int) % S
        ys = (y0 + np.sin(ang) * np.arange(ln)).astype(int) % S
        h[ys, xs] -= 0.18
        scratch_mask[ys, xs] = 1.0
    noise = rng.random((S // 8, S // 8)).astype(np.float32)
    noise = np.kron(noise, np.ones((8, 8), np.float32))
    for _ in range(2):
        noise = (noise + np.roll(noise, 4, 0) + np.roll(noise, 4, 1)) / 3
    h += (noise - 0.5) * 0.07
    # albedo: gunmetal plates, wear lightening on high spots, dark stains
    base = np.array([0.30, 0.34, 0.40], np.float32)
    alb = np.ones((S, S, 3), np.float32) * base
    fine = rng.random((S, S)).astype(np.float32)
    alb *= (0.97 + fine * 0.06)[..., None]
    alb *= (0.85 + noise * 0.35)[..., None]
    alb *= (1.0 + scratch_mask * 0.5)[..., None]
    alb *= (0.55 + h * 0.55)[..., None]
    stain = np.clip((noise - 0.62) * 2.4, 0, 1)
    alb *= (1 - stain * 0.35)[..., None]
    warm = np.clip(((xx / S) - 0.4), 0, 1) * 0.10
    alb[..., 0] += warm * 0.35; alb[..., 1] += warm * 0.16
    # roughness: mid base, polished wear lanes smoother, stains rougher
    rough = np.clip(0.46 + (noise - 0.5) * 0.22 - np.clip(h - 0.7, 0, 1) * 0.18 + stain * 0.15, 0.08, 0.9)
    # normal from height (Sobel), OpenGL Y+
    gx = np.roll(h, -1, 1) - np.roll(h, 1, 1)
    gy = np.roll(h, -1, 0) - np.roll(h, 1, 0)
    n = np.stack([-gx * 2.2, gy * 2.2, np.ones_like(h)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    nrm = n * 0.5 + 0.5

    def save(arr, fname, srgb):
        img = bpy.data.images.new(fname, S, S, alpha=False)
        # colorspace MUST be set before pixels: changing it afterwards
        # regenerates (clears) a generated image's buffer on save.
        img.colorspace_settings.name = 'sRGB' if srgb else 'Non-Color'
        rgba = np.ones((S, S, 4), np.float32)
        rgba[..., :3] = np.clip(arr, 0, 1)[::-1]  # flip rows for PNG orientation
        img.pixels = rgba.ravel().tolist()
        img.filepath_raw = os.path.join(TEXTURES, fname)
        img.file_format = 'PNG'
        img.save()
        print("TEXTURE", fname)
    save(alb, "deck_albedo.png", True)
    save(np.repeat(rough[..., None], 3, -1), "deck_rough.png", False)
    save(nrm, "deck_normal.png", False)


def preview(root, name):
    scene = bpy.context.scene
    scene.render.engine = 'BLENDER_EEVEE_NEXT'
    scene.render.resolution_x = 900; scene.render.resolution_y = 900
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("PreviewWorld"); scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.03, 0.07, 0.09, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.7
    meshes = [o for o in root.children_recursive if o.type == 'MESH']
    cam = H.add_camera("PreviewCam", (4, -5, 3), (0, 0, 1), lens=55)
    H.frame_objects(cam, meshes, azimuth=32, elevation=16, margin=1.12)
    H.studio_lighting(target=meshes, key_azimuth=-40, key_elevation=50, intensity=1.1, contrast=0.62, softness=0.5)
    ground = H.add_plane("PreviewGround", size=(30, 30), location=(0, 0, -0.001),
                         mat=H.material("GroundMat", "#232a30", roughness=0.5, metallic=0.6))
    scene.render.filepath = os.path.join(PREVIEW, name + "_preview.png")
    bpy.ops.render.render(write_still=True)
    print("PREVIEW", name)
    bpy.data.objects.remove(ground, do_unlink=True)
    bpy.data.objects.remove(cam, do_unlink=True)


def delete_tree(o):
    for c in list(o.children):
        delete_tree(c)
    bpy.data.objects.remove(o, do_unlink=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    only = args[args.index("--only") + 1] if "--only" in args else "all"
    do_render = "--render" in args
    H.reset_scene()
    M = make_mats()
    builders = [("courier", build_courier), ("gunner", build_gunner), ("charger", build_charger),
                ("bruiser", build_bruiser), ("splitter", build_splitter), ("mite", build_mite),
                ("boss", build_boss)]
    for name, fn in builders:
        if only not in ("all", "enemies", name):
            continue
        if only == "enemies" and name == "courier":
            continue
        root = fn(M)
        if do_render:
            preview(root, name)
        export_glb(root, name + ".glb")
        if name == "courier":
            H.save_blend(os.path.join(ROOT, "assets", "blender", "courier.blend"))
        delete_tree(root)
    if only in ("all", "deck"):
        build_deck_textures()
    print("BUILD DONE", only)


main()
