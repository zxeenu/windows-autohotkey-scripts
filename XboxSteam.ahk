#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Check the controller every 50 ms
SetTimer(CheckXboxButton, 50)

wasPressed := false

CheckXboxButton() {
    global wasPressed

    ; Xbox controllers expose the Guide button as button 11
    pressed := GetKeyState("Joy11")

    ; Only trigger once per press
    if (pressed && !wasPressed) {
        OpenSteam()
    }

    wasPressed := pressed
}

OpenSteam() {
    ; Launch Steam Big Picture.
    ; If Steam is already running, Steam handles the URI.
    Run("steam://open/bigpicture")
}