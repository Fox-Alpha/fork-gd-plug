# ![Icon](icon.png) gd-plug (fork)

Minimal plugin manager for Godot, inspired by [vim-plug](https://github.com/junegunn/vim-plug)

**English** · [Deutsch](README.de.md)

![Demo](screenshots/gd-plug_demo.gif)

> [!NOTE]
> This is a maintained fork of [imjp94/gd-plug](https://github.com/imjp94/gd-plug) by Tan Jian Ping, who wrote the
> original. The original is no longer actively maintained. This fork targets **Godot 4.x** (tested with 4.7) and keeps
> the MIT license, see [LICENSE](LICENSE). For Godot 3, use the
> [godot3](https://github.com/imjp94/gd-plug/tree/godot3) branch of the original.

## Content

- [Changes in this fork](#changes-in-this-fork)
- [Features](#features)
- [Commands](#commands)
- [Upgrade source](#upgrade-source)
- [Configs](#configs)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Post Update Hook](#post-update-hook)
- [Version Control](#version-control)
- [More Examples](#more-examples)
- [Known Limitations](#known-limitations)

## Changes in this fork

- `plug()` options `install_root` and `strip_prefix` for addons that are nested in non-standard directories, for
  example `plugin/addons/godot_ai/` (see [Configs](#configs) and [More Examples](#more-examples))
- `upgrade` installs gd-plug from this fork instead of the original, see [Upgrade source](#upgrade-source)
- Exit code `0` on success and `1` if an error was reported, usable in scripts and CI
- Code modernized for Godot 4.7: static typing, typed signals, GDScript style guide
- Bug fixes, among others:
  - an existing clone on the wrong branch was reused instead of cloned again
  - `install` failed on an `index.cfg` written by an older version
  - `upgrade` deleted the clone while it was still being downloaded, and the next `install` uninstalled gd-plug

## Features

- Minimal
  - No dependencies other than Godot and git
- Self-contained
  - [One script to run them all](addons/gd-plug/plug.gd)
- Zero learning curve
  - Config file written in GDScript
- Blazingly fast
  - Parallel download/installation
- Version freeze
  - Freeze plugins by branch, tag or commit
- Reduce remote repository size
  - Dependencies can be installed with just a single-line shell command
- Clean uninstall
  - Remove plugin `*.import` files or import resources from `/.import` on uninstall

## Commands

```shell
godot --headless -s plug.gd {action} {options...}
```

Actions:

| Action                   | Description                                                                                                                |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| `init`                   | Initialize current project by creating `plug.gd` at root                                                                   |
| `status`                 | Check the status of plugins (installed, added or removed), execute this command whenever in doubt                          |
| `install` alias `update` | Install or update (to latest version if not frozen) "plugged" plugins based on `plug.gd`, or uninstall "unplugged" plugins |
| `uninstall`              | Uninstall all plugins, regardless of `plug.gd`                                                                             |
| `clean`                  | Clean unused files/folders from `/.plugged`                                                                                |
| `upgrade`                | Upgrade `addons/gd-plug/plug.gd` to the latest version of this fork, see [Upgrade source](#upgrade-source)                 |
| `version`                | Print current version of gd-plug                                                                                           |
| `help`                   | Show help                                                                                                                  |
| `help-config`            | Show the arguments of `plug()`                                                                                             |

Options:

| Option                      | Description                                                                                                                                                                                       |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `production`                | Install only plugins not marked as `dev`, or uninstall already installed `dev` plugins                                                                                                            |
| `test`                      | Testing mode, no files will be installed/uninstalled while files to be installed/uninstalled will be printed, mainly used with `install` or `uninstall`                                           |
| `force`                     | Force gd-plug to overwrite destination files when running `install` command. By default, gd-plug will terminate installation of a plugin when any of its files would overwrite user files.        |
| `keep-import-file`          | Keep ".import" files generated by plugin, when running `uninstall` command                                                                                                                        |
| `keep-import-resource-file` | Keep files located in /.import that were generated by plugin, when running `uninstall` command                                                                                                    |
| `debug` alias `d`           | Print debug message                                                                                                                                                                               |
| `detail`                    | Print with datetime and log level, "[{time}] [{level}] {msg}"                                                                                                                                     |
| `quiet` alias `q`, `silent` | Disable logging                                                                                                                                                                                   |

> [!NOTE]
> Options are written without dashes. Godot consumes arguments like `--key` or `-key` itself, see
> [godotengine/godot#8721](https://github.com/godotengine/godot/issues/8721).

Exit code: `0` on success, `1` if any error was reported (failed download, invalid `plug()` arguments, unknown command).

### Upgrade source

`upgrade` installs gd-plug from this fork (`Fox-Alpha/fork-gd-plug`, branch `development`), not from the original
`imjp94/gd-plug`, so the changes of the fork are kept. Repo and branch can be overridden with environment variables:

| Variable                 | Default                  | Description                                                    |
| ------------------------ | ------------------------ | -------------------------------------------------------------- |
| `GD_PLUG_UPGRADE_REPO`   | `Fox-Alpha/fork-gd-plug` | Github repo `username/repo` or full git URL (e.g. `file:///…`) |
| `GD_PLUG_UPGRADE_BRANCH` | `development`            | Branch to install from                                         |

```shell
GD_PLUG_UPGRADE_BRANCH=master godot --headless -s plug.gd upgrade
```

> [!IMPORTANT]
> Copies of gd-plug taken from the original, or from this fork before November 2026, still upgrade from
> `imjp94/gd-plug`. Replace `addons/gd-plug/` once as described in [Installation](#installation), afterwards
> `upgrade` keeps using the fork.

## Configs

```gdscript
plug(src, args={})
```

Source:

- Github repo: "username/repo", for example, "Fox-Alpha/fork-gd-plug"

or

- Any valid git url

> [!NOTE]
> To install plugin from private repository, full Git SSH url must be used: `plug("git@github.com:username/repo.git")`. See [Generating new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) and [Adding a new SSH key to your Github account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

Arguments:

| Argument       | Type            | Description                                                                                                                                                                                                                                                                        |
| -------------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `include`      | `Array[String]` | Files or directories to include, only `addons/` will be included if omitted. (No expression like wildcard(*) supported yet.)                                                                                                                                                       |
| `exclude`      | `Array[String]` | Files or directories to exclude. (No expression like wildcard(*) supported yet.)                                                                                                                                                                                                   |
| `branch`       | `String`        | Name of branch to freeze to                                                                                                                                                                                                                                                        |
| `tag`          | `String`        | Name of tag to freeze to                                                                                                                                                                                                                                                           |
| `commit`       | `String`        | Commit hash string to freeze to, must be full length 40 digits commit-hash, for example, `7a642f90d3fb88976dd913051de994e58e838d1a`.                                                                                                                                               |
| `dev`          | `bool`          | Toggle `dev` mode. `dev` plugins will not be installed when `install` with `production` option (`dev` plugins will be removed if already installed)                                                                                                                               |
| `on_updated`   | `String`        | Post update hook, a function name declared in `plug.gd` that will be called whenever the plugin is installed/updated. See [Post Update Hook](#post-update-hook)                                                                                                                    |
| `install_root` | `String`        | Destination directory where included files will be installed                                                                                                                                                                                                                       |
| `strip_prefix` | `String`        | Path prefix to strip from included source paths before copying to `install_root`. If omitted and `install_root` is set with a single included directory (other than `addons/` or `.`), that directory is stripped automatically. Trailing `/` is added automatically if missing |

`include` and `exclude` match by substring: a file is included if any entry occurs in its path inside the cloned
repository.

## Installation

- gd-plug

  Clone this repository and copy `addons/gd-plug/` into your project:

  ```shell
  git clone --depth 1 -b development https://github.com/Fox-Alpha/fork-gd-plug.git /tmp/fork-gd-plug
  cp -r /tmp/fork-gd-plug/addons/gd-plug {project_dir}/addons/
  ```

  or download this repository as archive and move `addons/gd-plug/` to `{project_dir}/addons/`.

- git

  Download and install [git](https://git-scm.com/downloads)

  > git must be available in the `PATH` environment variable

- [gd-plug-ui](https://github.com/imjp94/gd-plug-ui) (optional)

  User interface for the original gd-plug, not required when working with commandline. Not tested with this fork.

## Getting Started

1. Create `plug.gd` at your project root, as below:

```gdscript
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	# Declare your plugins in here with plug(src, args)
	pass
```

> [!TIP]
> Or run `init` command: `godot --headless -s addons/gd-plug/plug.gd init`

2. Declare plugins in `plug.gd` under `_plugging()`, for example:

```gdscript
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	# Declare your plugins in here with plug(src, args)
	# By default, only "addons/" directory will be installed
	plug("bitwes/Gut")
	plug("hi-godot/godot-ai", {"install_root": "addons/godot_ai", "include": ["plugin/addons/godot_ai/"]})
```

3. Finally, run `install` command in shell

```shell
# --headless is optional to disable godot window
godot --headless -s plug.gd install
```

## Post Update Hook

Post update hook can be connected in 3 ways:

- Declare in `plug()` argument
  - `plug(src, {"on_updated": "post_update"})`
- Connect to `updated` signal
  - `updated.connect(post_update)`
- Override `_on_updated` function
  - `func _on_updated(plugin: Dictionary) -> void:`

Post update hook is always called with one argument, a dictionary that stores information about the plugin
(`name`, `url`, `dest_files`, …)

```gdscript
func post_update(plugin: Dictionary) -> void:
	print("%s updated" % plugin.name)
```

> [!NOTE]
> Plugins are installed in parallel threads, the hooks run in the thread of the plugin.

## Version Control

What can be ignored from version control system?

- `/.plugged`: Plugins' git repo are cloned to this directory
- `/addons`: Based on preference, but dependencies can be safely ignored since they will be managed by gd-plug

What should be added to version control system?

- `plug.gd`: Dependency config file
- `addons/gd-plug/plug.gd`: gd-plug's core

> It's recommended to add `.gitignore` to track/untrack files, see [/.gitignore](.gitignore).

```gitignore
# gd-plug
.plugged/

# Godot addons - ignore most, but keep essential ones tracked
addons/*
!addons/gd-plug/
# Add your custom addons below to keep them in git
#!addons/my-custom-addon/
```

## More Examples

For most of the case, a plugin can be "plugged" without any extra configuration, as by default gd-plug will extract whatever located in plugin's `/addons` directory and install to current project's `/addons` directory.

However, some plugin's repository may be structured differently, thus, different configuration needed.

- Addon files are not located in `/addons` directory, for example, [Master-J/DecalCo](https://github.com/Master-J/DecalCo)
  - Explicitly include the directory to install:

    `plug("Master-J/DecalCo", {"include": ["decalco/"]})`
- Repository contains only addons files, for example, [HungryProton/scatter](https://github.com/HungryProton/scatter/tree/v3)
  - Change `install_root` to destination directory and include all files:
    `plug("HungryProton/scatter", {"install_root": "addons/scatter", "include": ["."]})`
- Addon files are nested in a non-standard directory, for example, [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai)
  - Use `install_root` with the included directory; the directory is automatically stripped:
    `plug("hi-godot/godot-ai", {"install_root": "addons/godot_ai", "include": ["plugin/addons/godot_ai/"]})`
  - Or use `strip_prefix` to strip a specific path prefix:
    `plug("bnjmntmm/godot-exoplayer", {"install_root": "addons/godot_exoplayer", "include": ["plugin/demo/addons/godot_exoplayer/"], "strip_prefix": "plugin/demo/addons/godot_exoplayer/"})`

The repositories below only illustrate the syntax, check that a plugin supports your Godot version before plugging it.

```gdscript
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	# Declare your plugins in here with plug(src, args)
	# By default, only "addons/" directory will be installed
	# Version freeze
	plug("imjp94/UIDesignTool", {"branch": "demo"}) # Always pull update from "demo" branch
	plug("imjp94/gd-YAFSM", {"tag": "1.0.0-stable"}) # Freeze to stable version
	plug("Zylann/godot_heightmap_plugin", {"commit": "7a642f90d3fb88976dd913051de994e58e838d1a"}) # Must be full length 40 digits commit-hash

	# Dev plugins, can be excluded or uninstalled with "production" option
	plug("fenix-hub/godot-engine.github-integration", {"dev": true})
	plug("EricEzaM/godot-color-palette", {"dev": true})

	# Post update hook
	plug("bitwes/Gut", {"on_updated": "_on_gut_updated"})

	# It works even if the files are not located in "addons/"
	plug("Master-J/DecalCo", {"include": ["decalco/"]})

	# Repo that contains only addon files
	plug("HungryProton/scatter", {"install_root": "addons/scatter", "include": ["."]})

	# Addon files nested in a non-standard directory (automatically stripped when install_root is set)
	plug("hi-godot/godot-ai", {"install_root": "addons/godot_ai", "include": ["plugin/addons/godot_ai/"]})

	# Source other than github
	plug("https://gitlab.com/Xecestel/sound-manager") # Gitlab
	plug("file:///D/Godot/local-project/.git") # Local git repo

	updated.connect(_on_plugin_updated)


func _on_updated(plugin: Dictionary) -> void:
	# Override to catch all updated plugins
	match plugin.name:
		"Gut":
			print("Gut updated")


func _on_gut_updated(plugin: Dictionary) -> void:
	print("%s updated" % plugin.name)
	print("Installed files: %s" % plugin.dest_files)


func _on_plugin_updated(plugin: Dictionary) -> void:
	# Catch all updated plugins with signal
	print("%s post update hook with signal" % plugin.name)
```

## Known Limitations

- Godot always shows errors from plugin repositories in `./plugged` even with `.gdignore` (see [imjp94/gd-plug#32](https://github.com/imjp94/gd-plug/issues/32))
- Sometimes random .import files will be unable to remove, while the reason behind it still remains unknown.
  - Workaround: Read output for those .import files that failed to remove, and manually delete them.
- `autoload` script references in project setting are not cleared as plugin uninstalled.
  - Workaround: Manually remove `autoload` scripts from project setting
- Binary files in use by Godot can't be removed by gd-plug, when plugin uninstalled with editor opened. For example, [Zylann/godot_heightmap_plugin](https://github.com/Zylann/godot_heightmap_plugin)'s GDExtension binaries.
  - Workaround: Quit editor, then execute `clean` command or manually remove plugin folder from `/.plugged`

## License

MIT, see [LICENSE](LICENSE). Original work © 2021 Tan Jian Ping ([imjp94/gd-plug](https://github.com/imjp94/gd-plug)),
fork © 2026 Fox-Alpha.
