extends SceneTree

## Headless automated test suite to verify AnswerValidator, EscapeRoomData, and GameManager.

func _init() -> void:
	print("==================================================")
	print("RUNNING MATH CLUB ESCAPE ROOM GDSCRIPT TEST SUITE")
	print("==================================================")

	var tests_passed := 0
	var tests_failed := 0

	# --- TEST 1: EscapeRoomData Loading ---
	print("\n[TEST 1] Testing EscapeRoomData loading...")
	var data := EscapeRoomData.load_from_file("res://data/escape_room.json")
	if data.stages.size() == 6 and data.prologue_screens.size() == 2:
		print("  PASS: Loaded 6 stages and 2 prologue screens.")
		tests_passed += 1
	else:
		print("  FAIL: Stages size=%d, Prologues size=%d" % [data.stages.size(), data.prologue_screens.size()])
		tests_failed += 1

	if data.room_title == "THE VAULT OF NEWTON":
		print("  PASS: Room title matches: %s" % data.room_title)
		tests_passed += 1
	else:
		print("  FAIL: Room title mismatch: %s" % data.room_title)
		tests_failed += 1

	# --- TEST 2: AnswerValidator ---
	print("\n[TEST 2] Testing AnswerValidator matching...")
	var test_cases = [
		# Stage 1: "1660"
		{"input": "1660", "accepted": ["1660"], "expected": true, "name": "Stage 1 exact"},
		{"input": "  1660  ", "accepted": ["1660"], "expected": true, "name": "Stage 1 whitespace"},
		{"input": "1661", "accepted": ["1660"], "expected": false, "name": "Stage 1 wrong answer"},

		# Stage 2: "15 2", "15, 2", "15,2", "15 and 2", "15 pencils, 2 pens"
		{"input": "15 2", "accepted": ["15 2", "15, 2", "15,2", "15 and 2", "15 pencils, 2 pens", "15 pencils 2 pens"], "expected": true, "name": "Stage 2 space"},
		{"input": "15, 2", "accepted": ["15 2", "15, 2", "15,2", "15 and 2", "15 pencils, 2 pens", "15 pencils 2 pens"], "expected": true, "name": "Stage 2 comma"},
		{"input": "15 and 2", "accepted": ["15 2", "15, 2", "15,2", "15 and 2", "15 pencils, 2 pens", "15 pencils 2 pens"], "expected": true, "name": "Stage 2 'and' word"},
		{"input": "15 pencils and 2 pens", "accepted": ["15 2", "15, 2", "15,2", "15 and 2", "15 pencils, 2 pens", "15 pencils 2 pens"], "expected": true, "name": "Stage 2 full phrase"},
		{"input": "20 5", "accepted": ["15 2"], "expected": false, "name": "Stage 2 wrong answer"},

		# Stage 3: Caesar cipher
		{"input": "SEEK THE VAULT DOOR", "accepted": ["SEEK THE VAULT DOOR", "SEEK THE VAULT DOOR.", "SEEKTHEVAULTDOOR"], "expected": true, "name": "Stage 3 uppercase"},
		{"input": "seek the vault door", "accepted": ["SEEK THE VAULT DOOR", "SEEK THE VAULT DOOR.", "SEEKTHEVAULTDOOR"], "expected": true, "name": "Stage 3 lowercase"},
		{"input": "seek the vault door.", "accepted": ["SEEK THE VAULT DOOR", "SEEK THE VAULT DOOR.", "SEEKTHEVAULTDOOR"], "expected": true, "name": "Stage 3 trailing period"},
		{"input": "SEEKTHEVAULTDOOR", "accepted": ["SEEK THE VAULT DOOR"], "expected": true, "name": "Stage 3 alphanumeric match"},

		# Stage 4: "21", "21 oz", "21 ounces"
		{"input": "21", "accepted": ["21", "21 oz", "21 ounces", "21oz"], "expected": true, "name": "Stage 4 number only"},
		{"input": "21 oz", "accepted": ["21", "21 oz", "21 ounces", "21oz"], "expected": true, "name": "Stage 4 with unit"},
		{"input": "21 ounces", "accepted": ["21", "21 oz", "21 ounces", "21oz"], "expected": true, "name": "Stage 4 full word"},

		# Stage 5: "132", "1 3 2", "1, 3, 2"
		{"input": "132", "accepted": ["132", "1 3 2", "1, 3, 2", "1,3,2"], "expected": true, "name": "Stage 5 continuous"},
		{"input": "1 3 2", "accepted": ["132", "1 3 2", "1, 3, 2", "1,3,2"], "expected": true, "name": "Stage 5 spaces"},
		{"input": "1, 3, 2", "accepted": ["132", "1 3 2", "1, 3, 2", "1,3,2"], "expected": true, "name": "Stage 5 commas"},

		# Stage 6: "83"
		{"input": "83", "accepted": ["83"], "expected": true, "name": "Stage 6 prime sum"},
		{"input": "85", "accepted": ["83"], "expected": false, "name": "Stage 6 wrong prime sum"}
	]

	for tc in test_cases:
		var result = AnswerValidator.matches_answer(tc["input"], tc["accepted"])
		if result == tc["expected"]:
			print("  PASS: %s -> %s" % [tc["name"], result])
			tests_passed += 1
		else:
			print("  FAIL: %s -> got %s, expected %s" % [tc["name"], result, tc["expected"]])
			tests_failed += 1

	# --- TEST 3: GameManager State Machine Flow ---
	print("\n[TEST 3] Testing GameManager state machine flow...")
	var gm := GameManager.new()
	gm.load_game_data("res://data/escape_room.json")

	if gm.current_state == GameManager.State.START:
		print("  PASS: Initial state is START")
		tests_passed += 1
	else:
		print("  FAIL: Initial state is %d" % gm.current_state)
		tests_failed += 1

	# Start -> Prologue
	gm.start_game()
	for i in range(gm.data.get_total_stages()):
		gm.set_stage_variant_index(i, 0)
	if gm.current_state == GameManager.State.PROLOGUE and gm.current_prologue_idx == 0:
		print("  PASS: Transitioned to PROLOGUE screen 0")
		tests_passed += 1
	else:
		print("  FAIL: Expected PROLOGUE screen 0")
		tests_failed += 1

	# Prologue advance -> Prologue 1
	gm.advance_prologue()
	if gm.current_prologue_idx == 1:
		print("  PASS: Advanced to PROLOGUE screen 1")
		tests_passed += 1
	else:
		print("  FAIL: Expected PROLOGUE screen 1")
		tests_failed += 1

	# Prologue advance -> Playing Stage 1
	gm.advance_prologue()
	if gm.current_state == GameManager.State.PLAYING and gm.current_stage_idx == 0 and gm.timer_active:
		print("  PASS: Transitioned to PLAYING stage 0 with timer active")
		tests_passed += 1
	else:
		print("  FAIL: Expected PLAYING stage 0")
		tests_failed += 1

	# Wrong answer penalty deduction
	var time_before := gm.time_remaining
	gm.submit_answer("9999")
	if gm.time_remaining == time_before - 30.0 and gm.current_state == GameManager.State.PLAYING:
		print("  PASS: Incorrect answer applied 30s penalty (remaining: %d s)" % int(gm.time_remaining))
		tests_passed += 1
	else:
		print("  FAIL: Penalty calculation error. Before: %f, After: %f" % [time_before, gm.time_remaining])
		tests_failed += 1

	# Correct answer -> STAGE_SOLVED
	gm.submit_answer("1660")
	if gm.current_state == GameManager.State.STAGE_SOLVED:
		print("  PASS: Correct answer progressed to STAGE_SOLVED")
		tests_passed += 1
	else:
		print("  FAIL: Expected STAGE_SOLVED, got %d" % gm.current_state)
		tests_failed += 1

	# Advance to Stage 2
	gm.advance_stage()
	if gm.current_state == GameManager.State.PLAYING and gm.current_stage_idx == 1:
		print("  PASS: Advanced to PLAYING Stage 2")
		tests_passed += 1
	else:
		print("  FAIL: Expected PLAYING Stage 2, got %d" % gm.current_stage_idx)
		tests_failed += 1

	# Solve remaining stages up to Victory
	gm.submit_answer("15 2") # Stage 2
	gm.advance_stage()
	gm.submit_answer("seek the vault door") # Stage 3
	gm.advance_stage()
	gm.submit_answer("21 oz") # Stage 4
	gm.advance_stage()
	gm.submit_answer("132") # Stage 5
	gm.advance_stage()
	gm.submit_answer("83") # Stage 6
	gm.advance_stage() # Should trigger VICTORY

	if gm.current_state == GameManager.State.VICTORY and not gm.timer_active:
		print("  PASS: Cleared all 6 stages and achieved VICTORY state!")
		tests_passed += 1
	else:
		print("  FAIL: Expected VICTORY, got state %d" % gm.current_state)
		tests_failed += 1

	# --- TEST 4: Question Pool Replayability Database ---
	print("\n[TEST 4] Testing Question Pool Replayability Database...")
	var all_pools_valid := true
	var total_variants := 0
	for i in range(data.get_total_stages()):
		var pool := data.get_stage_question_pool(i)
		total_variants += pool.size()
		if pool.size() < 5:
			all_pools_valid = false
			print("  FAIL: Stage %d has only %d question variants" % [i + 1, pool.size()])
		for v in pool:
			if not v.has("puzzle_text") or not v.has("accepted_answers") or v["accepted_answers"].is_empty():
				all_pools_valid = false
				print("  FAIL: Stage %d variant has missing puzzle_text or accepted_answers" % [i + 1])

	if all_pools_valid and total_variants == 30:
		print("  PASS: All 6 stages have 5 question variants (Total %d questions in database)." % total_variants)
		tests_passed += 1
	else:
		tests_failed += 1

	# Test random selection generates differing variants
	gm.select_random_questions()
	var random_active := gm.get_active_stage(0)
	if random_active.has("puzzle_text") and not random_active["accepted_answers"].is_empty():
		print("  PASS: Random question selection populated active stage data successfully.")
		tests_passed += 1
	else:
		print("  FAIL: Random question selection failed.")
		tests_failed += 1

	gm.free()

	print("\n==================================================")
	print("RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("==================================================")

	if tests_failed > 0:
		quit(1)
	else:
		quit(0)
