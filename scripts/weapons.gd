extends Node3D
## Four distinct auto-targeted weapons. Projectiles travel through shared cover.
const Art = preload("res://scripts/art.gd")
const Traversal = preload("res://scripts/traversal.gd")
const PROFILES := {
	"kinetic":{"name":"VECTOR CARBINE","short":"CARBINE","role":"RAPID FIRE","damage":14.0,"interval":0.28,"speed":29.0,"range":10.0,"color":Color("a5edff"),"description":"Fast focused slugs. Rank III adds penetration; rank V fires paired rounds."},
	"scatter":{"name":"SHATTER CANNON","short":"SHATTER","role":"CLOSE-RANGE SPREAD","damage":9.0,"interval":0.75,"speed":22.0,"range":8.5,"color":Color("ffca79"),"description":"Five heavy pellets in a wide cone. Rank III fires seven; rank V adds explosive pellet impacts."},
	"arc":{"name":"ARC RELAY","short":"ARC RELAY","role":"CHAIN DISCHARGE","damage":24.0,"interval":0.62,"speed":24.0,"range":10.0,"color":Color("c7a5ff"),"description":"An ion bolt chains to nearby machines. Ranks III and V add targets and longer jump reach."},
	"plasma":{"name":"NOVA LANCE","short":"NOVA LANCE","role":"PIERCING PLASMA","damage":55.0,"interval":0.95,"speed":19.0,"range":13.0,"color":Color("76ffd7"),"description":"A heavy plasma core pierces a line of machines. Rank III adds blast damage; rank V widens the blast."}
}
const MAX_PROJECTILES := 80
var game: Node3D
var mode := "kinetic"
var ranks: Dictionary = {"kinetic":1,"scatter":0,"arc":0,"plasma":0}
var overclocks := 0
var cooldown := 0.0
var projectiles: Array = []
var previous_enemies: Dictionary = {}
var shots_fired := 0
var hits := 0
var kills := 0

func reset() -> void:
	clear_projectiles()
	ranks={"kinetic":1,"scatter":0,"arc":0,"plasma":0}
	mode="kinetic"
	overclocks=0
	cooldown=0
	shots_fired=0
	hits=0
	kills=0
	refresh_model()

func tier() -> int: return int(ranks[mode])

func damage_scale() -> float: return (1.0+0.22*float(tier()-1))*(1.0+0.025*overclocks)

func draft(rng: RandomNumberGenerator) -> Array:
	var pool: Array=PROFILES.keys()
	pool.erase(mode)
	var result: Array=[mode]
	while result.size()<3:
		var index:=rng.randi_range(0,pool.size()-1)
		result.append(pool.pop_at(index))
	return result

func offer(id: String) -> Dictionary:
	var rank: int=int(ranks.get(id,0))
	var action: String="UNLOCK" if rank==0 else "RANK %s → %s" % [roman(rank),roman(rank+1)] if rank<5 else "OVERCLOCK +2.5%" if overclocks<10 else "SERVICE +30 HULL"
	var base: float=float(PROFILES[id].damage)
	var old_damage: float=base*(1.0+0.22*maxi(0,rank-1))*(1.0+0.025*overclocks)
	var new_damage: float=base*(1.0+0.22*mini(rank,4))*(1.0+0.025*overclocks)
	var benefit: String="%.1f DAMAGE / %.2fs BETWEEN SHOTS" % [new_damage,float(PROFILES[id].interval)] if rank==0 else "DAMAGE %.1f → %.1f PER HIT" % [old_damage,new_damage] if rank<5 else "ARMORY POWER +%.1f%% → +%.1f%%" % [overclocks*2.5,(overclocks+1)*2.5] if overclocks<10 else "REPAIR 30 HULL & EQUIP THIS WEAPON"
	if id=="scatter" and rank<5: benefit+=" / PELLET"
	return {"name":PROFILES[id].name,"family":PROFILES[id].role,"description":PROFILES[id].description,"action":action,"benefit":benefit,"color":PROFILES[id].color,"rank":rank}

static func roman(rank: int) -> String: return ["—","I","II","III","IV","V"][clampi(rank,0,5)]

func install(id: String) -> bool:
	if not PROFILES.has(id): return false
	if int(ranks[id])<5: ranks[id]=int(ranks[id])+1
	elif overclocks<10: overclocks+=1
	else: game.rules.health=minf(100,game.rules.health+30)
	mode=id
	cooldown=0
	refresh_model()
	return true

func cycle() -> bool:
	var owned: Array=[]
	for id in PROFILES:
		if int(ranks[id])>0: owned.append(id)
	if owned.size()<2: return false
	mode=owned[(owned.find(mode)+1)%owned.size()]
	# Preserve the current reload: switching cannot bypass a slow weapon's cadence.
	refresh_model()
	return true

func refresh_model() -> void:
	if is_instance_valid(game) and is_instance_valid(game.player_node): Art.set_weapon(game.player_node,mode,tier())

func record_enemy_positions() -> void:
	previous_enemies.clear()
	for enemy in game.enemies:
		if is_instance_valid(enemy): previous_enemies[enemy.get_instance_id()]=enemy.position

func fire(target: Node3D) -> bool:
	if cooldown>0 or not is_instance_valid(target) or target.dead or target.spawning>0: return false
	var profile: Dictionary=PROFILES[mode]
	var at: Vector3=Art.muzzle_position(game.player_node)
	var center: Vector3=target.position+Vector3(0,1.45 if target.kind=="boss" else 0.85,0)
	if game.player_position.distance_to(target.position)>float(profile.range): return false
	var direction: Vector3=(center-at).normalized()
	if game.campaign_active and game.campaign.resolve_gates(at,center).distance_to(center)>0.05: return false
	Art.aim_weapon(game.player_node,direction)
	at=Art.muzzle_position(game.player_node)
	direction=(center-at).normalized()
	var count:=7 if mode=="scatter" and tier()>=3 else 5 if mode=="scatter" else 2 if mode=="kinetic" and tier()>=5 else 1
	if projectiles.size()+count>MAX_PROJECTILES: return false
	cooldown=float(profile.interval)*(0.91 if tier()>=5 else 1.0)
	for index in range(count):
		var spread:=float(index)-float(count-1)*0.5
		var shot_direction:=direction.rotated(Vector3.UP,spread*(0.085 if mode=="scatter" else 0.022))
		var bolt: Node3D=game.weapon_fx.create_bolt(mode,tier())
		add_child(bolt)
		bolt.position=at
		bolt.quaternion=Quaternion(Vector3.BACK,shot_direction)
		var penetration:=4 if mode=="plasma" and tier()>=5 else 3 if mode=="plasma" else 2 if mode=="kinetic" and tier()>=3 else 1
		projectiles.append({"node":bolt,"velocity":shot_direction*float(profile.speed),"range":float(profile.range),"damage":float(profile.damage)*damage_scale(),"mode":mode,"tier":tier(),"pierce":penetration,"struck":[]})
	shots_fired+=1
	Art.recoil_weapon(game.player_node,1.0 if mode in ["plasma","scatter"] else 0.45)
	game.weapon_fx.muzzle(at,direction,mode)
	game.cue(mode+"_fire",0.82)
	return true

func update(delta: float) -> void:
	cooldown=maxf(0,cooldown-delta)
	for index in range(projectiles.size()-1,-1,-1):
		var shot: Dictionary=projectiles[index]
		var node: Node3D=shot.node
		var from: Vector3=node.position
		var travel: float=minf(float(shot.range),shot.velocity.length()*delta)
		var to: Vector3=from+shot.velocity.normalized()*travel
		var wall_fraction:=1.0
		var occluded:=false
		if game.campaign_active:
			var stopped: Vector3=game.campaign.resolve_gates(from,to)
			occluded=stopped.distance_to(to)>0.01
			if occluded and absf(to.z-from.z)>0.00001: wall_fraction=clampf((stopped.z-from.z)/(to.z-from.z),0,1)
			elif occluded: wall_fraction=0.0
		var end: Vector3=from.lerp(to,wall_fraction)
		var contacts: Array=[]
		for enemy in game.enemies:
			if not is_instance_valid(enemy) or enemy.dead or enemy.spawning>0 or enemy.get_instance_id() in shot.struck: continue
			var prior: Vector3=previous_enemies.get(enemy.get_instance_id(),enemy.position)
			var time_fraction: float=travel/maxf(0.000001,shot.velocity.length()*delta)
			var current: Vector3=prior.lerp(enemy.position,wall_fraction*time_fraction)
			if Traversal.swept_body_hit(prior,current,from,end,enemy.radius+0.13,-0.13,0.13,2.8 if enemy.kind=="boss" else 1.5):
				contacts.append({"enemy":enemy,"t":Traversal.crossing_fraction(prior,current,from,end)})
		contacts.sort_custom(func(a,b):return a.t<b.t)
		for contact in contacts:
			var enemy: Node3D=contact.enemy
			if enemy.dead: continue
			var impact_at: Vector3=from.lerp(end,contact.t)
			shot.struck.append(enemy.get_instance_id())
			enemy.take_hit(shot.damage,false,shot.velocity.normalized(),shot.mode)
			hits+=1
			if enemy.dead: kills+=1
			game.cue("armor_impact",0.48)
			if shot.mode=="arc": chain_hit(enemy,shot)
			if shot.mode=="plasma" and shot.tier>=3 or shot.mode=="scatter" and shot.tier>=5:
				blast(impact_at,shot,enemy)
			shot.pierce-=1
			if shot.pierce<=0: break
		shot.range=maxf(0,float(shot.range)-travel)
		node.position=end
		if shot.pierce<=0 or occluded or shot.range<=0 or absf(end.x)>19 or absf(end.z)>19:
			if occluded: game.weapon_fx.impact(end,-shot.velocity.normalized(),shot.mode,0.45)
			node.queue_free()
			projectiles.remove_at(index)

func chain_hit(first: Node3D, shot: Dictionary) -> void:
	var source: Node3D=first
	var chained: Array=[first.get_instance_id()]
	var jumps:=4 if shot.tier>=5 else 3 if shot.tier>=3 else 2
	for jump in range(jumps):
		var target: Node3D=null
		var distance:=5.0 if shot.tier>=5 else 3.8
		for enemy in game.enemies:
			if enemy.dead or enemy.spawning>0 or enemy.get_instance_id() in chained: continue
			var gap: float=enemy.position.distance_to(source.position)
			var origin: Vector3=source.position+Vector3(0,0.85,0)
			var at: Vector3=enemy.position+Vector3(0,0.85,0)
			if game.campaign_active and game.campaign.resolve_gates(origin,at).distance_to(at)>0.05: continue
			if gap<distance: distance=gap; target=enemy
		if not is_instance_valid(target): break
		chained.append(target.get_instance_id())
		game.weapon_fx.arc_link(source.position+Vector3(0,0.85,0),target.position+Vector3(0,0.85,0),shot.tier)
		target.take_hit(shot.damage*pow(0.78,jump+1),false,(target.position-source.position).normalized(),"arc")
		if target.dead: kills+=1
		source=target

func blast(at: Vector3, shot: Dictionary, primary: Node3D) -> void:
	var radius:=2.0 if shot.mode=="plasma" and shot.tier>=5 else 1.25
	game.weapon_fx.impact(at,Vector3.UP,shot.mode,1.3)
	for enemy in game.enemies:
		if enemy==primary or enemy.dead or enemy.spawning>0: continue
		var center: Vector3=enemy.position+Vector3(0,0.85,0)
		if game.campaign_active and game.campaign.resolve_gates(at,center).distance_to(center)>0.05: continue
		if enemy.position.distance_to(at)<radius+enemy.radius:
			enemy.take_hit(shot.damage*0.30,true,(enemy.position-at).normalized(),shot.mode)
			if enemy.dead: kills+=1

func clear_projectiles() -> void:
	for shot in projectiles:
		if is_instance_valid(shot.node): shot.node.queue_free()
	projectiles.clear()
	previous_enemies.clear()
	cooldown=0
