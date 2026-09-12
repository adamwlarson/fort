extends SceneTree
const Internet = preload("res://scripts/fort_internet.gd")
const Main = preload("res://scripts/main.gd")
var failures := 0

class FakeRouter extends RefCounted:
	var discovery_error := 0
	var mapping_error := 0
	var valid := true
	var address := "203.0.113.10"
	var calls: Array = []
	func discover(_timeout: int) -> int: return discovery_error
	func get_gateway(): return self
	func is_valid_gateway() -> bool: return valid
	func add_port_mapping(port: int, internal: int, _description: String, protocol: String, _duration: int) -> int:
		calls.append(["add", port, internal, protocol])
		return mapping_error
	func query_external_address() -> String: return address
	func delete_port_mapping(port: int, protocol: String) -> int:
		calls.append(["remove", port, protocol])
		return 0

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	print(("PASS " if ok else "FAIL ") + message)
	if not ok: failures += 1
func until(test: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while not test.call() and Time.get_ticks_msec() < deadline:
		await create_timer(.01).timeout
	return test.call()
func capture(name: String) -> void:
	await create_timer(.2).timeout
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/" + name + ".png"))
func router_node(fake: FakeRouter) -> FortInternet:
	var node := Internet.new()
	node.backend_factory = func(): return fake
	root.add_child(node)
	return node

func run() -> void:
	check(Main.parse_endpoint(" 203.0.113.10:25001 ", 24567) == {"address":"203.0.113.10", "port":25001}, "IP:port overrides port field")
	check(Main.parse_endpoint("192.168.1.2", 25002).port == 25002, "bare address respects custom UDP field")
	check(Main.parse_endpoint("[::1]:25003", 24567).address == "::1", "bracketed IPv6 endpoint supported")
	check(Main.parse_endpoint("::1", 24567).port == 24567, "bare IPv6 preserved")
	for value in ["", "bad", "1.2.3.4:0", "1.2.3.4:65536", "1.2.3.4:abc", "[::1", "[::1]oops"]:
		check(Main.parse_endpoint(value, 24567).is_empty(), "reject invalid endpoint " + value)
	for value in ["10.0.0.2", "192.168.1.2", "172.16.0.1", "100.64.1.2", "100.127.1.2", "127.0.0.1", "169.254.1.1", "", "::1"]:
		check(not Internet.public_ipv4(value), "do not advertise private / CGNAT address " + value)
	var fake := FakeRouter.new()
	var node := router_node(fake)
	node.start(25001)
	check(await until(func(): return node.mapped), "background mapping succeeds")
	check(fake.calls == [["add",25001,25001,"UDP"]], "map exactly the selected UDP port, no TCP / delete first")
	check(node.external_address == fake.address and node.status.contains("not yet") == false, "public address and mapping status exposed")
	check(node.status.contains("verify reachability"), "success does not claim tested internet reachability")
	node.refresh_at = 0
	check(await until(func(): return fake.calls.size() == 2 and node.worker == null), "mapping refresh runs without deleting the port")
	node.stop()
	check(await until(func(): return fake.calls.size() == 3 and node.worker == null), "normal leave cleans mapping")
	check(fake.calls[2] == ["remove",25001,"UDP"] and node.external_address.is_empty(), "cleanup targets only owned UDP port and clears public address")
	node.free()
	check(fake.calls.size() == 3, "exit does not delete twice")
	var takeover := FakeRouter.new(); var refreshed := router_node(takeover)
	refreshed.start(25009)
	check(await until(func(): return refreshed.mapped), "map before ownership conflict")
	takeover.mapping_error = UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MAPPING
	refreshed.refresh_at = 0
	check(await until(func(): return refreshed.status.contains("conflicts")), "refresh reports mapping taken by another service")
	refreshed.stop(); await create_timer(.04).timeout; refreshed.free()
	check(takeover.calls.size() == 2, "do not remove another service's mapping after refresh conflict")
	for error in [UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MAPPING, UPNP.UPNP_RESULT_NOT_AUTHORIZED]:
		var denied := FakeRouter.new(); denied.mapping_error = error
		var failed := router_node(denied); failed.start(25002)
		check(await until(func(): return failed.worker == null and failed.attempted_generation == failed.generation), "failed mapping completes without blocking hosting")
		check(not failed.mapped and (failed.status.contains("conflicts") if error == 13 else failed.status.contains("Forward UDP")), "actionable failure status")
		failed.stop(); await create_timer(.04).timeout; failed.free()
		check(denied.calls.size() == 1, "never delete mapping after failed or conflicting add")
	var absent := FakeRouter.new(); absent.discovery_error = UPNP.UPNP_RESULT_NO_DEVICES
	var missing := router_node(absent); missing.start(25003)
	check(await until(func(): return missing.status.contains("unavailable")), "discovery failure offers manual forwarding")
	missing.free(); check(absent.calls.is_empty(), "failed discovery does not modify router")
	var stale := FakeRouter.new(); var cancelled := router_node(stale)
	cancelled.start(25004); cancelled._process(0); cancelled.stop()
	check(await until(func(): return stale.calls.size() == 2 and cancelled.worker == null), "late successful result after cancellation is cleaned")
	check(not cancelled.mapped and cancelled.external_address.is_empty(), "late result cannot restore stale public status")
	cancelled.free()
	var swapped := FakeRouter.new(); var switched := router_node(swapped)
	switched.start(25005); switched._process(0); switched.start(25006)
	check(await until(func(): return switched.mapped and switched.mapped_port == 25006), "rapid rehost maps latest session")
	check(swapped.calls == [["add",25005,25005,"UDP"],["remove",25005,"UDP"],["add",25006,25006,"UDP"]], "old mapping cleaned before new port opens")
	switched.free(); check(swapped.calls[-1] == ["remove",25006,"UDP"], "application exit cleans current mapping")
	var exiting := FakeRouter.new(); var pending := router_node(exiting)
	pending.start(25007); pending._process(0); pending.free()
	check(exiting.calls == [["add",25007,25007,"UDP"],["remove",25007,"UDP"]], "application exit during setup waits and cleans late mapping")
	check(Internet.describe_result({"mapped":true,"port":25001,"address":"100.64.2.1"}).contains("CGNAT"), "mapped private WAN reports double NAT / CGNAT")
	var main = load("res://scenes/main.tscn").instantiate(); root.add_child(main)
	await capture("internet10_title")
	check(not main.internet_toggle.button_pressed, "test mode disables real router mapping")
	var ui_router := FakeRouter.new(); main.internet.backend_factory = func(): return ui_router
	main.internet_toggle.button_pressed = true; main.port_edit.value = 25008; main._host()
	check(await until(func(): return main.internet.mapped), "Host button launches configured router setup")
	check(not main.public_copy.disabled and main.internet_label.text.contains(ui_router.address), "lobby offers public copy and router result")
	await capture("internet10_lobby")
	check(main.lobby.get_global_rect().end.y <= 720, "expanded lobby fits viewport")
	main._leave_game("Test leave")
	check(await until(func(): return ui_router.calls.size() == 2 and not main.returning_to_menu), "leaving lobby removes owned mapping")
	main.transport_connected = false; main._on_connection_failed()
	await create_timer(.08).timeout
	check(main.status_label.text.contains("Host not reached"), "transport failure distinguished")
	main.transport_connected = true; main._on_connection_failed()
	await create_timer(.08).timeout
	check(main.status_label.text.contains("Host reached, but lobby") and main.status_label.text.contains("Fort " + Main.BUILD_VERSION), "registration failure distinguished with current version")
	main.queue_free(); await create_timer(.05).timeout
	print("INTERNET10_RESULT ", "PASS" if failures == 0 else "FAIL")
	quit(failures)
