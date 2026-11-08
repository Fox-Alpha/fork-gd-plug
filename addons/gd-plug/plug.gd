@tool
extends SceneTree

#region Signals
signal updated(plugin: Dictionary)
#endregion

#region Constants
const VERSION: String = "0.2.6"
const DEFAULT_PLUGIN_URL: String = "https://git::@github.com/%s.git"
const DEFAULT_PLUG_DIR: String = "res://.plugged"
const DEFAULT_CONFIG_PATH: String = DEFAULT_PLUG_DIR + "/index.cfg"
const DEFAULT_USER_PLUG_SCRIPT_PATH: String = "res://plug.gd"
const DEFAULT_BASE_PLUG_SCRIPT_PATH: String = "res://addons/gd-plug/plug.gd"
const ENV_PRODUCTION: String = "production"
const ENV_TEST: String = "test"
const ENV_FORCE: String = "force"
const ENV_KEEP_IMPORT_FILE: String = "keep_import_file"
const ENV_KEEP_IMPORT_RESOURCE_FILE: String = "keep_import_resource_file"
# Quelle für den Befehl "upgrade": eigener Fork statt imjp94/gd-plug, damit die Änderungen des Forks erhalten bleiben
const DEFAULT_UPGRADE_REPO: String = "Fox-Alpha/fork-gd-plug"
const DEFAULT_UPGRADE_BRANCH: String = "development"
# Umgebungsvariablen zum Überschreiben von Repo und Branch beim Aufruf von "upgrade"
const ENV_UPGRADE_REPO: String = "GD_PLUG_UPGRADE_REPO"
const ENV_UPGRADE_BRANCH: String = "GD_PLUG_UPGRADE_BRANCH"
const MSG_PLUG_START_ASSERTION: String = "_plug_start() must be called first"
const INIT_PLUG_SCRIPT: String = """extends "res://addons/gd-plug/plug.gd"

func _plugging():
	# Declare plugins with plug(repo, args)
	# For example, clone from github repo("user/repo_name")
	# plug("imjp94/gd-YAFSM") # By default, gd-plug will only install anything from "addons/" directory
	# Or you can explicitly specify which file/directory to include
	# plug("imjp94/gd-YAFSM", {"include": ["addons/"]}) # By default, gd-plug will only install anything from "addons/" directory
	pass
"""
#endregion

#region Public Vars
var project_dir: DirAccess
var installation_config := ConfigFile.new()
var logger := _Logger.new()
var threadpool := _ThreadPool.new(logger)
#endregion

#region Private Vars
# Plugins aus .plugged/index.cfg, Schlüssel ist der Name des Plugins
var _installed_plugins: Dictionary = { }
# Plugins aus plug.gd des Projekts, Schlüssel ist der Name des Plugins
var _plugged_plugins: Dictionary = { }
# Ersetzt die frühere Prüfung von _installed_plugins auf null
var _is_plug_started: bool = false
var _mutex := Mutex.new()
var _start_time: int = 0
#endregion


#region Lifecycle
func _init() -> void:
	threadpool.all_thread_finished.connect(request_quit)
	project_dir = DirAccess.open("res://")


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	# Trim unwanted args passed to godot executable
	for arg in Array(args):
		args.remove_at(0)
		if "plug.gd" in arg:
			break

	var help: bool = false
	var help_config: bool = false
	for arg in args:
		# NOTE: "--key" or "-key" will always be consumed by godot executable,
		# see https://github.com/godotengine/godot/issues/8721
		var key: String = arg.to_lower()
		match key:
			"help":
				help = true
			"help-config":
				help_config = true
			"detail":
				logger.log_format = _Logger.DEFAULT_LOG_FORMAT_DETAIL
			"debug", "d":
				logger.log_level = _Logger.LogLevel.DEBUG
			"quiet", "q", "silent":
				logger.log_level = _Logger.LogLevel.NONE
			"production":
				OS.set_environment(ENV_PRODUCTION, "true")
			"test":
				OS.set_environment(ENV_TEST, "true")
			"force":
				OS.set_environment(ENV_FORCE, "true")
			"keep-import-file":
				OS.set_environment(ENV_KEEP_IMPORT_FILE, "true")
			"keep-import-resource-file":
				OS.set_environment(ENV_KEEP_IMPORT_RESOURCE_FILE, "true")

	logger.debug("cmdline_args: %s" % args)
	_start_time = Time.get_ticks_msec()
	_plug_start()
	if help_config:
		show_config_syntax()
	elif help or args.is_empty():
		show_syntax()
	else:
		_plugging()
		match args[0]:
			"init":
				_plug_init()
			"install", "update":
				_plug_install()
			"uninstall":
				_plug_uninstall()
			"clean":
				_plug_clean()
			"upgrade":
				_plug_upgrade()
			"status":
				_plug_status()
			"version":
				logger.info(VERSION)
			_:
				logger.error("Unknown command %s" % args[0])
				show_syntax()
	# NOTE: Do no put anything after this line except request_quit(), as _plug_*() may call request_quit()
	request_quit()


func _process(delta: float) -> bool:
	threadpool.process(delta)
	return false # Must return false, unless we are terminating.


func _finalize() -> void:
	_plug_end()
	threadpool.stop()
	logger.info("Finished, elapsed %.3fs" % ((Time.get_ticks_msec() - _start_time) / 1000.0))
#endregion


#region Public Funcs
func _plugging() -> void:
	pass


func _on_updated(_plugin: Dictionary) -> void:
	pass


func show_syntax() -> void:
	logger.info("gd-plug - Minimal plugin manager for Godot")
	logger.info("")
	logger.info("Usage: godot --headless -s plug.gd action [options...]")
	logger.info("")
	logger.info("Actions:")
	var actions: Dictionary[String, String] = {
		"init": "Initialize current project by creating plug.gd at root",
		"status": (
			"Check the status of plugins(installed, added or removed), " + "execute this command whenever in doubts"
		),
		"install(alias update)": "Install or update plugins based on plug.gd",
		"uninstall": "Uninstall all plugins, regardless of plug.gd",
		"clean": "Clean unused files/folders from /.plugged",
		"upgrade": (
			"Upgrade addons/gd-plug/plug.gd to the latest version of the fork "
			+ "(GD_PLUG_UPGRADE_REPO, GD_PLUG_UPGRADE_BRANCH)"
		),
		"version": "Print current version of gd-plug",
	}
	_log_table(actions)

	logger.info("")
	logger.info("Options:")
	var options: Dictionary[String, String] = {
		"production": "Install only plugins not marked as dev, or uninstall already installed dev plugins",
		"test": "Testing mode, no files will actually be installed/uninstalled",
		"force": (
			"Force gd-plug to overwrite destination files when running install command. "
			+ "*WARNING: Check README for more details*"
		),
		"keep-import-file": "Keep \".import\" files generated by plugin, when run uninstall command",
		"keep-import-resource-file": (
			"Keep files located in \".import\" that generated by plugin, when run uninstall command"
		),
		"debug(alias d)": "Print debug message",
		"detail": "Print with datetime and log level, \"[{time}] [{level}] {msg}\"",
		"quiet(alias q, silent)": "Disable logging",
		"help": "Show this help",
		"help-config": "plug.gd configuration documentation",
	}
	_log_table(options)
	logger.info("")


func show_config_syntax() -> void:
	logger.info("Configs: plug(src, args={})")
	logger.info("")
	logger.info("Sources:")
	logger.indent()
	logger.info("Github repo: \"username/repo\", for example, \"imjp94/gd-plug\"")
	logger.info("or")
	logger.info("Any valid git url, for example, \"git@github.com:username/repo.git\"")
	logger.dedent()
	logger.info("")
	logger.info("Arguments:")
	var arguments: Dictionary[String, String] = {
		"include": (
			"Array of strings that define what files or directory to include. "
			+ "Only \"addons/\" will be included if omitted"
		),
		"exclude": "Array of strings that define what files or directory to exclude",
		"branch": "Name of branch to freeze to",
		"tag": "Name of tag to freeze to",
		"commit": (
			"Commit hash string to freeze to, must be full length 40 digits commit-hash, "
			+ "for example, 7a642f90d3fb88976dd913051de994e58e838d1a"
		),
		"dev": (
			"Boolean to mark the plugin as dev or not, "
			+ "plugin marked as dev will not be installed when production command given"
		),
		"on_updated": (
			"Post update hook, a function name declared in plug.gd "
			+ "that will be called whenever the plugin installed/updated"
		),
		"install_root": "Destination directory where included files will be installed",
		"strip_prefix": (
			"Path prefix to strip from included source paths before copying to install_root. "
			+ "If omitted and install_root is set with a single included directory (other than addons/ or .), "
			+ "that directory is stripped automatically. Trailing / is added automatically if missing"
		),
	}
	_log_table(arguments)
	logger.info("")


func request_quit(exit_code: int = -1) -> bool:
	if threadpool.is_all_thread_finished() and threadpool.is_all_task_finished():
		# Ohne ausdrücklichen Code: 1, sobald ein Fehler gemeldet wurde, sonst 0
		if exit_code == -1:
			exit_code = 1 if logger.error_count > 0 else 0
		quit(exit_code)
		return true
	logger.debug("Request quit declined, threadpool is still running")
	return false


# Index & validate plugin
func plug(repo: String, args: Dictionary = { }) -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	repo = repo.strip_edges()
	var plugin_name: String = get_plugin_name_from_repo(repo)
	if plugin_name in _plugged_plugins:
		logger.info("Plugin already plugged: %s" % plugin_name)
		return
	var plugin: Dictionary = { }
	plugin.name = plugin_name
	plugin.url = ""
	if ":" in repo:
		plugin.url = repo
	elif repo.find("/") == repo.rfind("/"):
		plugin.url = DEFAULT_PLUGIN_URL % repo
	else:
		logger.error("Invalid repo: %s" % repo)
	plugin.plug_dir = DEFAULT_PLUG_DIR + "/" + plugin_name

	var is_valid: bool = true
	plugin.include = args.get("include", [])
	is_valid = is_valid and validate_var_type(plugin, "include", TYPE_ARRAY, "Array")
	plugin.exclude = args.get("exclude", [])
	is_valid = is_valid and validate_var_type(plugin, "exclude", TYPE_ARRAY, "Array")
	plugin.branch = args.get("branch", "")
	is_valid = is_valid and validate_var_type(plugin, "branch", TYPE_STRING, "String")
	plugin.tag = args.get("tag", "")
	is_valid = is_valid and validate_var_type(plugin, "tag", TYPE_STRING, "String")
	plugin.commit = args.get("commit", "")
	is_valid = is_valid and validate_var_type(plugin, "commit", TYPE_STRING, "String")
	if is_valid and not (plugin.commit as String).is_empty():
		var is_valid_commit: bool = (plugin.commit as String).length() == 40
		if not is_valid_commit:
			logger.error("Expected full length 40 digits commit-hash string, given %s" % plugin.commit)
		is_valid = is_valid_commit
	plugin.dev = args.get("dev", false)
	is_valid = is_valid and validate_var_type(plugin, "dev", TYPE_BOOL, "Boolean")
	plugin.on_updated = args.get("on_updated", "")
	is_valid = is_valid and validate_var_type(plugin, "on_updated", TYPE_STRING, "String")
	plugin.install_root = args.get("install_root", "")
	is_valid = is_valid and validate_var_type(plugin, "install_root", TYPE_STRING, "String")
	plugin.strip_prefix = args.get("strip_prefix", "")
	is_valid = is_valid and validate_var_type(plugin, "strip_prefix", TYPE_STRING, "String")

	if is_valid:
		_plugged_plugins[plugin_name] = plugin
		logger.debug("Plug: %s" % plugin)
	else:
		logger.error("Failed to plug %s, validation error" % plugin_name)


func install_plugin(plugin: Dictionary) -> void:
	var can_install: bool = not plugin.dev or not _is_env_set(ENV_PRODUCTION)
	if not can_install:
		return

	logger.info("Installing plugin %s..." % plugin.name)
	var result: int = is_plugin_downloaded(plugin)
	if result != OK:
		result = download(plugin)
	else:
		logger.info("Plugin already downloaded")

	if result == OK:
		install(plugin)
	else:
		logger.error("Failed to install plugin %s with error code %d" % [plugin.name, result])


func uninstall_plugin(plugin: Dictionary) -> void:
	logger.info("Uninstalling plugin %s..." % plugin.name)
	uninstall(plugin)
	directory_delete_recursively(plugin.plug_dir, { "exclude": [DEFAULT_CONFIG_PATH], "test": _is_env_set(ENV_TEST) })


func update_plugin(plugin: Dictionary, checking: bool = false) -> void:
	if not (plugin.name in _installed_plugins):
		logger.info("%s new plugin" % plugin.name)
		return

	var git := _GitExecutable.new(ProjectSettings.globalize_path(plugin.plug_dir), logger)
	var installed_plugin: Dictionary = get_installed_plugin(plugin.name)
	var changes: Array[String] = compare_plugins(plugin, installed_plugin)
	var branch: String = plugin.branch
	var should_clone: bool = false
	var should_pull: bool = false

	if plugin.tag or plugin.commit:
		for rev: String in ["tag", "commit"]:
			var freeze_at: String = plugin[rev]
			if not freeze_at.is_empty():
				logger.info("%s frozen at %s \"%s\"" % [plugin.name, rev, freeze_at])
				break
	else:
		var ahead_behind: Array[int] = []
		if git.fetch("origin " + branch if branch else "origin").exit == OK:
			ahead_behind = git.get_commit_comparison("HEAD", "origin/" + branch if branch else "origin")
		var is_commit_behind: bool = ahead_behind.size() == 2 and ahead_behind[1] > 0
		if is_commit_behind:
			logger.info("%s %d commits behind, update required" % [plugin.name, ahead_behind[1]])
			should_pull = true
		else:
			logger.info("%s up to date" % plugin.name)

	var should_reinstall: bool = not changes.is_empty()
	if should_reinstall:
		logger.info("%s changed %s" % [plugin.name, changes])
		if "url" in changes or "branch" in changes or "tag" in changes or "commit" in changes:
			logger.info("%s repository setting changed, update required" % plugin.name)
			should_clone = true

	if checking:
		return

	if should_clone:
		logger.info("%s cloning from %s..." % [plugin.name, plugin.url])
		uninstall(get_installed_plugin(plugin.name))
		directory_delete_recursively(
			plugin.plug_dir,
			{ "exclude": [DEFAULT_CONFIG_PATH], "test": _is_env_set(ENV_TEST) },
		)
		if download(plugin) == OK:
			install(plugin)
	elif should_pull:
		logger.info("%s pulling updates from %s..." % [plugin.name, plugin.url])
		uninstall(get_installed_plugin(plugin.name))
		if git.pull().exit == OK:
			install(plugin)
	elif should_reinstall:
		logger.info("%s reinstalling..." % plugin.name)
		uninstall(get_installed_plugin(plugin.name))
		install(plugin)


func check_plugin(plugin: Dictionary) -> void:
	update_plugin(plugin, true)


func download(plugin: Dictionary) -> int:
	logger.info("Downloading %s from %s..." % [plugin.name, plugin.url])
	var global_dest_dir: String = ProjectSettings.globalize_path(plugin.plug_dir)
	if project_dir.dir_exists(plugin.plug_dir):
		directory_delete_recursively(plugin.plug_dir)
	project_dir.make_dir(plugin.plug_dir)
	var result: Dictionary = _GitExecutable.new(global_dest_dir, logger).clone(
		plugin.url,
		global_dest_dir,
		{ "branch": plugin.branch, "tag": plugin.tag, "commit": plugin.commit },
	)
	if result.exit == OK:
		logger.info("Successfully download %s" % plugin.name)
	else:
		logger.info("Failed to download %s" % plugin.name)
		# Make sure plug_dir is clean when failed
		directory_delete_recursively(
			plugin.plug_dir,
			{ "exclude": [DEFAULT_CONFIG_PATH], "test": _is_env_set(ENV_TEST) },
		)
	project_dir.remove(plugin.plug_dir) # Remove empty directory
	return result.exit


func install(plugin: Dictionary) -> Error:
	var include: Array = plugin.get("include", [])
	if include.is_empty(): # Auto include "addons/" folder if not explicitly specified
		include = ["addons/"]

	var install_root: String = plugin.install_root
	var strip_prefix: String = plugin.get("strip_prefix", "")
	# Auto strip included directory into install_root when install_root is set
	# and a single non-default directory is included
	if strip_prefix.is_empty() and not install_root.is_empty() and include.size() == 1:
		var include_path: String = include[0]
		if include_path != "." and include_path != "addons/" and not include_path.is_empty():
			if project_dir.dir_exists(plugin.plug_dir + "/" + include_path):
				strip_prefix = include_path
	if not strip_prefix.is_empty() and not strip_prefix.ends_with("/"):
		strip_prefix += "/"

	var copy_args: Dictionary = {
		"include": include,
		"exclude": plugin.exclude,
		"strip_prefix": strip_prefix,
		"root_from": plugin.plug_dir,
	}
	if not _is_env_set(ENV_FORCE) and not _is_env_set(ENV_TEST):
		var is_exists: bool = false
		var test_args: Dictionary = copy_args.duplicate()
		test_args["test"] = true
		test_args["silent_test"] = true
		for dest_file in directory_copy_recursively(plugin.plug_dir, "res://" + install_root, test_args):
			if project_dir.file_exists(dest_file):
				logger.warn("%s attempting to overwrite file %s" % [plugin.name, dest_file])
				is_exists = true
		if is_exists:
			logger.warn(
				"Installation of %s terminated to avoid overwriting user files, " % plugin.name
				+ "you may disable safe mode with command \"force\""
			)
			return ERR_ALREADY_EXISTS

	logger.info("Installing files for %s..." % plugin.name)
	var run_args: Dictionary = copy_args.duplicate()
	run_args["test"] = _is_env_set(ENV_TEST)
	var dest_files: Array = directory_copy_recursively(plugin.plug_dir, "res://" + install_root, run_args)
	plugin.dest_files = dest_files
	logger.info("Installed %d file%s for %s" % [dest_files.size(), _plural_s(dest_files.size()), plugin.name])
	if plugin.name != "gd-plug":
		set_installed_plugin(plugin)

	logger.debug("Execute \"_on_updated\" function for %s" % plugin.name)
	_on_updated(plugin.duplicate())
	var on_updated: String = plugin.on_updated
	if not on_updated.is_empty() and has_method(on_updated):
		logger.debug("Execute post-update function \"%s\" for %s" % [on_updated, plugin.name])
		call(on_updated, plugin.duplicate())
	logger.debug("Emit \"updated\" signal for %s" % plugin.name)
	updated.emit(plugin.duplicate())
	return OK


func uninstall(plugin: Dictionary) -> void:
	# Array aus index.cfg, deshalb untypisiert
	var dest_files: Array = plugin.get("dest_files", [])
	var count: int = dest_files.size()
	logger.info("Uninstalling %d file%s for %s..." % [count, _plural_s(count), plugin.name])
	directory_remove_batch(
		dest_files,
		{
			"test": _is_env_set(ENV_TEST),
			"keep_import_file": _is_env_set(ENV_KEEP_IMPORT_FILE),
			"keep_import_resource_file": _is_env_set(ENV_KEEP_IMPORT_RESOURCE_FILE),
		},
	)
	logger.info("Uninstalled %d file%s for %s" % [count, _plural_s(count), plugin.name])
	remove_installed_plugin(plugin.name)


func is_plugin_downloaded(plugin: Dictionary) -> int:
	if not project_dir.dir_exists(plugin.plug_dir + "/.git"):
		return ERR_DOES_NOT_EXIST

	var git := _GitExecutable.new(ProjectSettings.globalize_path(plugin.plug_dir), logger)
	return git.is_up_to_date(plugin)


# Get installed plugin, thread safe
func get_installed_plugin(plugin_name: String) -> Dictionary:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	_mutex.lock()
	var installed_plugin: Dictionary = _installed_plugins[plugin_name]
	_mutex.unlock()
	return installed_plugin


# Set installed plugin, thread safe
func set_installed_plugin(plugin: Dictionary) -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	_mutex.lock()
	_installed_plugins[plugin.name] = plugin
	_mutex.unlock()


# Remove installed plugin, thread safe
func remove_installed_plugin(plugin_name: String) -> bool:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	_mutex.lock()
	var result: bool = _installed_plugins.erase(plugin_name)
	_mutex.unlock()
	return result


func directory_copy_recursively(from: String, to: String, args: Dictionary = { }) -> Array:
	var include: Array = args.get("include", [])
	var exclude: Array = args.get("exclude", [])
	var test: bool = args.get("test", false)
	var silent_test: bool = args.get("silent_test", false)
	var strip_prefix: String = args.get("strip_prefix", "")
	var root_from: String = args.get("root_from", from)
	# Untypisiert, weil die Liste als dest_files in index.cfg landet
	var dest_files: Array = []
	var dir := DirAccess.open(from)
	if dir == null:
		logger.error("Failed to access path: %s" % from)
		return dest_files

	dir.include_hidden = true
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var source: String = _join_path(dir.get_current_dir(), file_name)
		var relative_to_root: String = source.trim_prefix(root_from).trim_prefix("/")

		var dest: String
		if strip_prefix.is_empty():
			dest = _join_path(to, file_name)
		elif dir.current_is_dir():
			var dir_prefix: String = relative_to_root + "/" if not relative_to_root.is_empty() else ""
			if strip_prefix.begins_with(dir_prefix) or dir_prefix.begins_with(strip_prefix):
				dest = to
			else:
				dest = _join_path(to, file_name)
		else:
			dest = _join_path(to, relative_to_root.trim_prefix(strip_prefix))

		if dir.current_is_dir():
			dest_files.append_array(directory_copy_recursively(source, dest, args))
		elif _matches_any(source, include) and not _matches_any(source, exclude):
			if test:
				if not silent_test:
					logger.warn("[TEST] Writing to %s" % dest)
			else:
				dir.make_dir_recursive(dest.get_base_dir())
				if dir.copy(source, dest) == OK:
					logger.debug("Copy from %s to %s" % [source, dest])
			dest_files.append(dest)
		file_name = dir.get_next()
	dir.list_dir_end()
	return dest_files


func directory_delete_recursively(dir_path: String, args: Dictionary = { }) -> DirAccess:
	var remove_empty_directory: bool = args.get("remove_empty_directory", true)
	var exclude: Array = args.get("exclude", [])
	var test: bool = args.get("test", false)
	var silent_test: bool = args.get("silent_test", false)
	var dir := DirAccess.open(dir_path)
	if dir == null:
		logger.error("Failed to access path: %s" % dir_path)
		return null

	dir.include_hidden = true
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var source: String = _join_path(dir.get_current_dir(), file_name)
		if dir.current_is_dir():
			directory_delete_recursively(source, args)
			if remove_empty_directory:
				if test:
					if not silent_test:
						logger.warn("[TEST] Remove empty directory: %s" % source)
				elif source.get_file() == ".git":
					# Hacks to remove .git, as git pack files stop it from being removed
					# See https://stackoverflow.com/questions/1213430/how-to-fully-delete-a-git-repository-created-with-init
					if _remove_directory_by_shell(source) == OK:
						logger.debug("Remove empty directory: %s" % source)
					else:
						logger.debug("Failed to remove empty directory: %s" % source)
				elif dir.remove(source) == OK:
					logger.debug("Remove empty directory: %s" % source)
		else:
			# Umgekehrte Richtung als beim Kopieren: exclude enthält hier vollständige Pfade
			var excluded: bool = exclude.any(
				func(exclude_key: String) -> bool:
					return source in exclude_key,
			)
			if not excluded:
				if test:
					if not silent_test:
						logger.warn("[TEST] Remove file: %s" % source)
				elif dir.remove(file_name) == OK:
					logger.debug("Remove file: %s" % source)
		file_name = dir.get_next()
	dir.list_dir_end()

	if remove_empty_directory:
		dir.remove(dir.get_current_dir())

	return dir


func directory_remove_batch(files: Array, args: Dictionary = { }) -> void:
	var keep_import_file: bool = args.get("keep_import_file", false)
	var keep_import_resource_file: bool = args.get("keep_import_resource_file", false)
	var test: bool = args.get("test", false)
	var silent_test: bool = args.get("silent_test", false)
	var dirs: Dictionary[String, DirAccess] = { }
	for file: String in files:
		var file_dir: String = file.get_base_dir()
		var dir: DirAccess = dirs.get(file_dir)
		if dir == null:
			dir = DirAccess.open(file_dir)
			if dir == null:
				logger.warn("Failed to access path: %s" % file_dir)
				continue
			dirs[file_dir] = dir

		if file.ends_with(".import"):
			if not keep_import_file:
				_remove_import_file(dir, file, keep_import_resource_file, test, silent_test)
		else:
			if test:
				if not silent_test:
					logger.warn("[TEST] Remove file: " + file)
			elif dir.remove(file.get_file()) == OK:
				logger.debug("Remove file: " + file)
			if not keep_import_file:
				_remove_import_file(dir, file + ".import", keep_import_resource_file, test, silent_test)

	for dir: DirAccess in dirs.values():
		var current_dir: String = dir.get_current_dir()
		var slash_count: int = current_dir.count("/") - 2 # Deduct 2 slash from "res://"
		if test:
			if not silent_test:
				logger.warn("[TEST] Remove empty directory: %s" % current_dir)
		elif dir.remove(current_dir) == OK:
			logger.debug("Remove empty directory: %s" % current_dir)
		# Dumb method to clean empty ancestor directories
		logger.debug("Removing empty ancestor directory for %s..." % current_dir)
		for i in slash_count:
			current_dir = current_dir.get_base_dir()
			var ancestor := DirAccess.open(current_dir)
			if ancestor == null:
				continue
			if test:
				if not silent_test:
					logger.warn("[TEST] Remove empty ancestor directory: %s" % ancestor.get_current_dir())
			elif ancestor.remove(ancestor.get_current_dir()) == OK:
				logger.debug("Remove empty ancestor directory: %s" % ancestor.get_current_dir())


func compare_plugins(p1: Dictionary, p2: Dictionary) -> Array[String]:
	var changed_keys: Array[String] = []
	for key: String in p1.keys():
		# Index älterer Versionen kennt neue Optionen nicht, fehlende Schlüssel zählen als Änderung
		if p1[key] != p2.get(key):
			changed_keys.append(key)
	return changed_keys


func get_plugin_name_from_repo(repo: String) -> String:
	return repo.replace(".git", "").trim_suffix("/").get_file()


func validate_var_type(obj: Dictionary, var_name: String, type: Variant.Type, type_string: String) -> bool:
	var value: Variant = obj.get(var_name)
	var is_valid: bool = typeof(value) == type
	if not is_valid:
		logger.error("Expected variable \"%s\" to be %s, given %s" % [var_name, type_string, value])
	return is_valid
#endregion


#region Private Funcs
# Index installed plugins, or create directory "plugged" if not exists
func _plug_start() -> void:
	logger.debug("Plug start")
	if not project_dir.dir_exists(DEFAULT_PLUG_DIR):
		if project_dir.make_dir(ProjectSettings.globalize_path(DEFAULT_PLUG_DIR)) == OK:
			logger.debug("Make dir %s for plugin installation" % DEFAULT_PLUG_DIR)
	if installation_config.load(DEFAULT_CONFIG_PATH) == OK:
		logger.debug("Installation config loaded")
	else:
		logger.debug("Installation config not found")
	_installed_plugins = installation_config.get_value("plugin", "installed", { })
	_is_plug_started = true


# Install plugin or uninstall plugin if unlisted
func _plug_end() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	if not _is_env_set(ENV_TEST):
		installation_config.set_value("plugin", "installed", _installed_plugins)
		if installation_config.save(DEFAULT_CONFIG_PATH) == OK:
			logger.debug("Plugged config saved")
		else:
			logger.error("Failed to save plugged config")
	else:
		logger.warn("Skipped saving of plugged config in test mode")
	_is_plug_started = false


func _plug_init() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	logger.info("Init gd-plug...")
	if FileAccess.file_exists(DEFAULT_USER_PLUG_SCRIPT_PATH):
		logger.warn("%s already exists!" % DEFAULT_USER_PLUG_SCRIPT_PATH)
		return

	var file := FileAccess.open(DEFAULT_USER_PLUG_SCRIPT_PATH, FileAccess.WRITE)
	file.store_string(INIT_PLUG_SCRIPT)
	file.close()
	logger.info("Created %s" % DEFAULT_USER_PLUG_SCRIPT_PATH)


func _plug_install() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	logger.info("Installing...")
	for plugin: Dictionary in _plugged_plugins.values():
		if plugin.name in _installed_plugins:
			var installed_plugin: Dictionary = get_installed_plugin(plugin.name)
			if (installed_plugin.dev or plugin.dev) and _is_env_set(ENV_PRODUCTION):
				logger.info("Remove dev plugin for production: %s" % plugin.name)
				threadpool.enqueue_task(uninstall_plugin.bind(installed_plugin))
			else:
				threadpool.enqueue_task(update_plugin.bind(plugin))
		else:
			threadpool.enqueue_task(install_plugin.bind(plugin))

	var removed_plugins: Array[Dictionary] = []
	for plugin: Dictionary in _installed_plugins.values():
		if not (plugin.name in _plugged_plugins):
			removed_plugins.append(plugin)
	if not removed_plugins.is_empty():
		threadpool.all_thread_finished.disconnect(request_quit)
		if not threadpool.is_all_thread_finished():
			threadpool.active = true
			await threadpool.all_thread_finished
			threadpool.active = false
			logger.debug("All installation finished! Ready to uninstall removed plugins...")
		threadpool.all_thread_finished.connect(request_quit)
		for plugin in removed_plugins:
			threadpool.enqueue_task(uninstall_plugin.bind(plugin), Thread.PRIORITY_LOW)
	threadpool.active = true


func _plug_uninstall() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	logger.info("Uninstalling...")
	for plugin: Dictionary in _installed_plugins.values():
		var installed_plugin: Dictionary = get_installed_plugin(plugin.name)
		threadpool.enqueue_task(uninstall_plugin.bind(installed_plugin), Thread.PRIORITY_LOW)
	threadpool.active = true


func _plug_clean() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	logger.info("Cleaning...")
	for dir_name in _get_orphan_dirs():
		logger.info("Remove %s" % dir_name)
		threadpool.enqueue_task(directory_delete_recursively.bind(DEFAULT_PLUG_DIR + "/" + dir_name))
	threadpool.active = true


func _plug_upgrade() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	var upgrade_repo: String = OS.get_environment(ENV_UPGRADE_REPO).strip_edges()
	if upgrade_repo.is_empty():
		upgrade_repo = DEFAULT_UPGRADE_REPO
	var upgrade_branch: String = OS.get_environment(ENV_UPGRADE_BRANCH).strip_edges()
	if upgrade_branch.is_empty():
		upgrade_branch = DEFAULT_UPGRADE_BRANCH
	logger.info("Upgrading gd-plug from %s (branch %s)..." % [upgrade_repo, upgrade_branch])
	plug(upgrade_repo, { "branch": upgrade_branch })
	# Name aus dem Repo ableiten, beim Fork ist das "fork-gd-plug" statt "gd-plug"
	var gd_plug: Dictionary = _plugged_plugins.get(get_plugin_name_from_repo(upgrade_repo), { })
	if gd_plug.is_empty():
		logger.error("Failed to plug %s, upgrade aborted" % upgrade_repo)
		return
	# Stand gd-plug schon vorher im Index (über die plug.gd des Projekts), bleibt der Eintrag erhalten
	var keep_in_index: bool = gd_plug.name in _installed_plugins
	OS.set_environment(ENV_FORCE, "true") # Required to overwrite res://addons/gd-plug/plug.gd
	threadpool.enqueue_task(install_plugin.bind(gd_plug))
	threadpool.all_thread_finished.disconnect(request_quit)
	# Bei inaktivem Pool ist die Installation nur eingereiht, noch kein Thread läuft.
	# Ohne Prüfung der Warteschlange liefe das Löschen von plug_dir parallel zum Klonen.
	if not (threadpool.is_all_thread_finished() and threadpool.is_all_task_finished()):
		threadpool.active = true
		await threadpool.all_thread_finished
		threadpool.active = false
		logger.debug("All installation finished! Ready to uninstall removed plugins...")
	# Sonst stünde gd-plug in index.cfg und das nächste "install" würde es als entfernt deinstallieren
	if not keep_in_index:
		_installed_plugins.erase(gd_plug.name)
	threadpool.all_thread_finished.connect(request_quit)
	threadpool.enqueue_task(directory_delete_recursively.bind(gd_plug.plug_dir))
	threadpool.active = true


func _plug_status() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	var installed_count: int = _installed_plugins.size()
	logger.info("Installed %d plugin%s" % [installed_count, _plural_s(installed_count)])
	var new_plugins: Dictionary = _plugged_plugins.duplicate()
	var has_checking_plugin: bool = false
	var removed_plugins: Array[Dictionary] = []
	for plugin: Dictionary in _installed_plugins.values():
		logger.info("- {name} - {url}".format(plugin))
		new_plugins.erase(plugin.name)
		if not (plugin.name in _plugged_plugins):
			removed_plugins.append(plugin)
		else:
			threadpool.enqueue_task(check_plugin.bind(_plugged_plugins[plugin.name]))
			has_checking_plugin = true
	if has_checking_plugin:
		logger.info("\n", true)
		threadpool.all_thread_finished.disconnect(request_quit)
		threadpool.active = true
		await threadpool.all_thread_finished
		threadpool.active = false
		threadpool.all_thread_finished.connect(request_quit)
		logger.debug("Finished checking plugins, ready to proceed")
	if not new_plugins.is_empty():
		logger.info("\nPlugged %d plugin%s" % [new_plugins.size(), _plural_s(new_plugins.size())])
		for plugin: Dictionary in new_plugins.values():
			if not (plugin.name in _installed_plugins):
				logger.info("- {name} - {url}".format(plugin))
	if not removed_plugins.is_empty():
		logger.info("\nUnplugged %d plugin%s" % [removed_plugins.size(), _plural_s(removed_plugins.size())])
		for plugin in removed_plugins:
			logger.info("- %s removed" % plugin.name)
	var orphan_dirs: Array[String] = _get_orphan_dirs()
	if not orphan_dirs.is_empty():
		logger.info(
			"\nOrphan directory, %d found in %s, execute \"clean\" command to remove"
			% [orphan_dirs.size(), DEFAULT_PLUG_DIR]
		)
		for dir_name in orphan_dirs:
			logger.info("- %s" % dir_name)
	threadpool.active = true

	if has_checking_plugin:
		request_quit()


# Verzeichnisse in .plugged, die zu keinem installierten Plugin gehören
func _get_orphan_dirs() -> Array[String]:
	var orphan_dirs: Array[String] = []
	var plugged_dir := DirAccess.open(DEFAULT_PLUG_DIR)
	if plugged_dir == null:
		return orphan_dirs
	plugged_dir.include_hidden = true
	plugged_dir.list_dir_begin()
	var file_name: String = plugged_dir.get_next()
	while not file_name.is_empty():
		if plugged_dir.current_is_dir() and not (file_name in _installed_plugins):
			orphan_dirs.append(file_name)
		file_name = plugged_dir.get_next()
	plugged_dir.list_dir_end()
	return orphan_dirs


func _remove_import_file(
	dir: DirAccess,
	file: String,
	keep_import_resource_file: bool = false,
	test: bool = false,
	silent_test: bool = false,
) -> void:
	if not dir.file_exists(file):
		return

	if not keep_import_resource_file:
		var import_config := ConfigFile.new()
		if import_config.load(file) == OK:
			var metadata: Dictionary = import_config.get_value("remap", "metadata", { })
			var imported_formats: Array = metadata.get("imported_formats", [])
			if not imported_formats.is_empty():
				for format: String in imported_formats:
					_remove_import_resource_file(dir, import_config, "." + format, test)
			else:
				_remove_import_resource_file(dir, import_config, "", test)
	if test:
		if not silent_test:
			logger.warn("[TEST] Remove import file: " + file)
	elif dir.remove(file) == OK:
		logger.debug("Remove import file: " + file)
	else:
		# TODO: Sometimes Directory.remove() unable to remove random .import file
		# and return error code 1(Generic Error). Maybe enforce the removal from shell?
		logger.warn("Failed to remove import file: " + file)


func _remove_import_resource_file(
	dir: DirAccess,
	import_config: ConfigFile,
	import_format: String = "",
	test: bool = false,
) -> void:
	var import_resource_file: String = import_config.get_value("remap", "path" + import_format, "")
	if import_resource_file.is_empty():
		return

	if dir.file_exists(import_resource_file):
		if test:
			logger.info("[IMPORT] Remove import resource file: " + import_resource_file)
		elif dir.remove(import_resource_file) == OK:
			logger.debug("Remove import resource file: " + import_resource_file)
	var checksum_file: String = import_resource_file.get_basename() + ".md5"
	checksum_file = checksum_file.replace(import_format, "")
	if dir.file_exists(checksum_file):
		if test:
			logger.info("[IMPORT] Remove import checksum file: " + checksum_file)
		elif dir.remove(checksum_file) == OK:
			logger.debug("Remove import checksum file: " + checksum_file)


# Entfernt ein Verzeichnis über die Shell, nötig für .git mit schreibgeschützten Pack-Dateien
func _remove_directory_by_shell(path: String) -> int:
	var global_path: String = ProjectSettings.globalize_path(path)
	match OS.get_name():
		"Windows":
			var windows_path: String = "\"%s\"" % global_path.replace("/", "\\")
			return OS.execute("cmd", ["/C", "rd /s /q %s" % windows_path])
		"macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return OS.execute("bash", ["-c", "rm -rf '%s'" % global_path])
	return FAILED


func _is_env_set(env_name: String) -> bool:
	return not OS.get_environment(env_name).is_empty()


func _plural_s(count: int) -> String:
	return "s" if count > 1 else ""


func _join_path(base: String, file_name: String) -> String:
	return base + ("/" if base != "res://" else "") + file_name


# Wahr, wenn einer der Schlüssel als Teilstring im Pfad vorkommt
func _matches_any(path: String, keys: Array) -> bool:
	return keys.any(
		func(key: String) -> bool:
			return key in path,
	)


func _log_table(rows: Dictionary[String, String]) -> void:
	logger.indent()
	logger.table_start()
	for key in rows:
		logger.table_row([key, rows[key]])
	logger.table_end()
	logger.dedent()
#endregion


#region Inner Classes
class _GitExecutable extends RefCounted:
	var cwd: String = ""
	var logger: _Logger


	func _init(p_cwd: String, p_logger: _Logger) -> void:
		cwd = p_cwd
		logger = p_logger


	func _execute(command: String, output: Array = [], read_stderr: bool = false) -> int:
		var cmd: String = "cd '%s' && %s" % [cwd, command]
		# NOTE: OS.execute() seems to ignore read_stderr
		var exit: int = FAILED
		match OS.get_name():
			"Windows":
				cmd = cmd.replace("'", "\"") # cmd doesn't accept single-quotes
				cmd = cmd if read_stderr else "%s 2> nul" % cmd
				logger.debug("Execute \"%s\"" % cmd)
				exit = OS.execute("cmd", ["/C", cmd], output, read_stderr)
			"macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				cmd = cmd if read_stderr else "%s 2>/dev/null" % cmd
				logger.debug("Execute \"%s\"" % cmd)
				exit = OS.execute("bash", ["-c", cmd], output, read_stderr)
			var unhandled_os:
				logger.error("Unexpected OS: %s" % unhandled_os)
		logger.debug("Execution ended(code:%d): %s" % [exit, output])
		return exit


	func init() -> Dictionary:
		logger.debug("Initializing git at %s..." % cwd)
		return _run("git init", "Successfully init", "Failed to init")


	func clone(src: String, dest: String, args: Dictionary = { }) -> Dictionary:
		logger.debug("Cloning from %s to %s..." % [src, dest])
		var branch: String = args.get("branch", "")
		var tag: String = args.get("tag", "")
		var commit: String = args.get("commit", "")
		var command: String = "git clone --depth=1 --progress '%s' '%s'" % [src, dest]
		if branch or tag:
			command = "git clone --depth=1 --single-branch --branch %s '%s' '%s'" % [
				branch if branch else tag,
				src,
				dest,
			]
		elif commit:
			return clone_commit(src, dest, commit)
		return _run(command, "Successfully cloned from %s" % src, "Failed to clone from %s" % src)


	func clone_commit(src: String, dest: String, commit: String) -> Dictionary:
		if commit.length() < 40:
			logger.error("Expected full length 40 digits commit-hash to clone specific commit, given {%s}" % commit)
			return { "exit": FAILED, "output": [] }

		logger.debug("Cloning from %s to %s @ %s..." % [src, dest, commit])
		var result: Dictionary = init()
		if result.exit == OK:
			result = remote_add("origin", src)
			if result.exit == OK:
				result = fetch("%s %s" % ["origin", commit])
				if result.exit == OK:
					result = reset("--hard", "FETCH_HEAD")
		return result


	func fetch(rm: String = "--all") -> Dictionary:
		logger.debug("Fetching %s..." % rm.replace("--", ""))
		return _run("git fetch %s" % rm, "Successfully fetched", "Failed to fetch")


	func pull() -> Dictionary:
		logger.debug("Pulling...")
		return _run("git pull --rebase", "Successfully pulled", "Failed to pull")


	func remote_add(name: String, src: String) -> Dictionary:
		logger.debug("Adding remote %s@%s..." % [name, src])
		return _run("git remote add %s '%s'" % [name, src], "Successfully added remote", "Failed to add remote")


	func reset(mode: String, to: String) -> Dictionary:
		logger.debug("Resetting %s %s..." % [mode, to])
		return _run("git reset %s %s" % [mode, to], "Successfully reset", "Failed to reset")


	func get_commit_comparison(branch_a: String, branch_b: String) -> Array[int]:
		var ahead_behind: Array[int] = []
		var output: Array = []
		var exit: int = _execute("git rev-list --count --left-right %s...%s" % [branch_a, branch_b], output)
		# Ohne Erfolg gibt es keine Ausgabe, output[0] fehlt dann
		if exit != OK or output.is_empty():
			return ahead_behind
		for count in (output[0] as String).strip_edges().split("\t"):
			ahead_behind.append(count.to_int())
		return ahead_behind


	func get_current_branch() -> String:
		return _read_line("git rev-parse --abbrev-ref HEAD")


	func get_current_tag() -> String:
		return _read_line("git describe --tags --exact-match")


	func get_current_commit() -> String:
		# Voller Hash, plug() verlangt den Commit mit 40 Zeichen
		return _read_line("git rev-parse HEAD")


	func is_detached_head() -> bool:
		# symbolic-ref scheitert nur, wenn HEAD auf keinen Branch zeigt
		return _execute("git symbolic-ref -q HEAD") != OK


	func is_up_to_date(args: Dictionary = { }) -> int:
		if fetch().exit != OK:
			return FAILED

		var branch: String = args.get("branch", "")
		var tag: String = args.get("tag", "")
		var commit: String = args.get("commit", "")
		if branch:
			# Falscher Branch: neu klonen. Richtiger Branch: unten auf neue Commits prüfen
			if branch != get_current_branch() or is_detached_head():
				return FAILED
		elif tag:
			if tag == get_current_tag():
				return OK
		elif commit:
			if commit == get_current_commit():
				return OK

		var ahead_behind: Array[int] = get_commit_comparison("HEAD", "origin/" + branch if branch else "origin")
		var is_commit_behind: bool = ahead_behind.size() == 2 and ahead_behind[1] > 0
		return FAILED if is_commit_behind else OK


	# Führt einen Git-Befehl aus und liefert {"exit": int, "output": Array}
	func _run(command: String, success_msg: String, failure_msg: String) -> Dictionary:
		var output: Array = []
		var exit: int = _execute(command, output)
		logger.debug(success_msg if exit == OK else failure_msg)
		return { "exit": exit, "output": output }


	# Erste Zeile der Ausgabe ohne Zeilenumbruch, leer bei Fehler
	func _read_line(command: String) -> String:
		var output: Array = []
		var exit: int = _execute(command, output)
		if exit != OK or output.is_empty():
			return ""
		return (output[0] as String).strip_edges()


class _ThreadPool extends RefCounted:
	signal all_thread_finished()

	var active: bool = true
	var logger: _Logger

	# Feste Plätze je Prozessorkern, null für einen freien Platz
	var _threads: Array[Thread] = []
	var _finished_threads: Array[Thread] = []
	var _mutex := Mutex.new()
	# Aufgaben als {"callable": Callable, "priority": Thread.Priority}
	var _tasks: Array[Dictionary] = []


	func _init(p_logger: _Logger) -> void:
		logger = p_logger
		_threads.resize(OS.get_processor_count())


	func enqueue_task(callable: Callable, priority: Thread.Priority = Thread.PRIORITY_NORMAL) -> void:
		enqueue({ "callable": callable, "priority": priority })


	func enqueue(task: Dictionary) -> void:
		var can_execute: bool = false
		if active:
			can_execute = _execute_task(task)
		if not can_execute:
			_tasks.append(task)


	func process(_delta: float) -> void:
		if active:
			_flush_tasks()
			_flush_threads()


	func stop() -> void:
		_tasks.clear()
		_flush_threads()


	func is_all_thread_finished() -> bool:
		return _threads.all(
			func(thread: Thread) -> bool:
				return thread == null,
		)


	func is_all_task_finished() -> bool:
		return _tasks.is_empty()


	func _execute_task(task: Dictionary) -> bool:
		var thread: Thread = _get_thread()
		if thread == null:
			return false

		task.thread = weakref(thread)
		var callable: Callable = task.callable
		thread.start(_execute.bind(task), task.priority)
		logger.debug("Execute task %s.%s() " % [callable.get_object(), callable.get_method()])
		return true


	func _execute(task: Dictionary) -> void:
		var callable: Callable = task.callable
		callable.call()
		_mutex.lock()
		var thread: Thread = (task.thread as WeakRef).get_ref()
		_threads[_threads.find(thread)] = null
		_finished_threads.append(thread)
		var all_finished: bool = is_all_thread_finished()
		_mutex.unlock()

		logger.debug("Execution finished %s.%s() " % [callable.get_object(), callable.get_method()])
		if all_finished:
			logger.debug("All thread finished")
			all_thread_finished.emit()


	func _flush_tasks() -> void:
		while not _tasks.is_empty():
			if not _execute_task(_tasks.front()):
				return
			_tasks.pop_front()


	func _flush_threads() -> void:
		for i in _finished_threads.size():
			var thread: Thread = _finished_threads.pop_front()
			if not thread.is_alive():
				thread.wait_to_finish()


	func _get_thread() -> Thread:
		for i in OS.get_processor_count():
			var thread: Thread = _threads[i]
			if thread == null:
				thread = Thread.new()
				_threads[i] = thread
				return thread
			if not thread.is_started():
				return thread
		return null


class _Logger extends RefCounted:
	enum LogLevel {
		ALL,
		DEBUG,
		INFO,
		WARN,
		ERROR,
		NONE,
	}

	const DEFAULT_LOG_FORMAT_DETAIL: String = "[{time}] [{level}] {msg}"
	const DEFAULT_LOG_FORMAT_NORMAL: String = "{msg}"

	var log_level: LogLevel = LogLevel.INFO
	var log_format: String = DEFAULT_LOG_FORMAT_NORMAL
	var log_time_format: String = "{year}/{month}/{day} {hour}:{minute}:{second}"
	var indent_level: int = 0
	var is_locked: bool = false
	# Anzahl gemeldeter Fehler, bestimmt den Exit-Code von gd-plug
	var error_count: int = 0

	var _rows: Array[Array] = []
	var _is_table_started: bool = false
	var _max_column_length: Array[int] = []
	var _max_column_size: int = 0


	func debug(msg: Variant, raw: bool = false) -> void:
		_log(LogLevel.DEBUG, msg, raw)


	func info(msg: Variant, raw: bool = false) -> void:
		_log(LogLevel.INFO, msg, raw)


	func warn(msg: Variant, raw: bool = false) -> void:
		_log(LogLevel.WARN, msg, raw)


	func error(msg: Variant, raw: bool = false) -> void:
		error_count += 1
		_log(LogLevel.ERROR, msg, raw)


	func format_log(level: LogLevel, msg: String) -> String:
		return log_format.format(
			{
				"time": log_time_format.format(get_formatted_datatime()),
				"level": LogLevel.keys()[level],
				"msg": msg.indent("    ".repeat(indent_level)),
			},
		)


	func indent() -> void:
		indent_level += 1


	func dedent() -> void:
		indent_level = maxi(indent_level - 1, 0)


	func lock() -> void:
		is_locked = true


	func unlock() -> void:
		is_locked = false


	func table_start() -> void:
		_rows = []
		_is_table_started = true


	func table_end() -> void:
		assert(_is_table_started, "Expected table_start() to be called first")
		for columns in _rows:
			var text: String = ""
			for i in columns.size():
				var column: String = columns[i]
				var column_tabs: int = ceili(column.length() / 4.0)
				if i < _max_column_size - 1:
					# Auffüllen auf das nächste Vielfache von 4, dann Viererblöcke bis zur breitesten Zeile
					var tab_count: int = ceili(_max_column_length[i] / 4.0) - column_tabs
					var extra_spaces: int = column_tabs * 4 - column.length()
					text += column + " ".repeat(extra_spaces) + "    ".repeat(tab_count)
				else:
					text += column
			info(text)

		_rows.clear()
		_is_table_started = false
		_max_column_length.clear()
		_max_column_size = 0


	func table_row(columns: Array = []) -> void:
		assert(_is_table_started, "Expected table_start() to be called first")
		_rows.append(columns)
		_max_column_size = maxi(_max_column_size, columns.size())
		for i in columns.size():
			var column_length: int = (columns[i] as String).length()
			if _max_column_length.size() >= i + 1:
				_max_column_length[i] = maxi(_max_column_length[i], column_length)
			else:
				_max_column_length.append(column_length)


	func get_formatted_datatime() -> Dictionary:
		var datetime: Dictionary = Time.get_datetime_dict_from_system()
		datetime.year = "%04d" % datetime.year
		datetime.month = "%02d" % datetime.month
		datetime.day = "%02d" % datetime.day
		datetime.hour = "%02d" % datetime.hour
		datetime.minute = "%02d" % datetime.minute
		datetime.second = "%02d" % datetime.second
		return datetime


	func _log(level: LogLevel, msg: Variant, raw: bool = false) -> void:
		if is_locked or log_level > level:
			return

		var text: String = format_log(level, str(msg))
		match level:
			LogLevel.WARN:
				push_warning(text)
			LogLevel.ERROR:
				push_error(text)
			_:
				if raw:
					printraw(text)
				else:
					print(text)
#endregion
