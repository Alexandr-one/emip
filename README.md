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

Manually: download `Emip-linux-x86_64.so` or `Emip-macos-universal.dylib` from
[Releases](../../releases), rename it to `Emip.so` / `Emip.dylib` (the GCS takes the plugin
name from the file name) and put it into the user plugins folder `~/Documents/UAVOS/Plugins/`
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
is built for plus the plugin build number: `v11.2.32.1` is the first build for GCS 11.2.32.
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
links to. Output: `dist/Emip-<os>-<arch>.so|dylib` and `dist/BUILD_INFO-<os>-<arch>.txt`.

## Release

Tag = GCS version + plugin build number (`v<gcs>.<build>`):

```bash
git tag v11.2.32.1   # first build for GCS 11.2.32, the next one is v11.2.32.2
git push origin v11.2.32.1
```

The [workflow](.github/workflows/release.yml) builds the plugin for Linux (in the
`uavos/apx-gcs-linux` container) and macOS (universal arm64+x86_64, same Qt version as the GCS
release workflow; the VideoStreaming and Joystick GCS plugins are left out of the configuration
so the SDL/GStreamer frameworks are not needed) against the GCS sources of the tag version:
`release-11.2.32` when that GCS release exists, `main` otherwise (the version under development),
or `APX_GCS_REF` when the workflow is run manually. The build fails when the configured GCS
version is not the one of the tag. The release is published with both libraries and the
build info. Pushes to `main` and pull requests only build and upload the artifacts.

## License

LGPL-3.0, same as APX GCS, see [LICENSE](LICENSE).
