extends SceneTree
## Bounded FX lifecycle and model contract checks; no rendering/FPS claim.
const Art=preload("res://scripts/art.gd")
const FX=preload("res://scripts/combat_fx.gd")
var checks=0
var failures=0
func check(value:bool,message:String):
	checks+=1
	if not value:
		push_error(message)
		failures+=1
func _initialize(): call_deferred("run")
func run():
	var fx=FX.new()
	root.add_child(fx)
	var player=Art.player()
	root.add_child(player)
	for mode in ["kinetic","scatter","arc","plasma"]:
		for tier in [1,3,5]:
			Art.set_weapon(player,mode,tier)
			var bolt=fx.create_bolt(mode,tier)
			check(bolt.get_child_count()>1,"Bolt has core and sheath")
			bolt.free()
	Art.aim_weapon(player,Vector3.FORWARD)
	check(Art.muzzle_position(player).z<0,"Back aim rotates the weapon mount behind torso")
	var enemy=Art.enemy("bruiser")
	root.add_child(enemy)
	fx.destroy_enemy(enemy,Vector3.ZERO,"bruiser",Vector3.BACK)
	enemy.free()
	check(fx.counts().active>5,"Death visuals survive source enemy removal")
	for i in range(200):
		fx.impact(Vector3.ZERO,Vector3.BACK,"plasma",1.0)
		fx.arc_link(Vector3.ZERO,Vector3(4,1,5),5)
	check(fx.counts().active<=160,"Normal FX hard cap")
	check(fx.counts().allocated<=160,"Pool allocation hard cap")
	var recent_essential: MeshInstance3D
	for index in range(fx.active.size()-1,-1,-1):
		if fx.active[index].essential:
			recent_essential=fx.active[index].node
			break
	fx.low_effects=true
	check(fx.counts().active<=72,"Low effects trims active population")
	check(is_instance_valid(recent_essential) and recent_essential.visible,"Low effects retains the latest essential cue")
	for i in range(100): fx.impact(Vector3.ZERO,Vector3.BACK,"kinetic",1.0)
	check(fx.counts().active<=72,"Low effects emissions stay capped")
	var active=fx.counts().active
	fx.update(0.0)
	check(fx.counts().active==active,"Zero delta preserves FX lifetimes")
	for i in range(150): fx.update(1.0/60.0)
	check(fx.counts().active==0,"All transient FX expire")
	fx.impact(Vector3.ZERO,Vector3.BACK,"arc")
	fx.clear()
	check(fx.counts().active==0,"Clear restores empty active set")
	player.free()
	fx.free()
	print("Combat FX: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
