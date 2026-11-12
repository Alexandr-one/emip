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
downloads the library for its platform into `~/Documents/UAVOS/Plugins/github/emip/`.

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

The library links against the GCS libraries, so take a release built against the GCS
version you run (see `BUILD_INFO-*.txt` in the release) or build it yourself with
`-r <apx-gcs tag>`. The plugin needs a GCS with `groundControl.addControlPage` and the GitHub plugins entry
(apx-gcs PR #159); on an older GCS the `FP` page is not added and the settings menu is in Tools.

## Build

Same as CI, needs the GCS toolchain (Qt 6, cmake, ninja, python with jinja2/networkx):

```bash
scripts/build.sh                 # clones apx-gcs (main) into ./apx-gcs
scripts/build.sh -r release-12.0 # specific apx-gcs ref
scripts/build.sh -s ~/work/apx-gcs   # existing checkout
```

The plugin folder is copied into `src/Plugins/Tools/` of the GCS tree, registered in the
Tools `CMakeLists.txt` and built as the `Emip` target together with the GCS libraries it
links to. Output: `dist/Emip-<os>-<arch>.so|dylib` and `dist/BUILD_INFO-<os>-<arch>.txt`.

## Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The [workflow](.github/workflows/release.yml) builds the plugin for Linux (in the
`uavos/apx-gcs-linux` container) and macOS (universal arm64+x86_64, same Qt version as the GCS
release workflow; the VideoStreaming and Joystick GCS plugins are left out of the configuration
so the SDL/GStreamer frameworks are not needed) against `APX_GCS_REF` (default `main`, can be set when
running the workflow manually) and publishes a GitHub release with both libraries and the
build info. Pushes to `main` and pull requests only build and upload the artifacts.

## License

LGPL-3.0, same as APX GCS, see [LICENSE](LICENSE).
