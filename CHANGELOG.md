# Changelog

## Unreleased (fork Fox-Alpha/fork-gd-plug)

- Features:
  - `plug()` options `install_root` and `strip_prefix` for addons nested in non-standard directories
  - `upgrade` installs gd-plug from this fork (`Fox-Alpha/fork-gd-plug`, branch `development`) instead of
    `imjp94/gd-plug`, overridable with `GD_PLUG_UPGRADE_REPO` and `GD_PLUG_UPGRADE_BRANCH`
- Bugfixes:
  - `upgrade` deleted the downloaded clone while it was still being cloned
  - `install` uninstalled gd-plug itself after an `upgrade`, because `upgrade` added it to `.plugged/index.cfg`

## 0.1.1

- Bugfixes:
  - Fix [Inner class name conflict with other plugins](https://github.com/imjp94/gd-plug/issues/4)
- Features:
  - [Support for headless/server builds](https://github.com/imjp94/gd-plug/pull/1)

## 0.1.0

Initial release

- Features:
  - Config in GDScript
  - Commandline friendly
  - Multi-threaded download/installation
  - Support freezing plugin with branch/tag/commit
  - Safe installation, installation will be terminated when plugin files found to be overwritting project files(can be switched off with `force` command)
  - Clean .import files and import resources located in /.import when plugin uninstalled
