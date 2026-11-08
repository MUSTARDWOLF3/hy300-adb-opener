# The investigation

A straightforward narrative of how this was found. Useful if someone has a different model and
needs to replicate the reasoning.

## Device under test

A cheap Chinese Android projector marketed as "HY300" with inflated specs (claimed Android 12,
2 GB RAM, 16 GB storage). In reality:

- Android 11 (API 30)
- Rockchip RK3326 (4× Cortex-A35 @ 1.5 GHz, Mali-G31)
- 991 MB total RAM
- 3.75 GB internal storage
- Board: ChipTrip, kernel 4.19.232

Confirmed by CPU-Z inside the device.

## The initial roadblock

1. Developer Options showed USB Debugging, "Internet Adb" and "USB settings (Disconnect to
   Computer)".
2. Enabling "Internet Adb" did not open any ADB port on the LAN. A full port scan of
   `1024-65535` from another PC on the same Wi-Fi came back empty.
3. The USB-A port on the projector is host-only. A USB-A↔USB-C cable from a laptop was not
   detected at all; `adb devices` returned nothing. The "USB settings" toggle flipped back off
   when the menu closed.
4. Developer Options has no "Wireless debugging" (Android 11+ feature). It was omitted by the
   vendor build.
5. No official firmware for this specific board (`ChipTrip`, `rk3326_rgo`) is publicly
   available; it is not the same as the Allwinner H713 HY300 that has community firmware. A
   failed re-flash on an RK3326 unit was already reported on XDA.

So the normal paths were all closed. Factory reset only brings the projector back to the
same state.

## The hint

Looking at third-party sideload APKs the user had tried on this device, we noticed one of
them declared `WRITE_SECURE_SETTINGS` in its manifest alongside `INTERNET`,
`ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `READ_EXTERNAL_STORAGE` and
`RECEIVE_BOOT_COMPLETED` — and the device had installed it without crashing.

`WRITE_SECURE_SETTINGS` is a `signatureOrSystem` protection level. On a real Android build
Google ships to a user, it is impossible for a normal sideload APK to actually receive it.
The fact that the APK bothered to request it, and ran without a crash on this firmware,
suggested the author either knew or hoped the device would grant it.

Separately, the user had reported earlier in the session that "on this projector every app
has 'Modify system settings' turned on". That is the `WRITE_SETTINGS` permission, which is a
less powerful cousin of `WRITE_SECURE_SETTINGS`. Both being laxly granted was consistent with
a `userdebug` build having leaked to a consumer device — a known vendor shortcut to avoid the
longer signing and CTS process.

## The experiment

A minimal APK was written that:

1. Tries `Settings.Global.putInt("adb_wifi_enabled", 1)` and similar keys.
2. Tries `Settings.Secure.putInt("adb_enabled", 1)`.
3. Tries `Runtime.exec("setprop persist.adb.tcp.port 5555")` and `"start adbd"`.
4. Shows a full-screen panel with each attempt's result.

On the first run the output showed:

```
adb_wifi_enabled OK
adb_enabled OK
Secure.adb_enabled OK
setprop persist.adb.tcp.port 5555 code=0
start adbd code=1 err=Must be root
```

No `SecurityException`. Android quietly accepted the change.

A moment later `adb mdns services` from the PC returned:

```
adb-50Z5C368C6-bFXTHA   _adb-tls-connect._tcp   192.168.1.170:40903
```

And `adb connect 192.168.1.170:40903` landed on `device` — no pairing prompt.

## Why this works

- The projector's build fingerprint includes `userdebug/release-keys`. Vendors normally ship
  `user/release-keys` to consumers. `userdebug` enables ADB features (debuggable apps,
  broader permission grants) that `user` disables.
- On `userdebug`, the `SettingsService` allows `WRITE_SECURE_SETTINGS` operations from any
  package. That is why `Settings.Global.putInt` succeeds.
- Writing `1` to `adb_wifi_enabled` causes `adbd` to start a TLS socket on a random high port.
- Because the build is debuggable, ADB does not require pairing. The first connection is
  trusted.

## Why it probably won't work on your TV

- Real TVs (Sony, Hisense, TCL, Xiaomi) ship `user/release-keys`. On those,
  `WRITE_SECURE_SETTINGS` on a sideload APK throws `SecurityException`, the app says "No
  method succeeded", and nothing changes.
- The app is harmless on those: the only thing it would do is open the Developer Options
  screen for you to flip a switch manually, which is what you would do anyway.

## Credits

Investigation by MUSTARDWOLF3 (Iquitos, Peru) with technical pair-programming by Claude
(Anthropic). The user had already surveyed XDA, GitHub (Spocky's Projectivy Launcher,
gniax, YuujiLab, shift), Reddit and androidpctv.com and found no method for this specific
board; the reasoning in this document is original to this session.
