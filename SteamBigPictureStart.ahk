#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ---- Logging: one file per month, e.g. logs\log-2026-09.txt ----
logDir := A_ScriptDir "\logs"
DirCreate(logDir)
logFile := ""
logMonth := ""

Log(msg) {
    global logDir, logFile, logMonth

    month := FormatTime(, "yyyy-MM")
    if (month != logMonth) {           ; first write, or the month rolled over
        if IsObject(logFile)
            logFile.Close()
        logFile := FileOpen(logDir "\log-" month ".txt", "a")
        logMonth := month
    }

    logFile.WriteLine(FormatTime(, "yyyy-MM-dd HH:mm:ss") " - " msg)
    logFile.Read(0)  ; flush without closing
}

Log("=== Script started ===")

; ---- XInput setup (Xbox-mode / XInput-mode controllers) ----
; Ordinal 100 = XInputGetStateEx, the only XInput call that reports the Guide button
hXInput := DllCall("LoadLibrary", "Str", "xinput1_4.dll", "Ptr")
XInputGetStateEx := DllCall("GetProcAddress", "Ptr", hXInput, "Ptr", 100, "Ptr")
state := Buffer(16, 0)

xGuideHeld := [false, false, false, false]
xChorded  := [false, false, false, false]

; ---- DirectInput setup (Switch-mode 8BitDo, or any HID pad) ----
; Each entry: { joyId: <AHK joystick number>, homeBtn: <button number> }
diPads := [ { joyId: 3, homeBtn: 13 } ]
diGuideHeld := Map()
diChorded  := Map()
for pad in diPads {
    diGuideHeld[pad.joyId] := false
    diChorded[pad.joyId]  := false
}

SetTimer(CheckGuide, 20)

CheckGuide() {
    global xGuideHeld, xChorded, diPads, diGuideHeld, diChorded

    ; --- XInput controllers ---
    Loop 4 {
        slot := A_Index
        if DllCall(XInputGetStateEx, "UInt", slot - 1, "Ptr", state, "UInt") != 0 {
            ; nothing in this slot; clear any stale state
            xGuideHeld[slot] := false
            xChorded[slot] := false
            continue
        }

        buttons := NumGet(state, 4, "UShort")
        lx := NumGet(state, 8, "Short")
        ly := NumGet(state, 10, "Short")

        isDown := (buttons & 0x0400) != 0
        others := (buttons & ~0x0400) != 0 || Abs(lx) > 16000 || Abs(ly) > 16000

        if isDown && !xGuideHeld[slot] {
            xChorded[slot] := false
            Log("XInput slot " (slot - 1) ": Guide pressed")
        }
        if isDown && others && !xChorded[slot] {
            xChorded[slot] := true
            Log("XInput slot " (slot - 1) ": chorded (other input while held) - launch cancelled")
        }

        if !isDown && xGuideHeld[slot] {
            if !xChorded[slot] {
                Log("XInput slot " (slot - 1) ": Guide released, not chorded - triggering launch")
                OpenBigPicture()
            } else {
                Log("XInput slot " (slot - 1) ": Guide released, was chorded - no launch")
            }
        }

        xGuideHeld[slot] := isDown
    }

    ; --- DirectInput / Switch-mode controllers ---
    for pad in diPads {
        id := pad.joyId

        ; Controller not present: reset state so a stale "held" can't fire later
        if (GetKeyState(id "JoyName") = "") {
            ResetDI(id)
            continue
        }

        numButtons := GetKeyState(id "JoyButtons")
        x := GetKeyState(id "JoyX")
        y := GetKeyState(id "JoyY")

        ; Controller dropped out mid-poll (sleep / connection blip)
        if (numButtons = "" || x = "" || y = "") {
            ResetDI(id)
            continue
        }

        isDown := GetKeyState(id "Joy" pad.homeBtn)

        others := false
        Loop numButtons {
            if (A_Index != pad.homeBtn) && GetKeyState(id "Joy" A_Index) {
                others := true
                break
            }
        }
        if (Abs(x - 50) > 25 || Abs(y - 50) > 25)  ; axes report ~0-100, centered ~50
            others := true

        if isDown && !diGuideHeld[id] {
            diChorded[id] := false
            Log("DirectInput joy" id ": Home pressed")
        }
        if isDown && others && !diChorded[id] {
            diChorded[id] := true
            Log("DirectInput joy" id ": chorded (other input while held) - launch cancelled")
        }

        if !isDown && diGuideHeld[id] {
            if !diChorded[id] {
                Log("DirectInput joy" id ": Home released, not chorded - triggering launch")
                OpenBigPicture()
            } else {
                Log("DirectInput joy" id ": Home released, was chorded - no launch")
            }
        }

        diGuideHeld[id] := isDown
    }
}

ResetDI(id) {
    global diGuideHeld, diChorded
    if diGuideHeld[id]
        Log("DirectInput joy" id ": read failed / disconnected while Home held - state reset")
    diGuideHeld[id] := false
    diChorded[id] := false
}

OpenBigPicture() {
    if ProcessExist("steam.exe") {
        Log("Launch requested - Steam already running, skipped")
        return
    }
    Log("Launch requested - Steam not running, launching Big Picture")
    Run("steam://open/bigpicture")
}