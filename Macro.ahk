/*
A TDS Macro made by LucasLiorLE
Github: https://github.com/LucasLiorLE
*/

#SingleInstance On
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

RunWith(32)
RunWith(bits) {
If (A_IsCompiled || (A_IsUnicode && (A_PtrSize = (bits = 32 ? 4 : 8))))
Return

SplitPath, A_AhkPath,, ahkDirectory

If (!FileExist(ahkPath := ahkDirectory "\AutoHotkeyU" bits ".exe"))
MsgBox, 0x10, "Error", % "Couldn't find the " bits "-bit Unicode version of Autohotkey in:`n" ahkPath
Else
Reload(ahkpath)

ExitApp
}
Reload(ahkpath) {
static cmd := DllCall("GetCommandLine", "Str"), params := DllCall("shlwapi\PathGetArgs","Str",cmd,"Str")
Run % """" ahkpath """ /r " params
}

; elevate script if required (check write permissions in ScriptDir)
h := DllCall("CreateFile", "Str", A_ScriptFullPath, "UInt", 0x40000000, "UInt", 0, "UInt", 0, "UInt", 4, "UInt", 0, "UInt", 0), DllCall("CloseHandle", "UInt", h)
if (h = -1)
{
if (!A_IsAdmin || !(DllCall("GetCommandLine","Str") ~= " /restart(?!\S)"))
Try RunWait, *RunAs "%A_AhkPath%" /script /restart "%A_ScriptFullPath%"
if !A_IsAdmin {
MsgBox, 0x40010, Error, You must run the macro as administrator in this folder!`nIf you don't want to do this, move the macro to a different folder (e.g. Downloads, Desktop)
ExitApp
}
; elevated but still can't write, read-only directory?
MsgBox, 0x40010, Error, You cannot run the macro in this folder!`nTry moving the macro to a different folder (e.g. Downloads, Desktop)
}

; declare executable paths
global exe_path32 := A_AhkPath
global exe_path64 := (A_Is64bitOS && FileExist("submacros\AutoHotkeyU64.exe")) ? (A_WorkingDir "\submacros\AutoHotkeyU64.exe") : A_AhkPath

;==========================

; CONFIG

If (!FileExist("settings")) ; make sure the settings folder exists
{
FileCreateDir, settings
If (ErrorLevel)
{
MsgBox, 0x40010, Error, Could not create the settings directory!`nTry moving the macro to a different folder (e.g. Downloads, Desktop)
ExitApp
}
}

VersionID := "0.0.1"

if (A_ScreenDPI*100//96 != 100)
msgbox, 0x1030, WARNING!!, % "Your Display Scale seems to be a value other than 100`%. This means the macro will NOT work correctly!`n`nTo change this, right click on your Desktop -> Click 'Display Settings' -> Under 'Scale & Layout', set Scale to 100`% -> Close and Restart Roblox before starting the macro.", 60

DetectHiddenWindows, On
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CONFIG
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; KEYS
FwdKey:="sc011" ; w
LeftKey:="sc01e" ; a
BackKey:="sc01f" ; s
RightKey:="sc020" ; d
RotLeft:="sc033" ; ,
RotRight:="sc034" ; .
RotUp:="sc149" ; PgUp
RotDown:="sc151" ; PgDn
ZoomIn:="sc017" ; i
ZoomOut:="sc018" ; o
SC_E:="sc012" ; e
SC_R:="sc013" ; r
SC_L:="sc026" ; l
SC_Esc:="sc001" ; Esc
SC_Enter:="sc01c" ; Enter
SC_LShift:="sc02a" ; LShift
SC_Space:="sc039" ; Space
SC_1:="sc002" ; 1
TCFBKey:=FwdKey
AFCFBKey:=BackKey
TCLRKey:=LeftKey
AFCLRKey:=RightKey

; CONFIG FILES
config := {}

config["Settings"] := {"StartHotkey":"F1"
    ,"StopHotkey":"F2"
    ,"OpenCOA":"F3"
    ,"OpenMedic":"F4"
    ,"AlwaysOnTop":0}

config["AutoSelect"] := {"PrivateServerLinkCode":""
    ,"Map":"Winter Bridges"
    ,"EGTower":""
    ,"LGTower":""
    ,"UpgradeTowerKeybind":"E"
    ,"DeleteTowerKeybind":"X"
    ,"CommanderAbilityKey":"F"}

config["Status"] := {"TotalRuntime":0
    ,"SessionRuntime":0
    ,"TotalWins":0
    ,"SessionWins":0
    ,"TotalLosses":0
    ,"SessionLosses":0
    ,"TotalRounds":0
    ,"SessionRounds":0
    ,"Webhook":""
    ,"BotToken":""
    ,"MainChannelID":""
    ,"MainChannelCheck":1
    ,"DiscordUID":""
    ,"TotalDisconnects":0
    ,"SessionDisconnects":0}

for k,v in config
for i,j in v
%i% := j

if FileExist(A_WorkingDir "\settings\config.ini")
FileRead, configFiles, "\settings\config.ini"

ini := ""
for k,v in config
{
ini .= "[" k "]`r`n"
for i in v
ini .= i "=" %i% "`r`n"
ini .= "`r`n"
}
FileDelete, %A_WorkingDir%\settings\config.ini
FileAppend, %ini%, %A_WorkingDir%\settings\config.ini

global maps:=["Toyboard","Night Station","Grass Isles","Winter Bridges"]
global loadout:=["Farm", %FTower%, %STower%, "Commander", "DJ"]

;==========================
; START/STOP

Gui, Add, Button, x350 y20 -Wrap vStartButton gStart Disabled, % " Start Macro"
Gui, Add, Button, x425 y20 -Wrap vStopButton gStop Disabled, % " Stop Macro"
Gui, Add, Groupbox, x350 h100, Status

Gui, Add, Button, x350 vHotKeyGUI gHotkeyGUI, Change Hotkeys

Gui, Add, Tab3, x0 y-1 w350 h300 -Wrap hwndhTab vtab, % "Main|Settings|Other|Credits|Status"

; PRIVIVATE SERVER LINKS

Gui, Tab, Main
Gui, Add, GroupBox, x10 y30 w325 h100 vPS, Private server link:
Gui, Add, GroupBox, x10 y150 w325 h100 vMap, Select a map:

Gui, Add, Edit, x20 y50 w280 vPSLink
Gui, Add, Button, gNoPS, I don't have a private server

; MAP SELECTING

Gui, Add, DropDownList, x20 y180 vSelectedMap, Winter Bridges|Grass Isles|Toyboard|Night Station

; SETTINGS/CONFIG

Gui, Tab, Settings
Gui, Add, GroupBox, x10 y30 w150 h125 vTowerSlots, Tower Slots
Gui, Add, GroupBox, x180 y30 w150 h250 vKeybinds, Keybinds (TDS)
Gui, Add, GroupBox, x10 y160 w150 h120 vSettingsReset, Reset
Gui, Add, Text, x20 y50, Select early game tower slot:
Gui, Add, DropDownList, vFTower, Golden Scout|Gladiator|Shotgunner
Gui, Add, Text,, Select late game tower slot:
Gui, Add, DropDownList, vSTower, Minigunner|Golden Minigunner|Accelerator

; RESET

Gui, Font, Bold
Gui, Add, Button, x20 y180 gResetConfig, Reset ALL settings
Gui, Font, w400

; TDS KEYBINDS

Gui, Add, Text, x190 y50, Upgrade tower:
Gui, Add, DropDownList, vUPKey, E|F|C|B|X
Gui, Add, Text,, Delete tower:
Gui, Add, DropDownList, vDelKey, E|F|C|B|X
Gui, Add, Text,, Commander ability:
Gui, Add, DropDownList, vCOAKey, E|F|C|B|X

; CREDITS/CONTRIBUTORS

Gui, Tab, Credits
Gui, Add, Text,, Macro made by LucasLiorLE
Gui, Add, Text,, Single person project!
Gui, Add, Button, gSub, Subscribe to me here!
Gui, Add, Text,, Discord: LucasLiorLE (#9824)

; OTHER TABS (DON'T USE MACRO WITH THEM!)

Gui, Tab, Other
Gui, Add, Button, gCOA, Open auto commander (Don't use with macro)
Gui, Add, Button, gMSpam, Open auto medic spam (Don't use with macro)

; STATUS TABS

Gui, Tab, Status
Gui, Add, CheckBox, gEnableDiscord, Enable discord settings
Gui, Add, Button, vWebhookGUI gWebhook, Change Discord Settings (COMING LATER)


gui +border +hwndhGUI +OwnDialogs
Gui, Show, w500 h300, Tower Defense Simulator Macro v%VersionID%
WinSet, Transparent, % 255-floor(GuiTransparency*2.55), ahk_id %hGUI%


; ENABLE STUFFq


GuiControl, Enable, StartButton
GuiControl, Enable, StopButton

Hotkey, %StartHotkey%, start, UseErrorLevel On
Hotkey, %OpenCOA%, COA, UseErrorLevel On
Hotkey, %OpenMedic%, MSpam, UseErrorLevel On

return

; DEFINE

EnableDiscord:
    return

Start:
Gui, Submit, NoHide

; FIND LOADOUT

PFT := "None"
PST := "None"

If (FTower = "Gladiator") {
    PFT := "Glad"
    If (STower = "Minigunner") {
        PST := "Mini"
    }
    else if (STower = "Golden Minigunner") {
        PST := "Gmini"
    }
    else if (STower = "Accelerator") {
        PST := "Accel"
    }
}
If (FTower = "Golden Scout") {
    PFT := "Gscout"
    If (STower = "Minigunner") {
        PST := "Mini"
    }
    else if (STower = "Golden Minigunner") {
        PST := "Gmini"
    }
    else if (STower = "Accelerator") {
        PST := "Accel"
    }
}
If (FTower = "Shotgunner") {
    PFT := "Shotgun"
    If (STower = "Minigunner") {
        PST := "Mini"
    }
    else if (STower = "Golden Minigunner") {
        PST := "Gmini"
    }
    else if (STower = "Accelerator") {
        PST := "Accel"
    }
}

if ((FTower in Gladiator,Shotgunner,Golden Scout or STower in Accelerator,Minigunner,Golden Minigunner)){
    MsgBox, 4, Are you sure you want to start the macro?,Loadout: Farm, %FTower%, %STower%, Commander, DJ`nMap: %SelectedMap%
    IfMsgBox Yes
        GuiControl, Disable, StartButton
        GuiControl, Enable, StopButton

        ; Run, chrome.exe --new-tab %PSLink%
        ; WinWait, Roblox
        ; WinActivate, Roblox

        ; BUILDING LOADOUT / CHECKING

        ; GO TO MAP

        Run, Join.ahk

        ; WAIT SCRIPT (ADDING LATER)
        Run, Maps\%SelectedMap%\%PFT%%PST%.ahk

    IfMsgBox No
        MsgBox, Canceled.
   
}
else {
    if (FTower in Gladiator,Shotgunner,Golden Scout) {
        MsgBox, Please select a lategame tower.`nYour earlygame tower is: %FTower%
    }
    else if (STower in Accelerator,Minigunner,Golden Minigunner) {
        MsgBox, Please select an earlygame tower.`nYour lategame tower is: %STower%
    }
    else {
        MsgBox, Please select a lategame and earlygame tower.
    }
}
return

Stop:
GuiControl, Enable, StartButton
GuiControl, Disable, StopButton

return

Sub:
Gui, Submit, NoHide
Run, chrome.exe --new-tab youtube.com/@LucasLiorLE
return

NoPS:
clipboard := "https://www.roblox.com/games/3260590327?privateServerLinkCode=96206144108878830123398959346779"
MsgBox, Free VIP Server copied. It might expire.
return

COA:
Run Auto\AutoCommander.ahk
return

MSpam:
Run Auto\AutoMedicSpam.ahk
return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DEFINITIONS (DO NOT TOUCH!)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HotkeyGUI(){
global
Gui, hotkeys:Destroy
Gui, hotkeys:Add, Text, x10 y23 w60 +left +BackgroundTrans,Start Macro:
Gui, hotkeys:Add, Text, x10 yp+19 w60 +left +BackgroundTrans,Stop Macro:
    Gui, hotkeys:Add, Text, x10 yp+19 w60 +left +BackgroundTrans, Open COA:
    Gui, hotkeys:Add, Text, x10 yp+19 w60 +left +BackgroundTrans, Open Medic:
Gui, hotkeys:Add, Hotkey, x70 y20 w120 h18 vStartHotkeyEdit gsaveHotkey, %StartHotkey%
Gui, hotkeys:Add, Hotkey, x70 yp+19 w120 h18 vStopHotkeyEdit gsaveHotkey, %StopHotkey%
    Gui, hotkeys:Add, Hotkey, x70 yp+19 w120 h18 vOpenCOAEdit gsaveHotkey, %OpenCOA%
    Gui, hotkeys:Add, Hotkey, x70 yp+19 w120 h18 vOpenMedicEdit gsaveHotkey, %OpenMedic%
Gui, hotkeys:Add, Button, x30 yp+30 w140 h20 gResetHotkeys, Restore back to defualt
    Gui, hotkeys:Show, AutoSize, Hotkeys
}
ResetHotkeys(){
global
Hotkey, %StartHotkey%, start, UseErrorLevel Off
Hotkey, %StopHotkey%, stop, UseErrorLevel Off
Hotkey, %OpenCOA%, stop, UseErrorLevel Off
Hotkey, %OpenMedic%, stop, UseErrorLevel Off
IniWrite, % (StartHotkey := "F1"), settings\config.ini, Settings, StartHotkey
IniWrite, % (StopHotkey := "F2"), settings\config.ini, Settings, StopHotkey
IniWrite, % (OpenCOA := "F3"), settings\config.ini, Settings, StopHotkey
IniWrite, % (OpenMedic := "F4"), settings\config.ini, Settings, StopHotkey
GuiControl, hotkeys:, StartHotkeyEdit, F1
GuiControl, hotkeys:, StopHotkeyEdit, F2
GuiControl, hotkeys:, OpenCOAEdit, F3
GuiControl, hotkeys:, OpenMedicEdit, F4
GuiControl, %hGUI%:, StartButton, % " Start (F1)"
GuiControl, %hGUI%:, StopButton, % " Stop (F2)"
Hotkey, %StartHotkey%, start, UseErrorLevel On
Hotkey, %StopHotkey%, stop, UseErrorLevel On
    Hotkey, %OpenCOA%, stop, UseErrorLevel On
Hotkey, %OpenMedic%, stop, UseErrorLevel On
}
saveHotkey(hCtrl){
global
local k, v, l, NewHotkey
Gui +OwnDialogs
GuiControlGet, k, Name, %hCtrl%

v := StrReplace(k, "Edit")
if !(%k% ~= "^[!^+]+$")
{
switch % Format("sc{:03X}", GetKeySC(%k%))
{
case FwdKey,LeftKey,BackKey,RightKey,RotLeft,RotRight,RotUp,RotDown,ZoomIn,ZoomOut,SC_E,SC_R,SC_L,SC_Esc,SC_Enter,SC_LShift,SC_Space:
GuiControl, , %hCtrl%, % %v%
msgbox, 0x1030, Unacceptable Hotkey!, % "That hotkey cannot be used!`nThe key is already used elsewhere in the macro."
return

case SC_1,"sc003","sc004","sc005","sc006","sc007","sc008":
GuiControl, , %hCtrl%, % %v%
msgbox, 0x1030, Unacceptable Hotkey!, % "That hotkey cannot be used!`nIt will be required to use your tower slots."
return
}

if (StrLen(%k%) = 0) || (%k% = StartHotkey) || (%k% = StopHotkey) || (%k% = OpenCOA) || (%k% = OpenMedic)
GuiControl, , %hCtrl%, % %v%
else
{
l := StrReplace(v, "Hotkey")
Hotkey, % %v%, %l%, UseErrorLevel Off
IniWrite, % (%v% := %k%), settings\config.ini, Settings, %v%
GuiControl, %hGUI%:, %l%Button, % ((l = "Start") ? " Show " : (l = "Stop") ? "" : " ") l " (" %v% ")"
Hotkey, % %v%, %l%, % ("UseErrorLevel On" (v = "StopButton" ? " T2" : ""))
}
}
}
saveHotkeyConfig(){
global
GuiControlGet, ShowOnPause
IniWrite, %ShowOnPause%, settings\config.ini, Settings, ShowOnPause
}

SaveGui(){
global hGUI, GuiX, GuiY
VarSetCapacity(wp, 44), NumPut(44, wp)
    DllCall("GetWindowPlacement", "uint", hGUI, "uint", &wp)
x := NumGet(wp, 28, "int"), y := NumGet(wp, 32, "int")
if (x > 0)
IniWrite, %x%, settings\config.ini, Settings, GuiX
if (y > 0)
IniWrite, %y%, settings\config.ini, Settings, GuiY
}

ResetConfig(){
Gui, +OwnDialogs
msgbox, 0x40034, Reset Settings, Are you sure you want to reset ALL settings? This will set all settings back to normal.`nIf you want to proceed, click 'Yes'. Backup your 'settings' folder if you're unsure.
IfMsgBox, Yes
{
FileRemoveDir, %A_WorkingDir%\settings, 1
GoSub, stop
        reload
}
}

Webhook() {
    ; COMING LATER!!!
   
webhook := """ webhook """
bottoken := """ bottoken """

MainChannelCheck := """ MainChannelCheck """
MainChannelID := """ MainChannelID """

    Gui, new
    Gui, Add, Text,, Discord webhook ID:
    Gui, Add, Edit, vWebhookID
    Gui, Add, Button, gSendTest, Send Test
    Gui, Add, Button, gSetWebhook, Set Discord Webhook
    Gui, Show, AutoSize, Discord webhook settings
}

SendTest:
    Gui, Submit, NoHide
    url := WebhookID
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST", url, true)
    whr.SetRequestHeader("Content-Type", "application/json")
    whr.Send("{""content"": ""test""}")
return

SetWebhook:
    Gui, Submit, NoHide
    config["Status"]["Webhook"] := WebhookID
    SaveConfig()
    MsgBox, Webhook ID saved!
return

SaveConfig() {
    ini := ""
    for k,v in config
    {
        ini .= "[" k "]`r`n"
        for i in v
            ini .= i "=" %i% "`r`n"
        ini .= "`r`n"
    }
    FileDelete, %A_WorkingDir%\settings\config.ini
    FileAppend, %ini%, %A_WorkingDir%\settings\config.ini
}

GuiClose:
ExitApp
