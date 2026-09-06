class_name FortCampfire
extends Node3D

var fire_light: OmniLight3D
var elapsed := 0.0

func _ready() -> void:
	name = "Campfire"
	var logs := FortArt.asset("campfire_logs")
	if logs: add_child(logs)
	var flames := FortParticles.emitter("Flames", 34, 0.95, FortParticles.quad(Vector2(0.7,1.2), true))
	flames.position.y = 0.85
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius = 0.4
	flames.spread = 12
	flames.initial_velocity_min = 0.65
	flames.initial_velocity_max = 1.3
	flames.gravity = Vector3(0,0.3,0)
	flames.color_ramp = FortParticles.ramp([Color("#ffdb70"),Color("#ffab35"),Color("#ef5924"),Color(0.7,0.16,0.035,0)])
	flames.scale_amount_min = 0.65
	flames.scale_amount_max = 1.15
	flames.scale_amount_curve = FortParticles.curve([0.7,1.0,0.1])
	var embers := FortParticles.emitter("Embers", 22, 2.3, FortParticles.quad(Vector2(0.055,0.055)))
	embers.position.y = 0.95
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = 0.5
	embers.spread = 25
	embers.initial_velocity_min = 0.8
	embers.initial_velocity_max = 1.7
	embers.gravity = Vector3(0.14,0.15,0.03)
	embers.tangential_accel_min = 0.15
	embers.tangential_accel_max = 0.35
	embers.color_ramp = FortParticles.ramp([Color("#ffe399"),Color("#f99542"),Color(0.8,0.18,0.03,0)])
	var smoke := FortParticles.emitter("Smoke", 14, 3.5, FortParticles.quad(Vector2(1.1,1.1)))
	smoke.position.y = 1.55
	smoke.spread = 15
	smoke.initial_velocity_min = 0.45
	smoke.initial_velocity_max = 0.7
	smoke.gravity = Vector3(0.08,0.05,0.03)
	smoke.scale_amount_curve = FortParticles.curve([0.25,0.9,1.6])
	smoke.color_ramp = FortParticles.ramp([Color(0.38,0.36,0.32,0),Color(0.38,0.36,0.32,0.17),Color(0.38,0.36,0.32,0.10),Color(0.38,0.36,0.32,0)])
	for particles in [flames, embers, smoke]:
		particles.preprocess = particles.lifetime
		add_child(particles)
		particles.emitting = true
	fire_light = OmniLight3D.new()
	fire_light.name = "HearthLight"
	fire_light.position.y = 1.6
	fire_light.light_color = Color("#ffb45e")
	fire_light.omni_range = 9
	add_child(fire_light)

func _process(delta: float) -> void:
	elapsed += delta
	fire_light.light_energy = 0.82 + sin(elapsed*6.1)*0.06 + sin(elapsed*10.7)*0.035
