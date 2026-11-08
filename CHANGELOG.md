# fork-gd-plug (development)

Die folgenden Einträge wurden automatisch aus der Git-Historie generiert. Die Reihenfolge der Typen ist Add → Chg → Upd → Ref → Rem → Fix → Docs → Ren → Mov → Cfg → Fmt → sonstige.

## 2026-11-08

- Chg: init erzeugt plug.gd in Godot-4-Schreibweise [f774c02](https://github.com/Fox-Alpha/fork-gd-plug/commit/f774c02)
- Chg: upgrade lädt gd-plug aus dem eigenen Fork [fe7ab8f](https://github.com/Fox-Alpha/fork-gd-plug/commit/fe7ab8f)
- Ref: statische Typisierung und Godot-4-Syntax in plug.gd [039e476](https://github.com/Fox-Alpha/fork-gd-plug/commit/039e476)
- Ref: plug.gd in Regionen nach Styleguide gegliedert [7128bf2](https://github.com/Fox-Alpha/fork-gd-plug/commit/7128bf2)
- Rem: ungenutzte Variablen in plug.gd [a06675c](https://github.com/Fox-Alpha/fork-gd-plug/commit/a06675c)
- Fix: Absturz, wenn ein Verzeichnis nicht geöffnet werden kann [2a0c68b](https://github.com/Fox-Alpha/fork-gd-plug/commit/2a0c68b)
- Fix: Update scheiterte am Index einer älteren gd-plug-Version [b8d3ea4](https://github.com/Fox-Alpha/fork-gd-plug/commit/b8d3ea4)
- Fix: Einrückung des Loggers konnte negativ werden, Debug-Meldung ohne Pfad [5a2b762](https://github.com/Fox-Alpha/fork-gd-plug/commit/5a2b762)
- Fix: Löschen von .git nutzte Betriebssystem-Namen aus Godot 3 [8823d35](https://github.com/Fox-Alpha/fork-gd-plug/commit/8823d35)
- Fix: stderr von git wurde unter Linux und macOS nicht umgeleitet [a0ae2f9](https://github.com/Fox-Alpha/fork-gd-plug/commit/a0ae2f9)
- Fix: Commit-Vergleich griff ohne Prüfung auf die Git-Ausgabe zu [6d67f4b](https://github.com/Fox-Alpha/fork-gd-plug/commit/6d67f4b)
- Fix: vorhandener Klon wurde nicht auf Branch, Tag oder Commit geprüft [f6ccb03](https://github.com/Fox-Alpha/fork-gd-plug/commit/f6ccb03)
- Fix: Exit-Code war nach jedem Lauf 255 [5135168](https://github.com/Fox-Alpha/fork-gd-plug/commit/5135168)
- Fix: install deinstalliert gd-plug nach einem upgrade [791bb8e](https://github.com/Fox-Alpha/fork-gd-plug/commit/791bb8e)
- Fix: upgrade löscht den Klon, während er noch heruntergeladen wird [cf87d75](https://github.com/Fox-Alpha/fork-gd-plug/commit/cf87d75)
- Docs: Beispiel im Klassen-Docstring an das neue init-Template angeglichen [3704d55](https://github.com/Fox-Alpha/fork-gd-plug/commit/3704d55)
- Docs: Docstrings für plug.gd [11738bc](https://github.com/Fox-Alpha/fork-gd-plug/commit/11738bc)
- Docs: deutsche Fassung der README [5f08577](https://github.com/Fox-Alpha/fork-gd-plug/commit/5f08577)
- Docs: README auf den Stand des Forks gebracht [f3a131f](https://github.com/Fox-Alpha/fork-gd-plug/commit/f3a131f)
- Docs: eigenen Copyright-Vermerk in der LICENSE ergänzt [c3b3528](https://github.com/Fox-Alpha/fork-gd-plug/commit/c3b3528)
- Docs: Fork-Änderungen und upgrade im CHANGELOG [c04c4d1](https://github.com/Fox-Alpha/fork-gd-plug/commit/c04c4d1)
- Docs: Quelle und Einstellungen von upgrade im README [e9bbbde](https://github.com/Fox-Alpha/fork-gd-plug/commit/e9bbbde)
- Cfg: UID-Datei von plug.gd versioniert [de680d5](https://github.com/Fox-Alpha/fork-gd-plug/commit/de680d5)
- Cfg: Projekt auf Godot 4.7, Godot-3-Umgebung entfernt [a418f56](https://github.com/Fox-Alpha/fork-gd-plug/commit/a418f56)
- Cfg: lokales Testprojekt .reference ignorieren [c3331b7](https://github.com/Fox-Alpha/fork-gd-plug/commit/c3331b7)
- Cfg: .editorconfig nach Styleguide [53becf2](https://github.com/Fox-Alpha/fork-gd-plug/commit/53becf2)
- Fmt: icon.png.import vom Editor unter Godot 4.7 neu gespeichert [024cb5e](https://github.com/Fox-Alpha/fork-gd-plug/commit/024cb5e)
- Fmt: plug.gd mit gdscript-formatter formatiert [8773642](https://github.com/Fox-Alpha/fork-gd-plug/commit/8773642)

## 2026-08-22

- Add: support for strip_prefix and automatic path stripping with install_root [4ecc61e](https://github.com/Fox-Alpha/fork-gd-plug/commit/4ecc61e)
- Chg: simplify export-ignore in .gitattribute file [b21f5b7](https://github.com/Fox-Alpha/fork-gd-plug/commit/b21f5b7)
- Upd: restrict auto-strip to non-default includes and normalize strip_prefix [c5d3a0c](https://github.com/Fox-Alpha/fork-gd-plug/commit/c5d3a0c)

## 2026-05-23

- Fix `_process` missing return (#51) [209276d](https://github.com/Fox-Alpha/fork-gd-plug/commit/209276d)

## 2026-04-22

- Fix non-static calls to `get_open_error()` (#50) [b97a532](https://github.com/Fox-Alpha/fork-gd-plug/commit/b97a532)

## 2026-04-05

- Add guide to use .gitignore (#49) [0c742ba](https://github.com/Fox-Alpha/fork-gd-plug/commit/0c742ba)

## 2025-02-03

- Fix post update function calls [64d0000](https://github.com/Fox-Alpha/fork-gd-plug/commit/64d0000)

## 2025-02-02

- Fix init command [77573c7](https://github.com/Fox-Alpha/fork-gd-plug/commit/77573c7)

## 2024-10-12

- Fix default exit code is alway non-zero [a72d4a0](https://github.com/Fox-Alpha/fork-gd-plug/commit/a72d4a0)

## 2024-04-07

- Update README & Fix typo in help [cf0cbb4](https://github.com/Fox-Alpha/fork-gd-plug/commit/cf0cbb4)

## 2024-04-06

- Update version to 0.2.6 [963f9d9](https://github.com/Fox-Alpha/fork-gd-plug/commit/963f9d9)

## 2024-02-16

- Add a help action (#29) [b762f28](https://github.com/Fox-Alpha/fork-gd-plug/commit/b762f28)

## 2023-09-11

- Add explanation to install from private repository to README (#27) [989f43e](https://github.com/Fox-Alpha/fork-gd-plug/commit/989f43e)

## 2023-07-02

- Update README.md [4199623](https://github.com/Fox-Alpha/fork-gd-plug/commit/4199623)

## 2023-06-23

- fix: fixed download typo [bd9ac50](https://github.com/Fox-Alpha/fork-gd-plug/commit/bd9ac50)

## 2023-06-11

- Fix stuck again that caused by internal await threadpool.is_all_thread_finished [ef4daac](https://github.com/Fox-Alpha/fork-gd-plug/commit/ef4daac)
- Fix threapool is not processing [3f8dc73](https://github.com/Fox-Alpha/fork-gd-plug/commit/3f8dc73)
- Update version to 0.2.5 [eae4912](https://github.com/Fox-Alpha/fork-gd-plug/commit/eae4912)
- Update version to 0.2.4 [e0204e8](https://github.com/Fox-Alpha/fork-gd-plug/commit/e0204e8)
- Mention gd-plug-ui in README [092898a](https://github.com/Fox-Alpha/fork-gd-plug/commit/092898a)

## 2023-06-10

- Fix plug_install not executed [7b61beb](https://github.com/Fox-Alpha/fork-gd-plug/commit/7b61beb)
- Fix "not" keyword cannot be used on non-boolean [6858971](https://github.com/Fox-Alpha/fork-gd-plug/commit/6858971)
- Update version to 0.2.3 [7250d98](https://github.com/Fox-Alpha/fork-gd-plug/commit/7250d98)
- Update version to 0.2.2 [408c8e8](https://github.com/Fox-Alpha/fork-gd-plug/commit/408c8e8)

## 2023-06-09

- Make sure threadpool tasks are executed in batch, to avoid multiple emission of "all_thread_finished" signal [93e3895](https://github.com/Fox-Alpha/fork-gd-plug/commit/93e3895)
- Localize commandlin command for removing empty directory [0e82e03](https://github.com/Fox-Alpha/fork-gd-plug/commit/0e82e03)

## 2023-06-02

- Update version to 0.2.1 [3b95b56](https://github.com/Fox-Alpha/fork-gd-plug/commit/3b95b56)

## 2023-06-01

- Fix post update hook [ce27499](https://github.com/Fox-Alpha/fork-gd-plug/commit/ce27499)

## 2023-05-31

- Fix thread destroyed without wait_to_finish() called & Update thread.is_active to thread.is_started [f4935e1](https://github.com/Fox-Alpha/fork-gd-plug/commit/f4935e1)
- Update README.md [cab0466](https://github.com/Fox-Alpha/fork-gd-plug/commit/cab0466)

## 2023-05-09

- Update the names for Unix-like OSes [66dcce6](https://github.com/Fox-Alpha/fork-gd-plug/commit/66dcce6)

## 2023-05-02

- Update README.md [b4ac59b](https://github.com/Fox-Alpha/fork-gd-plug/commit/b4ac59b)

## 2022-09-19

- Port to Godot 4.0 [3636015](https://github.com/Fox-Alpha/fork-gd-plug/commit/3636015)

## 2021-07-16

- Enclose directories in command with double-quote [e83a682](https://github.com/Fox-Alpha/fork-gd-plug/commit/e83a682)

## 2021-06-29

- Update version to 0.1.1 & CHANGELOG [84c4078](https://github.com/Fox-Alpha/fork-gd-plug/commit/84c4078)

## 2021-06-27

- Add underscore prefix to inner classes [116ec29](https://github.com/Fox-Alpha/fork-gd-plug/commit/116ec29)

## 2021-05-31

- Enable headless/server platforms [83cd8f5](https://github.com/Fox-Alpha/fork-gd-plug/commit/83cd8f5)

## 2021-05-29

- Add LICENSE [24ad23b](https://github.com/Fox-Alpha/fork-gd-plug/commit/24ad23b)
- Validate plugin args [fae1072](https://github.com/Fox-Alpha/fork-gd-plug/commit/fae1072)

## 2021-05-26

- Add README, CHANGELOG and screenshot & Change icon [1d2a0e2](https://github.com/Fox-Alpha/fork-gd-plug/commit/1d2a0e2)

## 2021-05-28

- Exclude project root files from export [4c7e7f5](https://github.com/Fox-Alpha/fork-gd-plug/commit/4c7e7f5)

## 2021-05-27

- Add install_root plug option [5aca71c](https://github.com/Fox-Alpha/fork-gd-plug/commit/5aca71c)

## 2021-05-23

- Add upgrade command [64c07ac](https://github.com/Fox-Alpha/fork-gd-plug/commit/64c07ac)
- Clean file in /.import directory [0c990a6](https://github.com/Fox-Alpha/fork-gd-plug/commit/0c990a6)
- Implement simple thread pool to to handle multithread in "mainloop-friendly" way [e9468e9](https://github.com/Fox-Alpha/fork-gd-plug/commit/e9468e9)

## 2021-05-19

- Status command print more useful info [61ef429](https://github.com/Fox-Alpha/fork-gd-plug/commit/61ef429)

## 2021-05-22

- Support freezing plugin to specific commit [2057b4a](https://github.com/Fox-Alpha/fork-gd-plug/commit/2057b4a)

## 2021-05-16

- Add clean command [3324b76](https://github.com/Fox-Alpha/fork-gd-plug/commit/3324b76)
- Support safe mode when installing [e268f30](https://github.com/Fox-Alpha/fork-gd-plug/commit/e268f30)

## 2021-05-14

- Validate git directories in .plugged [288f717](https://github.com/Fox-Alpha/fork-gd-plug/commit/288f717)

## 2021-05-13

- Add test mode [b2d28b8](https://github.com/Fox-Alpha/fork-gd-plug/commit/b2d28b8)
- Add uninstall command [56e0b19](https://github.com/Fox-Alpha/fork-gd-plug/commit/56e0b19)

## 2021-05-15

- Add Logger [67e6982](https://github.com/Fox-Alpha/fork-gd-plug/commit/67e6982)
- Logging [ee9cf18](https://github.com/Fox-Alpha/fork-gd-plug/commit/ee9cf18)

## 2021-05-12

- Support multi-thread [f631fe0](https://github.com/Fox-Alpha/fork-gd-plug/commit/f631fe0)

## 2021-05-11

- Support marking plugin as dev and can be excluded with production command [33a6498](https://github.com/Fox-Alpha/fork-gd-plug/commit/33a6498)
- Support freezing plugin with branch/tag [361c988](https://github.com/Fox-Alpha/fork-gd-plug/commit/361c988)

## 2021-05-10

- Add GitExecutable class [76746ef](https://github.com/Fox-Alpha/fork-gd-plug/commit/76746ef)

## 2021-05-09

- Support command [3407553](https://github.com/Fox-Alpha/fork-gd-plug/commit/3407553)

## 2021-05-07

- Init [f6dd2aa](https://github.com/Fox-Alpha/fork-gd-plug/commit/f6dd2aa)
