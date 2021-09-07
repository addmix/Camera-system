extends Camera

#gonna need to make hybrid with normal controls
#also makes it shit easy to implement leaning

export var camera_sensitivity := Vector2(.1, .1)

var z_speed : float = 5.0
#changing target will do leaning
onready var z_spring := Spring.new(0, 0, 0.0, 0.95, z_speed)
onready var lerp_spring := Spring.new(0, 0, 0, 0.99, 3)

#lerp values for determination between flight_sim and traditional
var lerp_value := Vector2(deg2rad(60), deg2rad(70))

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		var movement : Vector2 = camera_sensitivity * event.relative
		
		#flight sim rotation
		#save a copy of the original rotation
		var flight_sim : Basis = transform.basis
		flight_sim = flight_sim.rotated(flight_sim.x.normalized(), -deg2rad(movement.y))
		flight_sim = flight_sim.rotated(flight_sim.y.normalized(), -deg2rad(movement.x))
		
		#fps rotation
		#save a copy of the original rotation
		var traditional : Basis = transform.basis
		traditional = traditional.rotated(Vector3(0, 1, 0), -deg2rad(movement.x))
		traditional = traditional.rotated(traditional.x, -deg2rad(movement.y))
		
		#then lerp between flight_sim and traditional based on transform.basis.get_euler().x
		# Convert the left range into a 0-1 range (float)
		#using abs() gives us the correct range for looking down, but the range is the wrong direction
		var value : float = clamp(map_range(abs(transform.basis.get_euler().x), lerp_value.x, lerp_value.y, 0, 1), 0, 1)
		if value > lerp_spring.position:
			lerp_spring.position = value
		
		lerp_spring.target = value
		transform.basis = traditional.slerp(flight_sim, lerp_spring.position).orthonormalized()

func _process(delta : float) -> void:
	lerp_spring.positionvelocity(delta)
	
	var clamped : float = clamp(map_range(lerp_spring.position, 0, 1, z_speed, 0.0), 0.0, z_speed)
	clamped = clamped * float(!clamped < 0.1)
	
	z_spring.speed = clamped
	
	z_spring.position = rotation_degrees.z
	z_spring.positionvelocity(delta)
	rotation_degrees = Vector3(rotation_degrees.x, rotation_degrees.y, z_spring.position)
	

func map_range(value : float, InputA : float = 0, InputB : float = 1, OutputA : float = 0, OutputB : float = 1) -> float:
	return (value - InputA) / (InputB - InputA) * (OutputB - OutputA) + OutputA
