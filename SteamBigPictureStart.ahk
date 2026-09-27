#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; ---- XInput setup (Xbox-mode / XInput-mode controllers) ----
hXInput := DllCall("LoadLibrary", "Str", "xinput1_4.dll", "Ptr")
XInputGetStateEx := DllCall("GetProcAddress", "Ptr", hXInput, "Ptr", 100, "Ptr")
state := Buffer(16, 0)

xGuideHeld := [false, false, false, false]
xChorded  := [false, false, false, false]

; ---- DirectInput setup (Switch-mode 8BitDo, or any HID pad) ----
; Map each entry to { joyId: <AHK joystick number>, homeBtn: <button number> }
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
        if DllCall(XInputGetStateEx, "UInt", slot - 1, "Ptr", state, "UInt") != 0
            continue

        buttons := NumGet(state, 4, "UShort")
        lx := NumGet(state, 8, "Short")
        ly := NumGet(state, 10, "Short")

        isDown := (buttons & 0x0400) != 0
        others := (buttons & ~0x0400) != 0 || Abs(lx) > 16000 || Abs(ly) > 16000

        if isDown && !xGuideHeld[slot]
            xChorded[slot] := false
        if isDown && others
            xChorded[slot] := true

        if !isDown && xGuideHeld[slot] && !xChorded[slot]
            OpenBigPicture()

        xGuideHeld[slot] := isDown
    }

    ; --- DirectInput / Switch-mode controllers ---
    for pad in diPads {
        id := pad.joyId
        name := GetKeyState(id "JoyName")
        if (name = "")
            continue  ; not connected right now

        isDown := GetKeyState(id "Joy" pad.homeBtn)

        others := false
        numButtons := GetKeyState(id "JoyButtons")
        Loop numButtons {
            if (A_Index != pad.homeBtn) && GetKeyState(id "Joy" A_Index) {
                others := true
                break
            }
        }
        x := GetKeyState(id "JoyX"), y := GetKeyState(id "JoyY")
        if (Abs(x - 50) > 25 || Abs(y - 50) > 25)  ; joystick axes report ~0-100, centered ~50
            others := true

        if isDown && !diGuideHeld[id]
            diChorded[id] := false
        if isDown && others
            diChorded[id] := true

        if !isDown && diGuideHeld[id] && !diChorded[id]
            OpenBigPicture()

        diGuideHeld[id] := isDown
    }
}

OpenBigPicture() {
    if ProcessExist("steam.exe")
        return
    Run("steam://open/bigpicture")
}