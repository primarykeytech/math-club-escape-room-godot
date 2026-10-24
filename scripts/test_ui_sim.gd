extends SceneTree

## Headless end-to-end integration test verifying UI controls, signals, and gameplay flow.

func _init() -> void:
	print("==================================================")
	print("RUNNING ESCAPE ROOM UI INTEGRATION TEST SUITE")
	print("==================================================")

	var main_scene = load("res://scenes/main.tscn")
	var main_node = main_scene.instantiate() as Main
	root.add_child(main_node)

	# Allow 1 frame to initialize
	await process_frame

	var tests_passed := 0
	var tests_failed := 0

	# 1. Verify initial START screen
	print("\n[CHECK 1] Initial Start Screen UI elements...")
	if main_node.title_label.text == "THE VAULT OF NEWTON":
		print("  PASS: Title is 'THE VAULT OF NEWTON'")
		tests_passed += 1
	else:
		print("  FAIL: Unexpected title: ", main_node.title_label.text)
		tests_failed += 1

	if main_node.stage_badge.text == "MISSION BRIEFING":
		print("  PASS: Stage badge is 'MISSION BRIEFING'")
		tests_passed += 1
	else:
		print("  FAIL: Unexpected badge: ", main_node.stage_badge.text)
		tests_failed += 1

	if main_node.stage_image.texture != null:
		print("  PASS: Viewport image successfully loaded and assigned.")
		tests_passed += 1
	else:
		print("  FAIL: Stage image texture is null!")
		tests_failed += 1

	if main_node.exit_btn != null and main_node.exit_btn.text.find("Exit") != -1:
		print("  PASS: Exit button is present in the header HUD.")
		tests_passed += 1
	else:
		print("  FAIL: Exit button missing or has wrong label")
		tests_failed += 1

	# 2. Transition through Prologue
	print("\n[CHECK 2] Starting game and navigating briefing...")
	main_node._on_action_pressed()
	for i in range(main_node.game_manager.data.get_total_stages()):
		main_node.game_manager.set_stage_variant_index(i, 0)
	await process_frame

	if main_node.game_manager.current_state == GameManager.State.PROLOGUE:
		print("  PASS: Entered PROLOGUE state, badge: %s" % main_node.stage_badge.text)
		tests_passed += 1
	else:
		print("  FAIL: Expected PROLOGUE state, got %d" % main_node.game_manager.current_state)
		tests_failed += 1

	# Advance to second prologue slide
	main_node._on_action_pressed()
	await process_frame
	if main_node.game_manager.current_prologue_idx == 1:
		print("  PASS: On Briefing slide 2/2, action button text: %s" % main_node.action_btn.text)
		tests_passed += 1
	else:
		print("  FAIL: Expected prologue slide 1")
		tests_failed += 1

	# Advance into Vault (PLAYING Stage 1)
	main_node._on_action_pressed()
	await process_frame
	if main_node.game_manager.current_state == GameManager.State.PLAYING and main_node.game_manager.current_stage_idx == 0:
		print("  PASS: Entered Vault! Stage 1 initiated, badge: %s" % main_node.stage_badge.text)
		tests_passed += 1
	else:
		print("  FAIL: Expected PLAYING stage 0")
		tests_failed += 1

	# 3. Test wrong answer input and hint
	print("\n[CHECK 3] Testing incorrect input and hint request...")
	var initial_time: float = main_node.game_manager.time_remaining
	main_node.input_line.text = "WRONG_CODE"
	main_node._on_submit_pressed()
	await process_frame

	if main_node.game_manager.total_penalties_applied == 30.0 and main_node.game_manager.time_remaining <= initial_time - 30.0:
		print("  PASS: Incorrect code applied 30s penalty. Status: %s" % main_node.status_label.text)
		tests_passed += 1
	else:
		print("  FAIL: Penalty mismatch")
		tests_failed += 1

	# Request hint
	main_node._on_hint_pressed()
	await process_frame
	if main_node.status_label.text.find("HINT 1") != -1:
		print("  PASS: Hint successfully displayed: %s" % main_node.status_label.text)
		tests_passed += 1
	else:
		print("  FAIL: Hint text not displayed")
		tests_failed += 1

	# 4. Solve Stage 1
	print("\n[CHECK 4] Submitting correct code for Stage 1...")
	main_node.input_line.text = "1660"
	main_node._on_submit_pressed()
	await process_frame

	if main_node.game_manager.current_state == GameManager.State.STAGE_SOLVED:
		print("  PASS: Stage 1 solved! Action button: %s" % main_node.action_btn.text)
		tests_passed += 1
	else:
		print("  FAIL: Expected STAGE_SOLVED")
		tests_failed += 1

	# 5. Advance to Stage 2 and solve all stages
	main_node._on_action_pressed()
	await process_frame
	if main_node.game_manager.current_stage_idx == 1:
		print("  PASS: Advanced to Stage 2: %s" % main_node.speaker_tag.text)
		tests_passed += 1
	else:
		print("  FAIL: Expected Stage 2")
		tests_failed += 1

	# Solve Stage 2 to 6
	var answers = ["15 2", "SEEK THE VAULT DOOR", "21 oz", "132", "83"]
	for i in range(answers.size()):
		main_node.input_line.text = answers[i]
		main_node._on_submit_pressed()
		await process_frame
		main_node._on_action_pressed()
		await process_frame

	if main_node.game_manager.current_state == GameManager.State.VICTORY:
		print("  PASS: Conquered all stages! Final state is VICTORY.")
		print("        Badge: %s" % main_node.stage_badge.text)
		print("        Summary text: %s" % main_node.puzzle_label.text)
		tests_passed += 1
	else:
		print("  FAIL: Expected VICTORY state, got %d" % main_node.game_manager.current_state)
		tests_failed += 1

	main_node.free()

	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("==================================================")

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
