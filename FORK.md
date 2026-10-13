# N0cky/arr-scripts

Eigener, fest versionierter Stand der arr-scripts für **Lidarr auf Phoenix** (Unraid).
Basis ist [mkaltner/arr-scripts](https://github.com/mkaltner/arr-scripts) (Fork von
[RandomNinjaAtk/arr-scripts](https://github.com/RandomNinjaAtk/arr-scripts)), Stand `e17e295` vom 27.02.2026.
Genutzt wird nur der Ordner `lidarr/` (plus `universal/`), alles andere ist unverändert.

## Warum ein Fork

Vorher lud der Container bei jedem Neuaufbau ungeprüft den aktuellen Stand von `mkaltner/main`.
Jetzt kommt alles aus einem festen Tag dieses Repos. Änderungen von mkaltner oder RandomNinjaAtk
werden nur bewusst übernommen.

## Änderungen gegenüber mkaltner

| Datei | Änderung |
|---|---|
| `lidarr/scripts_init.bash` | lädt `setup.bash` aus diesem Repo (fester Tag) |
| `lidarr/setup.bash` | alle Dateien aus `repoRaw` (fester Tag). Pakete werden nur bei neuer `scriptVersion` installiert, die Dienste aber bei **jedem** Start geladen, damit immer genau der Tag läuft |
| `lidarr/AutoArtistAdder.bash` | `AddDeezerArtistToLidarr` lädt die Künstlerliste nur noch nach einem Hinzufügen neu, statt pro geprüftem Künstler (~53 MB, mehrere Sekunden Lidarr-CPU je Abruf) |
| `lidarr/AutoConfig.service.bash` | Vorgabe `rescanAfterRefresh` = `afterManual` statt `always` (sonst täglich ~19 h Vollscan, Importe blockiert) |

## Neue Version ausrollen

1. Änderung committen.
2. In `lidarr/setup.bash` (`repoRaw`) und `lidarr/scripts_init.bash` den neuen Tag eintragen, committen.
3. Tag setzen und pushen: `git tag v1.x.y && git push origin main v1.x.y`.
4. Auf Phoenix `/mnt/data/appdata/lidarr/custom-cont-init/scripts_init.bash` auf den neuen Tag stellen.
5. Lidarr neu starten und im Container-Log prüfen, dass alle Dienste geladen wurden.

## Änderungen von oben übernehmen

```bash
git fetch mkaltner && git fetch upstream
git log --oneline main..mkaltner/main      # was ist bei mkaltner neu
git diff main mkaltner/main -- lidarr universal
```

Gezielt per `git cherry-pick` oder `git merge` übernehmen, danach wie oben einen neuen Tag ausrollen.
