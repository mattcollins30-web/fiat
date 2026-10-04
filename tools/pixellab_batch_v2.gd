extends SceneTree
## PixelLab v2 API batch generator (ships pass, 2026-09-02 — Matt: "we are
## using their worst image gen tool of the set"). The v1 script
## (tools/pixellab_batch.gd) only ever spoke /v1/generate-image-pixflux;
## this one drives the v2 BACKGROUND-JOB endpoints:
##
##   POST /v2/generate-image-v2          "Generate image (Pro)" — text +
##        up to 4 reference_images + a style_image (+ style_options);
##        returns a GRID of candidates per job (16 at 43-85px, 4 at
##        86-170px), every one written as <out>_01.png, _02.png ...
##        NO negative prompt on this endpoint (spec-pinned 2026-09-02).
##        Polled via GET /v2/background-jobs/{id}; images in last_response.
##   POST /v2/create-1-direction-object   "Create a 1-direction object"
##        (Pro Tools; 20-40 generations per call on a subscription).
##        Body: description, size (SQUARE, 16-256), view ("top-down" |
##        "sidescroller"), style_images [Base64Image, max 256px each —
##        when given, size is DERIVED from the largest style image and
##        must not be sent], item_descriptions. Returns object_id; polled
##        via GET /v2/objects/{object_id} until status is "completed"
##        (one candidate: storage_urls.unknown) or "review" (several:
##        frame_urls[]); every candidate URL is downloaded to
##        <out>_NN.png. The object stays in review on the account for
##        select-frames / dismiss-review in the PixelLab UI, unless the
##        job sets "dismiss_review": true.
##
##   POST /v2/animate-with-text-v3       "Animate with text v3" (the
##        crew's clips, 2026-09-09 — Matt: "use the manifest for this;
##        the existing crew figure as the init image, the prompts I
##        provided, one sheet per character, the file names already
##        set"). Body: first_frame (Base64Image, max 256px), action,
##        frame_count (4-16, even), seed, no_background. Polled like the
##        image job; the frames come back as images[]. Written as ONE
##        sheet at `out` exactly — the tool's own grid, cells the first
##        frame's size, no gutter, row-major, cell 0 the still itself
##        (WatchDeckArt.clip_frames reads it), then every returned frame
##        (a first returned frame identical to the still is not
##        repeated). Cost at 160px: ~4 generations for 16 frames.
##
## Schemas read from Matt's saved tools/pixellab_v2_openapi.json.
##
## RUN (from the project root):
##   godot --headless --script res://tools/pixellab_batch_v2.gd ++ --manifest res://tools/pixellab_ships_v2_manifest.json
##   options: ++ --dry-run   ++ --only <name>   ++ --force
##
## JOB FIELDS (manifest "jobs" entries):
##   out            output path WITHOUT the _NN suffix (e.g. art/ships/v2/ship_anvil.png)
##   endpoint       "generate-image-v2" (default) | "create-1-direction-object" | "animate-with-text-v3"
##   first_frame, frame_count, seed              (animate-with-text-v3; description is the action)
##   description, width, height, seed, no_background   (generate-image-v2)
##   reference_images  [res:// PNG paths] (generate-image-v2, up to 4)
##   style_image       res:// PNG path;  style_options {color_palette,
##                     outline, detail, shading: bool} (generate-image-v2)
##   view, style_images [res:// PNG paths], item_descriptions,
##   dismiss_review                                     (1-direction-object)
##   single            true: write ONE file, at `out` exactly - the first
##                     candidate the API returns - no _NN suffix, no contact
##                     sheet, no _response.json (Fiat's items, 2026-10-02:
##                     "only a single image is generated for each item ...
##                     place them directly in the correct folder with the
##                     correct name"). The API still returns its grid for
##                     sizes up to 170 px; the rest is dropped unseen.
##   flip_h            mirror every result before saving (and mirror the
##                     reference/style images before sending, so the
##                     generator sees the framing the prompt asks for)
##   extra          a dictionary merged VERBATIM into the request body —
##                  any field this script doesn't know about (the
##                  1-direction-object endpoint's own options, quality
##                  knobs, etc.) goes here, straight from the v2 spec.
##
## KEY: PIXELLAB_SECRET env var or tools/pixellab_secret.txt (never ships).
## Base64Image is {type:"base64", base64, format:"png"}; the spec's example
## carries the data:image/png;base64, prefix, so that is what is sent;
## results are decoded with or without it.

const BASE_URL: String = "https://api.pixellab.ai/v2"
const SECRET_PATH: String = "res://tools/pixellab_secret.txt"
const DELAY_BETWEEN_JOBS_SECONDS: float = 1.0
const POLL_DEFAULT_SECONDS: float = 5.0
const POLL_TIMEOUT_SECONDS: float = 600.0
const RETRY_DELAY_SECONDS: float = 20.0
const MAX_RETRIES: int = 3
const KNOWN_FIELDS: Array[String] = ["seed", "no_background", "style_options"]

var _http: HTTPRequest


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var dry_run: bool = args.has("--dry-run")
	var force: bool = args.has("--force")
	var only_filter: String = ""
	var only_index: int = args.find("--only")
	if only_index >= 0 and only_index + 1 < args.size():
		only_filter = args[only_index + 1]
	var manifest_path: String = ""
	var manifest_index: int = args.find("--manifest")
	if manifest_index >= 0 and manifest_index + 1 < args.size():
		manifest_path = args[manifest_index + 1]
	if manifest_path == "":
		push_error("v2 batch needs ++ --manifest <res:// path>")
		quit(1)
		return

	var secret: String = _read_secret()
	if secret == "" and not dry_run:
		push_error("No API key: set PIXELLAB_SECRET or put the key alone on line 1 of %s" % SECRET_PATH)
		quit(1)
		return
	var manifest: Dictionary = _read_manifest(manifest_path)
	if manifest.is_empty():
		quit(1)
		return
	var jobs: Array = manifest.get("jobs", [])
	print("PixelLab v2 batch — %d job(s) in %s." % [jobs.size(), manifest_path.get_file()])

	_http = HTTPRequest.new()
	get_root().add_child(_http)

	var generated: int = 0
	var skipped: int = 0
	var failed: int = 0
	var total_usd: float = 0.0
	for job in jobs:
		var out_path: String = String(job.get("out", ""))
		var label: String = out_path.get_file().get_basename()
		if only_filter != "" and not label.contains(only_filter):
			continue
		if out_path == "" or String(job.get("description", "")) == "":
			print("  SKIP (malformed job — needs 'out' and 'description'): %s" % [job])
			failed += 1
			continue
		var endpoint: String = String(job.get("endpoint", "generate-image-v2"))
		var animate: bool = endpoint == "animate-with-text-v3"
		var single: bool = bool(job.get("single", false))
		var first_out: String = out_path if (animate or single) else _numbered(out_path, 1)
		if not force and FileAccess.file_exists("res://" + first_out):
			print("  skip (exists): %s" % first_out)
			skipped += 1
			continue
		if dry_run:
			if animate:
				print("  would animate: %s from %s (%d frames)  \"%s\"" % [out_path, String(job.get("first_frame", "")), int(job.get("frame_count", 8)), String(job.get("description", "")).left(70)])
			else:
				print("  would generate: %s via /%s (%dx%d)  \"%s\"" % [out_path, endpoint, int(job.get("width", 0)), int(job.get("height", 0)), String(job.get("description", "")).left(70)])
			continue

		var result: Dictionary = await _generate(secret, job, endpoint)
		if result.get("ok", false) and animate:
			var frames: Array = result.get("images", [])
			var cells: int = _write_clip_sheet(out_path, String(job.get("first_frame", "")), frames)
			_write_response_dump(out_path, result.get("raw", {}))
			var usd_clip: float = float(result.get("usd", 0.0))
			total_usd += usd_clip
			if cells > 1:
				generated += 1
				print("  wrote %s (%d cells, %d frames from the API, $%.4f)" % [out_path, cells, frames.size(), usd_clip])
			else:
				failed += 1
				print("  FAIL %s: job completed but no frame decoded" % out_path)
			await create_timer(DELAY_BETWEEN_JOBS_SECONDS).timeout
			continue
		if result.get("ok", false):
			var images: Array = result.get("images", [])
			var written: int = 0
			for i in range(images.size()):
				if single and written > 0:
					break
				var png: PackedByteArray = _decode(String(images[i]))
				if png.is_empty():
					print("  WARN: result %d did not decode" % (i + 1))
					continue
				if job.get("flip_h", false):
					var image := Image.new()
					if image.load_png_from_buffer(png) == OK:
						image.flip_x()
						png = image.save_png_to_buffer()
				var target: String = "res://" + (out_path if single else _numbered(out_path, i + 1))
				DirAccess.make_dir_recursive_absolute(target.get_base_dir())
				var f := FileAccess.open(target, FileAccess.WRITE)
				if f == null:
					print("  FAIL (can't write %s): %s" % [target, FileAccess.get_open_error()])
					continue
				f.store_buffer(png)
				f.close()
				written += 1
			if written > 1:
				_write_sheet(out_path, images, job.get("flip_h", false))
			if not single:
				_write_response_dump(out_path, result.get("raw", {}))
			var usd: float = float(result.get("usd", 0.0))
			total_usd += usd
			if written > 0:
				generated += 1
				print("  wrote %d image(s) for %s ($%.4f)" % [written, out_path, usd])
			else:
				failed += 1
				print("  FAIL %s: job completed but no image decoded" % out_path)
		else:
			print("  FAIL %s: %s" % [out_path, result.get("error", "unknown")])
			failed += 1
		await create_timer(DELAY_BETWEEN_JOBS_SECONDS).timeout

	print("Done: %d generated, %d skipped (already on disk), %d failed. Batch cost: $%.4f" % [generated, skipped, failed, total_usd])
	quit(0 if failed == 0 else 1)


## art/ships/v2/ship_anvil.png, 3 -> art/ships/v2/ship_anvil_03.png
func _numbered(out_path: String, index: int) -> String:
	return "%s/%s_%02d.%s" % [out_path.get_base_dir(), out_path.get_file().get_basename(), index, out_path.get_extension()]


## One contact sheet per job — every returned candidate tiled in a square
## grid with a 2px transparent gutter, cells in API order, so a boat can
## be picked from a single image (<out>_sheet.png). The cells are pasted
## as received; a boat the API clipped at its cell edge stays clipped.
func _write_sheet(out_path: String, images: Array, flip: bool) -> void:
	var cells: Array[Image] = []
	for b64 in images:
		var image := Image.new()
		if image.load_png_from_buffer(_decode(String(b64))) == OK:
			if flip:
				image.flip_x()
			cells.append(image)
	if cells.size() < 2:
		return
	var cell_w: int = 0
	var cell_h: int = 0
	for c in cells:
		cell_w = max(cell_w, c.get_width())
		cell_h = max(cell_h, c.get_height())
	var columns: int = int(ceil(sqrt(float(cells.size()))))
	var rows: int = int(ceil(float(cells.size()) / float(columns)))
	const GUTTER: int = 2
	var sheet := Image.create(columns * (cell_w + GUTTER) - GUTTER, rows * (cell_h + GUTTER) - GUTTER, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in range(cells.size()):
		var c: Image = cells[i]
		c.convert(Image.FORMAT_RGBA8)
		var x: int = (i % columns) * (cell_w + GUTTER)
		var y: int = (i / columns) * (cell_h + GUTTER)
		sheet.blit_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()), Vector2i(x, y))
	var target: String = "res://%s/%s_sheet.%s" % [out_path.get_base_dir(), out_path.get_file().get_basename(), out_path.get_extension()]
	sheet.save_png(target)
	print("  wrote %s (%d cells, %dx%d)" % [target.trim_prefix("res://"), cells.size(), columns, rows])


## The clip sheet (animate-with-text-v3): cells the first frame's size,
## no gutter, row-major, ceil(sqrt(n)) columns — cell 0 the still (the
## first frame as sent), then the API's frames, a first frame identical
## to the still not repeated. Returns the cell count written (0 on a
## failure).
func _write_clip_sheet(out_path: String, first_frame_path: String, frames: Array) -> int:
	var still := Image.new()
	if not FileAccess.file_exists(first_frame_path) or still.load_png_from_buffer(FileAccess.get_file_as_bytes(first_frame_path)) != OK:
		print("  FAIL: first frame unreadable: %s" % first_frame_path)
		return 0
	still.convert(Image.FORMAT_RGBA8)
	var cells: Array[Image] = [still]
	for i in range(frames.size()):
		var image := Image.new()
		if image.load_png_from_buffer(_decode(String(frames[i]))) != OK:
			print("  WARN: frame %d did not decode" % (i + 1))
			continue
		image.convert(Image.FORMAT_RGBA8)
		if i == 0 and image.get_size() == still.get_size() and image.get_data() == still.get_data():
			continue
		cells.append(image)
	if cells.size() < 2:
		return 0
	var cell: Vector2i = still.get_size()
	var columns: int = int(ceil(sqrt(float(cells.size()))))
	var rows: int = int(ceil(float(cells.size()) / float(columns)))
	var sheet := Image.create(columns * cell.x, rows * cell.y, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for i in range(cells.size()):
		var c: Image = cells[i]
		# A frame the API returned at another size sits in its cell's
		# bottom-centre (the feet), clipped to the cell.
		var at := Vector2i((i % columns) * cell.x + (cell.x - c.get_width()) / 2, (i / columns) * cell.y + cell.y - c.get_height())
		sheet.blit_rect(c, Rect2i(0, 0, mini(c.get_width(), cell.x), mini(c.get_height(), cell.y)), at)
	var target: String = "res://" + out_path
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if sheet.save_png(target) != OK:
		print("  FAIL (can't write %s)" % target)
		return 0
	return cells.size()


## The job's final API response with every base64 payload replaced by its
## length, saved as <out>_response.json — so any field the script is not
## reading (an uncut sheet, extra metadata) is visible on disk.
func _write_response_dump(out_path: String, raw: Variant) -> void:
	if not (raw is Dictionary) or (raw as Dictionary).is_empty():
		return
	var target: String = "res://%s/%s_response.json" % [out_path.get_base_dir(), out_path.get_file().get_basename()]
	var f := FileAccess.open(target, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(_strip_base64(raw), "  "))
		f.close()


func _strip_base64(value: Variant) -> Variant:
	if value is Dictionary:
		var out: Dictionary = {}
		for key in value:
			out[key] = _strip_base64(value[key])
		return out
	if value is Array:
		var arr: Array = []
		for item in value:
			arr.append(_strip_base64(item))
		return arr
	if value is String and (String(value).length() > 200 or String(value).begins_with("data:")):
		return "<base64 %d chars>" % String(value).length()
	return value


## Submit one job and poll it to completion. Returns
## {"ok": true, "images": [base64...], "usd": ...} or {"ok": false, "error": ...}.
func _generate(secret: String, job: Dictionary, endpoint: String) -> Dictionary:
	var headers: PackedStringArray = [
		"Authorization: Bearer %s" % secret,
		"Content-Type: application/json",
	]
	if job.has("negative_prompt"):
		print("    note: v2 endpoints have no negative prompt — 'negative_prompt' ignored (fold it into the description).")
	if endpoint == "create-1-direction-object":
		return await _generate_object(job, headers)
	if endpoint == "animate-with-text-v3":
		return await _animate(job, headers)
	return await _generate_image_v2(job, headers, endpoint)


## animate-with-text-v3: the first frame off disk, the description as
## the action, the frames back through the same background-job poll.
func _animate(job: Dictionary, headers: PackedStringArray) -> Dictionary:
	var first: Dictionary = _base64_image(String(job.get("first_frame", "")), false)
	if first.is_empty():
		return {"ok": false, "error": "first frame not found: %s" % job.get("first_frame", "")}
	if int(first["_width"]) > 256 or int(first["_height"]) > 256:
		return {"ok": false, "error": "first frame over 256px: %s" % job.get("first_frame", "")}
	first.erase("_width")
	first.erase("_height")
	var body: Dictionary = {
		"first_frame": first,
		"action": String(job["description"]),
		"frame_count": int(job.get("frame_count", 8)),
		"no_background": bool(job.get("no_background", true)),
	}
	if job.has("seed") and job["seed"] != null:
		body["seed"] = int(job["seed"])
	_merge_extra(body, job)
	return await _submit_and_poll("animate-with-text-v3", body, headers)


## generate-image-v2: submit, poll /background-jobs, take last_response.images.
func _generate_image_v2(job: Dictionary, headers: PackedStringArray, endpoint: String) -> Dictionary:
	var body: Dictionary = {
		"description": String(job["description"]),
		"image_size": {"width": int(job.get("width", 64)), "height": int(job.get("height", 64))},
	}
	for field in KNOWN_FIELDS:
		if job.has(field) and job[field] != null:
			body[field] = job[field]
	var flip: bool = job.get("flip_h", false)
	if job.has("reference_images"):
		var refs: Array = []
		for path in job["reference_images"]:
			var ref: Dictionary = _reference_entry(String(path), flip)
			if ref.is_empty():
				return {"ok": false, "error": "reference image not found: %s" % path}
			refs.append(ref)
		body["reference_images"] = refs
	if job.has("style_image") and String(job["style_image"]) != "":
		var style: Dictionary = _reference_entry(String(job["style_image"]), flip)
		if style.is_empty():
			return {"ok": false, "error": "style image not found: %s" % job["style_image"]}
		body["style_image"] = style
	_merge_extra(body, job)
	return await _submit_and_poll(endpoint, body, headers)


## Submit a background job and poll it to completion; the images out of
## the last_response (or a direct reply).
func _submit_and_poll(endpoint: String, body: Dictionary, headers: PackedStringArray) -> Dictionary:
	var submitted: Dictionary = await _request_json(BASE_URL + "/" + endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if not submitted.get("ok", false):
		return submitted
	var response: Dictionary = submitted["json"]
	var direct: Array = _collect_images(response)
	if not direct.is_empty():
		return {"ok": true, "images": direct, "usd": _usd(response)}
	var job_id: String = String(response.get("background_job_id", ""))
	if job_id == "":
		return {"ok": false, "error": "no background_job_id in response: %s" % JSON.stringify(response).left(300)}
	var usd: float = _usd(response)
	print("    job %s submitted, polling..." % job_id)
	var waited: float = 0.0
	while waited < POLL_TIMEOUT_SECONDS:
		var wait: float = POLL_DEFAULT_SECONDS
		var polled: Dictionary = await _request_json(BASE_URL + "/background-jobs/" + job_id, headers, HTTPClient.METHOD_GET, "")
		if polled.get("ok", false):
			var status_json: Dictionary = polled["json"]
			var status: String = String(status_json.get("status", ""))
			if status == "completed":
				var last: Variant = status_json.get("last_response", status_json)
				var images: Array = _collect_images(last if last is Dictionary else status_json)
				if images.is_empty():
					return {"ok": false, "error": "completed but no images found in: %s" % JSON.stringify(status_json).left(400)}
				return {"ok": true, "images": images, "usd": max(usd, _usd(status_json)), "raw": status_json}
			if status == "failed":
				return {"ok": false, "error": "job failed: %s" % JSON.stringify(status_json.get("last_response", status_json)).left(300)}
			wait = max(1.0, float(status_json.get("retry_after", POLL_DEFAULT_SECONDS)))
		await create_timer(wait).timeout
		waited += wait
	return {"ok": false, "error": "timed out polling job %s" % job_id}


## create-1-direction-object: submit, poll /objects/{id}, download every
## candidate frame URL. Square size from the job's width; style_images
## replace size (the API derives it from the largest style image).
func _generate_object(job: Dictionary, headers: PackedStringArray) -> Dictionary:
	var body: Dictionary = {
		"description": String(job["description"]),
		"view": String(job.get("view", "top-down")),
	}
	var flip: bool = job.get("flip_h", false)
	var styles: Array = job.get("style_images", [])
	if styles.is_empty():
		body["size"] = int(job.get("width", 64))
	else:
		var encoded: Array = []
		for path in styles:
			var entry: Dictionary = _base64_image(String(path), flip)
			if entry.is_empty():
				return {"ok": false, "error": "style image not found: %s" % path}
			entry.erase("_width")
			entry.erase("_height")
			encoded.append(entry)
		body["style_images"] = encoded
		print("    style_images given — output size is derived from the largest style image (size not sent).")
	if job.has("item_descriptions"):
		body["item_descriptions"] = job["item_descriptions"]
	_merge_extra(body, job)

	var submitted: Dictionary = await _request_json(BASE_URL + "/create-1-direction-object", headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if not submitted.get("ok", false):
		return submitted
	var response: Dictionary = submitted["json"]
	var object_id: String = String(response.get("object_id", ""))
	if object_id == "":
		return {"ok": false, "error": "no object_id in response: %s" % JSON.stringify(response).left(300)}
	var usd: float = _usd(response)
	print("    object %s queued (%d candidate frame(s)), polling..." % [object_id, int(response.get("n_frames", 0))])
	var waited: float = 0.0
	while waited < POLL_TIMEOUT_SECONDS:
		var polled: Dictionary = await _request_json(BASE_URL + "/objects/" + object_id, headers, HTTPClient.METHOD_GET, "")
		if polled.get("ok", false):
			var info: Dictionary = polled["json"]
			var status: String = String(info.get("status", ""))
			if status == "failed":
				return {"ok": false, "error": "object %s failed" % object_id}
			if status == "completed" or status == "review":
				var urls: Array = _object_frame_urls(info)
				if urls.is_empty():
					return {"ok": false, "error": "object %s is %s but exposes no frame URLs: %s" % [object_id, status, JSON.stringify(info).left(400)]}
				var images: Array = []
				for url in urls:
					var png: PackedByteArray = await _download(String(url), headers)
					if png.is_empty():
						print("    WARN: could not download %s" % url)
						continue
					images.append(Marshalls.raw_to_base64(png))
				if images.is_empty():
					return {"ok": false, "error": "object %s: no frame downloaded" % object_id}
				if status == "review":
					if job.get("dismiss_review", false):
						await _request_json(BASE_URL + "/objects/" + object_id + "/dismiss-review", headers, HTTPClient.METHOD_POST, "{}")
						print("    review object dismissed (dismiss_review)")
					else:
						print("    object %s left in review on the account — pick keepers there (select-frames) or dismiss it." % object_id)
				return {"ok": true, "images": images, "usd": usd, "raw": info}
		await create_timer(POLL_DEFAULT_SECONDS).timeout
		waited += POLL_DEFAULT_SECONDS
	return {"ok": false, "error": "timed out polling object %s" % object_id}


## Candidate URLs in a stable order: frame_urls (review), then storage_urls
## frame_N keys sorted by N, then the single-direction 'unknown' slot.
func _object_frame_urls(info: Dictionary) -> Array:
	var frames: Variant = info.get("frame_urls", null)
	if frames is Array and not (frames as Array).is_empty():
		return frames
	var storage: Variant = info.get("storage_urls", {})
	var urls: Array = []
	if storage is Dictionary:
		var keys: Array = []
		for key in storage:
			if String(key).begins_with("frame_"):
				keys.append(String(key))
		keys.sort_custom(func(a: String, b: String) -> bool: return int(a.trim_prefix("frame_")) < int(b.trim_prefix("frame_")))
		for key in keys:
			urls.append(storage[key])
		if urls.is_empty() and storage.has("unknown"):
			urls.append(storage["unknown"])
	return urls


## Anything in job.extra is merged verbatim — the escape hatch for fields
## this script doesn't name.
func _merge_extra(body: Dictionary, job: Dictionary) -> void:
	var extra: Variant = job.get("extra", {})
	if extra is Dictionary:
		for key in extra:
			body[key] = extra[key]


## Raw bytes from a (signed) storage URL. Tried without the bearer header
## first — signed URLs can reject foreign auth — then with it.
func _download(url: String, headers: PackedStringArray) -> PackedByteArray:
	for attempt_headers in [PackedStringArray(), headers]:
		var err: int = _http.request(url, attempt_headers, HTTPClient.METHOD_GET, "")
		if err != OK:
			continue
		var response: Array = await _http.request_completed
		if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200:
			return response[3]
	return PackedByteArray()


## Base64Image: {type:"base64", base64:"data:image/png;base64,...", format:"png"}.
func _base64_image(res_path: String, flip: bool) -> Dictionary:
	if not FileAccess.file_exists(res_path):
		return {}
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(res_path)
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return {}
	if flip:
		image.flip_x()
		bytes = image.save_png_to_buffer()
	return {"type": "base64", "base64": "data:image/png;base64," + Marshalls.raw_to_base64(bytes), "format": "png",
		"_width": image.get_width(), "_height": image.get_height()}


## generate-image-v2's ReferenceImage: {image: Base64Image, size: {width, height}}.
func _reference_entry(res_path: String, flip: bool) -> Dictionary:
	var img: Dictionary = _base64_image(res_path, flip)
	if img.is_empty():
		return {}
	var w: int = img["_width"]
	var h: int = img["_height"]
	img.erase("_width")
	img.erase("_height")
	return {"image": img, "size": {"width": w, "height": h}}


## Every base64 image string reachable in a response: images[] first (the
## v2 grid cells, in order), then image (single). Any OTHER key carrying
## an image (a sheet, a preview) is reported so it can be wired in.
func _collect_images(response: Dictionary) -> Array:
	var found: Array = []
	if response.has("images") and response["images"] is Array:
		for entry in response["images"]:
			var b64: String = _b64_of(entry)
			if b64 != "":
				found.append(b64)
	if found.is_empty() and response.has("image"):
		var b64: String = _b64_of(response["image"])
		if b64 != "":
			found.append(b64)
	for key in response:
		if key == "images" or key == "image":
			continue
		if _b64_of(response[key]) != "":
			print("    note: response also carries an image under '%s' (not written — see the _response.json dump)" % key)
	return found


func _b64_of(entry: Variant) -> String:
	if entry is String:
		return String(entry)
	if entry is Dictionary:
		if entry.has("base64"):
			return String(entry["base64"])
		if entry.has("image"):
			return _b64_of(entry["image"])
	return ""


func _decode(b64: String) -> PackedByteArray:
	var comma: int = b64.find(",")
	if b64.begins_with("data:") and comma >= 0:
		b64 = b64.substr(comma + 1)
	return Marshalls.base64_to_raw(b64)


func _usd(response: Dictionary) -> float:
	var usage: Variant = response.get("usage", {})
	return float(usage.get("usd", 0.0)) if usage is Dictionary else 0.0


## One HTTP round trip with retry on 429/5xx. Returns {"ok", "json"} or {"ok": false, "error"}.
func _request_json(url: String, headers: PackedStringArray, method: int, payload: String) -> Dictionary:
	for attempt in range(1, MAX_RETRIES + 1):
		var err: int = _http.request(url, headers, method, payload)
		if err != OK:
			return {"ok": false, "error": "request dispatch error %d" % err}
		var response: Array = await _http.request_completed
		var http_result: int = response[0]
		var code: int = response[1]
		var text: String = (response[3] as PackedByteArray).get_string_from_utf8()
		if http_result != HTTPRequest.RESULT_SUCCESS:
			if attempt < MAX_RETRIES:
				print("    transport error (result %d), retry %d/%d in %ds..." % [http_result, attempt, MAX_RETRIES, int(RETRY_DELAY_SECONDS)])
				await create_timer(RETRY_DELAY_SECONDS).timeout
				continue
			return {"ok": false, "error": "transport error (HTTPRequest result %d)" % http_result}
		if code == 200 or code == 202:
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				return {"ok": true, "json": parsed}
			return {"ok": false, "error": "HTTP %d but not a JSON object: %s" % [code, text.left(200)]}
		if (code == 429 or code >= 500) and attempt < MAX_RETRIES:
			print("    HTTP %d, retry %d/%d in %ds..." % [code, attempt, MAX_RETRIES, int(RETRY_DELAY_SECONDS)])
			await create_timer(RETRY_DELAY_SECONDS).timeout
			continue
		return {"ok": false, "error": "HTTP %d: %s" % [code, text.left(400)]}
	return {"ok": false, "error": "retries exhausted"}


func _read_secret() -> String:
	var env: String = OS.get_environment("PIXELLAB_SECRET")
	if env.strip_edges() != "":
		return env.strip_edges()
	if FileAccess.file_exists(SECRET_PATH):
		var f := FileAccess.open(SECRET_PATH, FileAccess.READ)
		return f.get_line().strip_edges()
	return ""


func _read_manifest(manifest_path: String) -> Dictionary:
	if not FileAccess.file_exists(manifest_path):
		push_error("Manifest missing: %s" % manifest_path)
		return {}
	var f := FileAccess.open(manifest_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary) or not (parsed.get("jobs", null) is Array):
		push_error("Manifest must be a JSON object with a 'jobs' array.")
		return {}
	return parsed
