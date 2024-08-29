# DPaZ - Desktop Pan and Zoom

I really like Miro and similar tools for whiteboarding - and one particularly nice feature of those is that you can pan and zoom around the whiteboard. Zoom into something to work on it, zoom out, pan a bit and find something else on a giant whiteboard.

This tool aims to replicate that experience for the Windows Desktop - it gives you the feeling of unlimited desktop real-estate.

## Demo

https://github.com/user-attachments/assets/dbd5d3b4-4be3-4022-b728-4749ae275701

## Mappings

Binding                       | Action
----------------------------- | -----------------------------
`Ctrl`+`Win`+`left mouse`     | move a window
`Ctrl`+`Win`+`right mouse`    | resize a window
`Ctrl`+`Win`+`middle mouse`   | pan the whole desktop
`Ctrl`+`Win`+`scroll`         | Zoom in or out of the desktop

You can customize these by editing `DPaZ.ahk` in the `HOTKEYS` section - it defaults to "#*" - Windows and Control

## Installation

This is a short [AutoHotkey](https://www.autohotkey.com/) (v2) script - so install that, then load the `DPaZ.ahk` and you should be good to go.

## How does it work?

The windows are simply resized and moved as if you were doing that normally. The difference here is that it can apply to all windows on the screen at once to give you the feeling of panning the whole desktop. 

Windows aren't actually "zoomed" at all - they're just resized - which means that text remains the same size, just the windows get bigger or smaller.

The script tries its best to avoid trying to move windows that it shouldn't:
* Windows smaller than 2px width or 2px height
* Windows that are disabled or minimised
* Fully transparent windows
* Windows with no title

It uses the Windows DLL function "SetWindowPos" so that windows can be moved/panned whilst setting some flags to improve performance; see https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowpos#parameters for more details

Flag                 | Notes
-------------------- | -----
`SWP_NOREDRAW`       | Does not redraw changes
`SWP_NOSENDCHANGING` | Prevents the window from receiving the WM_WINDOWPOSCHANGING message
`SWP_DEFERERASE`     | Prevents generation of the WM_SYNCPAINT message
`SWP_NOCOPYBITS`     | Discards the entire contents of the client area
`SWP_NOZORDER`       | Retains the current Z order
`SWP_NOSIZE`         | Retains the current size (only used whilst moving/panning, not resizing)
