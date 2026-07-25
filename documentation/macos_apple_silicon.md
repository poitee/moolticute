# Building Moolticute on macOS (Apple Silicon)

Official release DMGs are currently built for Intel (`x86_64`). On Apple Silicon Macs the app runs through Rosetta today, but native `arm64` builds are supported from source.

## Quick build

```bash
brew install qt go
git clone --recurse-submodules https://github.com/mooltipass/moolticute.git
cd moolticute
./scripts/macos/build-local.sh
open build/Moolticute.app
```

To bundle the daemon and CLI tools into the app:

```bash
./scripts/macos/build-local.sh --package
```

## What changes on Apple Silicon

- Qt is taken from Homebrew (`/opt/homebrew/opt/qt`) when available.
- `mc-agent` and `mc-cli` are compiled from source because the prebuilt Intel binaries hosted for releases are not compatible with `arm64`.
- The resulting `Moolticute.app` runs natively without Rosetta.

## Verify the build

```bash
file build/Moolticute.app/Contents/MacOS/moolticute
# Expected on Apple Silicon: Mach-O 64-bit executable arm64
```

## Upgrading from the Intel build

Quit Moolticute (and make sure the daemon is gone) **before** replacing the
app, otherwise the new GUI can find a stale daemon record in shared memory,
refuse to start its own daemon, and report "daemon is not running" /
"Can't restart daemon, it was started by hand":

```bash
pkill -f moolticuted
```

Then launch the new app. A reboot also clears the stale state.

Two more things to expect on a native build:

- **Gatekeeper:** community builds are ad-hoc signed (not notarized), so the
  first launch must be done via right-click → Open.
- **Auto-updater:** the app may offer the official Intel `v1.04.0` DMG as an
  "update". Decline it — installing it would replace the native build with
  the Rosetta one.

## Related issues

- https://github.com/mooltipass/moolticute/issues/1254
- https://github.com/mooltipass/moolticute/issues/929
