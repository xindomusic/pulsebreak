extends Node3D
## Shared, bounded combat visuals. The director advances time explicitly so
## hit reactions, debris and discharge effects freeze together while paused.
const Art = preload("res://scripts/art.gd")
const MAX_EFFECTS := 160
const LOW_EFFECTS_LIMIT := 72
const DECORATIVE_RESERVE := 20
const PULSE_GATHER_TIME := 0.075
const PULSE_FRONT_TIME := 0.22
const PULSE_MAX_LIFE := 0.82
const COLORS: Dictionary = {
	"kinetic": Color("70e5ff"), "scatter": Color("ffd078"),
	"arc": Color("bb97ff"), "plasma": Color("67ffc5"),
	"white": Color("f3ffff"), "ember": Color("ff8c4b"),
	"smoke": Color("263545"), "dark": Color("111e2b"),
	"pulse_cyan": Color("24dcff"), "pulse_violet": Color("9670ff"),
	"pulse_hot": Color("ffe8bb")
}
var low_effects := false:
	set(value):
		low_effects=value
		var limit := LOW_EFFECTS_LIMIT if value else MAX_EFFECTS
		while active.size()>limit:
			var victim := 0
			for index: int in range(active.size()):
				if not active[index].essential:
					victim=index
					break
			_release(victim)
var active: Array[Dictionary] = []
var pool: Array[MeshInstance3D] = []
var emitted := 0
var recycled := 0
var elapsed := 0.0
var rng := RandomNumberGenerator.new()
static var _materials: Dictionary = {}
static var _meshes: Dictionary = {}


func _init() -> void:
	rng.seed = 541709


static func _material(key: String) -> StandardMaterial3D:
	if _materials.has(key): return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = COLORS.get(key, COLORS.kinetic)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = key.begins_with("pulse_")
	if key == "smoke":
		material.albedo_color.a = 0.48
	elif key == "dark":
		material.albedo_color.a = 0.65
	else:
		material.emission_enabled = true
		material.emission = material.albedo_color
		material.emission_energy_multiplier = 1.1
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_materials[key] = material
	return material


static func _mesh(key: String) -> Mesh:
	if _meshes.has(key): return _meshes[key]
	var mesh: Mesh
	if key == "ring":
		var ring := TorusMesh.new()
		ring.inner_radius = 0.92
		ring.outer_radius = 1.0
		ring.rings = 32
		ring.ring_segments = 5
		mesh = ring
	elif key in ["arc_core", "arc_glow"]:
		mesh = _lightning_mesh(0.018 if key == "arc_core" else 0.065)
	elif key.begins_with("pulse_"):
		mesh = _pulse_mesh(key)
	else:
		mesh = Art._mesh(key)
	_meshes[key] = mesh
	return mesh


static func _lightning_mesh(width: float) -> ArrayMesh:
	var points: Array[Vector3] = [Vector3.ZERO,Vector3(0.10,0.02,0.16),Vector3(-0.075,-0.025,0.33),Vector3(0.13,0.025,0.49),Vector3(-0.08,0.01,0.67),Vector3(0.055,-0.025,0.83),Vector3(0,0,1)]
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(points.size()-1):
		var a: Vector3 = points[index]
		var b: Vector3 = points[index+1]
		for offset: Vector3 in [Vector3.RIGHT*width,Vector3.UP*width]:
			for vertex: Vector3 in [a-offset,a+offset,b+offset,a-offset,b+offset,b-offset]:
				builder.set_normal(Vector3.UP)
				builder.add_vertex(vertex)
	return builder.commit()


static func _pulse_mesh(shape: String) -> ArrayMesh:
	# Shared, open silhouettes: the damage area stays readable between spokes.
	# Every vertex is inside the unit sphere, including the lifted shard spines.
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	if shape=="pulse_front":
		for index in range(64):
			var a := TAU*float(index)/64.0
			var b := TAU*float(index+1)/64.0
			var inner_a := Vector3(sin(a)*0.945,0,cos(a)*0.945)
			var outer_a := Vector3(sin(a),0,cos(a))
			var inner_b := Vector3(sin(b)*0.945,0,cos(b)*0.945)
			var outer_b := Vector3(sin(b),0,cos(b))
			for vertex: Vector3 in [inner_a,outer_a,outer_b,inner_a,outer_b,inner_b]:
				builder.set_color(Color(1,1,1,0.94 if vertex.length()>0.97 else 0.0))
				builder.set_normal(Vector3.UP)
				builder.add_vertex(vertex)
		return builder.commit()
	var count := 6 if shape=="pulse_sparse" else 12
	for index in range(count):
		var angle := TAU*float(index)/float(count)
		var vertices: Array[Vector3] = []
		if shape=="pulse_arcs":
			for segment in range(5):
				var a := angle+float(segment)*0.055
				var b := a+0.055
				var inner_a := Vector3(sin(a)*0.966,0,cos(a)*0.966)
				var outer_a := Vector3(sin(a),0,cos(a))
				var inner_b := Vector3(sin(b)*0.966,0,cos(b)*0.966)
				var outer_b := Vector3(sin(b),0,cos(b))
				vertices.append_array([inner_a,outer_a,outer_b,inner_a,outer_b,inner_b])
		else:
			var direction := Vector3(sin(angle),0,cos(angle))
			var tangent := Vector3(direction.z,0,-direction.x)
			if shape in ["pulse_gather","pulse_sparse"]:
				var tip := direction*0.985
				var tail := direction*0.51
				vertices.append_array([tail-tangent*0.004,tail+tangent*0.004,tip,tail-Vector3.UP*0.004,tail+Vector3.UP*0.004,tip])
			else:
				var reach := 0.99 if index%3==0 else 0.77
				var heel := direction*0.19
				var left := direction*0.53-tangent*0.037
				var right := direction*0.53+tangent*0.037
				var spine := direction*0.55+Vector3.UP*0.13
				var tip := direction*reach
				vertices.append_array([heel,left,spine,heel,spine,right,left,tip,spine,spine,tip,right])
		for vertex: Vector3 in vertices:
			var alpha := 1.0
			if shape=="pulse_shards":
				alpha=0.90 if vertex.y>0.0 else 0.06 if vertex.length()<0.25 else 0.10 if vertex.length()>0.70 else 0.42
			elif shape in ["pulse_gather","pulse_sparse"]:
				alpha=0.96 if vertex.length()>0.70 else 0.10
			builder.set_color(Color(1,1,1,alpha))
			builder.set_normal(Vector3.UP)
			builder.add_vertex(vertex)
	return builder.commit()


static func _part(parent: Node3D, mesh: String, at: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = _mesh(mesh)
	node.material_override = _material(color)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = at
	node.scale = size
	parent.add_child(node)
	return node


func create_bolt(mode: String, tier: int) -> Node3D:
	var root := Node3D.new()
	root.name = "PlayerBolt"
	var rank := clampi(tier,1,5)
	var weight := 1.0 + float(rank-1)*0.075
	var core: MeshInstance3D
	match mode:
		"scatter":
			core = _part(root,"sphere",Vector3.ZERO,Vector3(0.08,0.08,0.19)*weight,"white")
			_part(root,"sphere",Vector3(0,0,-0.18),Vector3(0.085,0.085,0.30)*weight,"scatter")
		"plasma":
			core = _part(root,"sphere",Vector3.ZERO,Vector3(0.12,0.12,0.34)*weight,"white")
			_part(root,"sphere",Vector3(0,0,-0.13),Vector3(0.21,0.21,0.46)*weight,"plasma").transparency = 0.55
			_part(root,"sphere",Vector3(0,0,-0.65),Vector3(0.09,0.09,0.63)*weight,"plasma")
			var collar := _part(root,"ring",Vector3(0,0,-0.12),Vector3.ONE*0.28*weight,"plasma")
			collar.rotation.x = PI*0.5
		"arc":
			core = _part(root,"sphere",Vector3.ZERO,Vector3.ONE*0.105*weight,"white")
			_part(root,"sphere",Vector3(0,0,-0.24),Vector3(0.10,0.10,0.32)*weight,"arc")
			for side: float in [-1.0,1.0]:
				_part(root,"sphere",Vector3(side*0.13,0,-0.10),Vector3(0.035,0.035,0.17)*weight,"arc")
		_:
			core = _part(root,"sphere",Vector3.ZERO,Vector3(0.065,0.065,0.25)*weight,"white")
			_part(root,"sphere",Vector3(0,0,-0.32),Vector3(0.080,0.08,0.41)*weight,"kinetic").transparency = 0.23
			_part(root,"sphere",Vector3(0,0,-0.62),Vector3(0.038,0.038,0.28)*weight,"kinetic").transparency = 0.46
	core.name = "Core"
	root.set_meta("mode",mode)
	root.set_meta("tier",rank)
	return root


func _release(index: int) -> void:
	var node: MeshInstance3D = active[index].node
	node.visible = false
	node.material_overlay = null
	pool.append(node)
	active.remove_at(index)


func _emit(shape: String, material: Material, at: Vector3, size: Vector3, life: float, style: String, essential: bool = false) -> Dictionary:
	var limit := LOW_EFFECTS_LIMIT if low_effects else MAX_EFFECTS
	if active.size() >= limit-(0 if essential else DECORATIVE_RESERVE):
		if not essential: return {}
		var victim := -1
		for index: int in range(active.size()):
			if not active[index].essential:
				victim=index
				break
		if victim < 0: victim=0
		_release(victim)
		recycled += 1
	var node: MeshInstance3D
	if pool.is_empty():
		node = MeshInstance3D.new()
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
	else:
		node = pool.pop_back()
	node.visible = true
	node.mesh = _mesh(shape)
	node.material_override = material
	node.material_overlay = null
	node.transparency = 0.0
	node.transform = Transform3D.IDENTITY
	node.global_position = at
	node.scale = size
	var entry: Dictionary = {"node":node,"life":life,"total":life,"style":style,"base":size,"velocity":Vector3.ZERO,"spin":Vector3.ZERO,"essential":essential,"floor":0.045}
	active.append(entry)
	emitted += 1
	return entry


func muzzle(at: Vector3, direction: Vector3, mode: String) -> void:
	var strength := 1.30 if mode in ["plasma","scatter"] else 1.0
	var flash := _emit("sphere",_material("white"),at,Vector3(0.12,0.12,0.27)*strength,0.07,"flash",true)
	if not flash.is_empty():
		flash.node.quaternion = Quaternion(Vector3.BACK,direction.normalized() if direction.length_squared()>0.001 else Vector3.BACK)
	if not low_effects:
		var flare := _emit("sphere",_material(mode),at,Vector3.ONE*0.22*strength,0.11,"flash")
		if not flare.is_empty(): flare.node.transparency=0.38


func impact(at: Vector3, direction: Vector3, mode: String, strength: float = 1.0) -> void:
	var weight := clampf(strength,0.55,2.2)
	var forward := direction.normalized() if direction.length_squared()>0.001 else Vector3.BACK
	_emit("sphere",_material("white"),at,Vector3.ONE*0.16*weight,0.085,"flash",true)
	var flare := _emit("ring",_material(mode),at,Vector3.ONE*0.18*weight,0.17,"impact_ring",true)
	if not flare.is_empty(): flare.node.quaternion=Quaternion(Vector3.UP,forward)
	_sparks(at,-forward,mode,3 if low_effects else 7,weight)
	if not low_effects:
		var haze := _emit("sphere",_material("smoke"),at,Vector3.ONE*0.17,0.35,"smoke")
		if not haze.is_empty(): haze.velocity=Vector3.UP*0.55


func _sparks(at: Vector3, direction: Vector3, mode: String, count: int, strength: float) -> void:
	for index: int in range(count):
		var entry := _emit("sphere",_material("white" if index%3==0 else mode),at,Vector3(0.023,0.023,0.15)*strength,rng.randf_range(0.18,0.42),"spark")
		if entry.is_empty(): break
		var velocity: Vector3 = direction*rng.randf_range(1.1,2.3)+Vector3(rng.randf_range(-1.9,1.9),rng.randf_range(0.5,2.8),rng.randf_range(-1.9,1.9))
		entry.velocity = velocity*strength
		entry.node.quaternion=Quaternion(Vector3.BACK,velocity.normalized())


func arc_link(from: Vector3, to: Vector3, tier: int = 1) -> void:
	var direction := to-from
	if direction.length_squared()<0.002: return
	var breadth := clampf(direction.length()*0.12,0.65,1.3)
	var size := Vector3(breadth,breadth,direction.length())
	var core := _emit("arc_core",_material("white"),from,size,0.12,"arc",true)
	if not core.is_empty(): core.node.quaternion=Quaternion(Vector3.BACK,direction.normalized())
	var glow := _emit("arc_glow",_material("arc"),from,size,0.17,"arc",true)
	if not glow.is_empty():
		glow.node.quaternion=Quaternion(Vector3.BACK,direction.normalized())
		glow.node.transparency=0.45
	if tier>=3 and not low_effects:
		var braid := _emit("arc_core",_material("arc"),from,size,0.14,"arc")
		if not braid.is_empty():
			braid.node.quaternion=Quaternion(Vector3.BACK,direction.normalized())*Quaternion(Vector3.BACK,2.3)


func _pulse_layer(shape: String, color: String, at: Vector3, size: Vector3, duration: float, style: String, delay: float = 0.0, essential: bool = false) -> Dictionary:
	var entry := _emit(shape,_material(color),at,size,duration+delay,style,essential)
	if entry.is_empty(): return entry
	entry.delay=delay
	entry.duration=duration
	entry.origin=at
	entry.opacity=1.0
	entry.rotation=0.0
	return entry


func pulse(at: Vector3, power: float, radius: float, echo: bool = false) -> void:
	if power<=0.0 or radius<=0.0 or not is_finite(radius) or not is_finite(power) or not at.is_finite(): return
	var strength := clampf((power-30.0)/70.0,0.0,1.0)
	var weight := lerpf(0.60,1.0,strength)*(0.48 if echo else 1.0)
	var speed := 0.72 if echo else 1.0
	var lifetime := lerpf(0.62,PULSE_MAX_LIFE,strength)*speed
	var ground_y := 0.075
	var ground_offset := ground_y-at.y
	var ground_clearance := absf(ground_offset)+minf(0.01,radius*0.1)
	var touches_ground := ground_clearance<radius
	# An airborne pulse intersects the floor in a smaller circle. If it cannot
	# reach the floor, show its boundary in the origin plane instead.
	var ground_radius := sqrt(maxf(0.0,radius*radius-ground_clearance*ground_clearance)) if touches_ground else radius
	var ground := Vector3(at.x,ground_y if touches_ground else at.y,at.z)
	# Keep filaments above the flush deck inlays rather than coincident with
	# the feet plane. Their radial extents leave room within the damage sphere.
	var energy_origin := at+Vector3.UP*minf(0.16,radius*0.02)
	var first_emitted := emitted
	var core_size := minf(radius*0.17,lerpf(0.40,0.69,strength))*(0.68 if echo else 1.0)
	var core := _pulse_layer("sphere","pulse_hot" if strength>=0.78 and not echo else "white",energy_origin,Vector3.ONE*core_size,0.17*speed,"pulse_core",0.0,true)
	core.opacity=0.90 if not echo else 0.52
	var front := _pulse_layer("pulse_front","pulse_cyan",ground,Vector3(ground_radius,minf(0.16,radius),ground_radius),0.37*speed,"pulse_front",0.0,true)
	front.opacity=lerpf(0.62,0.94,strength)*(0.54 if echo else 1.0)
	front.arrival=PULSE_FRONT_TIME*speed
	var boundary := _pulse_layer("pulse_arcs","pulse_violet",ground,Vector3(ground_radius,0.08,ground_radius),0.30*speed,"pulse_boundary",0.0,true)
	boundary.opacity=0.10 if echo else lerpf(0.18,0.28,strength)
	var gather := _pulse_layer("pulse_sparse" if low_effects or echo else "pulse_gather","pulse_cyan",energy_origin,Vector3.ONE*radius*0.60,PULSE_GATHER_TIME*speed,"pulse_gather")
	if not gather.is_empty(): gather.opacity=0.90*weight
	var shards := _pulse_layer("pulse_shards","pulse_cyan",energy_origin,Vector3(radius*0.94,radius*0.5,radius*0.94),0.34*speed,"pulse_shards",0.035*speed)
	if not shards.is_empty():
		shards.opacity=0.88*weight
		shards.rotation=rng.randf_range(-0.18,0.18)
	var aftermath := _pulse_layer("pulse_arcs","pulse_violet",ground,Vector3(ground_radius*0.87,0.08,ground_radius*0.87),lifetime-0.16*speed,"pulse_after",0.16*speed)
	if not aftermath.is_empty(): aftermath.opacity=0.26*weight
	if not low_effects and not echo:
		var halo := _pulse_layer("ring","pulse_cyan",energy_origin,Vector3(radius*0.26,minf(0.28,radius),radius*0.26),0.23,"pulse_halo",0.015)
		if not halo.is_empty(): halo.opacity=0.52*weight
		var arcs := _pulse_layer("pulse_arcs","pulse_violet",energy_origin,Vector3(radius*0.91,0.08,radius*0.91),0.39,"pulse_arcs",0.055)
		if not arcs.is_empty():
			arcs.opacity=0.62*weight
			arcs.rotation=0.16
		if strength>=0.78:
			var peak := _pulse_layer("pulse_shards","pulse_hot",energy_origin,Vector3(radius*0.64,radius*0.25,radius*0.64),0.19,"pulse_shards",0.025)
			if not peak.is_empty():
				peak.opacity=0.68
				peak.rotation=PI/12.0
	# Initialize delayed layers immediately, avoiding a single-frame full-size
	# flash at emission. Pulse owns no timers outside the existing bounded pool.
	for entry: Dictionary in active:
		if int(entry.get("pulse_serial",-1))>=0 or not entry.style.begins_with("pulse_"): continue
		entry.pulse_serial=first_emitted
		entry.radius=radius
		entry.power=power
		entry.echo=echo
		_update_pulse(entry,0.0)


func _update_pulse(entry: Dictionary, age: float) -> void:
	var node: MeshInstance3D = entry.node
	var local_time := age-float(entry.delay)
	node.visible=local_time>=0.0
	if not node.visible: return
	var progress := clampf(local_time/float(entry.duration),0.0,1.0)
	var opacity: float = entry.opacity
	node.global_position=entry.origin
	node.rotation=Vector3(0,float(entry.rotation),0)
	match entry.style:
		"pulse_core":
			var peak := clampf(local_time/0.045,0.0,1.0)
			node.scale=entry.base*lerpf(0.38,1.0,peak)*(1.0-progress*0.42)
			opacity*=1.0-progress*progress
		"pulse_gather":
			node.scale=entry.base*lerpf(1.0,0.06,progress*progress)
			node.rotation.y+=progress*0.14
			opacity*=1.0-progress*0.65
		"pulse_front":
			var travel := clampf(local_time/float(entry.arrival),0.0,1.0)
			var size := lerpf(0.07,1.0,1.0-pow(1.0-travel,2.0))
			node.scale=Vector3(entry.base.x*size,entry.base.y,entry.base.z*size)
			opacity*=1.0-pow(progress,1.7)
		"pulse_boundary":
			node.scale=entry.base
			opacity*=1.0-progress
		"pulse_shards":
			var travel := 1.0-pow(1.0-progress,3.0)
			node.scale=entry.base*lerpf(0.17,1.0,travel)
			opacity*=pow(1.0-progress,1.3)
		"pulse_halo":
			node.scale=entry.base*lerpf(0.18,1.0,1.0-pow(1.0-progress,3.0))
			opacity*=1.0-progress
		"pulse_arcs":
			node.scale=entry.base*lerpf(0.35,1.0,1.0-pow(1.0-progress,2.0))
			node.rotation.y+=progress*0.28
			opacity*=1.0-progress
		"pulse_after":
			node.scale=entry.base*lerpf(0.90,1.0,progress)
			node.rotation.y-=progress*0.07
			opacity*=pow(1.0-progress,2.0)
	node.transparency=1.0-clampf(opacity,0.0,1.0)


func _collect_parts(node: Node, results: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D and child.visible:
			results.append(child)
		_collect_parts(child,results)


func destroy_enemy(model: Node3D, at: Vector3, kind: String, direction: Vector3) -> void:
	var color := "arc" if kind in ["bruiser","charger"] else "ember"
	var size := 1.9 if kind=="boss" else 1.0
	var center := at+Vector3.UP*(1.2 if kind=="boss" else 0.65)
	_emit("sphere",_material("white"),center,Vector3.ONE*0.48*size,0.12,"flash",true)
	_emit("sphere",_material(color),center,Vector3.ONE*0.65*size,0.24,"burst",true)
	_emit("ring",_material(color),at+Vector3.UP*0.07,Vector3.ONE*0.25,0.38,"shock",true)
	_sparks(center,Vector3.UP,color,6 if low_effects else 18,size)
	var candidates: Array[MeshInstance3D] = []
	_collect_parts(model,candidates)
	candidates.sort_custom(func(a: MeshInstance3D,b: MeshInstance3D) -> bool:
		return a.mesh.get_aabb().size.length_squared()*a.global_basis.get_scale().length_squared()>b.mesh.get_aabb().size.length_squared()*b.global_basis.get_scale().length_squared())
	var part_limit := (5 if low_effects else 10) if kind!="boss" else (8 if low_effects else 16)
	for index: int in range(mini(part_limit,candidates.size())):
		var original: MeshInstance3D = candidates[index]
		var part := _emit("armor",original.material_override,original.global_position,original.global_basis.get_scale(),rng.randf_range(0.90,1.45),"debris",index<3)
		if part.is_empty(): break
		part.node.mesh=original.mesh
		part.node.global_transform=original.global_transform
		part.base=part.node.scale
		var radial := (original.global_position-center).normalized()
		part.velocity=(radial*rng.randf_range(1.5,3.5)+direction*1.8+Vector3.UP*rng.randf_range(2.2,4.5))*size
		part.spin=Vector3(rng.randf_range(-6,6),rng.randf_range(-5,5),rng.randf_range(-6,6))
	for index: int in range(2 if low_effects else 5):
		var smoke := _emit("sphere",_material("smoke"),center+Vector3(rng.randf_range(-0.35,0.35),0,rng.randf_range(-0.35,0.35)),Vector3.ONE*0.24*size,rng.randf_range(0.55,0.85),"smoke")
		if not smoke.is_empty(): smoke.velocity=Vector3(rng.randf_range(-0.3,0.3),rng.randf_range(0.5,1.2),rng.randf_range(-0.3,0.3))


func update(delta: float) -> void:
	if delta<=0.0: return
	elapsed += delta
	for index: int in range(active.size()-1,-1,-1):
		var entry: Dictionary = active[index]
		entry.life -= delta
		if entry.life<=0:
			_release(index)
			continue
		var node: MeshInstance3D = entry.node
		var progress: float = 1.0-entry.life/entry.total
		if entry.style.begins_with("pulse_"):
			_update_pulse(entry,entry.total-entry.life)
			continue
		match entry.style:
			"flash":
				node.scale=entry.base*(1.0+progress*0.7)
				node.transparency=progress*progress
			"impact_ring":
				node.scale=entry.base*(1.0+progress*2.6)
				node.transparency=progress
			"shock":
				node.scale=Vector3.ONE*lerpf(0.25,2.2,1.0-pow(1.0-progress,2.0))
				node.transparency=progress
			"burst":
				node.scale=entry.base*(1.0+progress*0.85)
				node.transparency=0.20+progress*0.80
			"spark":
				entry.velocity.y-=delta*6.0
				node.position+=entry.velocity*delta
				node.scale=entry.base*(1.0-progress*0.70)
				node.transparency=progress
			"smoke":
				node.position+=entry.velocity*delta
				node.scale=entry.base*(1.0+progress*2.4)
				node.transparency=progress
			"arc":
				node.transparency=clampf(progress*0.9,0.0,1.0)
			"debris":
				entry.velocity.y-=delta*11.0
				node.position+=entry.velocity*delta
				node.rotation+=entry.spin*delta
				if node.global_position.y<entry.floor:
					node.global_position.y=entry.floor
					entry.velocity.y=absf(entry.velocity.y)*0.27
					entry.velocity.x*=0.72
					entry.velocity.z*=0.72
					entry.spin*=0.63
				var dissolve := clampf((progress-0.52)/0.48,0.0,1.0)
				node.scale=entry.base*maxf(0.01,1.0-dissolve*dissolve)
				node.transparency=dissolve


func clear() -> void:
	for index: int in range(active.size()-1,-1,-1): _release(index)
	elapsed = 0.0


func counts() -> Dictionary:
	return {"active":active.size(),"pooled":pool.size(),"allocated":active.size()+pool.size(),"cap":MAX_EFFECTS,"active_limit":LOW_EFFECTS_LIMIT if low_effects else MAX_EFFECTS,"emitted":emitted,"recycled":recycled}
