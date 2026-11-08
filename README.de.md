# ![Icon](icon.png) gd-plug (Fork)

Minimaler Plugin-Manager für Godot, inspiriert von [vim-plug](https://github.com/junegunn/vim-plug)

[English](README.md) · **Deutsch**

![Demo](screenshots/gd-plug_demo.gif)

> [!NOTE]
> Dies ist ein gepflegter Fork von [imjp94/gd-plug](https://github.com/imjp94/gd-plug), geschrieben von Tan Jian Ping.
> Das Original wird nicht mehr aktiv gepflegt. Der Fork ist für **Godot 4.x** (getestet mit 4.7) und steht weiter
> unter der MIT-Lizenz, siehe [LICENSE](LICENSE). Für Godot 3 gibt es den Branch
> [godot3](https://github.com/imjp94/gd-plug/tree/godot3) im Original.
>
> Maßgeblich ist die englische [README](README.md). Diese Fassung gibt ihren Inhalt auf Deutsch wieder.

## Inhalt

- [Änderungen im Fork](#änderungen-im-fork)
- [Merkmale](#merkmale)
- [Befehle](#befehle)
- [Quelle für upgrade](#quelle-für-upgrade)
- [Konfiguration](#konfiguration)
- [Installation](#installation)
- [Erste Schritte](#erste-schritte)
- [Hook nach einem Update](#hook-nach-einem-update)
- [Versionsverwaltung](#versionsverwaltung)
- [Weitere Beispiele](#weitere-beispiele)
- [Bekannte Einschränkungen](#bekannte-einschränkungen)

## Änderungen im Fork

- Optionen `install_root` und `strip_prefix` für `plug()`: für Addons, die tief verschachtelt liegen, zum Beispiel
  unter `plugin/addons/godot_ai/` (siehe [Konfiguration](#konfiguration) und [Weitere Beispiele](#weitere-beispiele))
- `upgrade` installiert gd-plug aus diesem Fork statt aus dem Original, siehe [Quelle für upgrade](#quelle-für-upgrade)
- Exit-Code `0` bei Erfolg und `1`, wenn ein Fehler gemeldet wurde. So lässt sich gd-plug in Skripten und CI nutzen.
- Code für Godot 4.7 modernisiert: statische Typisierung, typisierte Signale, GDScript-Styleguide
- Fehler behoben, unter anderem:
  - ein vorhandener Klon auf einem falschen Branch wurde wiederverwendet statt neu geklont
  - `install` scheiterte an einer `index.cfg` aus einer älteren Version
  - `upgrade` löschte den Klon noch während des Herunterladens, und das nächste `install` deinstallierte gd-plug

## Merkmale

- Minimal
  - Keine Abhängigkeiten außer Godot und git
- In sich geschlossen
  - [Ein Skript für alles](addons/gd-plug/plug.gd)
- Nichts Neues zu lernen
  - Die Konfiguration ist in GDScript geschrieben
- Schnell
  - Herunterladen und Installieren laufen parallel
- Versionen festhalten
  - Plugins auf Branch, Tag oder Commit festlegen
- Kleinere Repos
  - Abhängigkeiten lassen sich mit einem einzigen Shell-Befehl installieren
- Sauberes Deinstallieren
  - Entfernt die `*.import`-Dateien eines Plugins und die importierten Ressourcen aus `/.import`

## Befehle

```shell
godot --headless -s plug.gd {aktion} {optionen...}
```

Aktionen:

| Aktion                   | Beschreibung                                                                                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `init`                   | Legt `plug.gd` im Wurzelverzeichnis des Projekts an                                                                                 |
| `status`                 | Zeigt den Stand der Plugins (installiert, hinzugefügt oder entfernt), im Zweifel immer zuerst ausführen                             |
| `install` alias `update` | Installiert oder aktualisiert die Plugins aus `plug.gd` (auf den neuesten Stand, wenn nicht festgelegt), entfernt nicht mehr gelistete |
| `uninstall`              | Deinstalliert alle Plugins, unabhängig von `plug.gd`                                                                                |
| `clean`                  | Entfernt ungenutzte Dateien und Ordner aus `/.plugged`                                                                              |
| `upgrade`                | Aktualisiert `addons/gd-plug/plug.gd` auf den neuesten Stand dieses Forks, siehe [Quelle für upgrade](#quelle-für-upgrade)          |
| `version`                | Gibt die Version von gd-plug aus                                                                                                    |
| `help`                   | Zeigt die Hilfe                                                                                                                     |
| `help-config`            | Zeigt die Argumente von `plug()`                                                                                                    |

Optionen:

| Option                      | Beschreibung                                                                                                                                                         |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `production`                | Installiert nur Plugins ohne `dev`, bereits installierte `dev`-Plugins werden entfernt                                                                               |
| `test`                      | Testmodus: Es wird nichts installiert oder deinstalliert, nur ausgegeben, welche Dateien betroffen wären. Vor allem mit `install` oder `uninstall`                   |
| `force`                     | Überschreibt beim `install` vorhandene Dateien. Ohne `force` bricht gd-plug die Installation eines Plugins ab, sobald eine seiner Dateien eine Datei im Projekt überschreiben würde. |
| `keep-import-file`          | Behält beim `uninstall` die vom Plugin erzeugten `.import`-Dateien                                                                                                  |
| `keep-import-resource-file` | Behält beim `uninstall` die vom Plugin erzeugten Dateien in `/.import`                                                                                              |
| `debug` alias `d`           | Gibt Debug-Meldungen aus                                                                                                                                            |
| `detail`                    | Gibt Datum, Uhrzeit und Log-Level mit aus: "[{time}] [{level}] {msg}"                                                                                               |
| `quiet` alias `q`, `silent` | Schaltet die Ausgabe ab                                                                                                                                             |

> [!NOTE]
> Optionen werden ohne Bindestriche geschrieben. Argumente wie `--key` oder `-key` verarbeitet Godot selbst, siehe
> [godotengine/godot#8721](https://github.com/godotengine/godot/issues/8721).

Exit-Code: `0` bei Erfolg, `1`, wenn ein Fehler gemeldet wurde (Download gescheitert, ungültige Argumente für `plug()`,
unbekannter Befehl).

### Quelle für upgrade

`upgrade` installiert gd-plug aus diesem Fork (`Fox-Alpha/fork-gd-plug`, Branch `development`) und nicht aus dem
Original `imjp94/gd-plug`. So bleiben die Änderungen des Forks erhalten. Repo und Branch lassen sich über
Umgebungsvariablen ändern:

| Variable                 | Standard                 | Beschreibung                                                     |
| ------------------------ | ------------------------ | ---------------------------------------------------------------- |
| `GD_PLUG_UPGRADE_REPO`   | `Fox-Alpha/fork-gd-plug` | GitHub-Repo `username/repo` oder vollständige Git-URL (`file:///…`) |
| `GD_PLUG_UPGRADE_BRANCH` | `development`            | Branch, aus dem installiert wird                                 |

```shell
GD_PLUG_UPGRADE_BRANCH=master godot --headless -s plug.gd upgrade
```

> [!IMPORTANT]
> Kopien von gd-plug aus dem Original oder aus diesem Fork vor November 2026 holen bei `upgrade` noch
> `imjp94/gd-plug`. Dann `addons/gd-plug/` einmal wie unter [Installation](#installation) beschrieben ersetzen, danach
> nutzt `upgrade` den Fork.

## Konfiguration

```gdscript
plug(src, args={})
```

Quelle:

- GitHub-Repo: "username/repo", zum Beispiel "Fox-Alpha/fork-gd-plug"

oder

- eine beliebige gültige Git-URL

> [!NOTE]
> Für private Repos ist die vollständige SSH-URL nötig: `plug("git@github.com:username/repo.git")`. Siehe
> [Generating a new SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
> und [Adding a new SSH key to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)

Argumente:

| Argument       | Typ             | Beschreibung                                                                                                                                                                                                                                           |
| -------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `include`      | `Array[String]` | Dateien oder Ordner, die installiert werden. Ohne Angabe nur `addons/`. (Keine Platzhalter wie `*`.)                                                                                                                                                   |
| `exclude`      | `Array[String]` | Dateien oder Ordner, die ausgelassen werden. (Keine Platzhalter wie `*`.)                                                                                                                                                                              |
| `branch`       | `String`        | Branch, auf den das Plugin festgelegt wird                                                                                                                                                                                                             |
| `tag`          | `String`        | Tag, auf den das Plugin festgelegt wird                                                                                                                                                                                                                |
| `commit`       | `String`        | Commit, auf den das Plugin festgelegt wird. Nur der volle Hash mit 40 Zeichen, zum Beispiel `7a642f90d3fb88976dd913051de994e58e838d1a`.                                                                                                                |
| `dev`          | `bool`          | Markiert ein Plugin als `dev`. `dev`-Plugins werden bei `install` mit `production` nicht installiert und, falls schon installiert, entfernt                                                                                                            |
| `on_updated`   | `String`        | Hook nach einem Update: Name einer Funktion in `plug.gd`, die nach jeder Installation oder Aktualisierung des Plugins aufgerufen wird. Siehe [Hook nach einem Update](#hook-nach-einem-update)                                                       |
| `install_root` | `String`        | Zielordner, in den die Dateien installiert werden                                                                                                                                                                                                      |
| `strip_prefix` | `String`        | Pfad-Präfix, das vor dem Kopieren nach `install_root` von den Quellpfaden entfernt wird. Fehlt es, ist `install_root` gesetzt und genau ein Ordner (außer `addons/` oder `.`) in `include`, wird dieser Ordner automatisch entfernt. Ein fehlendes `/` am Ende wird ergänzt |

`include` und `exclude` vergleichen Teilstrings: Eine Datei passt, wenn einer der Einträge in ihrem Pfad im geklonten
Repo vorkommt.

## Installation

- gd-plug

  Dieses Repo klonen und `addons/gd-plug/` ins eigene Projekt kopieren:

  ```shell
  git clone --depth 1 -b development https://github.com/Fox-Alpha/fork-gd-plug.git /tmp/fork-gd-plug
  cp -r /tmp/fork-gd-plug/addons/gd-plug {projektordner}/addons/
  ```

  oder das Repo als Archiv herunterladen und `addons/gd-plug/` nach `{projektordner}/addons/` verschieben.

- git

  [git](https://git-scm.com/downloads) herunterladen und installieren

  > git muss über die Umgebungsvariable `PATH` erreichbar sein

- [gd-plug-ui](https://github.com/imjp94/gd-plug-ui) (optional)

  Oberfläche für das originale gd-plug, auf der Kommandozeile nicht nötig. Mit diesem Fork nicht getestet.

## Erste Schritte

1. `plug.gd` im Wurzelverzeichnis des Projekts anlegen:

```gdscript
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	# Plugins hier mit plug(src, args) eintragen
	pass
```

> [!TIP]
> Oder den Befehl `init` verwenden: `godot --headless -s addons/gd-plug/plug.gd init`

2. Plugins in `plug.gd` unter `_plugging()` eintragen, zum Beispiel:

```gdscript
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	# Plugins hier mit plug(src, args) eintragen
	# Ohne weitere Angaben wird nur der Ordner "addons/" installiert
	plug("bitwes/Gut")
	plug("hi-godot/godot-ai", {"install_root": "addons/godot_ai", "include": ["plugin/addons/godot_ai/"]})
```

3. Zum Schluss `install` in der Shell ausführen

```shell
# --headless ist optional und unterdrückt das Godot-Fenster
godot --headless -s plug.gd install
```

## Hook nach einem Update

Ein Hook nach einem Update lässt sich auf drei Arten einrichten:

- als Argument von `plug()`
  - `plug(src, {"on_updated": "post_update"})`
- über das Signal `updated`
  - `updated.connect(post_update)`
- durch Überschreiben von `_on_updated`
  - `func _on_updated(plugin: Dictionary) -> void:`

Der Hook bekommt immer ein Argument: ein Dictionary mit den Angaben zum Plugin (`name`, `url`, `dest_files`, …)

```gdscript
func post_update(plugin: Dictionary) -> void:
	print("%s aktualisiert" % plugin.name)
```

> [!NOTE]
> Plugins werden in parallelen Threads installiert, die Hooks laufen im Thread des jeweiligen Plugins.

## Versionsverwaltung

Was kann aus der Versionsverwaltung herausbleiben?

- `/.plugged`: Hierhin werden die Repos der Plugins geklont
- `/addons`: nach Geschmack. Abhängigkeiten können herausbleiben, weil gd-plug sie verwaltet

Was gehört in die Versionsverwaltung?

- `plug.gd`: Liste der Abhängigkeiten
- `addons/gd-plug/plug.gd`: der Kern von gd-plug

> Am besten über eine `.gitignore` festlegen, siehe [/.gitignore](.gitignore).

```gitignore
# gd-plug
.plugged/

# Godot-Addons: die meisten ignorieren, die wichtigen versionieren
addons/*
!addons/gd-plug/
# Eigene Addons hier ergänzen, damit sie im Git bleiben
#!addons/my-custom-addon/
```

## Weitere Beispiele

Meist lässt sich ein Plugin ohne weitere Angaben eintragen. gd-plug nimmt standardmäßig alles aus dem Ordner
`/addons` des Plugins und installiert es nach `/addons` im Projekt.

Manche Repos sind anders aufgebaut und brauchen eine eigene Konfiguration.

- Die Addon-Dateien liegen nicht in `/addons`, zum Beispiel bei [Master-J/DecalCo](https://github.com/Master-J/DecalCo)
  - Den Ordner ausdrücklich angeben:

    `plug("Master-J/DecalCo", {"include": ["decalco/"]})`
- Das Repo enthält nur die Addon-Dateien, zum Beispiel [HungryProton/scatter](https://github.com/HungryProton/scatter/tree/v3)
  - `install_root` auf den Zielordner setzen und alle Dateien einschließen:
    `plug("HungryProton/scatter", {"install_root": "addons/scatter", "include": ["."]})`
- Die Addon-Dateien liegen tief verschachtelt, zum Beispiel bei [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai)
  - `install_root` mit dem Ordner in `include` angeben, der Ordner wird automatisch entfernt:
    `plug("hi-godot/godot-ai", {"install_root": "addons/godot_ai", "include": ["plugin/addons/godot_ai/"]})`
  - Oder mit `strip_prefix` ein bestimmtes Präfix entfernen:
    `plug("bnjmntmm/godot-exoplayer", {"install_root": "addons/godot_exoplayer", "include": ["plugin/demo/addons/godot_exoplayer/"], "strip_prefix": "plugin/demo/addons/godot_exoplayer/"})`

Die Repos unten zeigen nur die Schreibweise. Vor dem Eintragen prüfen, ob ein Plugin zur eigenen Godot-Version passt.

```gdscript
extends "res://addons/gd-plug/plug.gd"


func _plugging() -> void:
	# Plugins hier mit plug(src, args) eintragen
	# Ohne weitere Angaben wird nur der Ordner "addons/" installiert
	# Versionen festhalten
	plug("imjp94/UIDesignTool", {"branch": "demo"}) # Immer vom Branch "demo" aktualisieren
	plug("imjp94/gd-YAFSM", {"tag": "1.0.0-stable"}) # Auf eine stabile Version festlegen
	plug("Zylann/godot_heightmap_plugin", {"commit": "7a642f90d3fb88976dd913051de994e58e838d1a"}) # Nur der volle Hash mit 40 Zeichen

	# Dev-Plugins, mit der Option "production" ausgelassen bzw. entfernt
	plug("fenix-hub/godot-engine.github-integration", {"dev": true})
	plug("EricEzaM/godot-color-palette", {"dev": true})

	# Hook nach einem Update
	plug("bitwes/Gut", {"on_updated": "_on_gut_updated"})

	# Funktioniert auch, wenn die Dateien nicht in "addons/" liegen
	plug("Master-J/DecalCo", {"include": ["decalco/"]})

	# Repo, das nur die Addon-Dateien enthält
	plug("HungryProton/scatter", {"install_root": "addons/scatter", "include": ["."]})

	# Tief verschachtelte Addon-Dateien (mit install_root automatisch entfernt)
	plug("hi-godot/godot-ai", {"install_root": "addons/godot_ai", "include": ["plugin/addons/godot_ai/"]})

	# Andere Quellen als GitHub
	plug("https://gitlab.com/Xecestel/sound-manager") # GitLab
	plug("file:///D/Godot/local-project/.git") # Lokales Git-Repo

	updated.connect(_on_plugin_updated)


func _on_updated(plugin: Dictionary) -> void:
	# Überschreiben, um alle aktualisierten Plugins abzufangen
	match plugin.name:
		"Gut":
			print("Gut aktualisiert")


func _on_gut_updated(plugin: Dictionary) -> void:
	print("%s aktualisiert" % plugin.name)
	print("Installierte Dateien: %s" % plugin.dest_files)


func _on_plugin_updated(plugin: Dictionary) -> void:
	# Alle aktualisierten Plugins über das Signal abfangen
	print("%s: Hook über das Signal" % plugin.name)
```

## Bekannte Einschränkungen

- Godot zeigt Fehler aus den Plugin-Repos in `./plugged` an, auch mit `.gdignore` (siehe [imjp94/gd-plug#32](https://github.com/imjp94/gd-plug/issues/32))
- Manchmal lassen sich einzelne `.import`-Dateien nicht entfernen, der Grund ist unbekannt.
  - Abhilfe: In der Ausgabe nachsehen, welche `.import`-Dateien übrig geblieben sind, und sie von Hand löschen.
- Autoload-Einträge in den Projekteinstellungen bleiben nach dem Deinstallieren eines Plugins stehen.
  - Abhilfe: Autoloads in den Projekteinstellungen von Hand entfernen
- Binärdateien, die Godot gerade benutzt, kann gd-plug bei offenem Editor nicht entfernen, zum Beispiel die
  GDExtension-Bibliotheken von [Zylann/godot_heightmap_plugin](https://github.com/Zylann/godot_heightmap_plugin).
  - Abhilfe: Editor schließen, dann `clean` ausführen oder den Ordner des Plugins in `/.plugged` von Hand löschen

## Lizenz

MIT, siehe [LICENSE](LICENSE). Original © 2021 Tan Jian Ping ([imjp94/gd-plug](https://github.com/imjp94/gd-plug)),
Fork © 2026 Fox-Alpha.
