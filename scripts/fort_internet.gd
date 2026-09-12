class_name FortInternet
extends Node

# UPnP calls block: keep discovery, mapping and cleanup off the game thread.
# Use the gateway directly: UPNP.add_port_mapping() may delete a conflicting
# mapping before retrying. Never remove another application's mapping to host.
signal changed
var status := "Internet hosting disabled. LAN and manual forwarding still work."
var external_address := ""
var mapped := false
var desired_port := 0
var generation := 0
var attempted_generation := -1
var worker: Thread
var worker_generation := 0
var worker_kind := ""
var gateway: Object
var mapped_port := 0
var refresh_at := 0
var backend_factory: Callable # Test seam: automated tests never touch a router.

func start(port: int) -> void:
	desired_port = port
	generation += 1
	external_address = ""
	mapped = false
	status = "Checking router for UDP %d (UPnP)..." % port
	changed.emit()

func stop() -> void:
	desired_port = 0
	generation += 1
	external_address = ""
	mapped = false
	status = "Internet hosting disabled. LAN and manual forwarding still work."
	changed.emit()

func _process(_delta: float) -> void:
	if worker != null:
		if worker.is_alive(): return
		var result: Dictionary = worker.wait_to_finish()
		worker = null
		if worker_kind == "remove":
			if int(result.error) != UPNP.UPNP_RESULT_SUCCESS:
				push_warning("Fort could not remove its UDP mapping; check the router if needed (code %d)." % int(result.error))
		else:
			if bool(result.get("mapped", false)):
				gateway = result.gateway
				mapped_port = int(result.port)
			elif int(result.error) in [UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MAPPING, UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MECHANISM]:
				# Another service may have taken over since our last refresh.
				# Relinquish cleanup ownership rather than deleting its mapping.
				gateway = null
				mapped_port = 0
			if worker_generation == generation and desired_port > 0:
				mapped = bool(result.get("mapped", false))
				external_address = str(result.get("address", ""))
				status = describe_result(result)
				refresh_at = Time.get_ticks_msec() + 300000
				changed.emit()
	if gateway != null and (desired_port != mapped_port or worker_generation != generation):
		var old_gateway := gateway
		var old_port := mapped_port
		gateway = null
		mapped_port = 0
		_launch("remove", _remove_worker.bind(old_gateway, old_port))
	elif desired_port > 0 and attempted_generation != generation:
		attempted_generation = generation
		_launch("map", _map_worker.bind(desired_port))
	elif desired_port > 0 and gateway != null and Time.get_ticks_msec() >= refresh_at:
		# Refresh only the mapping this session successfully created.
		_launch("map", _refresh_worker.bind(gateway, mapped_port))

func _launch(kind: String, task: Callable) -> void:
	worker = Thread.new()
	worker_kind = kind
	worker_generation = generation
	var error := worker.start(task)
	if error != OK:
		worker = null
		status = "Could not start router setup. Use manual UDP forwarding."
		changed.emit()

func _map_worker(port: int) -> Dictionary:
	var backend = backend_factory.call() if backend_factory.is_valid() else UPNP.new()
	var error: int = backend.discover(2000)
	if error != UPNP.UPNP_RESULT_SUCCESS:
		return {"error": error, "port": port}
	var device = backend.get_gateway()
	if device == null or not device.is_valid_gateway():
		return {"error": UPNP.UPNP_RESULT_NO_GATEWAY, "port": port}
	return _refresh_worker(device, port)

func _refresh_worker(device: Object, port: int) -> Dictionary:
	var error: int = device.add_port_mapping(port, port, "Fort internet hosting", "UDP", 0)
	var address: String = device.query_external_address()
	return {"error": error, "port": port, "mapped": error == UPNP.UPNP_RESULT_SUCCESS,
		"gateway": device, "address": address}

func _remove_worker(device: Object, port: int) -> Dictionary:
	return {"error": device.delete_port_mapping(port, "UDP")}

static func public_ipv4(address: String) -> bool:
	if not address.is_valid_ip_address() or ":" in address: return false
	var parts := address.split(".")
	var a := int(parts[0]); var b := int(parts[1])
	return not (a in [0, 10, 127] or a >= 224 or (a == 172 and b >= 16 and b <= 31)
		or (a == 192 and b == 168) or (a == 169 and b == 254) or (a == 100 and b >= 64 and b <= 127))

static func describe_result(result: Dictionary) -> String:
	var port := int(result.port)
	var address := str(result.get("address", ""))
	if bool(result.get("mapped", false)):
		if address.is_empty():
			return "Router mapped UDP %d; public IP unavailable. Reachability is not yet verified." % port
		if not public_ipv4(address):
			return "Router mapped UDP %d, but WAN IP %s is not public IPv4. Double NAT / CGNAT may block internet joining." % [port, address]
		return "Router mapped UDP %d. Public IP: %s\nMapping succeeded; an outside connection must still verify reachability." % [port, address]
	var code := int(result.error)
	if code in [UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MAPPING, UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MECHANISM]:
		return "UDP %d mapping conflicts with another service. Leave and choose another port on both PCs. No existing mapping was removed." % port
	return "UPnP unavailable / refused (code %d). Forward UDP %d to this PC manually; LAN hosting still works." % [code, port]

func _exit_tree() -> void:
	# A result may arrive after leaving the lobby. Always reclaim that mapping.
	if worker != null:
		var result: Dictionary = worker.wait_to_finish()
		worker = null
		if worker_kind == "map" and bool(result.get("mapped", false)):
			gateway = result.gateway
			mapped_port = int(result.port)
		elif worker_kind == "map" and int(result.error) in [UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MAPPING, UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MECHANISM]:
			gateway = null
	if gateway != null:
		var result := _remove_worker(gateway, mapped_port)
		if int(result.error) != UPNP.UPNP_RESULT_SUCCESS:
			push_warning("Fort UDP mapping cleanup failed (code %d)." % int(result.error))
		gateway = null
