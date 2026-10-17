extends SubViewportContainer

## 上部に置く小さな3Dの街。体の耐久が減るとネオンがちらつき、死ぬと消える。

const PINK := Color(1.0, 0.2, 0.7)
const CYAN := Color(0.2, 0.95, 1.0)
const GRID := 6  # 街の広さ（-GRID〜GRID の区画）
const BLOCK := 3.0

var _pivot: Node3D
var _neon: Array[StandardMaterial3D] = []
var _time := 0.0


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	add_child(viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.07)
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.05, 0.2)
	env.fog_density = 0.025
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)

	_pivot = Node3D.new()
	viewport.add_child(_pivot)
	var camera := Camera3D.new()
	_pivot.add_child(camera)
	camera.look_at_from_position(Vector3(0, 10, 24), Vector3(0, 2, 0))

	_build_city(viewport)
	_build_rain(viewport)


func _build_city(parent: Node) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2077
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	ground.material_override = _flat(Color(0.05, 0.04, 0.09))
	parent.add_child(ground)

	for x in range(-GRID, GRID + 1):
		for z in range(-GRID, GRID + 1):
			if x % 3 == 0 or z % 4 == 0:
				continue  # 通り
			var dist := Vector2(x, z).length()
			var height := rng.randf_range(2.0, 6.0) + maxf(0.0, 10.0 - dist * 1.4) * rng.randf_range(0.6, 1.4)
			var building := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(2.4, height, 2.4)
			building.mesh = box
			building.position = Vector3(x * BLOCK, height / 2.0, z * BLOCK)
			var shade := rng.randf_range(0.08, 0.16)
			building.material_override = _flat(Color(shade * 0.8, shade * 0.6, shade * 1.3))
			parent.add_child(building)
			if rng.randf() < 0.45:
				_add_neon_strip(parent, building.position, height, rng)


func _add_neon_strip(parent: Node, base: Vector3, height: float, rng: RandomNumberGenerator) -> void:
	var strip := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.5, 0.18, 2.5)
	strip.mesh = box
	strip.position = Vector3(base.x, rng.randf_range(1.0, height - 0.3), base.z)
	var material := _flat(PINK if rng.randf() < 0.5 else CYAN)
	material.set_meta("base", material.albedo_color)
	_neon.append(material)
	strip.material_override = material
	parent.add_child(strip)


func _build_rain(parent: Node) -> void:
	var rain := CPUParticles3D.new()
	var drop := BoxMesh.new()
	drop.size = Vector3(0.03, 0.7, 0.03)
	rain.mesh = drop
	rain.material_override = _flat(Color(0.5, 0.6, 0.9, 0.5), true)
	rain.amount = 500
	rain.lifetime = 1.0
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(22, 0.5, 22)
	rain.position = Vector3(0, 18, 0)
	rain.direction = Vector3.DOWN
	rain.spread = 2.0
	rain.initial_velocity_min = 22.0
	rain.initial_velocity_max = 26.0
	rain.gravity = Vector3.ZERO
	parent.add_child(rain)


func _flat(color: Color, transparent := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func _process(delta: float) -> void:
	_time += delta
	_pivot.rotation.y = _time * 0.04
	var brightness := 1.0
	if not Game.alive:
		brightness = 0.12
	elif Game.durability < Game.LOW_DURABILITY:
		var flicker := sin(_time * 23.0) + sin(_time * 7.3)
		brightness = 1.0 if flicker > -0.4 else 0.25
	for material in _neon:
		var base: Color = material.get_meta("base")
		material.albedo_color = Color(base.r * brightness, base.g * brightness, base.b * brightness)
