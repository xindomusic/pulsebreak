# Courier Mk3 — key-art-faithful hero (heroic proportions, layered armor, tall binders).
# Same rig hierarchy/names as courier (Body/Torso/Head/Hip/Knee/Shoulder/Elbow/
# Reactor/Wing/Thruster/Plume/Ring) but heroic proportions and smooth
# subdivision/lathe construction. Authored in Blender coords via L():
#   L(right, up, fwd) -> blender (x, -fwd, up); front faces -Y.
# Usage: Blender -b --factory-startup --python-exit-code 1 -P build_hero2.py -- [--blockout|--final]
import sys, os, math
sys.path.insert(0, "/Users/xinboonchen/.local/share/muse/skills/bundled/muse-core--exact-minimal-literal-tests/skills/blender/scripts")
import bpy
import bpy_helpers as H

ROOT = "/Users/xinboonchen/Projects/pulsebreak"
OUT = "/tmp/pb-assets"
os.makedirs(OUT, exist_ok=True)
FINAL = "--final" in sys.argv
EXPORT = "--export" in sys.argv
COL = None  # hero collection, set in main

def L(x, up, fwd): return (x, -fwd, up)
def SZ(sx, sy_up, sz_fwd): return (sx, sz_fwd, sy_up)

def mats():
    m = {}
    m["ceramic"] = H.material("Ceramic", "#E9E5D8", roughness=0.30, metallic=0.06, coat=0.75, coat_roughness=0.22)
    H.add_noise_variation(m["ceramic"], scale=10, amount=0.16, roughness_amount=0.22, bump=0.02)
    m["white"] = H.material("WarmWhite", "#F4EFE3", roughness=0.36, metallic=0.05, coat=0.5, coat_roughness=0.3)
    H.add_noise_variation(m["white"], scale=16, amount=0.07, roughness_amount=0.12)
    m["dark"] = H.material("DarkFrame", "#16181D", roughness=0.48, metallic=0.7)
    H.add_noise_variation(m["dark"], scale=20, amount=0.12, roughness_amount=0.15)
    m["gunmetal"] = H.material("Gunmetal", "#2C2924", roughness=0.34, metallic=0.88)
    m["titanium"] = H.material("Titanium", "#A7B2BE", roughness=0.22, metallic=0.95)
    m["brass"] = H.material("Brass", "#C09544", roughness=0.27, metallic=1.0)
    m["visor"] = H.material("Visor", "#0A0E13", roughness=0.06, metallic=0.9, coat=1.0, coat_roughness=0.05)
    m["rubber"] = H.material("Rubber", "#12151A", roughness=0.92, metallic=0.0)
    m["glow"] = H.material("GlowAmber", "#2A1600", roughness=0.4, metallic=0.0, emission="#FFB35C", emission_strength=3.0)
    m["glow_hot"] = H.material("GlowHot", "#331A00", roughness=0.4, metallic=0.0, emission="#FFE2A0", emission_strength=4.0)
    m["copper"] = H.material("Copper", "#B56B45", roughness=0.34, metallic=1.0)
    m["rust"] = H.material("Rust", "#8A4030", roughness=0.58, metallic=0.3)
    H.add_noise_variation(m["rust"], scale=18, amount=0.22, roughness_amount=0.2, bump=0.02)
    m["decal"] = H.material("DecalDark", "#22262C", roughness=0.55, metallic=0.2)
    return m

def grp(name, parent, loc=(0, 0, 0), rot_deg=(0, 0, 0)):
    e = bpy.data.objects.new(name, None)
    COL.objects.link(e)
    e.empty_display_size = 0.04
    if parent is not None:
        H.parent(e, parent, keep_transform=False)
    e.location = loc
    e.rotation_euler = tuple(math.radians(a) for a in rot_deg)
    return e

def put(obj, parent, loc, rot_deg=(0, 0, 0)):
    H.parent(obj, parent, keep_transform=False)
    obj.location = loc
    obj.rotation_euler = tuple(math.radians(a) for a in rot_deg)
    return obj

def sub(obj, levels=2):
    H.add_modifier(obj, "SUBSURF", levels=levels, render_levels=levels)
    H.shade_smooth(obj, angle=55)
    return obj

def shell(parent, name, center, size_up_fwd, mat, rot_deg=(0, 0, 0), bevel=0.02, levels=1):
    """Rounded armor shell: beveled box + subdivision. center/size in (right, up, fwd)."""
    sx, sy, sz = size_up_fwd
    o = H.add_box(name, size=SZ(sx, sy, sz), bevel=min(bevel, min(size_up_fwd) * 0.30), mat=mat, collection=COL)
    sub(o, levels)
    return put(o, parent, L(*center), rot_deg)

def plate2(parent, name, center, size_up_fwd, mat, rot_deg=(0, 0, 0), bevel=0.008):
    sx, sy, sz = size_up_fwd
    o = H.add_box(name, size=SZ(sx, sy, sz), bevel=min(bevel, min(size_up_fwd) * 0.3), mat=mat, collection=COL)
    H.shade_smooth(o, angle=42)
    return put(o, parent, L(*center), rot_deg)

def limb(parent, name, center, profile, mat, scale=(1, 1, 1), rot_deg=(0, 0, 0)):
    """Lathe limb segment along local Z (up). profile = [(radius, z)...] bottom->top."""
    o = H.add_lathe(name, profile, segments=36, mat=mat, collection=COL, close_ends=True)
    o.scale = scale
    H.shade_smooth(o, angle=55)
    return put(o, parent, L(*center), rot_deg)

def ball2(parent, name, center, size_up_fwd, mat, rot_deg=(0, 0, 0)):
    sx, sy, sz = size_up_fwd
    o = H.add_sphere(name, radius=0.5, scale=(sx, sz, sy), mat=mat, collection=COL)
    sub(o, 1)
    return put(o, parent, L(*center), rot_deg)

def cyl2(parent, name, center, radius, depth, mat, rot_deg=(0, 0, 0), top=None, verts=36):
    o = H.add_cylinder(name, radius=radius, depth=depth, radius_top=top, vertices=verts, bevel=radius * 0.10, mat=mat, collection=COL)
    H.shade_smooth(o, angle=50)
    return put(o, parent, L(*center), rot_deg)

def tube(parent, name, pts_up_fwd, radius, mat, taper=None):
    pts = [L(*p) for p in pts_up_fwd]
    o = H.add_tube(name, pts, radius=radius, mat=mat, collection=COL, taper=taper, bevel_resolution=10)
    H.parent(o, parent, keep_transform=False)
    o.location = (0, 0, 0)
    return o

def groove(parent, name, center, size_up_fwd, mat_dark, rot_deg=(0, 0, 0)):
    return plate2(parent, name, center, size_up_fwd, mat_dark, rot_deg, bevel=0.001)

def bolt_row(parent, name, a_up_fwd, b_up_fwd, count, mat, r=0.008):
    for i in range(count):
        t = i / max(1, count - 1)
        c = tuple(a_up_fwd[k] + (b_up_fwd[k] - a_up_fwd[k]) * t for k in range(3))
        cyl2(parent, f"{name}{i}", c, r, 0.012, mat, rot_deg=(90, 0, 0), verts=6)

def light_strip(parent, name, center, count, dx, mat, size=0.011):
    for i in range(count):
        plate2(parent, f"{name}{i}", (center[0] + (i - (count - 1) / 2) * dx, center[1], center[2]),
               (size, size, 0.008), mat, bevel=0.001)


def build(M):
    root = grp("CourierModel", None)
    body = grp("Body", root)
    rig = {}

    # pelvis: narrow, armored codpiece + skirt plates
    shell(body, "Pelvis", (0, 1.34, 0), (0.34, 0.20, 0.26), M["dark"], bevel=0.035)
    shell(body, "Codpiece", (0, 1.32, 0.11), (0.20, 0.20, 0.10), M["ceramic"], rot_deg=(-20, 0, 0), bevel=0.03)
    plate2(body, "BeltBar", (0, 1.42, 0.13), (0.26, 0.035, 0.02), M["brass"])
    for s in (-1, 1):
        shell(body, f"Skirt{s}", (s * 0.175, 1.24, 0.05), (0.18, 0.30, 0.24), M["ceramic"], rot_deg=(-14, 0, s * 12), bevel=0.028)
        shell(body, f"SkirtBack{s}", (s * 0.13, 1.25, -0.13), (0.16, 0.27, 0.07), M["white"], rot_deg=(16, 0, s * 8), bevel=0.022)
        groove(body, f"SkirtGroove{s}", (s * 0.185, 1.20, 0.16), (0.10, 0.012, 0.01), M["dark"], rot_deg=(-14, 0, s * 12))

    # torso: sharp taper chest -> waist
    torso = grp("Torso", body, L(0, 1.42, 0))
    shell(torso, "Midriff", (0, 0.10, 0), (0.30, 0.24, 0.24), M["dark"], bevel=0.04)
    for i in range(3):
        r = cyl2(torso, f"AbRing{i}", (0, 0.02 + i * 0.07, 0.005), 0.145, 0.028, M["gunmetal"], verts=28)
        r.scale = (1.18, 0.82, 1.0)
    shell(torso, "Chest", (0, 0.34, 0.01), (0.54, 0.38, 0.33), M["ceramic"], rot_deg=(-6, 0, 0), bevel=0.045)
    shell(torso, "ChestUnder", (0, 0.20, 0.06), (0.44, 0.20, 0.26), M["gunmetal"], rot_deg=(-10, 0, 0), bevel=0.035)
    for s in (-1, 1):
        shell(torso, f"Pec{s}", (s * 0.14, 0.38, 0.135), (0.23, 0.25, 0.15), M["white"], rot_deg=(-10, s * -9, s * -6), bevel=0.04)
        plate2(torso, f"PecTrim{s}", (s * 0.14, 0.265, 0.20), (0.19, 0.018, 0.012), M["brass"], rot_deg=(-10, s * -9, s * -6))
        plate2(torso, f"PecLight{s}", (s * 0.155, 0.47, 0.16), (0.12, 0.018, 0.012), M["glow"], rot_deg=(-10, s * -8, 0))
        shell(torso, f"Lat{s}", (s * 0.22, 0.28, -0.05), (0.12, 0.30, 0.24), M["titanium"], rot_deg=(0, 0, s * 5), bevel=0.03)
        for r in range(4):
            groove(torso, f"Vent{s}{r}", (s * 0.235, 0.30 + r * 0.04, 0.09), (0.012, 0.018, 0.13), M["dark"])
        tube(torso, f"TorsoCable{s}", [(s * 0.09, 0.04, -0.10), (s * 0.15, 0.16, -0.16), (s * 0.10, 0.32, -0.14)], 0.017, M["copper"])
        bolt_row(torso, f"CollarBolts{s}", (s * 0.05, 0.52, 0.12), (s * 0.20, 0.52, 0.10), 3, M["titanium"], r=0.007)
    cyl2(torso, "ReactorHousing", (-0.085, 0.36, 0.20), 0.075, 0.045, M["brass"], rot_deg=(90, 0, 0), verts=6)
    cyl2(torso, "ReactorCore", (-0.085, 0.36, 0.225), 0.05, 0.03, M["glow_hot"], rot_deg=(90, 0, 0), verts=6)
    cyl2(torso, "ReactorRing", (-0.085, 0.36, 0.19), 0.095, 0.018, M["gunmetal"], rot_deg=(90, 0, 0), verts=24)
    groove(torso, "ChestSeamV", (0.02, 0.34, 0.20), (0.01, 0.20, 0.01), M["dark"])
    shell(torso, "Collar", (0, 0.545, -0.01), (0.30, 0.08, 0.27), M["brass"], bevel=0.028)
    light_strip(torso, "CollarLights", (0, 0.53, 0.135), 5, 0.04, M["glow_hot"], size=0.01)
    txt = H.add_text("Decal07", "07", size=0.06, extrude=0.002, mat=M["decal"], collection=COL)
    put(txt, torso, L(0.145, 0.30, 0.215), (0, 0, 0)); txt.rotation_euler = (math.radians(90), 0, 0)

    # head: small angular helm, recessed face, back-swept crest
    head = grp("Head", torso, L(0, 0.62, 0.01), rot_deg=(-6, 0, 0))
    cyl2(head, "Neck", (0, -0.05, -0.01), 0.052, 0.10, M["dark"], verts=24)
    shell(head, "Helm", (0, 0.06, -0.02), (0.21, 0.24, 0.25), M["ceramic"], rot_deg=(-10, 0, 0), bevel=0.045)
    shell(head, "Crown", (0, 0.17, -0.05), (0.16, 0.10, 0.20), M["white"], rot_deg=(-20, 0, 0), bevel=0.035)
    fin = H.add_extrusion("CrestFin", [(0.09, 0.0), (0.0, 0.075), (-0.17, 0.09), (-0.21, 0.02), (-0.08, -0.012)], depth=0.014, bevel=0.003, mat=M["brass"], collection=COL)
    put(fin, head, L(0, 0.20, -0.03), (0, 0, 0)); fin.rotation_euler = (0, math.radians(90), 0)
    shell(head, "Faceplate", (0, 0.015, 0.085), (0.16, 0.15, 0.11), M["visor"], rot_deg=(-14, 0, 0), bevel=0.03)
    plate2(head, "Brow", (0, 0.105, 0.105), (0.20, 0.035, 0.06), M["brass"], rot_deg=(-14, 0, 0), bevel=0.01)
    plate2(head, "EyeSlit", (0, 0.055, 0.145), (0.13, 0.018, 0.01), M["glow_hot"], rot_deg=(-12, 0, 0))
    shell(head, "Jaw", (0, -0.085, 0.06), (0.13, 0.09, 0.12), M["titanium"], rot_deg=(-16, 0, 0), bevel=0.02)
    for s in (-1, 1):
        shell(head, f"Cheek{s}", (s * 0.09, -0.01, 0.06), (0.06, 0.13, 0.14), M["ceramic"], rot_deg=(-12, 0, s * -8), bevel=0.02)
        cyl2(head, f"EarDisc{s}", (s * 0.11, 0.05, -0.01), 0.042, 0.028, M["titanium"], rot_deg=(0, 0, 90), verts=24)
        cyl2(head, f"EarLight{s}", (s * 0.127, 0.05, -0.01), 0.02, 0.01, M["glow"], rot_deg=(0, 0, 90), verts=16)
        tube(head, f"JawCable{s}", [(s * 0.07, -0.08, 0.04), (s * 0.10, -0.12, -0.04), (s * 0.06, -0.08, -0.09)], 0.009, M["rubber"])
    rig["head"] = head; rig["torso"] = torso

    # ---- legs: long, digitigrade, layered overlapping armor ----
    thigh_prof = [(0.001, -0.28), (0.075, -0.26), (0.105, -0.12), (0.12, 0.06), (0.10, 0.20), (0.065, 0.27), (0.001, 0.28)]
    shin_prof = [(0.001, -0.30), (0.060, -0.28), (0.082, -0.10), (0.09, 0.08), (0.072, 0.22), (0.052, 0.29), (0.001, 0.30)]
    for s in (-1, 1):
        suf = "Left" if s < 0 else "Right"
        hip = grp("Hip" + suf, body, L(s * 0.125, 1.32, 0))
        ball2(hip, "HipJoint", (0, 0, 0), (0.09, 0.09, 0.09), M["titanium"])
        cyl2(hip, "HipDisc", (s * 0.085, 0, 0), 0.075, 0.03, M["brass"], rot_deg=(0, 0, 90), verts=32)
        cyl2(hip, "HipDiscCore", (s * 0.105, 0, 0), 0.038, 0.016, M["gunmetal"], rot_deg=(0, 0, 90), verts=24)
        limb(hip, "Thigh", (0, -0.26, -0.005), thigh_prof, M["dark"], scale=(1.0, 0.85, 1.0))
        shell(hip, "ThighArmor", (s * 0.012, -0.22, 0.045), (0.20, 0.42, 0.13), M["ceramic"], rot_deg=(-4, 0, s * 3), bevel=0.04)
        shell(hip, "ThighArmorLow", (s * 0.012, -0.42, 0.055), (0.185, 0.20, 0.12), M["white"], rot_deg=(-2, 0, s * 3), bevel=0.035)
        plate2(hip, "ThighTrim", (s * 0.012, -0.335, 0.105), (0.16, 0.016, 0.012), M["brass"], rot_deg=(-4, 0, s * 3))
        plate2(hip, "ThighLight", (s * 0.10, -0.26, 0.02), (0.014, 0.24, 0.045), M["glow"])
        tube(hip, "ThighCable", [(s * 0.06, -0.05, -0.08), (s * 0.09, -0.28, -0.11), (s * 0.05, -0.48, -0.06)], 0.015, M["copper"])
        knee = grp("Knee" + suf, hip, L(0, -0.54, 0.015))
        ball2(knee, "KneeJoint", (0, 0, 0), (0.075, 0.075, 0.075), M["dark"])
        cyl2(knee, "KneeDisc", (s * 0.08, 0, 0.005), 0.062, 0.026, M["brass"], rot_deg=(0, 0, 90), verts=28)
        shell(knee, "KneeGuard", (0, 0.015, 0.07), (0.15, 0.14, 0.09), M["titanium"], rot_deg=(-10, 0, 0), bevel=0.03)
        limb(knee, "Shin", (0, -0.28, -0.045), shin_prof, M["dark"], scale=(1.0, 0.9, 1.0), rot_deg=(7, 0, 0))
        shell(knee, "ShinGuard", (0, -0.24, 0.035), (0.165, 0.42, 0.11), M["ceramic"], rot_deg=(5, 0, 0), bevel=0.035)
        shell(knee, "CalfArmor", (0, -0.16, -0.095), (0.14, 0.26, 0.09), M["white"], rot_deg=(9, 0, 0), bevel=0.03)
        plate2(knee, "ShinLight", (0, -0.22, 0.095), (0.026, 0.26, 0.012), M["glow"], rot_deg=(5, 0, 0))
        plate2(knee, "ShinTrim", (-0.055, -0.22, 0.09), (0.014, 0.30, 0.01), M["brass"], rot_deg=(5, 0, 0))
        cyl2(knee, "CalfPiston", (s * 0.04, -0.22, -0.10), 0.018, 0.34, M["titanium"], rot_deg=(7, 0, 0), verts=14)
        for r in range(3):
            groove(knee, f"ShinVent{r}", (-0.05, -0.12 - r * 0.055, 0.09), (0.04, 0.013, 0.01), M["dark"], rot_deg=(5, 0, 0))
        ankle = grp("Ankle" + suf, knee, L(0, -0.58, -0.09))
        ball2(ankle, "AnkleJoint", (0, 0, 0), (0.055, 0.055, 0.055), M["titanium"])
        cyl2(ankle, "AnkleDisc", (s * 0.06, 0, 0), 0.042, 0.02, M["brass"], rot_deg=(0, 0, 90), verts=24)
        shell(ankle, "FootBase", (0, -0.07, 0.05), (0.15, 0.09, 0.30), M["dark"], rot_deg=(2, 0, 0), bevel=0.025)
        shell(ankle, "ToeMain", (0, -0.085, 0.20), (0.145, 0.07, 0.16), M["ceramic"], rot_deg=(-8, 0, 0), bevel=0.02)
        for tx in (-0.045, 0.045):
            c = H.add_cone(f"ToeClaw{tx}", radius=0.026, depth=0.13, mat=M["titanium"], collection=COL)
            put(c, ankle, L(tx, -0.10, 0.30), (105, 0, 0))
        shell(ankle, "HeelSpur", (0, -0.075, -0.10), (0.09, 0.08, 0.12), M["gunmetal"], rot_deg=(24, 0, 0), bevel=0.02)
        plate2(ankle, "HeelLight", (0, -0.045, -0.145), (0.07, 0.025, 0.012), M["glow"])
        rig[f"hip{s}"] = hip; rig[f"knee{s}"] = knee; rig[f"ankle{s}"] = ankle

    # ---- arms: slim upper, bulky forearm (ref language) ----
    upper_prof = [(0.001, -0.19), (0.052, -0.17), (0.066, -0.05), (0.062, 0.08), (0.048, 0.18), (0.001, 0.19)]
    fore_prof = [(0.001, -0.20), (0.055, -0.18), (0.082, -0.04), (0.088, 0.08), (0.062, 0.19), (0.001, 0.20)]
    for s in (-1, 1):
        suf = "Left" if s < 0 else "Right"
        sh = grp("Shoulder" + suf, torso, L(s * 0.30, 0.46, 0))
        ball2(sh, "ShoulderJoint", (0, 0, 0), (0.085, 0.085, 0.085), M["dark"])
        ball2(sh, "Pauldron", (s * 0.055, 0.055, 0), (0.26, 0.21, 0.28), M["ceramic"], rot_deg=(0, s * -12, 0))
        shell(sh, "PauldronRim", (s * 0.07, -0.04, 0), (0.24, 0.07, 0.26), M["brass"], rot_deg=(0, s * -12, 0), bevel=0.02)
        plate2(sh, "PauldronLight", (s * 0.17, 0.04, 0.07), (0.014, 0.045, 0.08), M["glow"], rot_deg=(0, 0, s * 8))
        groove(sh, "PauldronGroove", (s * 0.055, 0.10, 0.10), (0.16, 0.012, 0.01), M["dark"], rot_deg=(0, s * -12, 0))
        limb(sh, "UpperArm", (s * 0.02, -0.18, 0), upper_prof, M["dark"], scale=(1.0, 0.9, 1.0))
        tube(sh, "ArmCable", [(s * 0.05, -0.03, -0.06), (s * 0.08, -0.18, -0.08), (s * 0.05, -0.32, -0.05)], 0.012, M["rubber"])
        el = grp("Elbow" + suf, sh, L(s * 0.02, -0.38, 0.01))
        ball2(el, "ElbowJoint", (0, 0, 0), (0.06, 0.06, 0.06), M["titanium"])
        cyl2(el, "ElbowDisc", (s * 0.062, 0, 0), 0.042, 0.02, M["brass"], rot_deg=(0, 0, 90), verts=24)
        limb(el, "Forearm", (0, -0.18, 0.01), fore_prof, M["dark"], scale=(1.0, 0.92, 1.0))
        shell(el, "ForearmGuard", (0, -0.17, 0.05), (0.17, 0.32, 0.11), M["ceramic"], rot_deg=(-4, 0, 0), bevel=0.032)
        shell(el, "ForearmPlate2", (s * 0.06, -0.20, 0.03), (0.10, 0.24, 0.12), M["white"], rot_deg=(-3, 0, s * 5), bevel=0.025)
        plate2(el, "ForearmCell", (0, -0.14, 0.105), (0.055, 0.10, 0.012), M["glow"])
        for r in range(3):
            groove(el, f"ForeVent{r}", (s * 0.088, -0.09 - r * 0.055, 0.045), (0.01, 0.016, 0.07), M["dark"])
        cyl2(el, "ElbowPiston", (s * 0.045, -0.07, -0.065), 0.014, 0.22, M["titanium"], verts=12)
        fist = grp("Fist" + suf, el, L(0, -0.40, 0.02))
        shell(fist, "FistBlock", (0, -0.035, 0.01), (0.12, 0.13, 0.14), M["gunmetal"], bevel=0.022)
        for fx in (-0.038, 0.0, 0.038):
            shell(fist, f"Finger{fx}", (fx, -0.11, 0.03), (0.03, 0.09, 0.04), M["dark"], rot_deg=(-30, 0, 0), bevel=0.011, levels=1)
        shell(fist, "Thumb", (-s * 0.065, -0.06, 0.035), (0.028, 0.08, 0.038), M["dark"], rot_deg=(-22, 0, s * 26), bevel=0.01, levels=1)
        rig[f"sh{s}"] = sh; rig[f"el{s}"] = el; rig[f"fist{s}"] = fist

    # ---- backpack + tall wing binders (ref signature) ----
    reactor = grp("Reactor", root, L(0, 1.72, -0.27))
    shell(reactor, "Pack", (0, 0.0, -0.03), (0.38, 0.48, 0.20), M["gunmetal"], bevel=0.04)
    shell(reactor, "PackPlate", (0, 0.08, -0.125), (0.27, 0.30, 0.07), M["titanium"], bevel=0.025)
    cyl2(reactor, "Exhaust", (0, 0.04, -0.19), 0.10, 0.07, M["dark"], rot_deg=(90, 0, 0), verts=28)
    cyl2(reactor, "ExhaustGlow", (0, 0.04, -0.23), 0.068, 0.025, M["glow"], rot_deg=(90, 0, 0), verts=24)
    for s in (-1, 1):
        cyl2(reactor, f"Tank{s}", (s * 0.13, 0.14, -0.10), 0.05, 0.34, M["copper"], verts=24)
        cyl2(reactor, f"TankCap{s}", (s * 0.13, 0.325, -0.10), 0.036, 0.03, M["gunmetal"], verts=20)
    for fi in range(5):
        plate2(reactor, f"RadFin{fi}", (-0.11 + fi * 0.055, -0.20, -0.12), (0.032, 0.18, 0.012), M["titanium"])
    cyl2(reactor, "Mast", (-0.16, 0.36, -0.08), 0.010, 0.32, M["gunmetal"], verts=10)
    cyl2(reactor, "MastLight", (-0.16, 0.54, -0.08), 0.015, 0.025, M["glow_hot"], verts=10)

    binder_outline = [(-0.62, 0.10), (-0.30, 0.20), (0.15, 0.22), (0.55, 0.16), (0.80, 0.06), (0.84, -0.02), (0.45, -0.10), (-0.05, -0.12), (-0.48, -0.08), (-0.66, 0.0)]
    for s in (-1, 1):
        suf = "Left" if s < 0 else "Right"
        wing = grp("Wing" + suf, reactor, L(s * 0.26, 0.10, -0.09), rot_deg=(-8, s * 17, s * 4))
        panels = grp("Panels" + suf, wing)
        panels.scale = (float(s) * 0.74, 1.0, 1.0)
        blade = H.add_extrusion("Binder" + suf, binder_outline, depth=0.05, bevel=0.01, mat=M["ceramic"], collection=COL)
        H.shade_smooth(blade, angle=48)
        put(blade, panels, (0, 0, 0), (0, 90, 0))
        inner = H.add_extrusion("BinderInner" + suf, [(-0.5, 0.06), (-0.1, 0.14), (0.4, 0.12), (0.68, 0.04), (0.3, -0.04), (-0.3, -0.03)], depth=0.014, bevel=0.002, mat=M["white"], collection=COL)
        put(inner, panels, (0, 0.032, 0), (0, 90, 0))
        edge = H.add_extrusion("BinderEdge" + suf, [(-0.62, 0.10), (-0.30, 0.20), (0.15, 0.22), (0.55, 0.16), (0.80, 0.06), (0.55, 0.10), (0.12, 0.15), (-0.28, 0.13), (-0.58, 0.05)], depth=0.056, bevel=0.003, mat=M["brass"], collection=COL)
        put(edge, panels, (0, 0, 0), (0, 90, 0))
        glowline = H.add_extrusion("BinderGlow" + suf, [(-0.35, -0.045), (0.35, -0.04), (0.70, -0.015), (0.68, 0.005), (0.32, -0.015), (-0.32, -0.018)], depth=0.058, bevel=0.001, mat=M["glow"], collection=COL)
        put(glowline, panels, (0, 0, 0), (0, 90, 0))
        for sg in range(2):
            groove(panels, f"BinderSeam{sg}", (0, 0.02, 0), (0.001, 0.001, 0.001), M["dark"])  # placeholder no-op kept tiny
        thr = grp("Thruster" + suf, reactor, L(s * 0.19, -0.26, -0.05))
        bell = H.add_lathe("Bell" + suf, [(0.001, -0.17), (0.11, -0.16), (0.078, -0.06), (0.055, 0.05), (0.068, 0.11), (0.001, 0.12)], segments=36, mat=M["titanium"], collection=COL, close_ends=True)
        put(bell, thr, (0, 0, 0))
        cyl2(thr, "NozzleGlow", (0, -0.165, 0), 0.072, 0.02, M["glow"], verts=24)
        rig[f"wing{s}"] = wing

    ring = grp("Ring", root, L(0, 1.62, -0.02), rot_deg=(9, 0, 5))
    tor = H.add_torus("HaloRing", major=0.50, minor=0.011, mat=M["glow"], collection=COL)
    put(tor, ring, (0, 0, 0))
    return root, rig


def build_gun(M, fist):
    gun = grp("Rifle", fist, L(0, -0.05, 0.09), rot_deg=(72, 0, 0))
    shell(gun, "Receiver", (0, 0, 0.08), (0.125, 0.17, 0.66), M["gunmetal"], bevel=0.025)
    shell(gun, "Shroud", (0, 0.015, 0.40), (0.145, 0.13, 0.34), M["dark"], bevel=0.02)
    cyl2(gun, "Barrel", (0, 0.01, 0.70), 0.036, 0.42, M["titanium"], rot_deg=(90, 0, 0), verts=24)
    cyl2(gun, "MuzzleBrake", (0, 0.01, 0.90), 0.052, 0.11, M["brass"], rot_deg=(90, 0, 0), verts=24)
    cyl2(gun, "Underbarrel", (0, -0.07, 0.48), 0.026, 0.40, M["gunmetal"], rot_deg=(90, 0, 0), verts=18)
    plate2(gun, "CellGlow", (0, 0.0, 0.20), (0.135, 0.055, 0.18), M["glow"])
    cyl2(gun, "Drum", (0.095, -0.05, 0.16), 0.078, 0.07, M["gunmetal"], rot_deg=(0, 0, 90), verts=28)
    cyl2(gun, "DrumCore", (0.135, -0.05, 0.16), 0.036, 0.02, M["glow"], rot_deg=(0, 0, 90), verts=20)
    plate2(gun, "Sight", (0, 0.115, 0.12), (0.035, 0.075, 0.20), M["titanium"])
    plate2(gun, "SightDot", (0, 0.13, 0.05), (0.018, 0.018, 0.018), M["glow_hot"])
    for ri in range(4):
        plate2(gun, f"Rail{ri}", (0, 0.09, 0.30 + ri * 0.075), (0.055, 0.02, 0.045), M["titanium"])
    for vi in range(4):
        groove(gun, f"ShroudVent{vi}", (0.076, 0.015, 0.30 + vi * 0.07), (0.008, 0.055, 0.035), M["rubber"])
    tube(gun, "PowerCable", [(0.05, -0.02, -0.18), (0.095, -0.11, 0.0), (0.06, -0.05, 0.22)], 0.014, M["copper"])
    shell(gun, "Mag", (0, -0.14, 0.12), (0.08, 0.17, 0.12), M["dark"], rot_deg=(16, 0, 0), bevel=0.015)
    shell(gun, "Grip", (0, -0.10, -0.12), (0.07, 0.17, 0.09), M["rubber"], rot_deg=(22, 0, 0), bevel=0.02)
    shell(gun, "Stock", (0, 0.01, -0.30), (0.10, 0.13, 0.24), M["gunmetal"], bevel=0.02)
    return gun


def pose(rig, torso, head, body):
    body.rotation_euler = (0, 0, math.radians(-4))
    torso.rotation_euler = (math.radians(3), 0, math.radians(9))
    head.rotation_euler = (math.radians(2), 0, math.radians(-16))
    rig["hip-1"].rotation_euler = (math.radians(-14), 0, math.radians(4))
    rig["knee-1"].rotation_euler = (math.radians(16), 0, 0)
    rig["ankle-1"].rotation_euler = (math.radians(-4), 0, 0)
    rig["hip1"].rotation_euler = (math.radians(6), 0, math.radians(-5))
    rig["knee1"].rotation_euler = (math.radians(4), 0, 0)
    rig["ankle1"].rotation_euler = (math.radians(-6), 0, 0)
    rig["sh1"].rotation_euler = (math.radians(-34), 0, math.radians(-5))
    rig["el1"].rotation_euler = (math.radians(-12), 0, 0)
    rig["sh-1"].rotation_euler = (math.radians(10), 0, math.radians(8))
    rig["el-1"].rotation_euler = (math.radians(-20), 0, 0)


def add_scene(M):
    deck_mat = H.material("DeckGround", "#171C21", roughness=0.30, metallic=0.62)
    H.add_noise_variation(deck_mat, scale=3, amount=0.12, roughness_amount=0.16)
    deck = H.add_cylinder("Deck", radius=7.5, depth=0.35, mat=deck_mat, collection=COL)
    deck.location = (0, 1.5, -0.18)
    for r, e in ((2.0, 1.6), (3.2, 1.2), (4.6, 0.9)):
        t = H.add_torus(f"DeckRing{r}", major=r, minor=0.016, mat=H.material(f"DeckGlow{r}", "#2A1400", roughness=0.5, metallic=0.0, emission="#FF8A1A", emission_strength=e), collection=COL)
        t.location = (0, 1.5, 0.005)
    dark = H.material("BackdropDark", "#12181F", roughness=0.62, metallic=0.5)
    ring = H.add_torus("TurbineRing", major=2.6, minor=0.34, mat=dark, collection=COL)
    ring.location = (-10.5, 15, 3.6)
    ring.rotation_euler = (math.radians(90), 0, 0)
    hub = H.add_cylinder("TurbineHub", radius=0.55, depth=0.8, mat=M["brass"], collection=COL)
    hub.location = (-10.5, 15, 3.6); hub.rotation_euler = (math.radians(90), 0, 0)
    for i in range(7):
        b = H.add_box(f"TBlade{i}", size=(0.3, 0.09, 2.0), mat=dark, collection=COL)
        a = i / 7 * math.tau
        b.location = (-10.5 + math.cos(a) * 1.35, 15, 3.6 + math.sin(a) * 1.35)
        b.rotation_euler = (0, -a, 0.5)


def add_plumes():
    plume_hot = H.material("PlumeHot", "#401A00", roughness=0.5, metallic=0.0, emission="#FFE4A2", emission_strength=2.6, alpha=0.55)
    plume_amber = H.material("PlumeAmber", "#3A1E00", roughness=0.5, metallic=0.0, emission="#FFB35C", emission_strength=2.0, alpha=0.5)
    for suf in ("Left", "Right"):
        thr = bpy.data.objects["Thruster" + suf]
        plume = grp("Plume" + suf, thr, L(0, -0.18, 0))
        cyl2(plume, "PlumeOuter", (0, -0.21, 0), 0.030, 0.42, plume_amber, top=0.095, verts=16)
        cyl2(plume, "PlumeCore", (0, -0.30, 0), 0.016, 0.60, plume_hot, top=0.055, verts=14)


def sanitize_materials_for_gltf():
    """Procedural noise graphs do not survive glTF: drop links into Principled
    sockets so the flat base color / roughness / metalness defaults export."""
    for mat in bpy.data.materials:
        if not mat.use_nodes or mat.node_tree is None:
            continue
        nt = mat.node_tree
        for link in list(nt.links):
            if link.to_node.type == "BSDF_PRINCIPLED" and link.from_node.type != "TEX_IMAGE":
                nt.links.remove(link)


def bake_mirrored_panels():
    """Godot mis-lights glTF nodes with negative scale (flipped normals).
    Bake PanelsLeft's mirror into its meshes' vertices and leave every
    node transform with a positive determinant."""
    panels = bpy.data.objects["PanelsLeft"]
    bpy.context.view_layer.update()
    olds = [(o, o.matrix_world.copy()) for o in list(panels.children_recursive) if o.type == 'MESH']
    panels.scale.x = abs(panels.scale.x)
    bpy.context.view_layer.update()
    inv = panels.matrix_world.inverted()
    for o, mw in olds:
        # Binder meshes are direct children of PanelsLeft (see build()).
        # If one is nested under another child, reparent it flat first.
        if o.parent != panels:
            mw2 = o.matrix_world.copy()
            o.parent = panels
            o.matrix_world = mw2
            mw = mw2
        local = inv @ mw
        o.data.transform(local)
        if local.determinant() < 0:
            for p in o.data.polygons:
                p.flip()
        o.data.update()
        o.matrix_basis.identity()


def export_game(root):
    add_plumes()
    sanitize_materials_for_gltf()
    # Text and beveled-curve tubes must become real meshes for glTF.
    def tree(o):
        yield o
        for c in o.children:
            yield from tree(c)
    objs = list(tree(root))
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        if o.type in ('FONT', 'CURVE'):
            o.select_set(True)
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.convert(target='MESH')
            o.select_set(False)
    bake_mirrored_panels()
    # Ground the model: lowest evaluated vertex sits exactly on z=0.
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    min_z, max_z = 1e9, -1e9
    tris = 0
    for o in objs:
        if o.type != 'MESH':
            continue
        eo = o.evaluated_get(dg)
        tris += sum(len(p.vertices) - 2 for p in eo.to_mesh().polygons)
        for c in eo.bound_box:
            z = (eo.matrix_world @ H.Vector(c)).z
            min_z = min(min_z, z); max_z = max(max_z, z)
    root.location.z -= min_z
    bpy.context.view_layer.update()
    print(f"EXPORT bounds height={max_z - min_z:.3f} min_z={min_z:.3f} tris~{tris} objects={len(objs)}")
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    path = os.path.join(ROOT, "assets", "models", "courier.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB',
                              export_apply=True, use_selection=True, export_yup=True)
    print("EXPORTED", path, os.path.getsize(path))


def main():
    global COL
    H.reset_scene()
    COL = H.collection("Hero")
    M = mats()
    M["ceramic"].node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = 0.34
    root, rig = build(M)
    if EXPORT:
        export_game(root)
        H.save_blend(os.path.join(ROOT, "assets", "blender", "hero3_game.blend"))
        print("HERO3 DONE export=True")
        return
    torso = rig["torso"]; head = rig["head"]
    body = root.children[0]
    build_gun(M, rig["fist1"])
    pose(rig, torso, head, body)
    add_scene(M)
    cam = H.add_camera("HeroCam", (3.25, -4.95, 1.72), (0, 0, 1.18), lens=55)
    H.sun_and_sky(elevation=10, azimuth=218, strength=0.18, sun_strength=5.2)
    H.add_light("AREA", "KeyFill", (-2.8, -3.6, 2.8), (0, 0, 1.2), energy=560, size=4)
    H.add_light("SPOT", "Rim", (3.4, 3.8, 3.4), (0, 0, 1.3), energy=2400, size=2)
    H.volume_fog(density=0.010, size=46, center=(0, 5, 2))
    if FINAL:
        H.set_render(engine="CYCLES", resolution=(1500, 1100), samples=96, percentage=100, view_transform="AgX")
        H.render_still(os.path.join(OUT, "hero3_final.png"))
        H.save_blend(os.path.join(ROOT, "assets", "blender", "hero3.blend"))
    else:
        H.set_render(engine="BLENDER_EEVEE_NEXT", resolution=(1100, 820), samples=32, percentage=75, view_transform="AgX")
        H.render_still(os.path.join(OUT, "hero3_preview.png"))
    H.report()
    print("HERO3 DONE final=", FINAL)


main()

