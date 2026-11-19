# EMIP plugin for APX Ground Control

Engine Monitoring and Indication Panel for [APX GCS](https://github.com/uavos/apx-gcs):
RPM dial with needle, EGT and fuel tank bars, pump voltage monitor and
LOW FUEL / LOW BAT / SATCOM annunciators, shown in the instruments area next to the
system terminal, plus the Sensors page (automatic magnetometer and barometer reset).
The plugin also adds the `FP` page (fuel pumps 1-3 and manual mode) to the Controls panel.

The plugin is pure QML ([Emip/](Emip/)), compiled into a GCS plugin library by the
GCS build system.

## Install

From the GCS (with the third party plugin system): Preferences, Application, Plugins,
GitHub plugins, enter `https://github.com/Alexandr-one/emip` and press Install. The GCS
downloads the library for its platform from the latest release made for its own version
into `~/Documents/UAVOS/Plugins/github/emip/`. Check for updates (also automatic on start)
lists newer builds for the running GCS version; Update in the plugin entry installs them.

Manually: download `Emip-linux-x86_64.zip` or `Emip-macos-universal.zip` from
[Releases](../../releases), unpack `Emip.so` / `Emip.dylib` (the GCS takes the plugin
name from the file name) into the user plugins folder `~/Documents/UAVOS/Plugins/`
(if a version-suffixed folder such as `Plugins.12` exists, use that one).

On the first start the plugin switches itself off; enable it in Preferences, Plugins, EMIP.

Settings (mandala paths, limits, tank names, FP page switches, automatic sensors reset) are
the EMIP menu under the plugin entry: Preferences, Application, Plugins, GitHub plugins,
Alexandr-one/emip, EMIP. On a GCS without that entry the menu is in Tools, System features.
Defaults are in [Emip/EmipConfig.qml](Emip/EmipConfig.qml); the values persist in the
application settings.

The plugin registers two instruments: EMIP (RPM, EGT, fuel, annunciators) and Sensors
(automatic magnetometer and barometer reset, guide target delay and distance).

The library links against the GCS libraries, so the release tag carries the GCS version it
is built for: `v11.2.32` is the build for GCS 11.2.32, further builds for the same GCS version
add a build number (`v11.2.32.1`, `v11.2.32.2`).
The GCS loads a GitHub plugin only when the versions match (a plugin for another version is
reported as disabled in the console) and offers the latest build for its version instead.
For a manual install take the release for the GCS version you run (see `BUILD_INFO-*.txt`).
The plugin needs a GCS with `groundControl.addControlPage` and the GitHub plugins entry
(apx-gcs PR #159); on an older GCS the `FP` page is not added and the settings menu is in Tools.

## Build

Same as CI, needs the GCS toolchain (Qt 6, cmake, ninja, python with jinja2/networkx):

```bash
scripts/build.sh                    # clones apx-gcs into ./apx-gcs (release of the tag, else main)
scripts/build.sh -r release-11.2.32 # specific apx-gcs ref
scripts/build.sh -s ~/work/apx-gcs  # existing checkout
```

The plugin folder is copied into `src/Plugins/Tools/` of the GCS tree, registered in the
Tools `CMakeLists.txt` and built as the `Emip` target together with the GCS libraries it
links to. Output: `dist/Emip-<os>-<arch>.zip` (with `Emip.so|dylib` and the build info inside)
and `dist/BUILD_INFO-<os>-<arch>.txt`.

## Release

Releases are made by the [workflow](.github/workflows/release.yml) on its own. Twice an hour it
reads the latest GCS release (`release-X.Y.Z`, repository `GCS_WATCH_REPO` in the workflow) and,
when no plugin release has been built from that GCS release yet, builds the plugin against it and
publishes the next tag for that GCS version:

| plugin tags for GCS X.Y.Z | published tag |
|---|---|
| none (e.g. the plugin is at 11.2.30, the GCS released 11.2.32) | `v11.2.32` |
| `v11.2.32` | `v11.2.32.1` |
| up to `v11.2.32.4` | `v11.2.32.5` |

The version always comes from the latest GCS release, not from the newest plugin tag: with plugin
tags for 11.2.33 (built from `main`) and the latest GCS release 11.2.32, the next build is for
11.2.32. A plugin release counts as built from a GCS release when its notes have the line
`apx-gcs: X.Y.Z release-X.Y.Z (<commit>)`.

By hand, in Actions, Build plugin, Run workflow: `auto` does the same check right away, `release`
publishes the next build for the latest GCS release even when one exists (after a plugin fix),
`build` only builds. A pushed tag is still built and published as it is:

```bash
git tag v11.2.32.5
git push origin v11.2.32.5
```

The plugin is built for Linux (in the `uavos/apx-gcs-linux` container) and macOS (universal
arm64+x86_64, same Qt version as the GCS release workflow; the VideoStreaming and Joystick GCS
plugins are left out of the configuration so the SDL/GStreamer frameworks are not needed) against
the GCS sources of the tag version: `release-11.2.32` when that GCS release exists, `main`
otherwise (the version under development), or `APX_GCS_REF` when the workflow is run manually.
The build fails when the configured GCS version is not the one of the tag. The release is
published with the two archives (Linux and macOS), the build info is in the release notes.
Pushes to `main` and pull requests only build and upload the artifacts.

## License

LGPL-3.0, same as APX GCS, see [LICENSE](LICENSE).
