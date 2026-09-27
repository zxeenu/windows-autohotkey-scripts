# Steam Big Picture Guide/Home Button Launcher

AutoHotkey v2 scripts that watch for a controller's Guide/Home button
**tap** (press and release, without pressing anything else while held) and
launch Steam Big Picture mode when detected. Supports controllers in both
**XInput mode** (e.g. Xbox-compatible / 8BitDo in XInput mode) and
**DirectInput / "Switch" mode** (e.g. 8BitDo Pro 3 in Switch mode).

## Files

- **`SteamBigPictureStart.ahk`** — the actual background utility. Run this
  one persistently (e.g. on startup / via Task Scheduler / Startup folder).
- **`Diagnostic.ahk`** — a one-off tool for identifying a DirectInput
  controller's joystick number and button number. Not needed for normal
  use; only run it when adding/reconfiguring a new Switch-mode-style
  controller.

## How it works

### XInput controllers (slots 0–3)
Polls `XInputGetStateEx` (ordinal 100 — the only XInput entry point that
reports the Guide button) every 20ms for all 4 possible controller slots.
Each slot has its own independent press/release/chord state, so multiple
XInput controllers work simultaneously without interfering with each other.

### DirectInput / Switch-mode controllers
XInput cannot see non-Xbox-compatible HID gamepads at all — a controller
in "Switch mode" (like the 8BitDo Pro 3) shows up only as a generic
DirectInput joystick. These are tracked separately via AHK's built-in
`GetKeyState("<id>JoyN")` joystick support, using a manually configured
list of `{ joyId, homeBtn }` pairs (see **Adding/updating a controller**
below).

### Chording (both modes)
If any other button is pressed, or a thumbstick is pushed off-center,
while the Guide/Home button is held down, that press is marked as a
"chord" and will **not** trigger Big Picture on release. This lets you use
Guide/Home as a modifier (e.g. Guide + A for some other function) without
accidentally opening Steam.

### Launch guard
Before launching, the script checks if `steam.exe` is already running
(desktop mode, tray, or already in Big Picture) and does nothing if so —
it only runs `steam://open/bigpicture` when Steam isn't already open.

## Setup

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Place both `.ahk` files in the same folder.
3. Run `SteamBigPictureStart.ahk`. It will sit in the background (check
   the tray icon) and poll every 20ms.
4. (Optional) Add it to Windows Startup so it runs automatically:
   - Press `Win+R`, type `shell:startup`, press Enter.
   - Drop a shortcut to `SteamBigPictureStart.ahk` into that folder.

## Adding or updating a DirectInput ("Switch mode") controller

XInput controllers need no configuration — slots 0–3 are polled
automatically. DirectInput controllers must be registered manually because
button numbering isn't standardized across devices:

1. Put the controller into DirectInput mode (e.g. 8BitDo in "Switch
   mode," not "XInput mode").
2. Run `Diagnostic.ahk`. It lists every connected joystick, its button
   count, which buttons are currently pressed, and stick X/Y position,
   refreshed every 100ms.
3. Press **only** the Guide/Home button (nothing else) and note:
   - The **Joystick number** (e.g. `Joystick 3`)
   - The **button number** that lights up under "Pressed"
4. Open `SteamBigPictureStart.ahk` and add/edit an entry in the `diPads`
   list near the top of the script:
   ```autohotkey
   diPads := [ { joyId: 3, homeBtn: 13 } ]
   ```
   Add more `{ joyId: N, homeBtn: N }` entries (comma-separated) for
   additional DirectInput controllers.
5. Save and re-run `SteamBigPictureStart.ahk`.

### Known caveat
DirectInput joystick numbers (`joyId`) are **not stable** the way XInput
slots are — unplugging/replugging a controller, or plugging in devices in
a different order, can shift which joystick number Windows assigns to it.
If a previously-working Switch-mode controller stops responding to
Guide/Home, re-run `Diagnostic.ahk` to confirm its current joystick
number and update `diPads` accordingly.

The stick-centering check in the DirectInput branch assumes axes report
roughly 0–100 with idle around 50 (as observed on the 8BitDo Pro 3). If a
different controller idles elsewhere, adjust the threshold check in
`CheckGuide()`.

## Requirements

- AutoHotkey v2.0+
- Windows (uses `xinput1_4.dll` and the Windows joystick/DirectInput API)
- Steam installed (for the `steam://` protocol handler)