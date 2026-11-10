# EMIP plugin for APX Ground Control

Engine Monitoring and Indication Panel for [APX GCS](https://github.com/uavos/apx-gcs):
RPM dial with needle, EGT and fuel tank bars, pump voltage monitor and
LOW FUEL / LOW BAT / SATCOM annunciators, shown in the instruments area next to the
system terminal. The plugin also adds the `FP` page (fuel pumps 1-3 and manual mode,
`ctr.sw.sw5..sw8`) to the Controls panel.

The plugin is pure QML ([Emip/](Emip/)), compiled into a GCS plugin library by the
GCS build system.

## Install

1. Download `Emip-linux-x86_64.so` from [Releases](../../releases).
2. Copy it to the user plugins folder: `~/Documents/UAVOS/Plugins/`
   (if a version-suffixed folder such as `Plugins.12` exists, use that one).
3. Start the GCS. On the first start the plugin switches itself off; enable it in
   Preferences, Plugins, EMIP.

Mandala bindings and limits: defaults in [Emip/EmipConfig.qml](Emip/EmipConfig.qml),
overridden by the user file `~/Documents/UAVOS/emip/emip.json` (same keys). The file is
created with the defaults on the first start and never overwritten afterwards.

The plugin needs a GCS with `application.loadJson/saveJson` and
`groundControl.addControlPage` (apx-gcs PR #159). On an older GCS the panel still works
with the bundled defaults, the `FP` page is not added.

## Build

Same as CI, needs the GCS toolchain (Qt 6, cmake, ninja, python with jinja2/networkx):

```bash
scripts/build.sh                 # clones apx-gcs (main) into ./apx-gcs
scripts/build.sh -r release-12.0 # specific apx-gcs ref
scripts/build.sh -s ~/work/apx-gcs   # existing checkout
```

The plugin folder is copied into `src/Plugins/Tools/` of the GCS tree, registered in the
Tools `CMakeLists.txt` and built as the `Emip` target together with the GCS libraries it
links to. Output: `dist/Emip-<os>-<arch>.so` and `dist/BUILD_INFO.txt`.

## Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

The [workflow](.github/workflows/release.yml) builds the plugin in the
`uavos/apx-gcs-linux` container against `APX_GCS_REF` (default `main`, can be set when
running the workflow manually) and publishes a GitHub release with the library and the
build info. Pushes to `main` and pull requests only build and upload the artifact.

## License

LGPL-3.0, same as APX GCS, see [LICENSE](LICENSE).
