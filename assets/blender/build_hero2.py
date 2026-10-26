# Courier Mk2 — smooth AAA hero asset proof.
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

    # ---- pelvis + skirt ----
    shell(body, "Pelvis", (0, 1.10, 0), (0.36, 0.22, 0.28), M["dark"], bevel=0.035)
    shell(body, "Codpiece", (0, 1.08, 0.12), (0.22, 0.20, 0.10), M["ceramic"], rot_deg=(-18, 0, 0), bevel=0.03)
    plate2(body, "PelvisLight", (0, 1.11, 0.18), (0.09, 0.03, 0.015), M["glow"])
    for s in (-1, 1):
        shell(body, f"Skirt{s}", (s * 0.19, 1.02, 0.07), (0.20, 0.30, 0.26), M["ceramic"], rot_deg=(-16, 0, s * 10), bevel=0.03)
        shell(body, f"SkirtBack{s}", (s * 0.15, 1.03, -0.15), (0.18, 0.26, 0.08), M["white"], rot_deg=(14, 0, s * 6), bevel=0.025)

    # ---- torso ----
    torso = grp("Torso", body, L(0, 1.16, 0))
    shell(torso, "Abdomen", (0, 0.10, 0), (0.34, 0.26, 0.26), M["dark"], bevel=0.04)
    for i in range(3):  # ab segmentation rings
        cyl2(torso, f"AbRing{i}", (0, 0.03 + i * 0.075, 0.01), 0.155, 0.03, M["gunmetal"], rot_deg=(90, 0, 0), verts=28).scale = (1.15, 1, 1)
    shell(torso, "Chest", (0, 0.34, 0.01), (0.50, 0.40, 0.34), M["ceramic"], rot_deg=(-6, 0, 0), bevel=0.045)
    for s in (-1, 1):
        shell(torso, f"Pec{s}", (s * 0.145, 0.37, 0.15), (0.24, 0.26, 0.16), M["white"], rot_deg=(-10, s * -8, s * -5), bevel=0.045)
        groove(torso, f"PecGroove{s}", (s * 0.145, 0.27, 0.205), (0.17, 0.015, 0.012), M["dark"], rot_deg=(-10, s * -8, s * -5))
        plate2(torso, f"PecLight{s}", (s * 0.16, 0.455, 0.185), (0.13, 0.02, 0.014), M["glow"], rot_deg=(-10, s * -8, 0))
        shell(torso, f"Lat{s}", (s * 0.24, 0.26, -0.06), (0.13, 0.30, 0.26), M["titanium"], rot_deg=(0, 0, s * 6), bevel=0.03)
        tube(torso, f"TorsoCable{s}", [(s * 0.10, 0.02, -0.12), (s * 0.16, 0.14, -0.17), (s * 0.11, 0.30, -0.15)], 0.018, M["rubber"])
    cyl2(torso, "ReactorHousing", (0, 0.36, 0.20), 0.10, 0.05, M["brass"], rot_deg=(90, 0, 0), verts=6)
    cyl2(torso, "ReactorCore", (0, 0.36, 0.225), 0.056, 0.03, M["glow_hot"], rot_deg=(90, 0, 0), verts=6)
    shell(torso, "Collar", (0, 0.545, -0.01), (0.34, 0.09, 0.30), M["brass"], bevel=0.03)
    for s in (-1, 1):
        for r in range(4):
            groove(torso, f"Vent{s}{r}", (s * 0.255, 0.28 + r * 0.042, 0.10), (0.014, 0.02, 0.15), M["dark"])
        plate2(torso, f"ChestSeam{s}", (s * 0.205, 0.24, 0.19), (0.012, 0.20, 0.01), M["glow"], rot_deg=(-8, 0, s * 12))
        bolt_row(torso, f"PecBolts{s}", (s * 0.06, 0.47, 0.20), (s * 0.24, 0.47, 0.19), 4, M["brass"])
    light_strip(torso, "CollarLights", (0, 0.545, 0.16), 5, 0.045, M["glow_hot"], size=0.012)
    groove(torso, "ChestGrooveV", (0, 0.33, 0.245), (0.012, 0.22, 0.01), M["dark"])
    txt = H.add_text("Decal07", "07", size=0.075, extrude=0.002, mat=M["decal"], collection=COL)
    put(txt, torso, L(-0.16, 0.30, 0.245), (0, 0, 0))
    txt.rotation_euler = (math.radians(90), 0, 0)
    txt2 = H.add_text("DecalMk", "MK.III", size=0.028, extrude=0.002, mat=M["brass"], collection=COL)
    put(txt2, torso, L(0.15, 0.215, 0.235), (0, 0, 0))
    txt2.rotation_euler = (math.radians(90), 0, 0)

    # ---- head ----
    head = grp("Head", torso, L(0, 0.60, 0.01), rot_deg=(-4, 0, 0))
    head.scale = (0.92, 0.92, 0.92)
    cyl2(head, "Neck", (0, -0.055, -0.01), 0.062, 0.11, M["dark"], verts=24)
    shell(head, "Helm", (0, 0.075, -0.015), (0.255, 0.27, 0.29), M["ceramic"], rot_deg=(-8, 0, 0), bevel=0.055)
    shell(head, "Crown", (0, 0.20, -0.04), (0.20, 0.12, 0.24), M["white"], rot_deg=(-16, 0, 0), bevel=0.04)
    plate2(head, "Brow", (0, 0.135, 0.115), (0.24, 0.045, 0.07), M["brass"], rot_deg=(-14, 0, 0), bevel=0.012)
    shell(head, "Faceplate", (0, 0.03, 0.10), (0.20, 0.17, 0.13), M["visor"], rot_deg=(-12, 0, 0), bevel=0.035)
    plate2(head, "EyeSlit", (0, 0.065, 0.165), (0.17, 0.026, 0.012), M["glow_hot"], rot_deg=(-10, 0, 0))
    cyl2(head, "SensorBump", (0.07, 0.24, 0.06), 0.028, 0.03, M["gunmetal"], verts=20)
    cyl2(head, "SensorEye", (0.07, 0.262, 0.06), 0.016, 0.012, M["glow_hot"], verts=14)
    for r in range(3):
        groove(head, f"ChinVent{r}", (0, -0.10 + r * 0.028, 0.155), (0.07, 0.012, 0.01), M["dark"], rot_deg=(-18, 0, 0))
    shell(head, "Jaw", (0, -0.075, 0.075), (0.16, 0.10, 0.14), M["titanium"], rot_deg=(-18, 0, 0), bevel=0.03)
    fin = H.add_extrusion("CrestFin", [(0.10, 0.0), (0.02, 0.085), (-0.16, 0.10), (-0.20, 0.02), (-0.10, -0.01)], depth=0.016, bevel=0.004, mat=M["brass"], collection=COL)
    put(fin, head, L(0, 0.24, -0.02), (0, 90, 0))
    for s in (-1, 1):
        shell(head, f"Cheek{s}", (s * 0.105, -0.02, 0.07), (0.07, 0.15, 0.16), M["ceramic"], rot_deg=(-14, 0, s * -10), bevel=0.025)
        cyl2(head, f"EarDisc{s}", (s * 0.135, 0.06, -0.01), 0.052, 0.035, M["titanium"], rot_deg=(0, 0, 90), verts=28)
        cyl2(head, f"EarLight{s}", (s * 0.155, 0.06, -0.01), 0.026, 0.012, M["glow"], rot_deg=(0, 0, 90), verts=20)
        tube(head, f"JawCable{s}", [(s * 0.09, -0.09, 0.05), (s * 0.12, -0.13, -0.03), (s * 0.08, -0.10, -0.10)], 0.011, M["rubber"])
    # ---- legs ----
    thigh_prof = [(0.001, -0.24), (0.085, -0.22), (0.105, -0.10), (0.115, 0.05), (0.10, 0.18), (0.07, 0.24), (0.001, 0.25)]
    shin_prof = [(0.001, -0.24), (0.07, -0.22), (0.088, -0.08), (0.095, 0.06), (0.08, 0.18), (0.06, 0.23), (0.001, 0.24)]
    rig = {}
    for s in (-1, 1):
        suf = "Left" if s < 0 else "Right"
        hip = grp("Hip" + suf, body, L(s * 0.125, 1.10, 0))
        ball2(hip, "HipJoint", (0, 0, 0), (0.10, 0.10, 0.10), M["titanium"])
        cyl2(hip, "HipRing", (s * 0.085, 0, 0), 0.062, 0.028, M["brass"], rot_deg=(0, 0, 90), verts=28)
        limb(hip, "Thigh", (0, -0.23, 0), thigh_prof, M["dark"], scale=(1.0, 0.86, 1.0))
        shell(hip, "ThighArmor", (s * 0.01, -0.20, 0.055), (0.20, 0.36, 0.13), M["ceramic"], rot_deg=(-5, 0, s * 3), bevel=0.04)
        groove(hip, "ThighGroove", (s * 0.01, -0.13, 0.115), (0.13, 0.014, 0.01), M["dark"], rot_deg=(-5, 0, s * 3))
        plate2(hip, "ThighLight", (s * 0.105, -0.22, 0.03), (0.016, 0.20, 0.05), M["glow"])
        plate2(hip, "ThighStripe", (s * 0.01, -0.06, 0.115), (0.15, 0.035, 0.012), M["brass"], rot_deg=(-5, 0, s * 3))
        tube(hip, "ThighCable", [(s * 0.07, -0.04, -0.08), (s * 0.10, -0.24, -0.11), (s * 0.06, -0.42, -0.07)], 0.014, M["rubber"])
        knee = grp("Knee" + suf, hip, L(0, -0.51, 0.01))
        ball2(knee, "KneeJoint", (0, 0, 0), (0.085, 0.085, 0.085), M["dark"])
        cyl2(knee, "KneeDisc", (s * 0.09, 0, 0.01), 0.058, 0.024, M["brass"], rot_deg=(0, 0, 90), verts=28)
        shell(knee, "KneeGuard", (0, 0.01, 0.075), (0.16, 0.15, 0.09), M["titanium"], rot_deg=(-8, 0, 0), bevel=0.03)
        limb(knee, "Shin", (0, -0.22, -0.01), shin_prof, M["dark"], scale=(1.0, 0.88, 1.0))
        shell(knee, "ShinGuard", (0, -0.20, 0.06), (0.175, 0.36, 0.11), M["ceramic"], rot_deg=(4, 0, 0), bevel=0.035)
        plate2(knee, "ShinLight", (0, -0.18, 0.115), (0.03, 0.22, 0.012), M["glow"])
        for r in range(3):
            groove(knee, f"ShinVent{r}", (-0.055, -0.10 - r * 0.05, 0.115), (0.045, 0.014, 0.01), M["dark"])
        for bi in range(6):
            ba = bi / 6 * math.tau
            cyl2(knee, f"KneeBolt{bi}", (s * 0.105, math.sin(ba) * 0.042, 0.01 + math.cos(ba) * 0.042), 0.007, 0.014, M["titanium"], rot_deg=(0, 0, 90), verts=6)
        stxt = H.add_text("ShinDecal" + suf, "07", size=0.05, extrude=0.0015, mat=M["decal"], collection=COL)
        put(stxt, knee, L(-0.045, -0.30, 0.118), (0, 0, 0))
        stxt.rotation_euler = (math.radians(90), 0, 0)
        cyl2(knee, "CalfPiston", (s * 0.045, -0.20, -0.085), 0.02, 0.30, M["titanium"], verts=16)
        ankle = grp("Ankle" + suf, knee, L(0, -0.49, 0.01))
        ball2(ankle, "AnkleJoint", (0, 0, 0), (0.06, 0.06, 0.06), M["titanium"])
        shell(ankle, "Foot", (0, -0.045, 0.06), (0.17, 0.11, 0.35), M["dark"], rot_deg=(3, 0, 0), bevel=0.03)
        shell(ankle, "ToeCap", (0, -0.03, 0.16), (0.165, 0.09, 0.20), M["ceramic"], rot_deg=(-6, 0, 0), bevel=0.028)
        plate2(ankle, "Sole", (0, -0.105, 0.07), (0.16, 0.025, 0.34), M["rubber"])
        plate2(ankle, "HeelLight", (0, -0.05, -0.12), (0.10, 0.03, 0.014), M["glow"])
        rig[f"hip{s}"] = hip; rig[f"knee{s}"] = knee; rig[f"ankle{s}"] = ankle

    # ---- arms ----
    upper_prof = [(0.001, -0.17), (0.06, -0.15), (0.075, -0.04), (0.07, 0.08), (0.055, 0.16), (0.001, 0.17)]
    fore_prof = [(0.001, -0.16), (0.055, -0.14), (0.075, -0.02), (0.08, 0.07), (0.06, 0.15), (0.001, 0.16)]
    for s in (-1, 1):
        suf = "Left" if s < 0 else "Right"
        sh = grp("Shoulder" + suf, torso, L(s * 0.31, 0.44, 0))
        ball2(sh, "ShoulderJoint", (0, 0, 0), (0.095, 0.095, 0.095), M["dark"])
        pd = ball2(sh, "Pauldron", (s * 0.05, 0.05, 0), (0.275, 0.23, 0.30), M["ceramic"], rot_deg=(0, s * -14, 0))
        shell(sh, "PauldronRim", (s * 0.06, -0.045, 0), (0.22, 0.07, 0.24), M["brass"], rot_deg=(0, s * -14, 0), bevel=0.02)
        plate2(sh, "PauldronLight", (s * 0.155, 0.03, 0.06), (0.014, 0.05, 0.09), M["glow"], rot_deg=(0, 0, s * 10))
        bolt_row(sh, "RimBolts", (s * 0.10, -0.055, -0.09), (s * 0.10, -0.055, 0.09), 4, M["titanium"], r=0.007)
        limb(sh, "UpperArm", (s * 0.02, -0.16, 0), upper_prof, M["dark"], scale=(1.0, 0.9, 1.0))
        shell(sh, "BicepPlate", (s * 0.03, -0.13, 0.045), (0.13, 0.20, 0.09), M["ceramic"], rot_deg=(-4, 0, s * 4), bevel=0.028)
        el = grp("Elbow" + suf, sh, L(s * 0.02, -0.33, 0.01))
        ball2(el, "ElbowJoint", (0, 0, 0), (0.068, 0.068, 0.068), M["titanium"])
        cyl2(el, "ElbowDisc", (s * 0.07, 0, 0), 0.045, 0.02, M["brass"], rot_deg=(0, 0, 90), verts=24)
        limb(el, "Forearm", (0, -0.15, 0.01), fore_prof, M["dark"], scale=(1.0, 0.92, 1.0))
        shell(el, "ForearmGuard", (0, -0.14, 0.055), (0.16, 0.26, 0.10), M["ceramic"], rot_deg=(-5, 0, 0), bevel=0.03)
        plate2(el, "ForearmCell", (0, -0.12, 0.11), (0.06, 0.09, 0.014), M["glow"])
        groove(el, "ForearmGroove", (0, -0.20, 0.105), (0.11, 0.012, 0.01), M["dark"])
        for r in range(3):
            groove(el, f"ForeVent{r}", (s * 0.085, -0.08 - r * 0.05, 0.05), (0.01, 0.016, 0.08), M["dark"])
        cyl2(el, "ElbowPiston", (s * 0.05, -0.06, -0.07), 0.016, 0.20, M["titanium"], verts=14)
        tube(el, "ForeCable", [(s * 0.06, -0.02, -0.06), (s * 0.09, -0.16, -0.08), (s * 0.05, -0.30, -0.03)], 0.012, M["copper"])
        fist = grp("Fist" + suf, el, L(0, -0.33, 0.02))
        shell(fist, "FistBlock", (0, -0.03, 0.01), (0.13, 0.13, 0.15), M["gunmetal"], bevel=0.024)
        for fx in (-0.04, 0.0, 0.04):
            shell(fist, f"Finger{fx}", (fx, -0.10, 0.035), (0.032, 0.09, 0.045), M["dark"], rot_deg=(-28, 0, 0), bevel=0.012, levels=1)
        shell(fist, "Thumb", (-s * 0.07, -0.06, 0.04), (0.03, 0.08, 0.04), M["dark"], rot_deg=(-20, 0, s * 24), bevel=0.01, levels=1)
        rig[f"sh{s}"] = sh; rig[f"el{s}"] = el; rig[f"fist{s}"] = fist

    # ---- backpack, wings, thrusters ----
    reactor = grp("Reactor", root, L(0, 1.50, -0.30))
    shell(reactor, "Pack", (0, 0.02, -0.03), (0.40, 0.46, 0.20), M["gunmetal"], bevel=0.04)
    shell(reactor, "PackPlate", (0, 0.10, -0.13), (0.28, 0.30, 0.07), M["titanium"], bevel=0.025)
    cyl2(reactor, "Exhaust", (0, 0.06, -0.19), 0.11, 0.07, M["dark"], rot_deg=(90, 0, 0), verts=28)
    cyl2(reactor, "ExhaustGlow", (0, 0.06, -0.23), 0.075, 0.025, M["glow"], rot_deg=(90, 0, 0), verts=24)
    for s in (-1, 1):
        cyl2(reactor, f"Tank{s}", (s * 0.14, 0.16, -0.10), 0.055, 0.34, M["copper"], verts=24)
        cyl2(reactor, f"TankCap{s}", (s * 0.14, 0.345, -0.10), 0.04, 0.03, M["gunmetal"], verts=20)
    for fi in range(5):
        plate2(reactor, f"RadFin{fi}", (-0.12 + fi * 0.06, -0.16, -0.14), (0.035, 0.20, 0.012), M["titanium"])
    cyl2(reactor, "Mast", (-0.17, 0.38, -0.08), 0.011, 0.34, M["gunmetal"], verts=10)
    cyl2(reactor, "MastLight", (-0.17, 0.56, -0.08), 0.016, 0.025, M["glow_hot"], verts=10)
    light_strip(reactor, "PackLights", (0.10, -0.05, -0.185), 4, 0.04, M["glow"], size=0.01)
    wing_outline = [(0.0, -0.26), (0.24, -0.28), (0.46, -0.02), (0.56, 0.34), (0.52, 0.66), (0.38, 0.98), (0.22, 1.22), (0.10, 1.26), (0.03, 0.86), (0.0, 0.32)]
    for s in (-1, 1):
        suf = "Left" if s < 0 else "Right"
        wing = grp("Wing" + suf, reactor, L(s * 0.20, 0.18, -0.10), rot_deg=(0, s * -6, s * 10))
        panels = grp("Panels" + suf, wing)
        panels.scale = (float(s), 1.0, 1.0)
        blade = H.add_extrusion("WingBlade" + suf, wing_outline, depth=0.045, bevel=0.01, mat=M["ceramic"], collection=COL)
        H.shade_smooth(blade, angle=45)
        # outline authored in (fwd, up) plane: rotate extrusion so outline Y -> up, thickness -> side
        put(blade, panels, (0, 0, 0), (0, 90, 0))
        blade.rotation_euler = (0, math.radians(90), 0)
        inner = H.add_extrusion("WingInner" + suf, [(0.03, -0.20), (0.40, 0.0), (0.48, 0.55), (0.30, 1.05), (0.12, 1.12), (0.04, 0.5)], depth=0.012, bevel=0.002, mat=M["gunmetal"], collection=COL)
        put(inner, panels, (0, 0.030, 0), (0, 90, 0))
        glowline = H.add_extrusion("WingGlow" + suf, [(0.07, 0.28), (0.11, 0.84), (0.15, 1.12), (0.185, 1.10), (0.14, 0.82), (0.105, 0.30)], depth=0.052, bevel=0.002, mat=M["glow"], collection=COL)
        put(glowline, panels, (0, 0, 0), (0, 90, 0))
        tip = H.add_extrusion("WingTip" + suf, [(0.16, 1.06), (0.22, 1.22), (0.10, 1.26), (0.07, 1.08)], depth=0.05, bevel=0.003, mat=M["brass"], collection=COL)
        put(tip, panels, (0, 0, 0), (0, 90, 0))
        thr = grp("Thruster" + suf, reactor, L(s * 0.20, -0.22, -0.06))
        bell = H.add_lathe("Bell" + suf, [(0.001, -0.16), (0.105, -0.15), (0.075, -0.06), (0.055, 0.04), (0.065, 0.10), (0.001, 0.11)], segments=32, mat=M["titanium"], collection=COL, close_ends=True)
        put(bell, thr, (0, 0, 0))
        cyl2(thr, "NozzleGlow", (0, -0.155, 0), 0.07, 0.02, M["glow"], verts=24)
        plume = grp("Plume" + suf, thr, L(0, -0.17, 0))
        plume_mat = H.material("PlumeMat" + suf, "#2A1600", roughness=0.5, metallic=0.0, emission="#FFB35C", emission_strength=2.2, alpha=0.5)
        cone_o = H.add_cone("PlumeCone" + suf, radius=0.075, depth=0.5, mat=plume_mat, collection=COL)
        put(cone_o, plume, L(0, -0.25, 0), (180, 0, 0))
        rig[f"wing{s}"] = wing

    ring = grp("Ring", root, L(0, 1.52, -0.04), rot_deg=(10, 0, 6))
    tor = H.add_torus("HaloRing", major=0.54, minor=0.012, mat=M["glow"], collection=COL)
    put(tor, ring, (0, 0, 0))
    return root, rig


def build_gun(M, fist):
    gun = grp("Rifle", fist, L(0, -0.06, 0.10), rot_deg=(74, 0, 0))
    shell(gun, "Receiver", (0, 0, 0.10), (0.13, 0.17, 0.62), M["gunmetal"], bevel=0.025)
    shell(gun, "Shroud", (0, 0.02, 0.38), (0.15, 0.13, 0.30), M["dark"], bevel=0.02)
    cyl2(gun, "Barrel", (0, 0.01, 0.62), 0.038, 0.34, M["titanium"], rot_deg=(90, 0, 0), verts=24)
    cyl2(gun, "MuzzleBrake", (0, 0.01, 0.78), 0.052, 0.09, M["brass"], rot_deg=(90, 0, 0), verts=24)
    plate2(gun, "CellGlow", (0, 0.0, 0.22), (0.145, 0.05, 0.16), M["glow"])
    plate2(gun, "Sight", (0, 0.115, 0.16), (0.035, 0.07, 0.18), M["titanium"])
    plate2(gun, "SightDot", (0, 0.125, 0.10), (0.02, 0.02, 0.02), M["glow_hot"])
    cyl2(gun, "Drum", (0.10, -0.05, 0.18), 0.075, 0.07, M["gunmetal"], rot_deg=(0, 0, 90), verts=28)
    cyl2(gun, "DrumCore", (0.14, -0.05, 0.18), 0.035, 0.02, M["glow"], rot_deg=(0, 0, 90), verts=20)
    for ri in range(4):
        plate2(gun, f"Rail{ri}", (0, 0.095, 0.30 + ri * 0.07), (0.05, 0.02, 0.04), M["titanium"])
    for vi in range(3):
        groove(gun, f"ShroudVent{vi}", (0.078, 0.02, 0.32 + vi * 0.07), (0.008, 0.05, 0.035), M["rubber"])
    tube(gun, "PowerCable", [(0.05, -0.02, -0.16), (0.09, -0.10, 0.02), (0.06, -0.04, 0.20)], 0.014, M["copper"])
    shell(gun, "Mag", (0, -0.13, 0.14), (0.08, 0.16, 0.12), M["dark"], rot_deg=(18, 0, 0), bevel=0.015)
    shell(gun, "Grip", (0, -0.09, -0.10), (0.07, 0.16, 0.09), M["rubber"], rot_deg=(24, 0, 0), bevel=0.02)
    shell(gun, "Stock", (0, 0.01, -0.26), (0.10, 0.13, 0.22), M["gunmetal"], bevel=0.02)
    return gun


def pose(rig):
    # heroic idle: slight contrapposto, gun arm forward-down, head turned
    rig["hip-1"].rotation_euler = (math.radians(4), 0, math.radians(3))
    rig["hip1"].rotation_euler = (math.radians(-7), 0, math.radians(-4))
    rig["knee-1"].rotation_euler = (math.radians(-6), 0, 0)
    rig["knee1"].rotation_euler = (math.radians(10), 0, 0)
    rig["ankle-1"].rotation_euler = (math.radians(2), 0, 0)
    rig["ankle1"].rotation_euler = (math.radians(-3), 0, 0)
    rig["sh1"].rotation_euler = (math.radians(-38), 0, math.radians(-6))   # gun arm
    rig["el1"].rotation_euler = (math.radians(-14), 0, 0)
    rig["sh-1"].rotation_euler = (math.radians(8), 0, math.radians(7))
    rig["el-1"].rotation_euler = (math.radians(-18), 0, 0)


def add_scene(M):
    ground_mat = H.material("DeckGround", "#14171B", roughness=0.34, metallic=0.6)
    H.add_noise_variation(ground_mat, scale=3, amount=0.10, roughness_amount=0.12)
    H.add_plane("Ground", size=(60, 60), location=(0, 0, 0), mat=ground_mat, collection=COL)
    dark = H.material("BackdropDark", "#141A20", roughness=0.6, metallic=0.5)
    H.add_box("TowerA", size=(3.5, 3.5, 9), location=(-9.5, 13, 4.5), mat=dark, collection=COL, bevel=0.05)
    H.add_box("TowerB", size=(5, 4, 12), location=(8.5, 15, 6), mat=dark, collection=COL, bevel=0.05)
    ring = H.add_torus("TurbineRing", major=2.4, minor=0.32, mat=dark, collection=COL)
    ring.location = (6.4, 10.5, 5.0)
    hub = H.add_cylinder("TurbineHub", radius=0.5, depth=0.7, mat=M["brass"], collection=COL)
    hub.location = (6.4, 10.5, 5.0); hub.rotation_euler = (math.radians(90), 0, 0)
    for i in range(7):
        b = H.add_box(f"TBlade{i}", size=(0.28, 0.08, 1.9), mat=dark, collection=COL)
        a = i / 7 * math.tau
        b.location = (6.4 + math.cos(a) * 1.25, 10.5, 5.0 + math.sin(a) * 1.25)
        b.rotation_euler = (0, -a, 0.5)


def main():
    global COL
    H.reset_scene()
    COL = H.collection("Hero")
    M = mats()
    root, rig = build(M)
    build_gun(M, rig["fist1"])
    pose(rig)
    for o in root.children_recursive:
        if o.name.startswith("PlumeCone"):
            o.hide_render = True
    add_scene(M)
    cam = H.add_camera("HeroCam", (3.05, -4.15, 1.85), (0, 0, 1.02), lens=57)
    H.sun_and_sky(elevation=8, azimuth=215, strength=0.16, sun_strength=5.0)
    H.add_light("AREA", "KeyFill", (-2.6, -3.4, 2.6), (0, 0, 1.1), energy=520, size=4)
    H.add_light("SPOT", "Rim", (3.2, 3.6, 3.2), (0, 0, 1.2), energy=2200, size=2)
    H.volume_fog(density=0.012, size=40, center=(0, 4, 2))
    if FINAL:
        H.set_render(engine="CYCLES", resolution=(1500, 1050), samples=96, percentage=100, view_transform="AgX")
        H.render_still(os.path.join(OUT, "hero2_final.png"))
        H.save_blend(os.path.join(ROOT, "assets", "blender", "hero2.blend"))
    else:
        H.set_render(engine="BLENDER_EEVEE_NEXT", resolution=(1100, 800), samples=32, percentage=70, view_transform="AgX")
        H.render_still(os.path.join(OUT, "hero2_preview.png"))
    H.report()
    print("HERO2 DONE final=", FINAL)


main()
