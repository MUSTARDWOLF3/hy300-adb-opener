# HY300 ADB Opener

Abre ADB inalámbrico en proyectores Android baratos con chip Rockchip RK3326 (clones del HY300,
placas ChipTrip) que vienen con un firmware `userdebug` y **sin cable USB A-A, sin root, sin la
opción "Depuración inalámbrica" en Opciones de desarrollador, y sin forma de encender ADB desde
los menús que realmente abren el puerto**.

**Resumen**: el firmware concede `WRITE_SECURE_SETTINGS` a apps normales de usuario, así que
un APK común puede llamar a `Settings.Global.putInt("adb_wifi_enabled", 1)` y Android arranca
el servicio TLS de ADB en un puerto aleatorio. El script compañero lo encuentra por mDNS y
se conecta.

## ¿Funciona en mi proyector?

Probado en:

| Dato | Valor |
|---|---|
| Modelo que muestra | `Projector` |
| Fingerprint | `rockchip/rk3326_rgo/rk3326_rgo:11/RD2A.211001.002/eng.penggw.20260108.110245:userdebug/release-keys` |
| Placa | ChipTrip, `rk30board` |
| SoC | Rockchip RK3326 (4× Cortex-A35 @ 1.5 GHz, Mali-G31) |
| Android | 11 (API 30) |
| RAM / Almacenamiento real | 1 GB / 4 GB |
| RAM / Almacenamiento anunciado | 2 GB + 16 GB (inflado) |

**Debería funcionar** si tu firmware cumple dos cosas:

1. `ro.build.type=userdebug`. Mírelo con CPU-Z en SoC → Build ID, o busque la palabra
   `userdebug` en Ajustes → Acerca de → Número de versión.
2. Todas las apps ya tienen el permiso "Modificar ajustes del sistema" activado por defecto —
   la señal clara de un build `userdebug` entregado como producto final.

**NO funciona** en firmwares `user` (teles, celulares, dispositivos legítimos). La app te lo
dirá y no cambiará nada.

## Qué hace

1. Intenta escribir `adb_wifi_enabled=1`, `adb_enabled=1` y algunas claves de ajustes.
   En un build `userdebug` pasan porque `WRITE_SECURE_SETTINGS` ya está concedido.
2. El init de Android arranca el servicio TLS de ADB en un puerto alto aleatorio.
3. El servicio se anuncia por mDNS (`_adb-tls-connect._tcp`).
4. Desde tu PC: `adb mdns services`, ves el puerto, y `adb connect <ip>:<puerto>`.
5. A diferencia de la depuración inalámbrica normal, **no pide código de emparejamiento** —
   el build autoriza la conexión sin preguntar.

## Qué NO hace

- **No** rootea el dispositivo.
- **No** toca el firmware.
- **No** cambia el launcher, instala apps, ni modifica datos de usuario.
- **No** se conecta a internet. El APK no declara el permiso `INTERNET`.

## Instalación

### En el proyector

1. Copia `HY300-ADB-Opener-v1.0.apk` al proyector. La forma fácil: abre el administrador de
   archivos del proyector, activa su servidor FTP, y copia el APK desde tu PC a
   `/sdcard/Download/`.
2. Abre el APK desde el administrador de archivos e instala. Permite "orígenes desconocidos"
   si lo pide.
3. Abre la app. Verás una pantalla negra con los resultados paso a paso.
4. Mira la línea "RESULT" al final:
   - "At least one method succeeded" → pasa a la sección de tu PC.
   - "No method succeeded" → tu firmware no concede el permiso. Nada fue modificado.

### En tu PC (Windows)

```powershell
adb mdns services
adb connect <ip>:<puerto>
adb devices
```

Donde `<ip>:<puerto>` es la línea que se parece a:

```
adb-XXXXXXXXXXX-XXXXXX   _adb-tls-connect._tcp   192.168.1.170:40903
```

El proyector saldrá como `device` (no como `unauthorized` ni `offline`).

Hay un script de ayuda en `scripts/connect.ps1` (Windows) y `scripts/connect.sh`
(Linux / macOS).

## Riesgos

- Si el proyector no arranca tras instalar, el único rescate es el reset de fábrica. Pulsa el
  botón de pinhole bajo el HDMI con un clip al encender.
- El build `userdebug` es ya en sí un problema de seguridad: cualquier app puede modificar
  ajustes secretos. Este APK aprovecha ese problema; no lo crea.
- Ten cuidado con otras apps en el proyector. Durante las pruebas un usuario encontró que
  `Launcher-Sama` (`com.natureglass.launcher`, 50 KB con los permisos
  `WRITE_SECURE_SETTINGS + INTERNET + RECEIVE_BOOT_COMPLETED`) **instaló silenciosamente**
  `com.google.android.adnoneu` — probable malware disfrazado de app de Google.

## Compilar desde el código

Requiere JDK 17, Android SDK platform 34 y build-tools 34.0.0.

```bash
./gradlew assembleRelease
```

El APK se firma con la clave de debug para que se pueda sideload como el build de referencia.
Para redistribución, firma con tu propia clave.

## Créditos

- Investigación y release: MUSTARDWOLF3 (Iquitos, Perú).
- Programación en pareja técnica: Claude (Anthropic).

## Licencia

MIT. Ver `LICENSE`.
