#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Ordinal 100 = XInputGetStateEx, the only XInput call that reports the Guide button
hXInput := DllCall("LoadLibrary", "Str", "xinput1_4.dll", "Ptr")
XInputGetStateEx := DllCall("GetProcAddress", "Ptr", hXInput, "Ptr", 100, "Ptr")
state := Buffer(16, 0)

guideHeld := false
chorded := false

SetTimer(CheckGuide, 20)

CheckGuide() {
    global guideHeld, chorded

    buttons := 0, lx := 0, ly := 0
    Loop 4 {  ; controller slots 0-3
        if DllCall(XInputGetStateEx, "UInt", A_Index - 1, "Ptr", state, "UInt") = 0 {
            buttons := NumGet(state, 4, "UShort")
            lx := NumGet(state, 8, "Short")
            ly := NumGet(state, 10, "Short")
            break
        }
    }

    isDown := (buttons & 0x0400) != 0
    others := (buttons & ~0x0400) != 0 || Abs(lx) > 16000 || Abs(ly) > 16000

    if isDown && !guideHeld
        chorded := false          ; new Guide press, reset
    if isDown && others
        chorded := true           ; something else was used while holding Guide

    ; Open Big Picture on release, but only if Guide wasn't used as a chord
    if !isDown && guideHeld && !chorded
        OpenBigPicture()

    guideHeld := isDown
}

OpenBigPicture() {
    ; Steam already running (desktop, Big Picture, or tray): do nothing
    if ProcessExist("steam.exe")
        return

    Run("steam://open/bigpicture")
}