#Requires AutoHotkey v2.0

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

myGui := Gui(, "Joystick Button Finder")
myGui.SetFont("s10")
outputText := myGui.AddText("w500 h400", "Move sticks / press buttons on each controller...")
myGui.Show()

SetTimer(Update, 100)

Update() {
    global outputText
    out := ""
    Loop 16 {  ; joystick IDs 1-16
        id := A_Index
        name := GetKeyState(id "JoyName")
        if (name = "")
            continue

        numButtons := GetKeyState(id "JoyButtons")
        pressed := ""
        Loop numButtons {
            if GetKeyState(id "Joy" A_Index)
                pressed .= A_Index ","
        }

        x := GetKeyState(id "JoyX")
        y := GetKeyState(id "JoyY")

        out .= "Joystick " id " (" name ") — Buttons: " numButtons
            . " | Pressed: " (pressed = "" ? "none" : pressed)
            . " | X:" Round(x) " Y:" Round(y) "`n"
    }
    outputText.Text := (out = "" ? "No joysticks detected." : out)
}