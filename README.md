# HY300 ADB Opener

> 🇪🇸 Español (principal) · [🇬🇧 English](README.en.md)

Abre ADB inalámbrico en proyectores Android baratos con chip Rockchip RK3326 (clones del HY300,
placas ChipTrip) que vienen con un firmware `userdebug` y **sin cable USB A-A, sin root, sin la
opción "Depuración inalámbrica" en Opciones de desarrollador, y sin forma de encender ADB desde
los menús que realmente abren el puerto**.

**Resumen**: el firmware concede `WRITE_SECURE_SETTINGS` a apps normales de usuario, así que
un APK común puede llamar a `Settings.Global.putInt("adb_wifi_enabled", 1)` y Android arranca
el servicio TLS de ADB en un puerto aleatorio. El script compañero lo encuentra por mDNS y
se conecta.

## ¿Es mi proyector candidato? (chequeo rápido)

Marca mentalmente estas señales. Si ves 3 o más, hay muy buena chance de que funcione:

- ☑️ **Lo compraste barato** como "HY300", "HY320", "L018", "Mini projector" o similar.
- ☑️ **La caja dice "Android 12, 2 GB RAM, 16 GB"** pero cuando instalas CPU-Z ves Android 11,
  1 GB RAM real y 4 GB de almacenamiento. Las specs están infladas.
- ☑️ **En Opciones de desarrollador NO existe "Depuración inalámbrica"**, solo aparece "Depuración
  USB" y quizás un interruptor llamado "Internet Adb" que al activarlo no abre ningún puerto.
- ☑️ **El único puerto USB-A del proyector sirve solo para pendrives**, no para conectarlo a tu
  PC con un cable.
- ☑️ **La señal definitiva**: abres cualquier app en **Ajustes → Apps → [cualquier app]** y
  ves que **"Modificar ajustes del sistema"** ya está activado por defecto, en todas las
  apps. Eso indica que el firmware es `userdebug` y esta app debería funcionar.
- ☑️ Al abrir CPU-Z, en la pestaña System el "Número de versión" contiene la palabra
  `userdebug`. Confirmación técnica final.

Si marcas 3 o más → prueba la app, no hace daño si no funciona.
Si no marcas ninguna → probablemente tu dispositivo tiene firmware `user` normal y esta app no
sirve (te lo dirá y no cambiará nada).

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

## Si no te deja instalar el APK

Reportado por un usuario con un clon HY300: el instalador del proyector bloqueaba la
instalación con el Wi-Fi activo. Solución:

1. Reinicio de fábrica del proyector (Ajustes → Sistema → Restablecer).
2. **Apaga el Wi-Fi** antes de abrir el APK.
3. Instala la app desde el administrador de archivos.
4. Vuelve a encender el Wi-Fi.
5. Abre la app normalmente.

Causa probable: con red activa, Play Protect consulta online y bloquea instalaciones
laterales en firmwares con Play Services sin certificar (habitual en estos clones).
Sin red, la comprobación falla por timeout y la instalación pasa.

## ¿Y después?

Esta app solo abre la puerta. Una vez que tu PC vea el proyector como `device`, puedes hacer
con él lo que harías con cualquier Android TV via ADB. Algunas ideas, de más fácil a más
avanzada:

### 1. Debloat (quitar lo que no usas)

Con ADB abierto puedes desactivar apps de telemetría, anuncios y utilidades de fábrica sin
desinstalarlas (reversible). Ejemplo para quitar la telemetría ADUPS, el reproductor de
anuncios y las actualizaciones chinas de firmware:

```bash
adb shell pm disable-user --user 0 com.adups.fota
adb shell pm disable-user --user 0 com.fotas.wanapp
adb shell pm disable-user --user 0 android.rockchip.update.service
adb shell pm disable-user --user 0 com.xintu.systemadplayer
adb shell pm disable-user --user 0 com.chiptrip.clearmemory
```

Para revertir: `pm enable` con el mismo paquete. Todo lo que desactives queda en
`adb shell pm list packages -d`.

### 2. Reemplazar el launcher

El launcher de fábrica (`com.chiptrip.tvlauncher.rk.zx` en este modelo) es feo y muestra
publicidad. Recomendado: **CleanYourTV** de Gathin23, un launcher libre tipo Apple TV con
temas, saludo personalizable y biblioteca de apps.

- Repo: https://github.com/Gathin23/cleanyourtv
- Es un launcher pensado para aplicarse via ADB, así que encaja perfectamente con el acceso
  que esta app te acaba de dar.
- Trae scripts de debloat con listas por modelo. En este proyector las listas específicas
  no existen (es placa ChipTrip RK3326, no documentada), pero puedes empezar por desactivar
  los paquetes `com.adups.*`, `com.fotas.*`, `com.xintu.*` y `com.chiptrip.*` que no uses.

### 3. Bloquear anuncios en tu red

Independiente del proyector, cambia el DNS en tu router a un servicio bloqueador de
anuncios (por ejemplo AdGuard DNS: `94.140.14.14` y `94.140.15.15`). Esto reduce el tráfico
de anuncios en TODO lo conectado a tu Wi-Fi, no solo el proyector.

### Importante: el puerto cambia al reiniciar

Cada vez que el proyector arranca, Android asigna un puerto diferente para ADB. Vuelve a
abrir esta app o usa `scripts/connect.ps1`/`scripts/connect.sh`, que lo descubre por mDNS
automáticamente.

## Riesgos

- Si el proyector no arranca tras instalar, el único rescate es el reset de fábrica. Pulsa el
  botón de pinhole bajo el HDMI con un clip al encender.
- El build `userdebug` es ya en sí un problema de seguridad: cualquier app puede modificar
  ajustes secretos. Este APK aprovecha ese problema; no lo crea.
- **Bloatware de fábrica sospechoso.** Un reset de fábrica de este proyector deja instalada
  `com.google.android.adnoneu`, con nombre disfrazado como si fuera una app de Google (las apps
  reales de Google llevan `com.google.android.*`, pero no existe ningún producto oficial llamado
  "adnoneu"). Reaparece tras cualquier reset, lo que confirma que la añadió el fabricante, no
  una app que el usuario instaló. Recomendado quitarla con:
  ```bash
  adb shell pm uninstall --user 0 com.google.android.adnoneu
  ```
- **Cualquier APK ajeno con `WRITE_SECURE_SETTINGS` sobre este firmware tiene el mismo poder
  que esta app.** Antes de instalar cualquier launcher o utilidad de origen desconocido,
  revisa qué permisos pide (con `aapt dump permissions app.apk` o una app como "Package
  Inspector"). Si pide `WRITE_SECURE_SETTINGS + INTERNET + RECEIVE_BOOT_COMPLETED` y pesa
  poco, trátalo con cuidado.

## Compilar desde el código

Requiere JDK 17, Android SDK platform 34 y build-tools 34.0.0.

```bash
./gradlew assembleRelease
```

El APK se firma con la clave de debug para que se pueda sideload como el build de referencia.
Para redistribución, firma con tu propia clave.

## Enlaces

- [🇬🇧 README in English](README.en.md)
- [Narrativa técnica (cómo lo descubrimos)](docs/INVESTIGATION.md)
- [Descargar APK v1.0](https://github.com/MUSTARDWOLF3/hy300-adb-opener/releases/latest)

## Créditos

- Investigación y release: MUSTARDWOLF3 (Iquitos, Perú).
- Programación en pareja técnica: Claude (Anthropic).

## Licencia

MIT. Ver `LICENSE`.
