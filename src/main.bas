' FBEditor Linux - Main Application
' FreeBASIC IDE using Window9 GUI library
' Ported from VB.NET FBEditor by Ronen Blumberg

#Include Once "window9.bi"
#Include Once "types.bi"
#Include Once "syntax.bi"
#Include Once "outline.bi"

' ============================================================
' Line number drawing for GtkTextView
' We use the left border window of the GtkTextView to draw
' line numbers, which is the standard GTK2 approach.
' ============================================================
Const LINE_NUM_WIDTH = 50  ' Width of line number margin in pixels
Dim Shared gDarkGutter As Integer = 0  ' Set by ApplyTheme

' Callback: draw line numbers in the left border window
Function LineNumExposeCB Cdecl(widget As GtkWidget Ptr, evnt As GdkEventExpose Ptr, _
                                userData As gpointer) As gboolean

    Dim As GtkTextView Ptr tv = GTK_TEXT_VIEW(widget)

    ' Only draw in the left border window
    Dim As GdkWindow Ptr leftWin = gtk_text_view_get_window(tv, GTK_TEXT_WINDOW_LEFT)
    If leftWin = 0 Then Return 0
    If evnt->window <> leftWin Then Return 0

    ' Use a static layout to avoid allocation on every expose
    Static As PangoLayout Ptr layout
    If layout = 0 Then layout = gtk_widget_create_pango_layout(widget, "")

    ' Get visible range
    Dim As GdkRectangle visRect
    gtk_text_view_get_visible_rect(tv, @visRect)

    Dim As GtkTextIter startIter, endIter
    Dim As Long yTop
    gtk_text_view_get_line_at_y(tv, @startIter, visRect.y, @yTop)
    gtk_text_view_get_line_at_y(tv, @endIter, visRect.y + visRect.height, @yTop)

    ' Set gutter background color for dark theme
    If gDarkGutter Then
        Dim As GdkColor gutterBg
        gutterBg.red = &h2222 : gutterBg.green = &h2525 : gutterBg.blue = &h2B2B
        gdk_window_set_background(leftWin, @gutterBg)
        gdk_window_clear(leftWin)
    End If

    ' Draw each visible line number
    Dim As GtkTextIter lineIter = startIter
    Dim As Long lastLine = gtk_text_iter_get_line(@endIter)
    Dim As String numStr
    Dim As Long txtW, txtH

    Do
        Dim As Long lineNum = gtk_text_iter_get_line(@lineIter) + 1
        Dim As Long yBuf, lineHeight
        gtk_text_view_get_line_yrange(tv, @lineIter, @yBuf, @lineHeight)

        ' Convert buffer y to window y
        Dim As Long winY
        gtk_text_view_buffer_to_window_coords(tv, GTK_TEXT_WINDOW_LEFT, 0, yBuf, 0, @winY)

        ' Format and measure
        numStr = Str(lineNum)
        pango_layout_set_text(layout, numStr, -1)
        pango_layout_get_pixel_size(layout, @txtW, @txtH)

        ' Draw right-aligned
        gtk_paint_layout(gtk_widget_get_style(widget), leftWin, _
                         GTK_STATE_NORMAL, 0, @(evnt->area), widget, "", _
                         LINE_NUM_WIDTH - txtW - 6, winY, layout)

        If gtk_text_iter_get_line(@lineIter) >= lastLine Then Exit Do
        gtk_text_iter_forward_line(@lineIter)
    Loop

    Return 0
End Function

' Callback: when text buffer changes, invalidate line number area for redraw
Sub LineNumBufferChangedCB Cdecl(buffer As GtkTextBuffer Ptr, userData As gpointer)
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, userData)
    Dim As GdkWindow Ptr leftWin = gtk_text_view_get_window(GTK_TEXT_VIEW(tv), GTK_TEXT_WINDOW_LEFT)
    If leftWin Then gdk_window_invalidate_rect(leftWin, 0, 0)
End Sub

' Setup line numbers on a GtkTextView gadget
Sub SetupLineNumbers(iGadget As Long)
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(iGadget))
    If tv = 0 Then Return

    ' Set left border window size for line numbers
    gtk_text_view_set_border_window_size(GTK_TEXT_VIEW(tv), GTK_TEXT_WINDOW_LEFT, LINE_NUM_WIDTH)

    ' Connect expose-event for drawing
    g_signal_connect(G_OBJECT(tv), "expose-event", G_CALLBACK(@LineNumExposeCB), 0)

    ' Redraw line numbers when text changes
    Dim As GtkTextBuffer Ptr buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv))
    g_signal_connect(G_OBJECT(buf), "changed", G_CALLBACK(@LineNumBufferChangedCB), tv)
End Sub

' ============================================================
' Gadget IDs
' ============================================================
Enum GadgetID
    ' Splitters
    giSplitMain = 1         ' Left panel | Right area
    giSplitRight            ' Editor area | Output panel

    ' Left panel
    giSplitLeft = 3         ' Project tree | Outline tree
    giTreeProject = 10
    giTreeOutline

    ' Editor area
    giEditorContainer = 20  ' Container for combo + editor
    giCboFiles              ' File tab selector
    giEditor                ' Main code editor

    ' Output panel
    giTabOutput = 30        ' Output tabs
    giTxtOutput             ' Compiler output text
    giTxtDebugOutput        ' Debug output

    ' Status bar
    giStatusBar = 40

    ' Find/Replace dialog gadgets (in child window)
    giFindText = 50
    giReplaceText
    giFindNext
    giFindPrev
    giReplaceOne
    giReplaceAll
    giFindClose
    giFindMatchCase

    ' Debug gadgets
    giTxtGDBCmd = 70

    ' Toolbar button IDs
    giTbNew = 75
    giTbOpen
    giTbSave
    giTbUndo
    giTbRedo
    giTbFind
    giTbCompile
    giTbRun

    ' Build options dialog gadgets
    giBldTargetType = 80
    giBldOptimize
    giBldErrCheck
    giBldDebugInfo
    giBldExtraFlags
    giBldIncPaths
    giBldLibPaths
    giBldOK
    giBldCancel
End Enum

' ============================================================
' Menu IDs
' ============================================================
Enum MenuID
    ' File menu
    mnuFileNew = 100
    mnuFileOpen
    mnuFileSave
    mnuFileSaveAs
    mnuFileClose
    mnuFileSaveAll
    mnuFileExit
    mnuRecentBase = 110     ' 110-119 for recent files

    ' Edit menu
    mnuEditUndo = 200
    mnuEditRedo
    mnuEditCut
    mnuEditCopy
    mnuEditPaste
    mnuEditSelectAll
    mnuEditComment
    mnuEditUncomment
    mnuEditFind
    mnuEditReplace
    mnuEditGoToLine
    mnuEditSelectLine
    mnuEditDuplicateLine
    mnuEditDeleteLine

    ' View menu
    mnuViewDarkTheme = 350
    mnuViewRefreshOutline
    mnuViewWordWrap
    mnuViewFont
    mnuViewZoomIn
    mnuViewZoomOut
    mnuViewZoomReset

    ' Build menu
    mnuBuildCompile = 300
    mnuBuildCompileRun
    mnuBuildRun
    mnuBuildOptions
    mnuBuildSetFBC

    ' Debug menu
    mnuDebugStart = 360
    mnuDebugStop
    mnuDebugStepOver
    mnuDebugStepInto
    mnuDebugStepOut
    mnuDebugToggleBP

    ' Help menu
    mnuHelpAbout = 400
End Enum

' ============================================================
' Keyboard Shortcut IDs
' ============================================================
Enum ShortcutID
    kbNew = 500
    kbOpen
    kbSave
    kbClose
    kbCompile
    kbCompileRun
    kbRun
    kbFind
    kbReplace
    kbGoToLine
    kbComment
    kbUncomment
    kbDebugStart
    kbDebugStop
    kbDebugStepOver
    kbDebugStepInto
    kbDebugStepOut
    kbDebugToggleBP
    kbFindNext
    kbRefreshOutline
    kbAutoComplete
    kbZoomIn
    kbZoomOut
    kbZoomReset
    kbNextFile
    kbPrevFile
    kbSelectLine
    kbDuplicateLine
    kbMoveLineUp
    kbMoveLineDown
    kbSaveAll
    kbDeleteLine
End Enum

' ============================================================
' Theme colors
' ============================================================
Const DARK_BG      = Bgr(40, 44, 52)
Const DARK_FG      = Bgr(171, 178, 191)
Const DARK_EDITOR  = Bgr(30, 33, 40)
Const DARK_PANEL   = Bgr(33, 37, 43)
Const LIGHT_BG     = Bgr(255, 255, 255)
Const LIGHT_FG     = Bgr(0, 0, 0)

' ============================================================
' Global State
' ============================================================
Dim Shared hWin As HWND                       ' Main window handle
Dim Shared hFindWin As HWND                   ' Find/Replace window
Dim Shared hBuildOptWin As HWND               ' Build options window
Dim Shared gSettings As EditorSettings
Dim Shared gBuild As BuildSettings
Dim Shared gFiles(MAX_OPEN_FILES - 1) As OpenFileInfo
Dim Shared gFileCount As Long = 0
Dim Shared gActiveFile As Long = -1
Dim Shared gNewFileCounter As Long = 0
Dim Shared gAppPath As String
Dim Shared gConfigPath As String
Dim Shared gEditorFont As Long = 0
Dim Shared gRecentFiles(MAX_RECENT_FILES - 1) As String
Dim Shared gRecentCount As Long = 0
Dim Shared gFindMatchCase As Integer = 0
Dim Shared gLastFindText As String
Dim Shared gStatusDirty As Integer = 0  ' Deferred status bar update flag
Dim Shared gModifyDirty As Integer = 0  ' Deferred modify check flag
Dim Shared gHighlightDirty As Integer = 0  ' Deferred syntax highlight flag
Dim Shared gWordWrap As Integer = 0
Dim Shared gFontSize As Long = 11
Dim Shared gFontName As String
Dim Shared gWinX As Long = 50
Dim Shared gWinY As Long = 50
Dim Shared gWinW As Long = 1200
Dim Shared gWinH As Long = 750
Dim Shared gSplitMainPos As Long = 220
Dim Shared gSplitRightPos As Long = 0
Dim Shared gSplitLeftPos As Long = 0
Dim Shared gStartupFile As String
Dim Shared gToolbar As Long = 0

' Compiler errors parsed from build output
Const MAX_ERRORS = 100
Type ParsedError
    filePath As String
    lineNum As Long
    msg As String
End Type
Dim Shared gErrors(MAX_ERRORS - 1) As ParsedError
Dim Shared gErrorCount As Long = 0

' Auto-complete state
Dim Shared hAutoWin As HWND               ' Auto-complete popup window
Const giAutoList = 90                      ' Listbox gadget ID in popup

' Debugger state
Dim Shared gDbgRunning As Integer = 0
Dim Shared gDbgPaused As Integer = 0
Dim Shared gDbgPID As Long = 0

' ============================================================
' Forward Declarations
' ============================================================
Declare Sub InitSettings()
Declare Sub SaveSettings()
Declare Sub CreateMainWindow()
Declare Sub CreateMenuBar()
Declare Sub CreateToolbarUI()
Declare Sub CreateLayout()
Declare Sub SetupStatusBar()
Declare Sub HandleResize()
Declare Sub ResizeInternalGadgets()
Declare Sub ApplyTheme()

Declare Sub DoNewFile()
Declare Sub DoOpenFile()
Declare Sub DoOpenFilePath(filePath As String)
Declare Sub DoSaveFile()
Declare Sub DoSaveFileAs()
Declare Sub DoCloseFile()
Declare Sub SwitchToFile(idx As Long)
Declare Sub UpdateFileCombo()
Declare Sub UpdateTitle()
Declare Sub UpdateStatusBar()
Declare Sub CheckEditorModified()
Declare Sub SyncEditorToFile()
Declare Sub SyncFileFromEditor()
Declare Sub UpdateProjectTree()

Declare Sub DoBuild(runAfter As Integer = 0)
Declare Sub DoRun()
Declare Sub DoSetFBCPath()
Declare Function BuildCommandLine(sourceFile As String) As String
Declare Function FindFBCPath() As String

Declare Sub ShowFindReplace(showReplace As Integer)
Declare Sub DoFindNext(searchForward As Integer)
Declare Sub DoReplaceOne()
Declare Sub DoReplaceAll()
Declare Sub DoGoToLine()
Declare Sub DoCommentBlock()
Declare Sub DoUncommentBlock()

Declare Sub AddRecentFile(filePath As String)
Declare Sub LoadRecentFiles()
Declare Sub SaveRecentFiles()

Declare Sub DoDebugStart()
Declare Sub DoDebugStop()
Declare Sub DoDebugStepOver()
Declare Sub DoDebugStepInto()
Declare Sub DoDebugStepOut()
Declare Sub DoToggleBreakpoint()

Declare Sub AppendOutput(txt As String)
Declare Sub ClearOutput()
Declare Sub AppendDebugOutput(txt As String)
Declare Sub SetStatusText(txt As String)
Declare Sub RefreshOutline()
Declare Sub GoToOutlineItem()
Declare Sub ShowBuildOptions()
Declare Sub ApplyBuildOptions()
Declare Sub CloseBuildOptions()
Declare Sub ParseCompilerErrors(compilerOutput As String)
Declare Sub JumpToError(errLine As Long)
Declare Sub ShowAutoComplete()
Declare Sub HideAutoComplete()
Declare Sub InsertAutoComplete()
Declare Function GetWordAtCursor() As String
Declare Sub ToggleWordWrap()
Declare Sub ChangeEditorFont()
Declare Sub DoToggleComment()
Declare Sub DoSelectLine()
Declare Sub DoDuplicateLine()
Declare Sub DoMoveLineUp()
Declare Sub DoMoveLineDown()
Declare Sub DoDeleteLine()
Declare Sub SetEditorFontSize(newSize As Long)
Declare Sub SaveAllModified()
Declare Sub SetupDragDrop()

' ============================================================
' Settings
' ============================================================
Sub InitSettings()
    gAppPath = Getcurentdir()
    gConfigPath = Environ("HOME") + "/.config/fbeditor"

    gSettings.TabWidth = 4
    gSettings.ShowLineNumbers = -1
    gSettings.DarkTheme = -1

    gBuild.FBCPath = FindFBCPath()
    gBuild.GDBPath = ""
    gBuild.TargetType = 0
    gBuild.Optimization = 0
    gBuild.ErrorChecking = 0
    gBuild.DebugInfo = -1
    gBuild.ExtraCompilerOpts = ""
    gBuild.IncludePaths = ""
    gBuild.LibraryPaths = ""

    ' Find GDB
    If w9isFileExists("/usr/bin/gdb") Then
        gBuild.GDBPath = "/usr/bin/gdb"
    ElseIf w9isFileExists("/usr/local/bin/gdb") Then
        gBuild.GDBPath = "/usr/local/bin/gdb"
    End If

    If w9isFileExists(gConfigPath + "/settings.ini") Then
        Dim As Any Ptr cfg = ConfigCreate()
        ConfigLoad(cfg, gConfigPath + "/settings.ini")
        Dim As String v

        v = GetConfigValue(cfg, "Build", "FBCPath")
        If Len(v) > 0 Then gBuild.FBCPath = v
        v = GetConfigValue(cfg, "Build", "GDBPath")
        If Len(v) > 0 Then gBuild.GDBPath = v
        v = GetConfigValue(cfg, "Build", "TargetType")
        If Len(v) > 0 Then gBuild.TargetType = Val(v)
        v = GetConfigValue(cfg, "Build", "DebugInfo")
        If Len(v) > 0 Then gBuild.DebugInfo = Val(v)
        v = GetConfigValue(cfg, "Editor", "TabWidth")
        If Len(v) > 0 Then gSettings.TabWidth = Val(v)
        v = GetConfigValue(cfg, "Editor", "DarkTheme")
        If Len(v) > 0 Then gSettings.DarkTheme = Val(v)
        v = GetConfigValue(cfg, "Editor", "FontSize")
        If Len(v) > 0 Then gFontSize = Val(v)
        v = GetConfigValue(cfg, "Editor", "FontName")
        If Len(v) > 0 Then gFontName = v

        v = GetConfigValue(cfg, "Window", "X")
        If Len(v) > 0 Then gWinX = Val(v)
        v = GetConfigValue(cfg, "Window", "Y")
        If Len(v) > 0 Then gWinY = Val(v)
        v = GetConfigValue(cfg, "Window", "W")
        If Len(v) > 0 Then gWinW = Val(v)
        v = GetConfigValue(cfg, "Window", "H")
        If Len(v) > 0 Then gWinH = Val(v)
        v = GetConfigValue(cfg, "Window", "SplitMain")
        If Len(v) > 0 Then gSplitMainPos = Val(v)
        v = GetConfigValue(cfg, "Window", "SplitRight")
        If Len(v) > 0 Then gSplitRightPos = Val(v)
        v = GetConfigValue(cfg, "Window", "SplitLeft")
        If Len(v) > 0 Then gSplitLeftPos = Val(v)

        ConfigDelete(cfg)
    End If

    LoadRecentFiles()
End Sub

Sub SaveSettings()
    If w9isDirExists(gConfigPath) = 0 Then
        Createdir(gConfigPath)
    End If

    Dim As Any Ptr cfg = ConfigCreate()
    SetConfigValue(cfg, "Build", "FBCPath", gBuild.FBCPath)
    SetConfigValue(cfg, "Build", "GDBPath", gBuild.GDBPath)
    SetConfigValue(cfg, "Build", "TargetType", Str(gBuild.TargetType))
    SetConfigValue(cfg, "Build", "DebugInfo", Str(gBuild.DebugInfo))
    SetConfigValue(cfg, "Editor", "TabWidth", Str(gSettings.TabWidth))
    SetConfigValue(cfg, "Editor", "DarkTheme", Str(gSettings.DarkTheme))
    SetConfigValue(cfg, "Editor", "FontSize", Str(gFontSize))
    If Len(gFontName) > 0 Then SetConfigValue(cfg, "Editor", "FontName", gFontName)

    ' Save window position and size
    SetConfigValue(cfg, "Window", "X", Str(Windowx(hWin)))
    SetConfigValue(cfg, "Window", "Y", Str(Windowy(hWin)))
    SetConfigValue(cfg, "Window", "W", Str(Windowwidth(hWin)))
    SetConfigValue(cfg, "Window", "H", Str(Windowheight(hWin)))
    SetConfigValue(cfg, "Window", "SplitMain", Str(GetSplitterPos(giSplitMain)))
    SetConfigValue(cfg, "Window", "SplitRight", Str(GetSplitterPos(giSplitRight)))
    SetConfigValue(cfg, "Window", "SplitLeft", Str(GetSplitterPos(giSplitLeft)))

    ConfigSave(cfg, gConfigPath + "/settings.ini")
    ConfigDelete(cfg)

    SaveRecentFiles()
End Sub

' ============================================================
' Recent Files
' ============================================================
Sub AddRecentFile(filePath As String)
    ' Remove if already in list
    Dim As Long i, j
    For i = 0 To gRecentCount - 1
        If LCase(gRecentFiles(i)) = LCase(filePath) Then
            For j = i To gRecentCount - 2
                gRecentFiles(j) = gRecentFiles(j + 1)
            Next
            gRecentCount -= 1
            Exit For
        End If
    Next
    ' Insert at top
    If gRecentCount >= MAX_RECENT_FILES Then gRecentCount = MAX_RECENT_FILES - 1
    For i = gRecentCount To 1 Step -1
        gRecentFiles(i) = gRecentFiles(i - 1)
    Next
    gRecentFiles(0) = filePath
    gRecentCount += 1
End Sub

Sub LoadRecentFiles()
    Dim As String rfPath = gConfigPath + "/recent.txt"
    If w9isFileExists(rfPath) = 0 Then Return
    Dim As Long ff = FreeFile
    If Open(rfPath For Input As #ff) <> 0 Then Return
    gRecentCount = 0
    Do Until Eof(ff) OrElse gRecentCount >= MAX_RECENT_FILES
        Dim As String ln
        Line Input #ff, ln
        ln = Trim(ln)
        If Len(ln) > 0 Then
            gRecentFiles(gRecentCount) = ln
            gRecentCount += 1
        End If
    Loop
    Close #ff
End Sub

Sub SaveRecentFiles()
    If w9isDirExists(gConfigPath) = 0 Then Createdir(gConfigPath)
    Dim As String rfPath = gConfigPath + "/recent.txt"
    Dim As Long ff = FreeFile
    If Open(rfPath For Output As #ff) = 0 Then
        For i As Long = 0 To gRecentCount - 1
            Print #ff, gRecentFiles(i)
        Next
        Close #ff
    End If
End Sub

' ============================================================
' Find FBC compiler on Linux
' ============================================================
Function FindFBCPath() As String
    If w9isFileExists("/usr/local/bin/fbc") Then Return "/usr/local/bin/fbc"
    If w9isFileExists("/usr/bin/fbc") Then Return "/usr/bin/fbc"
    Dim As String result
    Dim As Long ff = FreeFile
    Open Pipe "which fbc 2>/dev/null" For Input As #ff
    Line Input #ff, result
    Close #ff
    result = Trim(result)
    If Len(result) > 0 AndAlso w9isFileExists(result) Then Return result
    Return ""
End Function

' ============================================================
' Theme
' ============================================================
Sub ApplyTheme()
    gDarkGutter = gSettings.DarkTheme
    If gSettings.DarkTheme Then
        Windowcolor(hWin, DARK_BG)
        ' flag 3 = set both BG and FG
        Setgadgetcolor(giEditor, DARK_EDITOR, DARK_FG, 3)
        Setgadgetcolor(giTxtOutput, DARK_PANEL, DARK_FG, 3)
        Setgadgetcolor(giTxtDebugOutput, DARK_PANEL, DARK_FG, 3)
        Setgadgetcolor(giTreeProject, DARK_PANEL, DARK_FG, 3)
        Setgadgetcolor(giTreeOutline, DARK_PANEL, DARK_FG, 3)
        Setgadgetcolor(giTxtGDBCmd, DARK_PANEL, DARK_FG, 3)
    Else
        Windowcolor(hWin, LIGHT_BG)
        Setgadgetcolor(giEditor, LIGHT_BG, LIGHT_FG, 3)
        Setgadgetcolor(giTxtOutput, LIGHT_BG, LIGHT_FG, 3)
        Setgadgetcolor(giTxtDebugOutput, LIGHT_BG, LIGHT_FG, 3)
        Setgadgetcolor(giTreeProject, LIGHT_BG, LIGHT_FG, 3)
        Setgadgetcolor(giTreeOutline, LIGHT_BG, LIGHT_FG, 3)
        Setgadgetcolor(giTxtGDBCmd, LIGHT_BG, LIGHT_FG, 3)
    End If
End Sub

' ============================================================
' Main Window & Layout
' ============================================================
Sub CreateMainWindow()
    hWin = Openwindow(APP_NAME + " " + APP_VERSION, gWinX, gWinY, gWinW, gWinH)
    Windowbounds(hWin, 400, 300, 4000, 3000)
End Sub

Sub CreateMenuBar()
    Dim As HMENU hMenu, mFile, mEdit, mView, mBuild, mDebug, mHelp

    hMenu = Create_menu()

    ' ---- File ----
    mFile = Menutitle(hMenu, "File")
    Menuitem(mnuFileNew, mFile, "New                Ctrl+N")
    Menuitem(mnuFileOpen, mFile, "Open...          Ctrl+O")
    Menuitem(0, mFile, "-")
    Menuitem(mnuFileSave, mFile, "Save               Ctrl+S")
    Menuitem(mnuFileSaveAs, mFile, "Save As...")
    Menuitem(mnuFileSaveAll, mFile, "Save All          Ctrl+Shift+S")
    Menuitem(0, mFile, "-")
    Menuitem(mnuFileClose, mFile, "Close File      Ctrl+W")
    Menuitem(0, mFile, "-")
    ' Recent files will be added dynamically via submenu
    Dim As HMENU mRecent = Opensubmenu(mFile, "Recent Files")
    For i As Long = 0 To gRecentCount - 1
        Menuitem(mnuRecentBase + i, mRecent, Getfilepart(gRecentFiles(i)))
    Next
    If gRecentCount = 0 Then
        Menuitem(0, mRecent, "(empty)")
    End If
    Menuitem(0, mFile, "-")
    Menuitem(mnuFileExit, mFile, "Exit")

    ' ---- Edit ----
    mEdit = Menutitle(hMenu, "Edit")
    Menuitem(mnuEditUndo, mEdit, "Undo                Ctrl+Z")
    Menuitem(mnuEditRedo, mEdit, "Redo                Ctrl+Y")
    Menuitem(0, mEdit, "-")
    Menuitem(mnuEditCut, mEdit, "Cut")
    Menuitem(mnuEditCopy, mEdit, "Copy")
    Menuitem(mnuEditPaste, mEdit, "Paste")
    Menuitem(0, mEdit, "-")
    Menuitem(mnuEditSelectAll, mEdit, "Select All")
    Menuitem(0, mEdit, "-")
    Menuitem(mnuEditComment, mEdit, "Comment Block       Ctrl+/")
    Menuitem(mnuEditUncomment, mEdit, "Uncomment Block")
    Menuitem(0, mEdit, "-")
    Menuitem(mnuEditFind, mEdit, "Find...              Ctrl+F")
    Menuitem(mnuEditReplace, mEdit, "Replace...         Ctrl+H")
    Menuitem(mnuEditGoToLine, mEdit, "Go To Line...    Ctrl+G")
    Menuitem(0, mEdit, "-")
    Menuitem(mnuEditSelectLine, mEdit, "Select Line         Ctrl+L")
    Menuitem(mnuEditDuplicateLine, mEdit, "Duplicate Line    Ctrl+D")
    Menuitem(mnuEditDeleteLine, mEdit, "Delete Line          Ctrl+Shift+K")

    ' ---- View ----
    mView = Menutitle(hMenu, "View")
    Menuitem(mnuViewDarkTheme, mView, "Toggle Dark/Light Theme")
    Menuitem(mnuViewWordWrap, mView, "Toggle Word Wrap")
    Menuitem(mnuViewFont, mView, "Editor Font...")
    Menuitem(0, mView, "-")
    Menuitem(mnuViewZoomIn, mView, "Zoom In                  Ctrl++")
    Menuitem(mnuViewZoomOut, mView, "Zoom Out                Ctrl+-")
    Menuitem(mnuViewZoomReset, mView, "Reset Zoom            Ctrl+0")
    Menuitem(0, mView, "-")
    Menuitem(mnuViewRefreshOutline, mView, "Refresh Outline        F4")

    ' ---- Build ----
    mBuild = Menutitle(hMenu, "Build")
    Menuitem(mnuBuildCompile, mBuild, "Compile              Ctrl+F5")
    Menuitem(mnuBuildCompileRun, mBuild, "Compile && Run   F6")
    Menuitem(mnuBuildRun, mBuild, "Run                    Ctrl+F6")
    Menuitem(0, mBuild, "-")
    Menuitem(mnuBuildOptions, mBuild, "Build Options...")
    Menuitem(mnuBuildSetFBC, mBuild, "Set FBC Path...")

    ' ---- Debug ----
    mDebug = Menutitle(hMenu, "Debug")
    Menuitem(mnuDebugStart, mDebug, "Start / Continue   F5")
    Menuitem(mnuDebugStop, mDebug, "Stop                   Shift+F5")
    Menuitem(0, mDebug, "-")
    Menuitem(mnuDebugStepOver, mDebug, "Step Over          F10")
    Menuitem(mnuDebugStepInto, mDebug, "Step Into           F11")
    Menuitem(mnuDebugStepOut, mDebug, "Step Out            Shift+F11")
    Menuitem(0, mDebug, "-")
    Menuitem(mnuDebugToggleBP, mDebug, "Toggle Breakpoint F9")

    ' ---- Help ----
    mHelp = Menutitle(hMenu, "Help")
    Menuitem(mnuHelpAbout, mHelp, "About FBEditor")

    Menubar(hMenu)

    ' Keyboard shortcuts
    Addkeyboardshortcut(hWin, FCONTROL, VK_N, kbNew)
    Addkeyboardshortcut(hWin, FCONTROL, VK_O, kbOpen)
    Addkeyboardshortcut(hWin, FCONTROL, VK_S, kbSave)
    Addkeyboardshortcut(hWin, FCONTROL, VK_W, kbClose)
    Addkeyboardshortcut(hWin, FCONTROL, VK_F5, kbCompile)
    Addkeyboardshortcut(hWin, 0, VK_F6, kbCompileRun)
    Addkeyboardshortcut(hWin, FCONTROL, VK_F6, kbRun)
    Addkeyboardshortcut(hWin, FCONTROL, VK_F, kbFind)
    Addkeyboardshortcut(hWin, FCONTROL, VK_H, kbReplace)
    Addkeyboardshortcut(hWin, FCONTROL, VK_G, kbGoToLine)
    Addkeyboardshortcut(hWin, 0, VK_F3, kbFindNext)
    Addkeyboardshortcut(hWin, 0, VK_F5, kbDebugStart)
    Addkeyboardshortcut(hWin, FSHIFT, VK_F5, kbDebugStop)
    Addkeyboardshortcut(hWin, 0, VK_F10, kbDebugStepOver)
    Addkeyboardshortcut(hWin, 0, VK_F11, kbDebugStepInto)
    Addkeyboardshortcut(hWin, FSHIFT, VK_F11, kbDebugStepOut)
    Addkeyboardshortcut(hWin, 0, VK_F9, kbDebugToggleBP)
    Addkeyboardshortcut(hWin, 0, VK_F4, kbRefreshOutline)
    Addkeyboardshortcut(hWin, FCONTROL, VK_space, kbAutoComplete)
    Addkeyboardshortcut(hWin, FCONTROL, &h02F, kbComment)        ' Ctrl+/
    Addkeyboardshortcut(hWin, FCONTROL, VK_Add, kbZoomIn)       ' Ctrl+NumPad+
    Addkeyboardshortcut(hWin, FCONTROL, VK_Subtract, kbZoomOut) ' Ctrl+NumPad-
    Addkeyboardshortcut(hWin, FCONTROL, VK_0, kbZoomReset)      ' Ctrl+0
    Addkeyboardshortcut(hWin, FCONTROL, VK_NEXT, kbNextFile)   ' Ctrl+PageDown
    Addkeyboardshortcut(hWin, FCONTROL, VK_PRIOR, kbPrevFile)  ' Ctrl+PageUp
    Addkeyboardshortcut(hWin, FCONTROL, VK_L, kbSelectLine)
    Addkeyboardshortcut(hWin, FCONTROL, VK_D, kbDuplicateLine)
    Addkeyboardshortcut(hWin, FCONTROL Or FSHIFT, VK_S, kbSaveAll)
    Addkeyboardshortcut(hWin, FCONTROL Or FSHIFT, VK_K, kbDeleteLine)
End Sub

Sub CreateToolbarUI()
    Usegadgetlist(hWin)
    gToolbar = Createtoolbar(IDB_STD_SMALL_COLOR, TBSTYLE_TOOLTIPS)
    ' Index: 0=Cut 1=Copy 2=Paste 3=Undo 4=Redo 5=Delete 6=New 7=Open 8=Save
    '        9=PrintPreview 10=Properties 11=Help 12=Find 13=FindReplace 14=Print
    Toolbarstandardbutton(gToolbar, giTbNew, 6, "New")
    Toolbarstandardbutton(gToolbar, giTbOpen, 7, "Open")
    Toolbarstandardbutton(gToolbar, giTbSave, 8, "Save")
    Toolbarseparator(gToolbar)
    Toolbarstandardbutton(gToolbar, giTbUndo, 3, "Undo")
    Toolbarstandardbutton(gToolbar, giTbRedo, 4, "Redo")
    Toolbarseparator(gToolbar)
    Toolbarstandardbutton(gToolbar, giTbFind, 12, "Find")
    Toolbarseparator(gToolbar)
    Toolbarstandardbutton(gToolbar, giTbCompile, 10, "Build")
    Toolbarstandardbutton(gToolbar, giTbRun, 9, "Run")
End Sub

Sub CreateLayout()
    Dim As Long winW = Windowclientwidth(hWin)
    Dim As Long winH = Windowclientheight(hWin)
    Dim As Long topH = 60          ' Menu (28) + Toolbar (32)
    Dim As Long statusH = 24
    Dim As Long bodyH = winH - topH - statusH

    Dim As Long mainSplit = IIf(gSplitMainPos > 0, gSplitMainPos, 220)
    Dim As Long leftSplit = IIf(gSplitLeftPos > 0, gSplitLeftPos, bodyH \ 3)
    Dim As Long rightSplit = IIf(gSplitRightPos > 0, gSplitRightPos, bodyH - 200)

    Usegadgetlist(hWin)
    SplitterGadget(giSplitMain, 0, topH, winW, bodyH, mainSplit, 1)

    ' Left: project tree (top) / code outline (bottom)
    Usegadgetlist(Gadgetid(giSplitMain))
    SplitterGadget(giSplitLeft, 0, 0, 220, bodyH, leftSplit, 0)

    Usegadgetlist(Gadgetid(giSplitLeft))
    Treeviewgadget(giTreeProject, 0, 0, 220, bodyH \ 3)
    Treeviewgadget(giTreeOutline, 0, 0, 220, bodyH * 2 \ 3)
    SplitterGadgetAddGadget(giSplitLeft, giTreeProject, giTreeOutline)

    ' Right: editor / output
    Usegadgetlist(Gadgetid(giSplitMain))
    Dim As Long rightW = winW - mainSplit
    SplitterGadget(giSplitRight, 0, 0, rightW, bodyH, rightSplit, 0)

    ' Editor container (combo + editor)
    Dim As Long edH = bodyH - 200
    Usegadgetlist(Gadgetid(giSplitRight))
    Containergadget(giEditorContainer, 0, 0, rightW, edH)
    Usegadgetlist(Gadgetid(giEditorContainer))
    Comboboxgadget(giCboFiles, 0, 0, rightW, 28)
    Editorgadget(giEditor, 0, 28, rightW, edH - 28, "", 0)
    Settabstopseditor(giEditor, gSettings.TabWidth * 8)
    SetupLineNumbers(giEditor)
    InitSyntaxHighlight(giEditor, gSettings.DarkTheme)
    SetupDragDrop()

    ' Load monospace font
    If Len(gFontName) = 0 Then gFontName = "Monospace"
    gEditorFont = Loadfont(gFontName, gFontSize)

    ' Output panel (tabbed)
    Dim As Long outH = 200
    Usegadgetlist(Gadgetid(giSplitRight))
    Panelgadget(giTabOutput, 0, 0, rightW, outH)

    ' Output tab
    Dim As HWND tabOut = Addpanelgadgetitem(giTabOutput, 0, "Output", 0)
    Usegadgetlist(tabOut)
    Editorgadget(giTxtOutput, 0, 0, rightW, outH - 30, "", 0)
    Readonlyeditor(giTxtOutput, 1)

    ' Debug Output tab
    Dim As HWND tabDbg = Addpanelgadgetitem(giTabOutput, 1, "Debug", 0)
    Usegadgetlist(tabDbg)
    Editorgadget(giTxtDebugOutput, 0, 0, rightW, outH - 56, "", 0)
    Readonlyeditor(giTxtDebugOutput, 1)
    Stringgadget(giTxtGDBCmd, 0, outH - 56, rightW, 26, "")

    ' Set fonts
    If gEditorFont Then
        Setgadgetfont(giEditor, gEditorFont)
        Setgadgetfont(giTxtOutput, gEditorFont)
        Setgadgetfont(giTxtDebugOutput, gEditorFont)
        Setgadgetfont(giTxtGDBCmd, gEditorFont)
    End If

    ' Wire splitters
    SplitterGadgetAddGadget(giSplitRight, giEditorContainer, giTabOutput)
    SplitterGadgetAddGadget(giSplitMain, giSplitLeft, giSplitRight)

    ' Status bar
    Usegadgetlist(hWin)
    SetupStatusBar()
End Sub

Sub SetupStatusBar()
    Usegadgetlist(hWin)
    Statusbargadget(giStatusBar, "Ready")
    Setstatusbarfield(giStatusBar, 0, 500, "Ready")
    Setstatusbarfield(giStatusBar, 1, 150, "Ln: 1  Col: 1")
    Setstatusbarfield(giStatusBar, 2, 100, "UTF-8")
End Sub

Sub ResizeInternalGadgets()
    Static As Integer inResize = 0
    If inResize Then Return
    inResize = -1

    ' Resize editor container children to fill the container
    Dim As Long contW = Gadgetwidth(giEditorContainer)
    Dim As Long contH = Gadgetheight(giEditorContainer)
    If contW > 10 AndAlso contH > 30 Then
        Resizegadget(giCboFiles, 0, 0, contW, 28)
        Resizegadget(giEditor, 0, 28, contW, contH - 28)
    End If

    ' Resize output text to fill the tab panel
    Dim As Long outW = Gadgetwidth(giTabOutput)
    Dim As Long outH = Gadgetheight(giTabOutput)
    If outW > 10 AndAlso outH > 30 Then
        Resizegadget(giTxtOutput, 0, 0, outW, outH - 30)
        Resizegadget(giTxtDebugOutput, 0, 0, outW, outH - 56)
        Resizegadget(giTxtGDBCmd, 0, outH - 56, outW, 26)
    End If

    inResize = 0
End Sub

Sub HandleResize()
    Dim As Long winW = Windowclientwidth(hWin)
    Dim As Long winH = Windowclientheight(hWin)
    Resizegadget(giSplitMain, 0, 60, winW, winH - 84)
    ResizeInternalGadgets()
End Sub

' ============================================================
' File Operations
' ============================================================
Function NewUntitledName() As String
    gNewFileCounter += 1
    If gNewFileCounter = 1 Then Return "Untitled.bas"
    Return "Untitled" + Str(gNewFileCounter) + ".bas"
End Function

Sub DoNewFile()
    If gFileCount >= MAX_OPEN_FILES Then
        Messbox("Error", "Maximum number of open files reached.")
        Return
    End If
    Dim As Long idx = gFileCount
    gFiles(idx).FileName = NewUntitledName()
    gFiles(idx).FilePath = ""
    gFiles(idx).IsModified = 0
    gFiles(idx).Content = ""
    gFiles(idx).CursorPos = 0
    gFiles(idx).IsNew = -1
    gFiles(idx).FileEnc = ENC_UTF8
    gFileCount += 1
    SwitchToFile(idx)
    UpdateFileCombo()
    UpdateProjectTree()
    SetStatusText("New file created")
End Sub

Sub DoOpenFile()
    Dim As String filter = "FreeBASIC (*.bas *.bi)" + Chr(0) + "*.bas;*.bi" + Chr(0) + _
                           "All files (*.*)" + Chr(0) + "*.*" + Chr(0)
    Dim As String filePath = Openfilerequester("Open File", Getcurentdir(), filter)
    If Len(filePath) > 0 Then DoOpenFilePath(filePath)
End Sub

Sub DoOpenFilePath(filePath As String)
    If Len(filePath) = 0 Then Return

    ' Check if already open
    For i As Long = 0 To gFileCount - 1
        If gFiles(i).FilePath = filePath Then
            SwitchToFile(i)
            Return
        End If
    Next

    If gFileCount >= MAX_OPEN_FILES Then
        Messbox("Error", "Maximum number of open files reached.")
        Return
    End If

    Dim As String content
    Dim As Long ff = FreeFile
    If Open(filePath For Input As #ff) = 0 Then
        If Lof(ff) > 0 Then content = Input(Lof(ff), ff)
        Close #ff
    Else
        Messbox("Error", "Could not open file: " + filePath)
        Return
    End If

    Dim As Long idx = gFileCount
    gFiles(idx).FilePath = filePath
    gFiles(idx).FileName = Getfilepart(filePath)
    gFiles(idx).IsModified = 0
    gFiles(idx).Content = content
    gFiles(idx).CursorPos = 0
    gFiles(idx).IsNew = 0
    gFiles(idx).FileEnc = ENC_UTF8
    gFileCount += 1

    AddRecentFile(filePath)
    SwitchToFile(idx)
    UpdateFileCombo()
    UpdateProjectTree()
    SetStatusText("Opened: " + filePath)
End Sub

Sub DoSaveFile()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return
    SyncFileFromEditor()
    If gFiles(gActiveFile).IsNew Then
        DoSaveFileAs()
        Return
    End If
    Dim As Long ff = FreeFile
    If Open(gFiles(gActiveFile).FilePath For Output As #ff) = 0 Then
        Print #ff, gFiles(gActiveFile).Content;
        Close #ff
        gFiles(gActiveFile).IsModified = 0
        Setmodifyeditor(giEditor, 0)
        UpdateTitle()
        UpdateFileCombo()
        UpdateProjectTree()
        SetStatusText("Saved: " + gFiles(gActiveFile).FilePath)
    Else
        Messbox("Error", "Could not save file: " + gFiles(gActiveFile).FilePath)
    End If
End Sub

Sub DoSaveFileAs()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return
    SyncFileFromEditor()
    Dim As String filter = "FreeBASIC (*.bas *.bi)" + Chr(0) + "*.bas;*.bi" + Chr(0) + _
                           "All files (*.*)" + Chr(0) + "*.*" + Chr(0)
    Dim As String filePath = Savefilerequester("Save File As", Getcurentdir(), filter)
    If Len(filePath) = 0 Then Return
    gFiles(gActiveFile).FilePath = filePath
    gFiles(gActiveFile).FileName = Getfilepart(filePath)
    gFiles(gActiveFile).IsNew = 0
    Dim As Long ff = FreeFile
    If Open(filePath For Output As #ff) = 0 Then
        Print #ff, gFiles(gActiveFile).Content;
        Close #ff
        gFiles(gActiveFile).IsModified = 0
        Setmodifyeditor(giEditor, 0)
        AddRecentFile(filePath)
        UpdateFileCombo()
        UpdateTitle()
        UpdateProjectTree()
        SetStatusText("Saved: " + filePath)
    Else
        Messbox("Error", "Could not save file: " + filePath)
    End If
End Sub

Sub DoCloseFile()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return
    SyncFileFromEditor()
    If gFiles(gActiveFile).IsModified Then
        Dim As Long ans = Messbox("Save Changes?", _
            "File '" + gFiles(gActiveFile).FileName + "' has unsaved changes." + Chr(10) + _
            "Save before closing?", MB_YESNOCANCEL)
        If ans = IDYES Then DoSaveFile()
        If ans = IDCANCEL Then Return
    End If
    For i As Long = gActiveFile To gFileCount - 2
        gFiles(i) = gFiles(i + 1)
    Next
    gFileCount -= 1
    gFiles(gFileCount).FilePath = ""
    gFiles(gFileCount).FileName = ""
    gFiles(gFileCount).Content = ""
    If gFileCount = 0 Then
        gActiveFile = -1
        Setgadgettext(giEditor, "")
        Resetallcombobox(giCboFiles)
        UpdateTitle()
    Else
        If gActiveFile >= gFileCount Then gActiveFile = gFileCount - 1
        SwitchToFile(gActiveFile)
        UpdateFileCombo()
    End If
    UpdateProjectTree()
End Sub

Sub SwitchToFile(idx As Long)
    If idx < 0 OrElse idx >= gFileCount Then Return
    SyncFileFromEditor()
    gActiveFile = idx
    SyncEditorToFile()
    UpdateTitle()
    UpdateStatusBar()
    Setitemcombobox(giCboFiles, idx)
End Sub

Sub SyncEditorToFile()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return
    Setgadgettext(giEditor, gFiles(gActiveFile).Content)
    Setmodifyeditor(giEditor, 0)
    HighlightAll(giEditor)
    RefreshOutline()
End Sub

Sub SyncFileFromEditor()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return
    gFiles(gActiveFile).Content = Getgadgettext(giEditor)
    If Getmodifyeditor(giEditor) Then gFiles(gActiveFile).IsModified = -1
End Sub

Sub CheckEditorModified()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return
    If Getmodifyeditor(giEditor) AndAlso gFiles(gActiveFile).IsModified = 0 Then
        gFiles(gActiveFile).IsModified = -1
        UpdateTitle()
        UpdateFileCombo()
    End If
End Sub

Sub UpdateFileCombo()
    Resetallcombobox(giCboFiles)
    For i As Long = 0 To gFileCount - 1
        Dim As String label = gFiles(i).FileName
        If gFiles(i).IsModified Then label = "* " + label
        Addcomboboxitem(giCboFiles, label)
    Next
    If gActiveFile >= 0 Then Setitemcombobox(giCboFiles, gActiveFile)
End Sub

Sub UpdateTitle()
    Dim As String title = APP_NAME + " " + APP_VERSION
    If gActiveFile >= 0 AndAlso gActiveFile < gFileCount Then
        title = gFiles(gActiveFile).FileName
        If gFiles(gActiveFile).IsModified Then title = "* " + title
        If Len(gFiles(gActiveFile).FilePath) > 0 Then
            title += " - " + gFiles(gActiveFile).FilePath
        End If
        title += " - " + APP_NAME
    End If
    Setwindowtext(hWin, title)
End Sub

Sub UpdateStatusBar()
    If gActiveFile >= 0 AndAlso gActiveFile < gFileCount Then
        Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
        Dim As Long ln = Linefromchareditor(giEditor, curIdx) + 1
        Dim As Long lineStart = Lineindexeditor(giEditor, ln - 1)
        Dim As Long col = curIdx - lineStart + 1
        Dim As Long totalLines = Getlinecounteditor(giEditor)
        Dim As String info = "Ln: " + Str(ln) + "/" + Str(totalLines) + "  Col: " + Str(col)

        ' Show selection info if text is selected
        Dim As String selText = Getselecttexteditorgadget(giEditor)
        If Len(selText) > 0 Then
            ' Count selected lines
            Dim As Long selLines = 1, si = 1
            Do
                si = InStr(si, selText, Chr(10))
                If si > 0 Then selLines += 1 : si += 1 Else Exit Do
            Loop
            info += "  Sel: " + Str(Len(selText)) + " chars"
            If selLines > 1 Then info += ", " + Str(selLines) + " lines"
        End If

        If gFiles(gActiveFile).IsModified Then info += "  [*]"
        Setstatusbarfield(giStatusBar, 1, 300, info)
    End If
End Sub

Sub UpdateProjectTree()
    Deletetreeviewitemall(giTreeProject)
    If gFileCount = 0 Then Return
    Dim As Long root = Addtreeviewitem(giTreeProject, "Open Files", 0, 0, 0, 0)
    For i As Long = 0 To gFileCount - 1
        Dim As String label = gFiles(i).FileName
        If gFiles(i).IsModified Then label = "* " + label
        Addtreeviewitem(giTreeProject, label, 0, 0, 0, root)
    Next
    Expandtreeviewitem(giTreeProject, root, 1)
End Sub

' ============================================================
' Find / Replace
' ============================================================
Sub ShowFindReplace(showReplace As Integer)
    ' Use InputBox approach — create a child window
    If hFindWin <> 0 Then
        ' Bring existing window to front
        Hidewindow(hFindWin, 0)
        Setfocus(Gadgetid(giFindText))
        Return
    End If

    Dim As Long fW = 420, fH = IIf(showReplace, 200, 150)
    hFindWin = Openwindow("Find / Replace", 200, 200, fW, fH, _
                          WS_OVERLAPPEDWINDOW Or WS_VISIBLE, 0, 0, hWin)

    Usegadgetlist(hFindWin)
    Textgadget(0, 10, 10, 50, 22, "Find:")
    Stringgadget(giFindText, 65, 8, 230, 26, gLastFindText)
    Buttongadget(giFindNext, 305, 8, 50, 26, "Next")
    Buttongadget(giFindPrev, 360, 8, 50, 26, "Prev")

    If showReplace Then
        Textgadget(0, 10, 42, 55, 22, "Replace:")
        Stringgadget(giReplaceText, 65, 40, 230, 26, "")
        Buttongadget(giReplaceOne, 305, 40, 50, 26, "One")
        Buttongadget(giReplaceAll, 360, 40, 50, 26, "All")
    End If

    Dim As Long yOff = IIf(showReplace, 76, 44)
    Checkboxgadget(giFindMatchCase, 65, yOff, 150, 24, "Match case")
    If gFindMatchCase Then Setgadgetstate(giFindMatchCase, 1)
    Buttongadget(giFindClose, 305, yOff, 105, 26, "Close")

    Setfocus(Gadgetid(giFindText))
End Sub

Sub DoFindNext(searchForward As Integer)
    Dim As String searchText
    If hFindWin <> 0 Then
        searchText = Getgadgettext(giFindText)
        gFindMatchCase = Getgadgetstate(giFindMatchCase)
    Else
        searchText = gLastFindText
    End If

    If Len(searchText) = 0 Then Return
    gLastFindText = searchText

    Dim As String edText = Getgadgettext(giEditor)
    Dim As Long curPos = Getcurrentindexchareditor(giEditor)

    Dim As String haystack = edText
    Dim As String needle = searchText
    If gFindMatchCase = 0 Then
        haystack = LCase(haystack)
        needle = LCase(needle)
    End If

    Dim As Long foundPos = 0
    If searchForward Then
        foundPos = InStr(curPos + 2, haystack, needle)
        If foundPos = 0 Then foundPos = InStr(1, haystack, needle) ' wrap
    Else
        ' Search backward
        Dim As Long fPos = 0, lastFound = 0
        Do
            fPos = InStr(fPos + 1, haystack, needle)
            If fPos > 0 AndAlso fPos < curPos Then lastFound = fPos
        Loop While fPos > 0 AndAlso fPos < curPos
        foundPos = lastFound
        If foundPos = 0 Then
            ' Wrap from end
            fPos = InStr(curPos + 1, haystack, needle)
            Do While fPos > 0
                lastFound = fPos
                fPos = InStr(fPos + 1, haystack, needle)
            Loop
            foundPos = lastFound
        End If
    End If

    If foundPos > 0 Then
        Setselecttexteditorgadget(giEditor, foundPos - 1, foundPos - 1 + Len(searchText))
        ' Scroll to line
        Dim As Long ln = Linefromchareditor(giEditor, foundPos - 1)
        Dim As Long firstVis = Getfirstvisiblelineeditor(giEditor)
        If ln < firstVis OrElse ln > firstVis + 30 Then
            Linescrolleditor(giEditor, ln - firstVis - 10)
        End If
        SetStatusText("Found at position " + Str(foundPos))
    Else
        SetStatusText("Not found: " + searchText)
        Messbox("Find", "Text not found: " + searchText)
    End If
End Sub

Sub DoReplaceOne()
    If hFindWin = 0 Then Return
    Dim As String replText = Getgadgettext(giReplaceText)
    Dim As String selText = Getselecttexteditorgadget(giEditor)

    If Len(selText) > 0 Then
        ' Replace selection with replacement text
        Pasteeditor(giEditor, replText)
        CheckEditorModified()
    End If
    DoFindNext(-1) ' Find next occurrence
End Sub

Sub DoReplaceAll()
    If hFindWin = 0 Then Return
    Dim As String searchText = Getgadgettext(giFindText)
    Dim As String replText = Getgadgettext(giReplaceText)
    gFindMatchCase = Getgadgetstate(giFindMatchCase)

    If Len(searchText) = 0 Then Return
    gLastFindText = searchText

    Dim As String edText = Getgadgettext(giEditor)
    Dim As Long count = 0
    Dim As Long fPos = 0

    ' Simple replace all
    Dim As String result = ""
    Dim As String haystack = edText
    Dim As String needle = searchText
    If gFindMatchCase = 0 Then
        haystack = LCase(haystack)
        needle = LCase(needle)
    End If

    Dim As Long lastEnd = 1
    Do
        fPos = InStr(lastEnd, haystack, needle)
        If fPos > 0 Then
            result += Mid(edText, lastEnd, fPos - lastEnd) + replText
            lastEnd = fPos + Len(searchText)
            count += 1
        End If
    Loop While fPos > 0

    result += Mid(edText, lastEnd)

    If count > 0 Then
        Setgadgettext(giEditor, result)
        CheckEditorModified()
        SetStatusText("Replaced " + Str(count) + " occurrence(s)")
    Else
        SetStatusText("No occurrences found")
    End If
End Sub

' ============================================================
' Go To Line
' ============================================================
Sub DoGoToLine()
    Dim As String lineStr = Inputbox("Go To Line", "Line number:", "1", 0, 0, hWin)
    If Len(lineStr) = 0 Then Return
    Dim As Long targetLine = Val(lineStr)
    If targetLine < 1 Then Return
    Dim As Long totalLines = Getlinecounteditor(giEditor)
    If targetLine > totalLines Then targetLine = totalLines
    Dim As Long lineIdx = Lineindexeditor(giEditor, targetLine - 1)
    Setselecttexteditorgadget(giEditor, lineIdx, lineIdx)
    Dim As Long firstVis = Getfirstvisiblelineeditor(giEditor)
    Linescrolleditor(giEditor, (targetLine - 1) - firstVis - 10)
    Setfocus(Gadgetid(giEditor))
    UpdateStatusBar()
    SetStatusText("Line " + Str(targetLine))
End Sub

' ============================================================
' Comment / Uncomment Block
' ============================================================
Sub DoCommentBlock()
    Dim As String edText = Getgadgettext(giEditor)
    Dim As Long selStart = 0, selEnd = 0
    Dim As String selText = Getselecttexteditorgadget(giEditor)

    If Len(selText) = 0 Then
        ' Comment current line
        Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
        Dim As Long ln = Linefromchareditor(giEditor, curIdx)
        Dim As Long lineStart = Lineindexeditor(giEditor, ln)
        Setselecttexteditorgadget(giEditor, lineStart, lineStart)
        Pasteeditor(giEditor, "' ")
    Else
        ' Comment each selected line
        Dim As String result = ""
        Dim As Long i = 1
        Do
            Dim As Long nlPos = InStr(i, selText, Chr(10))
            Dim As String ln
            If nlPos > 0 Then
                ln = Mid(selText, i, nlPos - i)
                result += "' " + ln + Chr(10)
                i = nlPos + 1
            Else
                ln = Mid(selText, i)
                result += "' " + ln
                i = Len(selText) + 1
            End If
        Loop While i <= Len(selText)
        Pasteeditor(giEditor, result)
    End If
    CheckEditorModified()
End Sub

Sub DoUncommentBlock()
    Dim As String selText = Getselecttexteditorgadget(giEditor)

    If Len(selText) = 0 Then
        ' Uncomment current line
        Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
        Dim As Long ln = Linefromchareditor(giEditor, curIdx)
        Dim As String lineText = Getlinetexteditor(giEditor, ln)
        Dim As String trimmed = LTrim(lineText)
        If Left(trimmed, 2) = "' " Then
            Dim As Long commentPos = InStr(lineText, "' ")
            Dim As Long lineStart = Lineindexeditor(giEditor, ln)
            Setselecttexteditorgadget(giEditor, lineStart + commentPos - 1, lineStart + commentPos + 1)
            Pasteeditor(giEditor, "")
        ElseIf Left(trimmed, 1) = "'" Then
            Dim As Long commentPos = InStr(lineText, "'")
            Dim As Long lineStart = Lineindexeditor(giEditor, ln)
            Setselecttexteditorgadget(giEditor, lineStart + commentPos - 1, lineStart + commentPos)
            Pasteeditor(giEditor, "")
        End If
    Else
        ' Uncomment each selected line
        Dim As String result = ""
        Dim As Long i = 1
        Do
            Dim As Long nlPos = InStr(i, selText, Chr(10))
            Dim As String ln
            If nlPos > 0 Then
                ln = Mid(selText, i, nlPos - i)
            Else
                ln = Mid(selText, i)
            End If
            Dim As String trimmed = LTrim(ln)
            If Left(trimmed, 2) = "' " Then
                Dim As Long cPos = InStr(ln, "' ")
                ln = Left(ln, cPos - 1) + Mid(ln, cPos + 2)
            ElseIf Left(trimmed, 1) = "'" Then
                Dim As Long cPos = InStr(ln, "'")
                ln = Left(ln, cPos - 1) + Mid(ln, cPos + 1)
            End If
            result += ln
            If nlPos > 0 Then result += Chr(10)
            i = IIf(nlPos > 0, nlPos + 1, Len(selText) + 1)
        Loop While i <= Len(selText)
        Pasteeditor(giEditor, result)
    End If
    CheckEditorModified()
End Sub

' Toggle comment: if line starts with ' → uncomment, else comment
Sub DoToggleComment()
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx)
    Dim As String lineText = Getlinetexteditor(giEditor, ln)
    Dim As String trimmed = LTrim(lineText)

    If Left(trimmed, 2) = "' " OrElse Left(trimmed, 1) = "'" Then
        DoUncommentBlock()
    Else
        DoCommentBlock()
    End If
End Sub

' Select current line (Ctrl+L)
Sub DoSelectLine()
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx)
    Dim As Long lineStart = Lineindexeditor(giEditor, ln)
    Dim As Long lineLen = Linelengtheditor(giEditor, ln)
    Setselecttexteditorgadget(giEditor, lineStart, lineStart + lineLen)
End Sub

' Duplicate current line (Ctrl+D)
Sub DoDuplicateLine()
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx)
    Dim As String lineText = Getlinetexteditor(giEditor, ln)
    ' Move to end of line and insert newline + copy
    Dim As Long lineStart = Lineindexeditor(giEditor, ln)
    Dim As Long lineLen = Linelengtheditor(giEditor, ln)
    Setselecttexteditorgadget(giEditor, lineStart + lineLen, lineStart + lineLen)
    Pasteeditor(giEditor, Chr(10) + lineText)
    CheckEditorModified()
    gHighlightDirty = -1
End Sub

' Delete current line (Ctrl+Shift+K)
Sub DoDeleteLine()
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx)
    Dim As Long totalLines = Getlinecounteditor(giEditor)
    Dim As Long lineStart = Lineindexeditor(giEditor, ln)
    Dim As Long lineLen = Linelengtheditor(giEditor, ln)

    ' Include the newline character if not the last line
    Dim As Long delEnd = lineStart + lineLen
    If ln < totalLines - 1 Then delEnd += 1  ' include trailing newline

    Setselecttexteditorgadget(giEditor, lineStart, delEnd)
    Pasteeditor(giEditor, "")
    CheckEditorModified()
    gHighlightDirty = -1
End Sub

' Move current line up (Alt+Up)
Sub DoMoveLineUp()
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx)
    If ln <= 0 Then Return

    Dim As String curLine = Getlinetexteditor(giEditor, ln)
    Dim As String prevLine = Getlinetexteditor(giEditor, ln - 1)

    ' Select previous line + current line and replace swapped
    Dim As Long prevStart = Lineindexeditor(giEditor, ln - 1)
    Dim As Long curEnd = Lineindexeditor(giEditor, ln) + Linelengtheditor(giEditor, ln)
    Setselecttexteditorgadget(giEditor, prevStart, curEnd)
    Pasteeditor(giEditor, curLine + Chr(10) + prevLine)

    ' Place cursor on the moved line
    Dim As Long newStart = Lineindexeditor(giEditor, ln - 1)
    Setselecttexteditorgadget(giEditor, newStart, newStart)
    CheckEditorModified()
    gHighlightDirty = -1
End Sub

' Move current line down (Alt+Down)
Sub DoMoveLineDown()
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx)
    Dim As Long totalLines = Getlinecounteditor(giEditor)
    If ln >= totalLines - 1 Then Return

    Dim As String curLine = Getlinetexteditor(giEditor, ln)
    Dim As String nextLine = Getlinetexteditor(giEditor, ln + 1)

    ' Select current line + next line and replace swapped
    Dim As Long curStart = Lineindexeditor(giEditor, ln)
    Dim As Long nextEnd = Lineindexeditor(giEditor, ln + 1) + Linelengtheditor(giEditor, ln + 1)
    Setselecttexteditorgadget(giEditor, curStart, nextEnd)
    Pasteeditor(giEditor, nextLine + Chr(10) + curLine)

    ' Place cursor on the moved line
    Dim As Long newStart = Lineindexeditor(giEditor, ln + 1)
    Setselecttexteditorgadget(giEditor, newStart, newStart)
    CheckEditorModified()
    gHighlightDirty = -1
End Sub

' ============================================================
' Code Outline
' ============================================================
Sub RefreshOutline()
    Deletetreeviewitemall(giTreeOutline)
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return

    SyncFileFromEditor()
    ParseOutline(gFiles(gActiveFile).Content)

    If gOutlineCount = 0 Then Return

    ' Group items by category
    Dim As Long procRoot = 0, typeRoot = 0, enumRoot = 0
    Dim As Long constRoot = 0, declRoot = 0, defRoot = 0

    For i As Long = 0 To gOutlineCount - 1
        Dim As Long parentNode = 0
        Dim As String cat = gOutline(i).category

        If cat = "Procedures" Then
            If procRoot = 0 Then procRoot = Addtreeviewitem(giTreeOutline, "Procedures", 0, 0, 0, 0)
            parentNode = procRoot
        ElseIf cat = "Types" Then
            If typeRoot = 0 Then typeRoot = Addtreeviewitem(giTreeOutline, "Types", 0, 0, 0, 0)
            parentNode = typeRoot
        ElseIf cat = "Enums" Then
            If enumRoot = 0 Then enumRoot = Addtreeviewitem(giTreeOutline, "Enums", 0, 0, 0, 0)
            parentNode = enumRoot
        ElseIf cat = "Constants" Then
            If constRoot = 0 Then constRoot = Addtreeviewitem(giTreeOutline, "Constants", 0, 0, 0, 0)
            parentNode = constRoot
        ElseIf cat = "Declares" Then
            If declRoot = 0 Then declRoot = Addtreeviewitem(giTreeOutline, "Declares", 0, 0, 0, 0)
            parentNode = declRoot
        ElseIf cat = "Defines" Then
            If defRoot = 0 Then defRoot = Addtreeviewitem(giTreeOutline, "Defines", 0, 0, 0, 0)
            parentNode = defRoot
        End If

        If parentNode > 0 Then
            Dim As String label = gOutline(i).prefix + " " + gOutline(i).itemName
            Addtreeviewitem(giTreeOutline, label, 0, 0, 0, parentNode)
        End If
    Next

    ' Expand all categories
    If procRoot Then Expandtreeviewitem(giTreeOutline, procRoot, 1)
    If typeRoot Then Expandtreeviewitem(giTreeOutline, typeRoot, 1)
    If enumRoot Then Expandtreeviewitem(giTreeOutline, enumRoot, 1)
    If constRoot Then Expandtreeviewitem(giTreeOutline, constRoot, 1)
    If declRoot Then Expandtreeviewitem(giTreeOutline, declRoot, 1)
    If defRoot Then Expandtreeviewitem(giTreeOutline, defRoot, 1)
End Sub

Sub GoToOutlineItem()
    ' Get selected item text from outline tree
    Dim As Long selItem = Getitemtreeview(giTreeOutline)
    If selItem <= 0 Then Return

    Dim As String selText = Gettexttreeview(giTreeOutline, selItem)
    If Len(selText) = 0 Then Return

    ' Skip category headers (they don't have a prefix like "Sub ", "Function ", etc.)
    ' Find matching outline item by name
    For i As Long = 0 To gOutlineCount - 1
        Dim As String label = gOutline(i).prefix + " " + gOutline(i).itemName
        If label = selText Then
            ' Jump to line
            Dim As Long targetLine = gOutline(i).lineNum
            Dim As Long lineIdx = Lineindexeditor(giEditor, targetLine - 1)
            Setselecttexteditorgadget(giEditor, lineIdx, lineIdx)
            Dim As Long firstVis = Getfirstvisiblelineeditor(giEditor)
            Linescrolleditor(giEditor, (targetLine - 1) - firstVis - 10)
            Setfocus(Gadgetid(giEditor))
            UpdateStatusBar()
            SetStatusText("Line " + Str(targetLine) + ": " + selText)
            Return
        End If
    Next
End Sub

' ============================================================
' Build System
' ============================================================
Function BuildCommandLine(sourceFile As String) As String
    Dim As String args = ""
    If gBuild.TargetType = 1 Then args += " -s gui"
    If gBuild.Optimization > 0 Then args += " -O " + Str(gBuild.Optimization)
    Select Case gBuild.ErrorChecking
        Case 1 : args += " -e"
        Case 2 : args += " -ex"
        Case 3 : args += " -exx"
    End Select
    If gBuild.DebugInfo Then args += " -g"
    If Len(gBuild.IncludePaths) > 0 Then args += " -i """ + gBuild.IncludePaths + """"
    If Len(gBuild.LibraryPaths) > 0 Then args += " -p """ + gBuild.LibraryPaths + """"
    If Len(gBuild.ExtraCompilerOpts) > 0 Then args += " " + gBuild.ExtraCompilerOpts
    args += " """ + sourceFile + """"
    Return args
End Function

Sub DoBuild(runAfter As Integer = 0)
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then
        Messbox("Build", "No file open to compile.")
        Return
    End If
    ' Save all modified files before building
    SyncFileFromEditor()
    If gFiles(gActiveFile).IsNew Then
        DoSaveFileAs()
        If gFiles(gActiveFile).IsNew Then Return
    End If
    SaveAllModified()

    If Len(gBuild.FBCPath) = 0 Then
        Messbox("Build Error", "FreeBASIC compiler path not set." + Chr(10) + _
                "Use Build > Set FBC Path...")
        Return
    End If

    Dim As String sourceFile = gFiles(gActiveFile).FilePath
    Dim As String args = BuildCommandLine(sourceFile)
    Dim As String cmdLine = gBuild.FBCPath + args
    Dim As String workDir = Getpathpart(sourceFile)

    ClearOutput()
    AppendOutput("Compiler: " + gBuild.FBCPath + Chr(10))
    AppendOutput("Command:  " + cmdLine + Chr(10))
    AppendOutput("Source:   " + sourceFile + Chr(10))
    AppendOutput(String(60, Asc("-")) + Chr(10))
    SetStatusText("Building...")

    ' Switch to output tab
    Panelgadgetsetcursel(giTabOutput, 0)

    Dim As String compOut, ln
    Dim As Long ff = FreeFile
    Open Pipe cmdLine + " 2>&1" For Input As #ff
    Do Until Eof(ff)
        Line Input #ff, ln
        compOut += ln + Chr(10)
    Loop
    Close #ff

    Dim As String outExe = Left(sourceFile, InStrRev(sourceFile, ".") - 1)
    Dim As Integer buildSuccess = w9isFileExists(outExe)

    If Len(compOut) > 0 Then AppendOutput(compOut)
    AppendOutput(String(60, Asc("-")) + Chr(10))

    ' Parse errors from output
    ParseCompilerErrors(compOut)

    If buildSuccess OrElse Len(Trim(compOut)) = 0 Then
        AppendOutput("Build successful!" + Chr(10))
        SetStatusText("Build successful")
        If runAfter AndAlso w9isFileExists(outExe) Then
            AppendOutput("Running: " + outExe + Chr(10))
            Runprogram(outExe, "", workDir)
        End If
    Else
        If gErrorCount > 0 Then
            AppendOutput(Str(gErrorCount) + " error(s) found. Double-click output to jump to error." + Chr(10))
            ' Jump to first error automatically
            JumpToError(gErrors(0).lineNum)
        End If
        AppendOutput("Build FAILED" + Chr(10))
        SetStatusText("Build failed - " + Str(gErrorCount) + " error(s)")
    End If
End Sub

Sub DoRun()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return
    If gFiles(gActiveFile).IsNew Then Return
    Dim As String sourceFile = gFiles(gActiveFile).FilePath
    Dim As String outExe = Left(sourceFile, InStrRev(sourceFile, ".") - 1)
    Dim As String workDir = Getpathpart(sourceFile)
    If w9isFileExists(outExe) Then
        Runprogram(outExe, "", workDir)
        SetStatusText("Running: " + outExe)
    Else
        Messbox("Run", "Executable not found: " + outExe + Chr(10) + "Compile first.")
    End If
End Sub

Sub DoSetFBCPath()
    Dim As String filter = "All files (*.*)" + Chr(0) + "*.*" + Chr(0)
    Dim As String fbcPath = Openfilerequester("Select FreeBASIC Compiler (fbc)", "/usr/local/bin/", filter)
    If Len(fbcPath) > 0 Then
        gBuild.FBCPath = fbcPath
        SaveSettings()
        SetStatusText("FBC path set: " + fbcPath)
    End If
End Sub

' ============================================================
' Build Options Dialog
' ============================================================
Sub ShowBuildOptions()
    If hBuildOptWin <> 0 Then
        Hidewindow(hBuildOptWin, 0)
        Return
    End If

    hBuildOptWin = Openwindow("Build Options", 200, 150, 450, 380, _
                              WS_OVERLAPPEDWINDOW Or WS_VISIBLE, 0, 0, hWin)
    Usegadgetlist(hBuildOptWin)

    Dim As Long yy = 10

    ' Target type
    Textgadget(0, 10, yy, 120, 22, "Target Type:")
    Comboboxgadget(giBldTargetType, 140, yy - 2, 280, 28)
    Addcomboboxitem(giBldTargetType, "Console Application")
    Addcomboboxitem(giBldTargetType, "GUI Application (-s gui)")
    Setitemcombobox(giBldTargetType, gBuild.TargetType)
    yy += 34

    ' Optimization
    Textgadget(0, 10, yy, 120, 22, "Optimization:")
    Comboboxgadget(giBldOptimize, 140, yy - 2, 280, 28)
    Addcomboboxitem(giBldOptimize, "None (O0)")
    Addcomboboxitem(giBldOptimize, "Level 1 (-O 1)")
    Addcomboboxitem(giBldOptimize, "Level 2 (-O 2)")
    Addcomboboxitem(giBldOptimize, "Level 3 (-O 3)")
    Setitemcombobox(giBldOptimize, gBuild.Optimization)
    yy += 34

    ' Error checking
    Textgadget(0, 10, yy, 120, 22, "Error Checking:")
    Comboboxgadget(giBldErrCheck, 140, yy - 2, 280, 28)
    Addcomboboxitem(giBldErrCheck, "None")
    Addcomboboxitem(giBldErrCheck, "Standard (-e)")
    Addcomboboxitem(giBldErrCheck, "Extended (-ex)")
    Addcomboboxitem(giBldErrCheck, "Full (-exx)")
    Setitemcombobox(giBldErrCheck, gBuild.ErrorChecking)
    yy += 34

    ' Debug info
    Checkboxgadget(giBldDebugInfo, 140, yy, 200, 24, "Debug Info (-g)")
    If gBuild.DebugInfo Then Setgadgetstate(giBldDebugInfo, 1)
    yy += 34

    ' Extra compiler flags
    Textgadget(0, 10, yy, 120, 22, "Extra Flags:")
    Stringgadget(giBldExtraFlags, 140, yy - 2, 280, 26, gBuild.ExtraCompilerOpts)
    yy += 34

    ' Include paths
    Textgadget(0, 10, yy, 120, 22, "Include Paths:")
    Stringgadget(giBldIncPaths, 140, yy - 2, 280, 26, gBuild.IncludePaths)
    yy += 34

    ' Library paths
    Textgadget(0, 10, yy, 120, 22, "Library Paths:")
    Stringgadget(giBldLibPaths, 140, yy - 2, 280, 26, gBuild.LibraryPaths)
    yy += 40

    ' Buttons
    Buttongadget(giBldOK, 240, yy, 80, 30, "OK")
    Buttongadget(giBldCancel, 330, yy, 80, 30, "Cancel")
End Sub

Sub ApplyBuildOptions()
    gBuild.TargetType = Getitemcombobox(giBldTargetType)
    gBuild.Optimization = Getitemcombobox(giBldOptimize)
    gBuild.ErrorChecking = Getitemcombobox(giBldErrCheck)
    gBuild.DebugInfo = IIf(Getgadgetstate(giBldDebugInfo), -1, 0)
    gBuild.ExtraCompilerOpts = Getgadgettext(giBldExtraFlags)
    gBuild.IncludePaths = Getgadgettext(giBldIncPaths)
    gBuild.LibraryPaths = Getgadgettext(giBldLibPaths)
    SaveSettings()
    SetStatusText("Build options saved")
    CloseBuildOptions()
End Sub

Sub CloseBuildOptions()
    If hBuildOptWin <> 0 Then
        Close_window(hBuildOptWin)
        hBuildOptWin = 0
    End If
End Sub

' ============================================================
' Compiler Error Parsing
' ============================================================
' Parse FBC output for errors: filename.bas(line) error num: message
Sub ParseCompilerErrors(compilerOutput As String)
    gErrorCount = 0
    If Len(compilerOutput) = 0 Then Return

    Dim As Long i = 1
    Do While i <= Len(compilerOutput) AndAlso gErrorCount < MAX_ERRORS
        Dim As Long eol = InStr(i, compilerOutput, Chr(10))
        If eol = 0 Then eol = Len(compilerOutput) + 1
        Dim As String ln = Trim(Mid(compilerOutput, i, eol - i))
        i = eol + 1

        ' Look for pattern: filename(line) error|warning num: message
        Dim As Long paren1 = InStr(ln, "(")
        Dim As Long paren2 = InStr(ln, ")")
        If paren1 > 0 AndAlso paren2 > paren1 Then
            Dim As String afterParen = LTrim(Mid(ln, paren2 + 1))
            Dim As String upperAfter = UCase(Left(afterParen, 7))
            If upperAfter = "ERROR " OrElse Left(upperAfter, 8) = "WARNING " Then
                Dim As String errFile = Left(ln, paren1 - 1)
                Dim As String lineStr = Mid(ln, paren1 + 1, paren2 - paren1 - 1)
                Dim As Long errLine = Val(lineStr)
                If errLine > 0 Then
                    gErrors(gErrorCount).filePath = errFile
                    gErrors(gErrorCount).lineNum = errLine
                    gErrors(gErrorCount).msg = afterParen
                    gErrorCount += 1
                End If
            End If
        End If
    Loop
End Sub

Sub JumpToError(errLine As Long)
    If errLine < 1 Then Return
    Dim As Long lineIdx = Lineindexeditor(giEditor, errLine - 1)
    Dim As Long lineEndIdx = lineIdx + Linelengtheditor(giEditor, errLine - 1)
    Setselecttexteditorgadget(giEditor, lineIdx, lineEndIdx)
    Dim As Long firstVis = Getfirstvisiblelineeditor(giEditor)
    Linescrolleditor(giEditor, (errLine - 1) - firstVis - 10)
    Setfocus(Gadgetid(giEditor))
    UpdateStatusBar()
End Sub

' ============================================================
' Auto-Complete
' ============================================================
Function GetWordAtCursor() As String
    Dim As String edText = Getgadgettext(giEditor)
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    If curIdx <= 0 OrElse Len(edText) = 0 Then Return ""

    ' Walk backwards from cursor to find word start
    Dim As Long wordStart = curIdx
    Do While wordStart > 0
        Dim As Long c = edText[wordStart - 1]
        If (c >= Asc("A") AndAlso c <= Asc("Z")) OrElse _
           (c >= Asc("a") AndAlso c <= Asc("z")) OrElse _
           (c >= Asc("0") AndAlso c <= Asc("9")) OrElse _
           c = Asc("_") OrElse c = Asc("#") Then
            wordStart -= 1
        Else
            Exit Do
        End If
    Loop

    If curIdx - wordStart < 2 Then Return ""  ' Need at least 2 chars
    Return Mid(edText, wordStart + 1, curIdx - wordStart)
End Function

Sub ShowAutoComplete()
    Dim As String prefix = GetWordAtCursor()
    If Len(prefix) < 2 Then
        HideAutoComplete()
        Return
    End If

    Dim As String lowerPrefix = LCase(prefix)

    ' Build matching word list from keywords + types + functions
    Dim As String matches(200)
    Dim As Long matchCount = 0

    ' Search keywords
    Dim As Long searchPos = 1
    Do
        searchPos = InStr(searchPos, gFBKeywords, "|")
        If searchPos = 0 Then Exit Do
        searchPos += 1
        Dim As Long endBar = InStr(searchPos, gFBKeywords, "|")
        If endBar = 0 Then Exit Do
        Dim As String word = Mid(gFBKeywords, searchPos, endBar - searchPos)
        If Len(word) > 0 AndAlso Left(LCase(word), Len(lowerPrefix)) = lowerPrefix Then
            If matchCount < 200 Then
                matches(matchCount) = UCase(Left(word, 1)) + Mid(word, 2)
                matchCount += 1
            End If
        End If
        searchPos = endBar
    Loop

    ' Search types
    searchPos = 1
    Do
        searchPos = InStr(searchPos, gFBTypes, "|")
        If searchPos = 0 Then Exit Do
        searchPos += 1
        Dim As Long endBar = InStr(searchPos, gFBTypes, "|")
        If endBar = 0 Then Exit Do
        Dim As String word = Mid(gFBTypes, searchPos, endBar - searchPos)
        If Len(word) > 0 AndAlso Left(LCase(word), Len(lowerPrefix)) = lowerPrefix Then
            If matchCount < 200 Then
                matches(matchCount) = UCase(Left(word, 1)) + Mid(word, 2)
                matchCount += 1
            End If
        End If
        searchPos = endBar
    Loop

    ' Search functions
    searchPos = 1
    Do
        searchPos = InStr(searchPos, gFBFunctions, "|")
        If searchPos = 0 Then Exit Do
        searchPos += 1
        Dim As Long endBar = InStr(searchPos, gFBFunctions, "|")
        If endBar = 0 Then Exit Do
        Dim As String word = Mid(gFBFunctions, searchPos, endBar - searchPos)
        If Len(word) > 0 AndAlso Left(LCase(word), Len(lowerPrefix)) = lowerPrefix Then
            If matchCount < 200 Then
                matches(matchCount) = UCase(Left(word, 1)) + Mid(word, 2)
                matchCount += 1
            End If
        End If
        searchPos = endBar
    Loop

    If matchCount = 0 Then
        HideAutoComplete()
        Return
    End If

    ' Create or update popup
    If hAutoWin = 0 Then
        hAutoWin = Openwindow("", 400, 400, 220, 180, _
                              WS_POPUP Or WS_VISIBLE, 0, 0, hWin)
        Usegadgetlist(hAutoWin)
        Listboxgadget(giAutoList, 0, 0, 220, 180)
        If gEditorFont Then Setgadgetfont(giAutoList, gEditorFont)
    Else
        Resetalllistbox(giAutoList)
    End If

    ' Fill listbox
    For i As Long = 0 To matchCount - 1
        Addlistboxitem(giAutoList, matches(i))
    Next
    Setitemlistbox(giAutoList, 0)

    ' Position popup near cursor
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx)
    Dim As Long yBuf, lineHeight
    Dim As GtkTextIter iter
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(giEditor))
    Dim As GtkTextBuffer Ptr buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv))
    gtk_text_buffer_get_iter_at_offset(buf, @iter, curIdx)
    gtk_text_view_get_line_yrange(GTK_TEXT_VIEW(tv), @iter, @yBuf, @lineHeight)
    Dim As Long winX, winY
    gtk_text_view_buffer_to_window_coords(GTK_TEXT_VIEW(tv), GTK_TEXT_WINDOW_WIDGET, 0, yBuf + lineHeight, 0, @winY)

    ' Get absolute position of the editor widget
    Dim As Long edX, edY
    gdk_window_get_origin(gtk_widget_get_window(tv), @edX, @edY)
    Resizewindow(hAutoWin, edX + LINE_NUM_WIDTH + 50, edY + winY, 220, 180)
    Hidewindow(hAutoWin, 0)
End Sub

Sub HideAutoComplete()
    If hAutoWin <> 0 Then
        Close_window(hAutoWin)
        hAutoWin = 0
    End If
End Sub

Sub InsertAutoComplete()
    If hAutoWin = 0 Then Return
    Dim As Long sel = Getitemlistbox(giAutoList)
    If sel < 0 Then
        HideAutoComplete()
        Return
    End If
    Dim As String word = Getlistboxtext(giAutoList, sel)
    If Len(word) = 0 Then
        HideAutoComplete()
        Return
    End If

    ' Get the prefix length to replace
    Dim As String prefix = GetWordAtCursor()
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long replStart = curIdx - Len(prefix)

    ' Select the prefix and replace with completion
    Setselecttexteditorgadget(giEditor, replStart, curIdx)
    Pasteeditor(giEditor, word)

    HideAutoComplete()
    CheckEditorModified()
    gHighlightDirty = -1
End Sub

' ============================================================
' Word Wrap, Font, Save All, Drag & Drop
' ============================================================
Sub ToggleWordWrap()
    gWordWrap = IIf(gWordWrap, 0, -1)
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(giEditor))
    If tv Then
        If gWordWrap Then
            gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(tv), GTK_WRAP_WORD_CHAR)
        Else
            gtk_text_view_set_wrap_mode(GTK_TEXT_VIEW(tv), GTK_WRAP_NONE)
        End If
    End If
    SetStatusText("Word wrap: " + IIf(gWordWrap, "ON", "OFF"))
End Sub

Sub ChangeEditorFont()
    Dim As Long result = Fontrequester(hWin)
    If result Then
        Dim As String fn = Selectedfontname()
        Dim As Long fs = Selectedfontsize()
        If Len(fn) > 0 AndAlso fs > 0 Then
            gFontName = fn
            gFontSize = fs
            SetEditorFontSize(gFontSize)
        End If
    End If
End Sub

Sub SetEditorFontSize(newSize As Long)
    If newSize < 6 Then newSize = 6
    If newSize > 72 Then newSize = 72
    gFontSize = newSize
    If gEditorFont Then Freefont(gEditorFont)
    gEditorFont = Loadfont(gFontName, gFontSize)
    If gEditorFont Then
        Setgadgetfont(giEditor, gEditorFont)
        Setgadgetfont(giTxtOutput, gEditorFont)
        Setgadgetfont(giTxtDebugOutput, gEditorFont)
    End If
    SetStatusText("Font: " + gFontName + " " + Str(gFontSize) + "pt")
End Sub

Sub SaveAllModified()
    Dim As Long savedActive = gActiveFile
    For i As Long = 0 To gFileCount - 1
        If gFiles(i).IsModified Then
            gActiveFile = i
            SyncEditorToFile()  ' Load back from editor if it was current
            If gFiles(i).IsNew = 0 Then
                Dim As Long ff = FreeFile
                If Open(gFiles(i).FilePath For Output As #ff) = 0 Then
                    Print #ff, gFiles(i).Content;
                    Close #ff
                    gFiles(i).IsModified = 0
                End If
            End If
        End If
    Next
    gActiveFile = savedActive
    SyncEditorToFile()
    UpdateFileCombo()
    UpdateTitle()
    SetStatusText("All files saved")
End Sub

' Drag & Drop callback
Sub DragDataReceivedCB Cdecl(widget As GtkWidget Ptr, context As GdkDragContext Ptr, _
                              x As gint, y As gint, selData As GtkSelectionData Ptr, _
                              info As guint, evTime As guint, userData As gpointer)
    Dim As gchar Ptr Ptr uris = gtk_selection_data_get_uris(selData)
    If uris = 0 Then Return

    Dim As Long i = 0
    Do While uris[i] <> 0
        Dim As gchar Ptr filePath = g_filename_from_uri(uris[i], 0, 0)
        If filePath <> 0 Then
            Dim As String fp = *filePath
            g_free(filePath)
            ' Only open .bas and .bi files
            Dim As String ext = LCase(Right(fp, 4))
            If ext = ".bas" OrElse ext = ".bi" OrElse Right(fp, 3) = ".bi" Then
                DoOpenFilePath(fp)
            End If
        End If
        i += 1
    Loop
    g_strfreev(uris)
    gtk_drag_finish(context, 1, 0, evTime)
End Sub

Sub SetupDragDrop()
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(giEditor))
    If tv = 0 Then Return

    ' Set up the editor as a drag-drop target for URIs
    Static As GtkTargetEntry targets(0)
    targets(0).target = @"text/uri-list"
    targets(0).flags = 0
    targets(0).info = 0

    gtk_drag_dest_set(tv, GTK_DEST_DEFAULT_ALL, @targets(0), 1, GDK_ACTION_COPY)
    g_signal_connect(G_OBJECT(tv), "drag-data-received", G_CALLBACK(@DragDataReceivedCB), 0)
End Sub

' ============================================================
' GDB Debugger (basic integration)
' ============================================================
Sub DoDebugStart()
    If gActiveFile < 0 OrElse gActiveFile >= gFileCount Then Return

    If gDbgRunning = 0 Then
        ' Need to build with -g first
        gBuild.DebugInfo = -1
        DoBuild(0)

        Dim As String sourceFile = gFiles(gActiveFile).FilePath
        Dim As String outExe = Left(sourceFile, InStrRev(sourceFile, ".") - 1)

        If w9isFileExists(outExe) = 0 Then
            AppendDebugOutput("Build failed - cannot start debugger" + Chr(10))
            Return
        End If

        If Len(gBuild.GDBPath) = 0 Then
            Messbox("Debug", "GDB path not set. Install gdb: sudo apt install gdb")
            Return
        End If

        ' Launch GDB with the executable
        Dim As String gdbCmd = gBuild.GDBPath + " --interpreter=mi """ + outExe + """ 2>&1"
        AppendDebugOutput("Starting debugger: " + gdbCmd + Chr(10))
        Panelgadgetsetcursel(giTabOutput, 1) ' Switch to debug tab

        ' For now, run with a simple pipe (full async GDB/MI would need threads)
        Dim As Long ff = FreeFile
        Dim As String gdbOut, ln
        Open Pipe gBuild.GDBPath + " -batch -ex run -ex quit """ + outExe + """ 2>&1" For Input As #ff
        Do Until Eof(ff)
            Line Input #ff, ln
            gdbOut += ln + Chr(10)
        Loop
        Close #ff

        AppendDebugOutput(gdbOut)
        AppendDebugOutput("Debug session ended." + Chr(10))
        SetStatusText("Debug session ended")
    End If
End Sub

Sub DoDebugStop()
    If gDbgRunning Then
        gDbgRunning = 0
        gDbgPaused = 0
        SetStatusText("Debugger stopped")
        AppendDebugOutput("Debugger stopped." + Chr(10))
    End If
End Sub

Sub DoDebugStepOver()
    AppendDebugOutput("Step Over (not yet implemented - needs async GDB/MI)" + Chr(10))
End Sub

Sub DoDebugStepInto()
    AppendDebugOutput("Step Into (not yet implemented - needs async GDB/MI)" + Chr(10))
End Sub

Sub DoDebugStepOut()
    AppendDebugOutput("Step Out (not yet implemented - needs async GDB/MI)" + Chr(10))
End Sub

Sub DoToggleBreakpoint()
    If gActiveFile < 0 Then Return
    Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
    Dim As Long ln = Linefromchareditor(giEditor, curIdx) + 1
    SetStatusText("Breakpoint toggled at line " + Str(ln))
    AppendDebugOutput("Breakpoint at line " + Str(ln) + Chr(10))
End Sub

' ============================================================
' Output Helpers
' ============================================================
Sub ClearOutput()
    Setgadgettext(giTxtOutput, "")
End Sub

Sub AppendOutput(txt As String)
    Dim As String current = Getgadgettext(giTxtOutput)
    Setgadgettext(giTxtOutput, current + txt)
    Linescrolleditor(giTxtOutput, Getlinecounteditor(giTxtOutput))
End Sub

Sub AppendDebugOutput(txt As String)
    Dim As String current = Getgadgettext(giTxtDebugOutput)
    Setgadgettext(giTxtDebugOutput, current + txt)
    Linescrolleditor(giTxtDebugOutput, Getlinecounteditor(giTxtDebugOutput))
End Sub

Sub SetStatusText(txt As String)
    Setstatusbarfield(giStatusBar, 0, 500, txt)
End Sub

' ============================================================
' Main Entry Point
' ============================================================
' Read startup file from /proc/self/cmdline (gtk_init eats Command())
Scope
    Dim As ZString * 4096 cmdBuf
    Dim As FILE Ptr cmdFp = fopen("/proc/self/cmdline", "r")
    If cmdFp Then
        Dim As Long cmdN = fread(@cmdBuf, 1, 4095, cmdFp)
        fclose(cmdFp)
        If cmdN > 0 Then
            Dim As Long nulAt = strlen(@cmdBuf)
            If nulAt > 0 AndAlso nulAt < cmdN Then
                gStartupFile = *(Cast(ZString Ptr, @cmdBuf + nulAt + 1))
            End If
        End If
    End If
End Scope

InitSyntaxData()
InitSettings()
CreateMainWindow()
CreateMenuBar()
CreateToolbarUI()
CreateLayout()
ApplyTheme()

' Always start with a new file, then open command-line file after
DoNewFile()
SetStatusText("Ready - FBC: " + IIf(Len(gBuild.FBCPath) > 0, gBuild.FBCPath, "(not set)"))
UpdateInfoXserver()

' Force initial layout after window is fully realized
HandleResize()

' Open command-line file after window is realized
If Len(gStartupFile) > 0 AndAlso w9isFileExists(gStartupFile) Then
    DoOpenFilePath(gStartupFile)
End If

' ============================================================
' Main Event Loop
' ============================================================
' Drain all pending GTK events each iteration to keep scrolling smooth.
' Only do expensive work (status bar, modify check) when the queue is empty.
' ============================================================
Do
    ' Process GTK events until queue is empty or we get a Window9 event
    Dim As Long ev = Windowevent()

    ' No event — process deferred updates, then yield CPU
    If ev = 0 Then
        ' Drain any remaining GTK events that didn't produce Window9 events
        While gtk_events_pending()
            gtk_main_iteration_do(0)
        Wend

        If gStatusDirty Then
            UpdateStatusBar()
            gStatusDirty = 0
        End If
        If gModifyDirty Then
            CheckEditorModified()
            gModifyDirty = 0
        End If
        If gHighlightDirty Then
            HighlightCurrentLine(giEditor)
            gHighlightDirty = 0
        End If
        Sleepw9(2)  ' ~2ms idle sleep
        Continue Do
    End If

    Select Case ev

    Case Eventclose
        If hFindWin <> 0 AndAlso Eventhwnd() = hFindWin Then
            Close_window(hFindWin)
            hFindWin = 0
        ElseIf hAutoWin <> 0 AndAlso Eventhwnd() = hAutoWin Then
            HideAutoComplete()
        ElseIf hBuildOptWin <> 0 AndAlso Eventhwnd() = hBuildOptWin Then
            CloseBuildOptions()
        ElseIf Eventhwnd() = hWin Then
            Dim As Integer canClose = -1
            For i As Long = 0 To gFileCount - 1
                If gFiles(i).IsModified Then
                    SyncFileFromEditor()
                    Dim As Long ans = Messbox("Unsaved Changes", _
                        "File '" + gFiles(i).FileName + "' has unsaved changes." + Chr(10) + _
                        "Save before exiting?", MB_YESNOCANCEL)
                    If ans = IDYES Then
                        gActiveFile = i
                        DoSaveFile()
                    ElseIf ans = IDCANCEL Then
                        canClose = 0
                        Exit For
                    End If
                End If
            Next
            If canClose Then
                SaveSettings()
                End
            End If
        End If

    Case Eventmenu
        Select Case Eventnumber()
        ' File
        Case mnuFileNew     : DoNewFile()
        Case mnuFileOpen    : DoOpenFile()
        Case mnuFileSave    : DoSaveFile()
        Case mnuFileSaveAs  : DoSaveFileAs()
        Case mnuFileSaveAll : SaveAllModified()
        Case mnuFileClose   : DoCloseFile()
        Case mnuFileExit    : SaveSettings() : End
        Case mnuRecentBase To mnuRecentBase + 9
            Dim As Long ri = Eventnumber() - mnuRecentBase
            If ri >= 0 AndAlso ri < gRecentCount Then
                DoOpenFilePath(gRecentFiles(ri))
            End If

        ' Edit
        Case mnuEditFind      : ShowFindReplace(0)
        Case mnuEditReplace   : ShowFindReplace(-1)
        Case mnuEditGoToLine  : DoGoToLine()
        Case mnuEditComment      : DoCommentBlock()
        Case mnuEditUncomment    : DoUncommentBlock()
        Case mnuEditSelectLine   : DoSelectLine()
        Case mnuEditDuplicateLine: DoDuplicateLine()
        Case mnuEditDeleteLine   : DoDeleteLine()

        ' View
        Case mnuViewDarkTheme
            gSettings.DarkTheme = IIf(gSettings.DarkTheme, 0, -1)
            ApplyTheme()
            SaveSettings()
        Case mnuViewWordWrap
            ToggleWordWrap()
        Case mnuViewFont
            ChangeEditorFont()
        Case mnuViewZoomIn
            SetEditorFontSize(gFontSize + 1)
        Case mnuViewZoomOut
            SetEditorFontSize(gFontSize - 1)
        Case mnuViewZoomReset
            SetEditorFontSize(11)
        Case mnuViewRefreshOutline
            RefreshOutline()

        ' Build
        Case mnuBuildCompile    : DoBuild(0)
        Case mnuBuildCompileRun : DoBuild(-1)
        Case mnuBuildRun        : DoRun()
        Case mnuBuildOptions    : ShowBuildOptions()
        Case mnuBuildSetFBC     : DoSetFBCPath()

        ' Debug
        Case mnuDebugStart    : DoDebugStart()
        Case mnuDebugStop     : DoDebugStop()
        Case mnuDebugStepOver : DoDebugStepOver()
        Case mnuDebugStepInto : DoDebugStepInto()
        Case mnuDebugStepOut  : DoDebugStepOut()
        Case mnuDebugToggleBP : DoToggleBreakpoint()

        ' Help
        Case mnuHelpAbout
            Messbox(APP_NAME, APP_NAME + " " + APP_VERSION + Chr(10) + _
                    "FreeBASIC IDE for Linux" + Chr(10) + _
                    "By " + APP_AUTHOR + Chr(10) + Chr(10) + _
                    "Using Window9 GUI Library" + Chr(10) + _
                    "FBC: " + gBuild.FBCPath + Chr(10) + _
                    "GDB: " + gBuild.GDBPath)

        ' Keyboard shortcuts
        Case kbNew         : DoNewFile()
        Case kbOpen        : DoOpenFile()
        Case kbSave        : DoSaveFile()
        Case kbClose       : DoCloseFile()
        Case kbCompile     : DoBuild(0)
        Case kbCompileRun  : DoBuild(-1)
        Case kbRun         : DoRun()
        Case kbFind        : ShowFindReplace(0)
        Case kbReplace     : ShowFindReplace(-1)
        Case kbGoToLine    : DoGoToLine()
        Case kbFindNext    : DoFindNext(-1)
        Case kbDebugStart  : DoDebugStart()
        Case kbDebugStop   : DoDebugStop()
        Case kbDebugStepOver : DoDebugStepOver()
        Case kbDebugStepInto : DoDebugStepInto()
        Case kbDebugStepOut  : DoDebugStepOut()
        Case kbDebugToggleBP : DoToggleBreakpoint()
        Case kbRefreshOutline : RefreshOutline()
        Case kbAutoComplete  : ShowAutoComplete()
        Case kbComment       : DoToggleComment()
        Case kbZoomIn        : SetEditorFontSize(gFontSize + 1)
        Case kbZoomOut       : SetEditorFontSize(gFontSize - 1)
        Case kbZoomReset     : SetEditorFontSize(11)
        Case kbNextFile
            If gFileCount > 1 Then
                Dim As Long nxt = gActiveFile + 1
                If nxt >= gFileCount Then nxt = 0
                SwitchToFile(nxt)
            End If
        Case kbPrevFile
            If gFileCount > 1 Then
                Dim As Long prv = gActiveFile - 1
                If prv < 0 Then prv = gFileCount - 1
                SwitchToFile(prv)
            End If
        Case kbSelectLine    : DoSelectLine()
        Case kbDuplicateLine : DoDuplicateLine()
        Case kbSaveAll       : SaveAllModified()
        Case kbDeleteLine    : DoDeleteLine()
        End Select

    Case Eventgadget
        Select Case Eventnumber()
        Case giCboFiles
            Dim As Long sel = Getitemcombobox(giCboFiles)
            If sel >= 0 AndAlso sel < gFileCount AndAlso sel <> gActiveFile Then
                SwitchToFile(sel)
            End If
        Case giEditor
            ' Defer — don't do expensive work on every gadget event
            gModifyDirty = -1
            gStatusDirty = -1
        ' Find/Replace buttons
        Case giFindNext   : DoFindNext(-1)
        Case giFindPrev   : DoFindNext(0)
        Case giReplaceOne : DoReplaceOne()
        Case giReplaceAll : DoReplaceAll()
        Case giFindClose
            If hFindWin <> 0 Then
                Close_window(hFindWin)
                hFindWin = 0
            End If
        ' Toolbar buttons
        Case giTbNew     : DoNewFile()
        Case giTbOpen    : DoOpenFile()
        Case giTbSave    : DoSaveFile()
        Case giTbUndo
            ' GTK2 GtkTextView doesn't have undo API, emit Ctrl+Z key event
            SetStatusText("Use Ctrl+Z for Undo")
        Case giTbRedo
            SetStatusText("Use Ctrl+Y for Redo")
        Case giTbFind    : ShowFindReplace(0)
        Case giTbCompile : DoBuild(0)
        Case giTbRun     : DoBuild(-1)
        ' Build options buttons
        Case giBldOK       : ApplyBuildOptions()
        Case giBldCancel   : CloseBuildOptions()
        End Select

    Case Eventsize
        If Eventhwnd() = hWin Then
            HandleResize()
        Else
            ResizeInternalGadgets()
        End If

    Case Eventkeydown, Eventkeyup
        If ev = Eventkeydown Then
            Dim As Long key = Eventkey()

            ' Auto-complete key handling
            If hAutoWin <> 0 Then
                If key = VK_ESCAPE Then
                    HideAutoComplete()
                ElseIf key = VK_RETURN OrElse key = VK_TAB Then
                    InsertAutoComplete()
                End If
            End If

            ' Auto-indent: after Enter, match previous line's indentation
            If key = VK_RETURN Then
                ' Wait for GTK to insert the newline first
                While gtk_events_pending()
                    gtk_main_iteration_do(0)
                Wend
                ' Get the previous line's indentation
                Dim As Long curIdx = Getcurrentindexchareditor(giEditor)
                Dim As Long curLine = Linefromchareditor(giEditor, curIdx)
                If curLine > 0 Then
                    Dim As String prevLine = Getlinetexteditor(giEditor, curLine - 1)
                    Dim As String indent
                    Dim As Long ci = 1
                    Do While ci <= Len(prevLine)
                        Dim As Long ch = prevLine[ci - 1]
                        If ch = Asc(" ") OrElse ch = Asc(!"\t") Then
                            indent += Chr(ch)
                            ci += 1
                        Else
                            Exit Do
                        End If
                    Loop
                    If Len(indent) > 0 Then
                        Pasteeditor(giEditor, indent)
                    End If
                End If
            End If
        End If
        ' Just mark dirty — actual update happens when event queue drains
        gModifyDirty = -1
        gStatusDirty = -1
        gHighlightDirty = -1

    Case Eventlbup, Eventlbdown
        gStatusDirty = -1

    Case Eventmousewheel
        ' Drain remaining scroll events to prevent queue buildup
        While gtk_events_pending()
            gtk_main_iteration_do(0)
        Wend
        gStatusDirty = -1

    Case Eventdblclick
        ' Double-click on project tree → switch to file
        If Eventhwnd() = Gadgetid(giTreeProject) Then
            Dim As Long selItem = Getitemtreeview(giTreeProject)
            If selItem > 0 Then
                Dim As String selName = Gettexttreeview(giTreeProject, selItem)
                ' Strip "* " prefix if present
                If Left(selName, 2) = "* " Then selName = Mid(selName, 3)
                ' Find matching file
                For fi As Long = 0 To gFileCount - 1
                    If gFiles(fi).FileName = selName Then
                        SwitchToFile(fi)
                        Exit For
                    End If
                Next
            End If
        ' Double-click on outline tree → jump to item
        ElseIf Eventhwnd() = Gadgetid(giTreeOutline) Then
            GoToOutlineItem()
        ' Double-click on output → jump to error
        ElseIf Eventhwnd() = Gadgetid(giTxtOutput) Then
            ' Get current line in output
            Dim As Long outIdx = Getcurrentindexchareditor(giTxtOutput)
            Dim As Long outLn = Linefromchareditor(giTxtOutput, outIdx)
            Dim As String outLineText = Getlinetexteditor(giTxtOutput, outLn)
            ' Try to parse error from this line
            Dim As Long p1 = InStr(outLineText, "(")
            Dim As Long p2 = InStr(outLineText, ")")
            If p1 > 0 AndAlso p2 > p1 Then
                Dim As Long errLn = Val(Mid(outLineText, p1 + 1, p2 - p1 - 1))
                If errLn > 0 Then JumpToError(errLn)
            End If
        ' Double-click on auto-complete list → insert
        ElseIf hAutoWin <> 0 AndAlso Eventhwnd() = Gadgetid(giAutoList) Then
            InsertAutoComplete()
        End If

    Case Eventmousemove
        ' Ignore mouse move — very frequent, don't do any work

    End Select
Loop
