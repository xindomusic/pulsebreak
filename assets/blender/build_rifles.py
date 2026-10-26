# Pulsebreak 2.0 player rifles: smooth Blender models for the four weapon
# variants, matching scripts/art.gd's contract: Rifle/{kinetic,scatter,arc,
# plasma}/{Evolved,Masterwork}, receiver near origin, muzzle toward +Z.
# Usage: Blender -b --factory-startup --python-exit-code 1 -P build_rifles.py -- [--render]
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
    m["dark"]     = H.material("DarkFrame", "#15171B", roughness=0.52, metallic=0.65)
    m["gunmetal"] = H.material("Gunmetal",  "#2A2721", roughness=0.34, metallic=0.88)
    m["titanium"] = H.material("Titanium",  "#9AA7B4", roughness=0.22, metallic=0.92)
    m["brass"]    = H.material("Brass",     "#B08A45", roughness=0.28, metallic=1.0)
    m["rubber"]   = H.material("Rubber",    "#14181F", roughness=0.95, metallic=0.0)
    m["copper"]   = H.material("Copper",    "#B56B45", roughness=0.34, metallic=1.0)
    m["visor"]    = H.material("Visor",     "#0A0F14", roughness=0.08, metallic=0.9, coat=1.0, coat_roughness=0.06)
    m["glow_kinetic"] = H.material("GlowKinetic", "#101820", roughness=0.4, metallic=0.0, emission="#BFE3FF", emission_strength=3.2)
    m["glow_scatter"] = H.material("GlowScatter", "#2A1600", roughness=0.4, metallic=0.0, emission="#FFAA33", emission_strength=3.2)
    m["glow_arc"]     = H.material("GlowArc",     "#0A1626", roughness=0.4, metallic=0.0, emission="#6FC3FF", emission_strength=3.4)
    m["glow_plasma"]  = H.material("GlowPlasma",  "#2A1E00", roughness=0.4, metallic=0.0, emission="#FFD98A", emission_strength=3.4)
    m["glow_hot"]     = H.material("GlowHot",     "#331A00", roughness=0.4, metallic=0.0, emission="#FFE2A0", emission_strength=3.6)
    return m

def P(g): return (g[0], -g[2], g[1])
def R(g): return (g[0], -g[2], g[1])

def grp(name, parent, loc_g=(0, 0, 0)):
    e = bpy.data.objects.new(name, None)
    COL.objects.link(e)
    e.empty_display_size = 0.04
    if parent is not None:
        H.parent(e, parent, keep_transform=False)
    e.location = P(loc_g)
    return e

def place(obj, parent, loc_g, rot_g=(0, 0, 0)):
    H.parent(obj, parent, keep_transform=False)
    obj.location = P(loc_g)
    obj.rotation_euler = R(rot_g)
    return obj

def plate(parent, name, c, size, mat, rot=(0, 0, 0), bevel=0.008):
    sx, sy, sz = size
    o = H.add_box(name, size=(sx, sz, sy), bevel=min(bevel, min(sx, sy, sz) * 0.32), mat=mat, collection=COL)
    H.shade_smooth(o, angle=42)
    return place(o, parent, c, rot)

def shell(parent, name, c, size, mat, rot=(0, 0, 0), bevel=0.018):
    sx, sy, sz = size
    o = H.add_box(name, size=(sx, sz, sy), bevel=min(bevel, min(sx, sy, sz) * 0.32), mat=mat, collection=COL)
    H.add_modifier(o, "SUBSURF", levels=1, render_levels=1)
    H.shade_smooth(o, angle=55)
    return place(o, parent, c, rot)

def ball(parent, name, c, radii, mat, rot=(0, 0, 0)):
    o = H.add_sphere(name, radius=1.0, scale=(radii[0], radii[2], radii[1]), mat=mat,
                     segments=28, rings=18, collection=COL)
    H.shade_smooth(o, angle=55)
    return place(o, parent, c, rot)

def cyl(parent, name, c, size, mat, rot=(0, 0, 0), top_ratio=1.0, verts=24):
    o = H.add_cylinder(name, radius=size[0], depth=size[1], radius_top=size[0] * top_ratio,
                       vertices=verts, bevel=size[0] * 0.08, mat=mat, collection=COL)
    H.shade_smooth(o, angle=50)
    return place(o, parent, c, rot)

def lathe(parent, name, c, profile, mat, rot=(0, 0, 0), segments=24):
    o = H.add_lathe(name, profile, segments=segments, mat=mat, collection=COL, close_ends=True)
    H.shade_smooth(o, angle=55)
    return place(o, parent, c, rot)

def cable(parent, name, pts, radius, mat):
    o = H.add_tube(name, [P(p) for p in pts], radius=radius, mat=mat, collection=COL, bevel_resolution=8)
    H.parent(o, parent, keep_transform=False)
    o.location = (0, 0, 0)
    return o

def vents(parent, name, c, size, mat, rows=3):
    for i in range(rows):
        dy = (i - (rows - 1) / 2) * size[1] * 0.95
        plate(parent, f"{name}Vent{i}", (c[0], c[1] + dy, c[2]), (size[0], size[1] * 0.42, size[2]), mat, bevel=0.002)


def build_base(M, rifle):
    shell(rifle, "Receiver", (0, 0, 0.02), (0.15, 0.19, 0.52), M["gunmetal"], bevel=0.03)
    shell(rifle, "ReceiverTop", (0, 0.085, -0.02), (0.11, 0.07, 0.40), M["titanium"], bevel=0.02)
    for s in (-1, 1):
        shell(rifle, f"SidePanel{s}", (s * 0.078, 0.01, 0.06), (0.03, 0.13, 0.34), M["ceramic"], bevel=0.012)
        vents(rifle, f"RecvVent{s}", (s * 0.097, 0.02, -0.02), (0.012, 0.03, 0.14), M["dark"], rows=3)
        cable(rifle, f"PowerCable{s}", [(s * 0.06, -0.04, -0.28), (s * 0.09, -0.07, 0.02), (s * 0.06, -0.03, 0.26)], 0.013, M["copper"] if s > 0 else M["rubber"])
    shell(rifle, "Stock", (0, 0.015, -0.36), (0.11, 0.16, 0.26), M["dark"], bevel=0.03)
    plate(rifle, "ButtPad", (0, 0.01, -0.50), (0.12, 0.17, 0.03), M["rubber"], bevel=0.01)
    shell(rifle, "Grip", (0, -0.13, -0.12), (0.07, 0.17, 0.09), M["rubber"], (0.38, 0, 0), bevel=0.02)
    shell(rifle, "Mag", (0, -0.16, 0.10), (0.08, 0.18, 0.12), M["dark"], (0.22, 0, 0), bevel=0.018)
    plate(rifle, "MagBase", (0, -0.245, 0.12), (0.09, 0.03, 0.13), M["brass"], (0.22, 0, 0), bevel=0.008)
    plate(rifle, "SightPost", (0, 0.14, 0.02), (0.03, 0.06, 0.16), M["titanium"], bevel=0.006)
    plate(rifle, "SightGlass", (0, 0.155, -0.03), (0.045, 0.035, 0.05), M["visor"], bevel=0.006)
    plate(rifle, "SightDot", (0, 0.155, 0.0), (0.014, 0.014, 0.014), M["glow_hot"], bevel=0.002)
    cyl(rifle, "ChargeCell", (0.085, -0.02, 0.18), (0.035, 0.05, 0.035), M["gunmetal"], (0, 0, math.pi / 2), verts=18)


def tier_addons(M, variant, glow):
    evolved = grp("Evolved", variant)
    for s in (-1, 1):
        shell(evolved, f"Pod{s}", (s * 0.155, 0.0, 0.38), (0.07, 0.13, 0.40), M["gunmetal"], (0, s * 0.10, 0), bevel=0.02)
        plate(evolved, f"PodGlow{s}", (s * 0.192, 0.02, 0.40), (0.012, 0.04, 0.26), glow, bevel=0.002)
        plate(evolved, f"PodFin{s}", (s * 0.16, 0.085, 0.30), (0.015, 0.05, 0.18), M["brass"], bevel=0.004)
    plate(evolved, "CellBand", (0, -0.09, 0.42), (0.13, 0.03, 0.10), glow, bevel=0.002)
    master = grp("Masterwork", variant)
    shell(master, "TopShroud", (0, 0.115, 0.32), (0.16, 0.07, 0.46), M["titanium"], bevel=0.02)
    plate(master, "SpineGlow", (0, 0.152, 0.32), (0.05, 0.012, 0.34), glow, bevel=0.002)
    plate(master, "SpineTrim", (0, 0.10, 0.56), (0.17, 0.025, 0.03), M["brass"], bevel=0.004)
    cyl(master, "MuzzleCrown", (0, 0.01, 0.98), (0.055, 0.045, 0.055), M["brass"], (math.pi / 2, 0, 0), verts=6)


def build_kinetic(M, rifle):
    v = grp("kinetic", rifle)
    glow = M["glow_kinetic"]
    shell(v, "Shroud", (0, 0.01, 0.40), (0.16, 0.14, 0.44), M["ceramic"], bevel=0.025)
    for s in (-1, 1):
        plate(v, f"Rail{s}", (s * 0.052, 0.025, 0.66), (0.028, 0.035, 0.52), M["titanium"], bevel=0.004)
        for i in range(3):
            plate(v, f"Cell{s}{i}", (s * 0.085, 0.01, 0.28 + i * 0.12), (0.012, 0.05, 0.07), glow, bevel=0.002)
        vents(v, f"ShroudVent{s}", (s * 0.082, 0.045, 0.52), (0.01, 0.025, 0.16), M["dark"], rows=2)
    plate(v, "RailGlow", (0, 0.025, 0.66), (0.03, 0.016, 0.50), glow, bevel=0.002)
    cyl(v, "Barrel", (0, 0.01, 0.80), (0.028, 0.34, 0.028), M["gunmetal"], (math.pi / 2, 0, 0), verts=18)
    cyl(v, "MuzzleBrake", (0, 0.01, 0.96), (0.045, 0.08, 0.045), M["brass"], (math.pi / 2, 0, 0), verts=6)
    tier_addons(M, v, glow)


def build_scatter(M, rifle):
    v = grp("scatter", rifle)
    glow = M["glow_scatter"]
    shell(v, "Shroud", (0, 0.01, 0.40), (0.26, 0.20, 0.46), M["titanium"], bevel=0.03)
    shell(v, "ShroudTop", (0, 0.10, 0.38), (0.20, 0.08, 0.38), M["ceramic"], bevel=0.025)
    for s in (-1, 1):
        cyl(v, f"Barrel{s}", (s * 0.072, 0.01, 0.68), (0.042, 0.52, 0.042), M["gunmetal"], (math.pi / 2, 0, 0), verts=20)
        cyl(v, f"Muzzle{s}", (s * 0.072, 0.01, 0.95), (0.055, 0.06, 0.055), M["brass"], (math.pi / 2, 0, 0), verts=20)
        cyl(v, f"MuzzleGlow{s}", (s * 0.072, 0.01, 0.985), (0.030, 0.015, 0.030), glow, (math.pi / 2, 0, 0), verts=14)
        vents(v, f"SideVent{s}", (s * 0.135, 0.02, 0.40), (0.012, 0.04, 0.24), M["dark"], rows=3)
    plate(v, "TopGlow", (0, 0.145, 0.38), (0.10, 0.014, 0.24), glow, bevel=0.002)
    cyl(v, "Drum", (0, -0.13, 0.44), (0.105, 0.10, 0.105), M["gunmetal"], (0, 0, math.pi / 2), verts=24)
    cyl(v, "DrumCore", (0.058, -0.13, 0.44), (0.045, 0.02, 0.045), glow, (0, 0, math.pi / 2), verts=16)
    shell(v, "PumpGrip", (0, -0.09, 0.66), (0.14, 0.07, 0.20), M["rubber"], bevel=0.02)
    tier_addons(M, v, glow)


def build_arc(M, rifle):
    v = grp("arc", rifle)
    glow = M["glow_arc"]
    cyl(v, "CoreBarrel", (0, 0.01, 0.45), (0.045, 0.50, 0.045), M["dark"], (math.pi / 2, 0, 0), verts=18)
    ball(v, "Orb", (0, 0.01, 0.40), (0.085, 0.085, 0.085), glow)
    ball(v, "OrbCore", (0, 0.01, 0.40), (0.045, 0.045, 0.045), M["glow_hot"])
    for i, zz in enumerate((0.30, 0.40, 0.50)):
        cyl(v, f"CoilRing{i}", (0, 0.01, zz), (0.105, 0.025, 0.105), M["copper"], (math.pi / 2, 0, 0), verts=24)
    for s in (-1, 1):
        shell(v, f"Prong{s}", (s * 0.11, 0.01, 0.62), (0.045, 0.11, 0.62), M["titanium"], bevel=0.015)
        plate(v, f"ProngGlow{s}", (s * 0.11, 0.07, 0.64), (0.02, 0.014, 0.44), glow, bevel=0.002)
        ball(v, f"ProngTip{s}", (s * 0.11, 0.01, 0.95), (0.034, 0.034, 0.034), glow)
        cyl(v, f"Capacitor{s}", (s * 0.10, -0.03, 0.22), (0.032, 0.20, 0.032), M["copper"], (math.pi / 2, 0, 0), verts=14)
        cable(v, f"CoilFeed{s}", [(s * 0.08, -0.02, 0.14), (s * 0.12, 0.02, 0.30), (s * 0.10, 0.01, 0.48)], 0.011, M["rubber"])
    tier_addons(M, v, glow)


def build_plasma(M, rifle):
    v = grp("plasma", rifle)
    glow = M["glow_plasma"]
    shell(v, "Shroud", (0, 0.01, 0.30), (0.18, 0.17, 0.30), M["ceramic"], bevel=0.03)
    cyl(v, "Barrel", (0, 0.01, 0.60), (0.070, 0.62, 0.070), M["gunmetal"], (math.pi / 2, 0, 0), verts=24)
    cyl(v, "InnerBarrel", (0, 0.01, 0.88), (0.048, 0.24, 0.048), M["titanium"], (math.pi / 2, 0, 0), verts=20)
    cyl(v, "MuzzleGlow", (0, 0.01, 1.0), (0.036, 0.02, 0.036), glow, (math.pi / 2, 0, 0), verts=16)
    for i, zz in enumerate((0.42, 0.60, 0.78)):
        cyl(v, f"GlowRing{i}", (0, 0.01, zz), (0.088, 0.032, 0.088), glow, (math.pi / 2, 0, 0), verts=24)
        cyl(v, f"RingClamp{i}", (0, 0.01, zz - 0.035), (0.080, 0.02, 0.080), M["brass"], (math.pi / 2, 0, 0), verts=24)
    for s in (-1, 1):
        cyl(v, f"Tank{s}", (s * 0.125, -0.02, 0.36), (0.034, 0.30, 0.034), M["copper"], (math.pi / 2, 0, 0), verts=16)
        cyl(v, f"TankCap{s}", (s * 0.125, -0.02, 0.52), (0.026, 0.03, 0.026), glow, (math.pi / 2, 0, 0), verts=12)
        shell(v, f"SideFin{s}", (s * 0.115, 0.04, 0.52), (0.02, 0.10, 0.34), M["ceramic"], bevel=0.008)
    plate(v, "TopCell", (0, 0.105, 0.30), (0.07, 0.02, 0.16), glow, bevel=0.002)
    tier_addons(M, v, glow)


def tree(o):
    yield o
    for c in o.children:
        yield from tree(c)


def set_variant_visible(rifle, mode):
    for m in ("kinetic", "scatter", "arc", "plasma"):
        for o in tree(bpy.data.objects[m]):
            o.hide_render = (m != mode)


def main():
    global COL
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    H.reset_scene()
    COL = H.collection("Rifles")
    M = make_mats()
    root = grp("RifleModel", None)
    rifle = grp("Rifle", root)
    build_base(M, rifle)
    build_kinetic(M, rifle)
    build_scatter(M, rifle)
    build_arc(M, rifle)
    build_plasma(M, rifle)
    if "--render" in args:
        cam = H.add_camera("RifleCam", (1.5, -2.1, 0.65), (0, 0.05, 0.25), lens=58)
        H.sun_and_sky(elevation=18, azimuth=210, strength=0.35, sun_strength=3.2)
        H.add_light("AREA", "Fill", (-1.4, -1.6, 1.2), (0, 0, 0.2), energy=260, size=2)
        H.add_plane("RG", size=(12, 12), location=(0, 0, -0.42),
                    mat=H.material("RGM", "#232a30", roughness=0.45, metallic=0.6), collection=COL)
        H.set_render(engine="BLENDER_EEVEE_NEXT", resolution=(1000, 620), samples=32, percentage=100, view_transform="AgX")
        for mode in ("kinetic", "scatter", "arc", "plasma"):
            set_variant_visible(rifle, mode)
            H.render_still(os.path.join(PREVIEW, f"rifle_{mode}.png"))
        for o in tree(root):
            o.hide_render = False
            o.hide_viewport = False
    bpy.ops.object.select_all(action='DESELECT')
    for o in tree(root):
        o.select_set(True)
    bpy.context.view_layer.objects.active = root
    path = os.path.join(MODELS, "rifles.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB',
                              export_apply=True, use_selection=True, export_yup=True)
    print("EXPORTED rifles.glb", os.path.getsize(path), "objects", len(list(tree(root))))
    print("RIFLES DONE")


main()
