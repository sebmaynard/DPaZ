#Requires AutoHotkey v2.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A script which lets you move stuff around the screen, resize it, 
;; and pan and zoom around your whole desktop, just like you would in
;; something like Miro
;; 
;; Press ctrl+windows then mouse buttons:
;;    Left mouse: Move the window under the cursor
;;    Right mouse: Resize the window under the cursor
;;    Middle mouse: Pan the whole desktop around
;;    Scroll wheel: "Zoom" the desktop - feels like you're zooming into or 
;;                  out of the desktop; in practice, it's simply resizing 
;;                  and moving the windows about, sometimes to locations 
;;                  outside of the current screen resolution
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DetectHiddenWindows false

global StartX := 0
global StartY := 0

global delay := 10
global ZoomAmount := 0.30


global Busy := false
;; the last window we "grabbed" - so we don't accidentally grab another one during move/resize
global GrabbedWindow := ""
;; whether we're in the right/left, top/bottom half of the window (for deciding which direction to resize)
;; either "left"/"right"/""
global GrabbedHalfX := ""
;; either "top"/"bottom"/""
global GrabbedHalfY := ""

coordmode "Mouse", "Screen"

A_MaxHotkeysPerInterval := 1000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HOTKEYS


; Hotkey for starting window pan
#^MButton:: {
    global StartX
    global StartY
    MouseGetPos &StartX, &StartY
    SetTimer PanWindows, -delay
}
#^MButton Up:: {
    SetTimer PanWindows, 0
}

#^LButton:: {
    global StartX
    global StartY
    MouseGetPos &StartX, &StartY
    SetTimer MoveWindow, -delay
}
#^LButton Up:: {
    global GrabbedWindow := ""
    SetTimer MoveWindow, 0
}


#^RButton:: {
    global StartX
    global StartY
    MouseGetPos &StartX, &StartY
    SetTimer ResizeWindow, -delay
}
#^RButton Up::{
    global GrabbedWindow := ""
    global GrabbedHalfX := ""
    global GrabbedHalfY := ""
    SetTimer ResizeWindow, 0
}


#^WheelDown::ZoomWindows(-1)

#^WheelUp::ZoomWindows(1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ACTIONS

ZoomWindows(zoom) {
    global StartX
    global StartY
    MouseGetPos &StartX, &StartY
    DoStuffToWindows("zoom", zoom)

    GuiHwnd := WinExist()
}

PanWindows() {
    DoStuffToWindows("pan", 1)
}

MoveWindow() {
    DoStuffToWindows("move", 1)
}

ResizeWindow() {
    DoStuffToWindows("resize", 1)
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MAGIC

DoStuffToWindows(what, multiplier) {
    SetWinDelay -1
    global StartX
    global StartY
    global Busy
    global GrabbedWindow
    global GrabbedHalfX
    global GrabbedHalfY

    switch what {
        case "move": 
            if not GetKeyState("LButton", "P")
                return
        case "pan": 
            if not GetKeyState("MButton", "P")
                return
        case "resize": 
            if not GetKeyState("RButton", "P")
                return
    }

    if (MouseClickDrag)

    ;; if we're already doing something to the window, don't try and clobber it
    if (Busy) 
        return
    Busy := true

    ; Get the current mouse position
    MouseGetPos &MouseX, &MouseY, &WindowUnderCursor

    ; Calculate the offset
    OffsetX := MouseX - StartX
    OffsetY := MouseY - StartY

    ;; Get the list of window ids to affect; different actions have different criteria
    WindowIds := []
    if (what == "resize" || what == "move") {
        ; only applies to window under the cursor
        if (not GrabbedWindow)
            GrabbedWindow := WindowUnderCursor
        WindowIds := [GrabbedWindow]
    }
    else {
        ;; applying to all windows (zoom and pan)
        ; WindowIds := WinGetList("Notepad") ; for testing
        WindowIds := WinGetList(,, "Program Manager")
    }

    ;; remove "bad" windows from our list - either removed windows, or windows that are too small, minimised, hidden etc
    NewWindowIds := []
    for window in WindowIds {
        ;; window has been removed since we started the loop?
        if not WinExist(window)
            continue

        WinGetPos(&WindowX, &WindowY, &WindowWidth, &WindowHeight, window)
        if ( not IsGoodWindow(window, WindowWidth, WindowHeight))
            continue

        NewWindowIds.Push(window)
    }

    ;; Loop through the windows and "do stuff" to them
    for window in NewWindowIds {
        WinGetPos(&WindowX, &WindowY, &WindowWidth, &WindowHeight, window)

        ;; Otherwise, we're good to go
        if (what == "zoom") {
            ; apply a static zoom on each iteration
            scale := 1 + (multiplier * ZoomAmount)

            ; then get a vector from current mouse pos to the center of the window
            ; now move the center of the window to the end point of the scaled vector
            global Center := [WindowWidth / 2, WindowHeight / 2]
            global Vector := [(WindowX + Center[1]) - MouseX, (WindowY + Center[2]) - MouseY]
            ; scale the vector, but keep the origin the same
            global Scaled := [Vector[1] * scale, Vector[2] * scale]
            global NewPos := [MouseX + Scaled[1] - (Center[1] * scale), MouseY + Scaled[2] - (Center[2] * scale)]

            MoveAndResize(NewPos[1], NewPos[2], WindowWidth * scale, WindowHeight * scale, window)
        }
        else if (what == "resize") {
            ;; figure out which quarter of the window we're in so we can "drag" that corner
            ;; essentially moves the window minus amount, and increases its size in the opposite direction
            ;; so the opposite corner doesn't move
            if (not GrabbedHalfX || not GrabbedHalfY) {
                GrabbedHalfX := "right"
                GrabbedHalfY := "bottom"
                if (MouseX < WindowX + WindowWidth / 2) 
                    GrabbedHalfX := "left"
                if (MouseY < WindowY + WindowHeight / 2)
                    GrabbedHalfY := "top"
            }

            if (GrabbedHalfX == "left") {
                OffsetX *= -1
                WindowX -= OffsetX
            }
            if (GrabbedHalfY == "top") {
                OffsetY *= -1
                WindowY -= OffsetY
            }
            MoveAndResize(WindowX, WindowY, WindowWidth + OffsetX, WindowHeight + OffsetY, window)
        }
        else if (what == "move" || what == "pan") {
            MoveAndResize((WindowX + OffsetX), (WindowY + OffsetY), , , window)
        }
    }

    for window in NewWindowIds {
        SetTimer(ResumeRedraw.Bind(window), -delay)
    }

    ; Update the start position for the next calculation
    StartX := MouseX
    StartY := MouseY

    if (what == "pan")
        SetTimer PanWindows, -delay
    if (what == "move")
        SetTimer MoveWindow, -delay
    if (what == "resize")
        SetTimer ResizeWindow, -delay
    
    Busy := false
}

PauseRedraw(window) {
    ; SendMessage(0xB, 0, 0,, window) ; wParam 0 disables redraw
}

ResumeRedraw(window) {
    SendMessage(0xB, 1, 0,, window) ; wParam 1 enables redraw
    ; force a redraw
    DllCall("RedrawWindow", "Ptr", WinExist(window), "Ptr", 0, "Ptr", 0, "UInt", 0x85)
}

IsGoodWindow(window, WindowWidth, WindowHeight) {
    ;; Skip tiny windows
    if (WindowWidth < 2 || WindowHeight < 2)
        return false

    ;; Skip disabled or minimized windows
    Style := WinGetStyle(window)
    WS_DISABLED := 0x8000000
    WS_MINIMIZE := 0x20000000
    if (Style & WS_DISABLED || Style & WS_MINIMIZE) {
        return false
    }

    ;; Skip fully transparent windows
    Trans := WinGetTransparent(window)
    if (Trans == 0) 
        return false

    ;; Skip windows with no title
    Title := WinGetTitle(window)
    if (Title == "" || Title == "Transparent Window") 
        return false

    return true
}

MoveAndResize(WindowX, WindowY, WindowWidth := "", WindowHeight := "", Window := "") {
    SWP_NOREDRAW := 0x0008
    SWP_NOSENDCHANGING := 0x0400
    SWP_DEFERERASE := 0x2000
    SWP_NOCOPYBITS := 0x0100
    SWP_NOZORDER := 0x0004
    Flags := SWP_NOREDRAW | SWP_NOSENDCHANGING | SWP_DEFERERASE | SWP_NOCOPYBITS | SWP_NOZORDER
    try {
        if (WindowWidth && WindowHeight) {
            ; SWP_gcc
            DllCall("SetWindowPos", "UInt", Window, "UInt", 0, "Int", WindowX, "Int", WindowY, "Int", WindowWidth, "Int", WindowHeight, "UInt", Flags)
            ; WinMove(WindowX, WindowY, WindowWidth, WindowHeight, window)
        }
        else {
            SWP_NOSIZE := 0x0001
            Flags |= SWP_NOSIZE
            DllCall("SetWindowPos", "UInt", Window, "UInt", 0, "Int", WindowX, "Int", WindowY, "Int", 0, "Int", 0, "UInt", Flags)
            ; WinMove(WindowX, WindowY, , , Window)
        }
    }
    catch {
        ;; not a lot we can do here...
    }
}

Canvas_DrawLine(p_x1, p_y1, p_x2, p_y2) {
    hDC := DllCall("GetDC", "UInt", 0)
    hCurrPen := DllCall("CreatePen", "UInt", 0, "UInt", 2, "UInt", 0xff0000)
    DllCall("SelectObject", "UInt", hdc, "UInt", hCurrPen)
    DllCall("gdi32.dll\MoveToEx", "UInt", hdc, "UInt", p_x1, "UInt", p_y1, "UInt", 0)
    DllCall("gdi32.dll\LineTo", "UInt", hdc, "UInt", p_x2, "UInt", p_y2)
    DllCall("ReleaseDC", "uint", 0, "uint", hDC)
    DllCall("DeleteObject", "UInt", hCurrPen)
}