# HY300 ADB Opener

Open wireless ADB on cheap Rockchip RK3326 Android 11 projectors (HY300 clones, ChipTrip boards)
that ship with a `userdebug` build and have **no USB-A-to-A cable, no root, no Developer Options
"Wireless debugging" toggle, and no way to flip ADB on from inside the menus that actually open the port**.

**TL;DR**: the firmware grants `WRITE_SECURE_SETTINGS` to normal user apps, so a regular APK can
call `Settings.Global.putInt("adb_wifi_enabled", 1)` and Android will start the TLS ADB service on
a random port. The companion script finds it via mDNS and connects.

## Does this work on my projector?

This has only been tested on:

| Field | Value |
|---|---|
| Model string | `Projector` |
| Build fingerprint | `rockchip/rk3326_rgo/rk3326_rgo:11/RD2A.211001.002/eng.penggw.20260108.110245:userdebug/release-keys` |
| Board | ChipTrip, `rk30board`, Allwinner naming scheme but actually Rockchip RK3326 |
| SoC | Rockchip RK3326 (4× Cortex-A35 @ 1.5 GHz, Mali-G31) |
| Android | 11 (API 30) |
| RAM / Storage | 1 GB / 4 GB |
| Advertised specs | "Android 12, 2 GB + 16 GB" (inflated) |

**It should work** on any build that satisfies two conditions:

1. `ro.build.type=userdebug` (check with CPU-Z, under SoC → "Build ID"; or search the "Número de
   versión" field in Ajustes → Acerca de for `userdebug`).
2. Every app on the device already has "Modify system settings" granted by default — which is the
   dead giveaway of a `userdebug` build shipped to a consumer device.

**It will NOT work** on:

- Proper `user` builds (TVs, phones, most legitimate devices).
- Firmwares where the app installs but Android denies `WRITE_SECURE_SETTINGS` — the app will tell
  you clearly that nothing was accepted. Nothing is modified in that case.

## What it does

1. The app tries to write `adb_wifi_enabled=1`, `adb_enabled=1` and a few related settings keys.
   On a `userdebug` build these succeed because `WRITE_SECURE_SETTINGS` is pre-granted.
2. Android's own init starts the TLS ADB service on a random high port.
3. The service announces itself via mDNS (`_adb-tls-connect._tcp`).
4. You run `adb mdns services` from your PC, see the port, and `adb connect <ip>:<port>`.
5. Unlike normal wireless debugging, no pairing code is needed — the build is authorized to pair
   silently.

## What it does NOT do

- It does **not** root your device.
- It does **not** modify any system partition.
- It does **not** change the launcher, install apps, or touch any user data.
- It does **not** phone home. The APK has no `INTERNET` permission.

## Install and use

### On the projector

1. Copy `HY300-ADB-Opener-v1.0.apk` to the projector. Easiest way: open the stock File Manager,
   enable its FTP server, and copy the APK from your PC to `/sdcard/Download/`.
2. Open the APK with the File Manager and install. Allow "Unknown sources" if asked.
3. Open the app. You will see a black screen with step-by-step results.
4. Read the "RESULT" line at the bottom:
   - "At least one method succeeded" → go to the next section on your PC.
   - "No method succeeded" → your firmware denies the permission. Nothing was changed.

### On your PC (Windows)

```powershell
adb mdns services
adb connect <ip>:<port>
adb devices
```

Where `<ip>:<port>` is the line that looks like:

```
adb-XXXXXXXXXXX-XXXXXX   _adb-tls-connect._tcp   192.168.1.170:40903
```

You should now see the projector as `device` (not `unauthorized`, not `offline`).

A helper script is in `scripts/connect.ps1` for Windows and `scripts/connect.sh` for Linux / macOS.

## What next?

This app only opens the door. Once your PC sees the projector as `device`, you can do with
it anything you would do with any ADB-reachable Android TV. Some ideas:

### 1. Debloat (disable apps you don't use)

```bash
adb shell pm disable-user --user 0 com.adups.fota
adb shell pm disable-user --user 0 com.fotas.wanapp
adb shell pm disable-user --user 0 android.rockchip.update.service
adb shell pm disable-user --user 0 com.xintu.systemadplayer
adb shell pm disable-user --user 0 com.chiptrip.clearmemory
```

Reversible with `pm enable`. See `pm list packages -d` to list disabled.

### 2. Replace the stock launcher

The factory launcher (`com.chiptrip.tvlauncher.rk.zx`) is ugly and shows ads. Recommended
replacement: **CleanYourTV** by Gathin23, a libre Apple TV-style launcher with themes,
customizable greeting and an app library.

- Repo: https://github.com/Gathin23/cleanyourtv
- Designed to be applied via ADB, so it pairs perfectly with the access this app just gave you.
- Its debloat lists by device don't include this exact ChipTrip RK3326 board, but you can
  start by disabling the `com.adups.*`, `com.fotas.*`, `com.xintu.*` and unused `com.chiptrip.*`
  packages.

### 3. Block ads at your router

Independent of the projector, point your router's DNS to an ad-blocker (for example AdGuard
DNS: `94.140.14.14` and `94.140.15.15`). This blocks ads on everything on your Wi-Fi.

### Note: the port changes on reboot

Every time the projector boots, Android picks a different random port for ADB. Re-open this
app or use `scripts/connect.ps1` / `scripts/connect.sh`, which discover it via mDNS.

## Risks

- If the projector will not boot after installing this, factory reset is the only recovery. Press
  the pinhole reset button under the HDMI port with a paperclip while powering on.
- The `userdebug` build is itself a security concern (any app can modify secure settings).
  Consider this a side effect of that pre-existing weakness, not something this app creates.
- **Suspicious factory bloatware.** A factory reset of this projector leaves
  `com.google.android.adnoneu` installed. The name is disguised to look like a Google app
  (real Google packages are `com.google.android.*`, but no official product is called
  "adnoneu"). It comes back after every reset, which confirms the vendor pre-installed it,
  not a user-installed app. Recommended removal:
  ```bash
  adb shell pm uninstall --user 0 com.google.android.adnoneu
  ```
- **Any third-party APK with `WRITE_SECURE_SETTINGS` on this firmware has the same power as
  this app.** Before installing any launcher or utility from an unknown source, check what
  permissions it requests (with `aapt dump permissions app.apk` or a "Package Inspector"
  app). Treat tiny APKs that request `WRITE_SECURE_SETTINGS + INTERNET +
  RECEIVE_BOOT_COMPLETED` with caution.

## Build from source

Requires JDK 17, Android SDK platform 34 and build-tools 34.0.0.

```bash
./gradlew assembleRelease
```

The release APK is signed with the debug key so it installs over sideload the same way the
reference build does. For redistribution please sign with your own key.

## Credits

- Investigation and release: MUSTARDWOLF3 (Iquitos, Peru).
- Technical pair-programming: Claude (Anthropic).
- Based on the empirical observation that a third-party sideload APK had already been
  observed carrying `WRITE_SECURE_SETTINGS` without crashing on this firmware, which hinted
  that the firmware grants it to normal apps.

## License

MIT. See `LICENSE`.

## Español

Para instrucciones en español: `README.es.md`.
