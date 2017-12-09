extends Spatial

const GROUND_X_SIZE = 128
const GROUND_Z_SIZE = 128
const VIEW_RANGE2 = 60.0
const VIEW_RANGE = VIEW_RANGE2 / 2
const SPEED = 5
const ROTSPEED = 50
const GROUND_BLOCK_HEIGHT = 0.01
const DEF_ENGINE_ROT_X = 35.0
const DEF_ENGINE_POS_Y = 9.5
const VERTEX_OFFSET = -VIEW_RANGE

var mat = preload("res://Planet.material")

var sphere_ratio = 0.01

onready var camera = get_parent().get_node("Camera")
var beginZoom = false
var zoom = false
var camera_pos = Vector3(0, 3.5, -3)
var camera_target = Vector3(0, 0, 4)

var enginePosX = 128/2
var enginePosY = 0.0
var enginePosZ = 128/2

var engineRotX = DEF_ENGINE_ROT_X
var engineRotY = 0.0
var engineRotZ = 0.0
var hdecr_factor = 0.0

var st = null
var map_image
var map_texture

class Height:
	var h1
	var h2
	var h3
	var h4

class PlanetVertex:
	var height = 0.0
	var volume
	
var vertexes = []
var quad = [Vector3(),Vector3(),Vector3(),Vector3()]

func combine_2byte(a, b):
	return (b << 8) | (a & 0xff)
	
func get_index(x, y):
	x = wrapi(x, 0, GROUND_X_SIZE)
	y = wrapi(y, 0, GROUND_Z_SIZE)
	return x + y * GROUND_X_SIZE
	
func _ready():	

	map_image = Image.new()
	map_image.create(128, 128, 0, Image.FORMAT_RGB8)
	var texture = ImageTexture.new()

	var file = File.new()
	file.open("faceoff.dat", File.READ)
	var buffer = file.get_buffer(16384 * 2)
	var data = []
	var i = 0
	var j = 0
	while j < 16384:
		data.push_back(combine_2byte(buffer[i], buffer[i+1]))
		i+=2
		j+=1		
	map_image.lock()
	for x in range(GROUND_X_SIZE):
		for z in range(GROUND_Z_SIZE):
			var v = PlanetVertex.new()
			v.height = float(data[x + z * 128]) * 0.3
			v.volume = CollisionShape.new()
			var box = BoxShape.new()
			box.extents = Vector3(x + 0.5,0.5,z + 0.5)
			v.volume.set_shape(box)
			vertexes.append(v)
			var c = clamp(data[x + z * 128] / 700.0, 0.0, 1.0)
			map_image.set_pixel(wrapi(x, 0, 128), wrapi(z, 0, 128), Color(c,c,c))
	map_image.unlock()
	file.close()
	
	map_texture = ImageTexture.new()
	map_texture.create_from_image(map_image, Texture.FLAG_REPEAT)
	#$Sprite.texture = texture
	st = SurfaceTool.new()
	mat.set_shader_param("map_texture", map_texture)

	create_mesh()
#	var data = map_texture.get_data()
#	data.lock()
#	for x in range(GROUND_X_SIZE):
#		for z in range(GROUND_Z_SIZE):
#			var v = PlanetVertex.new()
#			v.height = data.get_pixel(x,z).r * 255
#			vertexes.append(v)
#	data.unlock()

func rotate_forward(step):
	var f = 360.0 - engineRotY
	while f >= 360.0:
		f -= 360.0
	while f < 0.0: 
		f += 360.0
	enginePosX -= sin(deg2rad(f)) * step
	enginePosZ -= cos(deg2rad(f)) * step

func rotate_backward(step):
	var f = 360.0 - engineRotY
	while f >= 360.0:
		f -= 360.0
	while f < 0.0: 
		f += 360.0
	enginePosX += sin(deg2rad(f)) * step
	enginePosZ += cos(deg2rad(f)) * step
	
func rotate_left(step):
	var f = 360.0 - engineRotY + 90.0
	while f >= 360.0:
		f -= 360.0
	while f < 0.0: 
		f += 360.0
	enginePosX -= sin(deg2rad(f)) * step
	enginePosZ -= cos(deg2rad(f)) * step

func rotate_right(step):
	var f = 360.0 - engineRotY + 90.0
	while f >= 360.0:
		f -= 360.0
	while f < 0.0: 
		f += 360.0
	enginePosX += sin(deg2rad(f)) * step
	enginePosZ += cos(deg2rad(f)) * step
	
func rotate_view_left(step):
	engineRotY -= step

func rotate_view_right(step):
	engineRotY += step



func process_input(delta):
	
	var speed = SPEED
	var rspeed = ROTSPEED
	var strafe = false
	if Input.is_action_pressed("planet_accelkey"):
		speed *= 2
		rspeed *= 2
	if Input.is_action_pressed("planet_altkey"):
		strafe = true
	
	if Input.is_action_pressed("planet_rotate_forward"):
		rotate_forward(speed * delta)
	elif Input.is_action_pressed("planet_rotate_backward"):
		rotate_backward(speed * delta)
	if Input.is_action_pressed("planet_rotate_left"):
		if strafe:
			rotate_left(speed * delta)
		else:
			rotate_view_left(rspeed * delta)
	elif Input.is_action_pressed("planet_rotate_right"):
		if strafe:
			rotate_right(speed * delta)
		else:
			rotate_view_right(rspeed * delta)
			
	if Input.is_action_just_pressed("planet_view"):
		if !beginZoom:
			beginZoom = true
			zoom = !zoom
		
	update_zoom(delta)
 
	
func update_zoom(delta):
	
	var s = 60.0
	
	if beginZoom:
		if zoom:
			if enginePosY >= 60:
				enginePosY = 60
				beginZoom = false
				
				
			enginePosY += 1 * s * delta
			hdecr_factor += 0.1 * s * delta
			
			sphere_ratio += 0.001 * s * delta
			camera_target.y -= 0.5 * s * delta
			camera_pos.y += 0.11 * s * delta
		 
			camera_pos.z += 0.02 * s * delta
		else:
			
			if enginePosY <= 0:
				enginePosY = 0
				beginZoom = false
			
			enginePosY -= 1 * s * delta
			hdecr_factor -= 0.1* s * delta;
			
			sphere_ratio -= 0.001 * s * delta
			camera_target.y += 0.5 * s * delta
			camera_pos.y -= 0.11 * s * delta
			 
			camera_pos.z -= 0.02 * s * delta
			
		mat.set_shader_param("sphere_ratio", sphere_ratio)
		mat.set_shader_param("hdecr_factor", hdecr_factor)
			
			#if enginePosY > 9.5

func _process(delta):
	process_input(delta)
	

	enginePosX = wrapf(enginePosX, 0, 128)
	enginePosZ = wrapf(enginePosZ, 0, 128)
	engineRotX = wrapf(engineRotX, 0.0, 360.0)
	engineRotY = wrapf(engineRotY, 0.0, 360.0)
	engineRotZ = wrapf(engineRotZ, 0.0, 360.0)
	
	get_parent().get_node("UI/pos_label").text = str(int(enginePosX)) + "," + str(int(enginePosZ))
	 
	#var h = Vector3(0.0, vertexes[get_index(int(enginePosX - 15), int(enginePosZ - 15))].height * 0.01, 0.0)
	
	if Input.is_action_just_pressed("change_grid"):
		mat.set_shader_param("enable_grid", !mat.get_shader_param("enable_grid"))
	
	camera.look_at_from_position(camera_pos, camera_target, Vector3(0,1,0))
	
	update_transforms()
	
	mat.set_shader_param("tpos", Vector2(wrapf(enginePosX, 0.0, 1.0), wrapf(enginePosZ, 0.0, 1.0)))
	mat.set_shader_param("rpos", Vector2(enginePosX, enginePosZ))

	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()

	if Input.is_key_pressed(KEY_X):
		var x = wrapi(128-enginePosX, 0, 128)
		var y = wrapi(128-enginePosZ, 0, 128)
		map_image.lock()
		map_image.set_pixel(x, y, map_image.get_pixel(x, y) + Color(0.005,0.005,0.005))
		map_image.unlock()
		map_texture.set_data(map_image)

func update_transforms():
	rotation = (Vector3(0,deg2rad(engineRotY),0))

func compute_normal(x, z):
	var hL = vertexes[get_index(x-1,z)].height
	var hR = vertexes[get_index(x+1,z)].height
	var hD = vertexes[get_index(x,z-1)].height
	var hU = vertexes[get_index(x,z+1)].height
	
	var N = Vector3()
	N.x = hL - hR
	N.y = hD - hU
	N.z = 2.0
	N = N.normalized()
	
	return N

var defColor = Color(0.8,0.8,0.8)

func create_mesh():
	st.clear()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	st.set_material(mat)
	var z = wrapf(enginePosZ, 0, VIEW_RANGE2)
	for az in range(VIEW_RANGE2):
		var x =  wrapf(enginePosX, 0, VIEW_RANGE2)
		for ax in range(VIEW_RANGE2):

			var _x =  int(x) - int(enginePosX) 
			var _z =  int(z) - int(enginePosZ)

			quad[0] = Vector3(x + VERTEX_OFFSET, 0.0, z + VERTEX_OFFSET)
			quad[1] = Vector3(x+1 + VERTEX_OFFSET, 0.0, z + VERTEX_OFFSET)
			quad[2] = Vector3(x + VERTEX_OFFSET, 0.0, z+1 + VERTEX_OFFSET)
			quad[3] = Vector3(x+1 + VERTEX_OFFSET, 0.0, z+1 + VERTEX_OFFSET)

 
			st.add_uv(Vector2(0,0))
			st.add_normal(Vector3(0,1,0))
			st.add_vertex(quad[0])
 
			st.add_uv(Vector2(1,0))
			st.add_normal(Vector3(0,1,0))
			st.add_vertex(quad[1])
 
			st.add_uv(Vector2(0,1))
			st.add_normal(Vector3(0,1,0))
			st.add_vertex(quad[2])
 
			st.add_uv(Vector2(1,1))
			st.add_normal(Vector3(0,1,0))
			st.add_vertex(quad[3])

			x = wrapf(x + 1, 0, VIEW_RANGE2)
		z = wrapf(z + 1, 0, VIEW_RANGE2)
	$MeshInstance.mesh = st.commit()
	