class_name AnswerValidator
extends RefCounted

## Validates user answer submissions against accepted puzzle answers.
## Supports exact match, normalized punctuation, word equivalencies ("and"),
## extracted numeric sequence matching, and stripped alphanumeric matching.

static var _regex_normalize: RegEx
static var _regex_digits: RegEx
static var _regex_alphanum: RegEx

static func _init_regex() -> void:
	if _regex_normalize == null:
		_regex_normalize = RegEx.new()
		_regex_normalize.compile("[,;:]|\\band\\b")
		_regex_digits = RegEx.new()
		_regex_digits.compile("\\d+")
		_regex_alphanum = RegEx.new()
		_regex_alphanum.compile("[^a-zA-Z0-9]")

static func _collapse_whitespace(text: String) -> String:
	var parts := text.split(" ", false)
	return " ".join(parts)

static func _extract_all_matches(regex: RegEx, text: String) -> PackedStringArray:
	var results := PackedStringArray()
	var matches := regex.search_all(text)
	for m in matches:
		results.append(m.get_string())
	return results

## Evaluates whether the given command string satisfies any of the accepted answers.
static func matches_answer(cmd: String, accepted_answers: Array) -> bool:
	var cleaned_cmd := cmd.strip_edges().to_lower()
	if cleaned_cmd.is_empty():
		return false

	_init_regex()

	for acc in accepted_answers:
		var acc_clean := str(acc).strip_edges().to_lower()
		# 1. Exact match (case-insensitive, whitespace trimmed)
		if cleaned_cmd == acc_clean:
			return true

		# 2. Normalized punctuation (commas, semicolons, and "and" into spaces)
		var norm_cmd := _collapse_whitespace(_regex_normalize.sub(cleaned_cmd, " ", true))
		var norm_acc := _collapse_whitespace(_regex_normalize.sub(acc_clean, " ", true))
		if norm_cmd == norm_acc:
			return true

		# 3. Numeric sequence comparison
		var nums_cmd := _extract_all_matches(_regex_digits, cleaned_cmd)
		var nums_acc := _extract_all_matches(_regex_digits, acc_clean)
		if not nums_cmd.is_empty() and not nums_acc.is_empty() and nums_cmd == nums_acc:
			return true

		# 4. Alphanumeric stripped comparison (removes spaces, periods, quotes)
		var alphanum_cmd := _regex_alphanum.sub(cleaned_cmd, "", true)
		var alphanum_acc := _regex_alphanum.sub(acc_clean, "", true)
		if not alphanum_cmd.is_empty() and alphanum_cmd == alphanum_acc:
			return true

	return false
