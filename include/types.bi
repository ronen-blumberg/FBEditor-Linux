' FBEditor Linux - Core Data Types
' Ported from VB.NET AppSettings.vb and W9GadgetInfo.vb

#Ifndef __FBEDITOR_TYPES_BI__
#Define __FBEDITOR_TYPES_BI__

' Application constants
Const APP_NAME = "FBEditor"
Const APP_VERSION = "0.1.0"
Const APP_AUTHOR = "Ronen Blumberg"
Const MAX_RECENT_FILES = 10
Const MAX_OPEN_FILES = 32

' File encoding types
Enum FileEncoding
    ENC_UTF8 = 0
    ENC_ANSI = 1
End Enum

' Open file information for multi-tab support
Type OpenFileInfo
    FilePath As String
    FileName As String
    IsModified As Integer       ' boolean
    Content As String
    CursorPos As Long
    IsNew As Integer            ' boolean
    FileEnc As FileEncoding
End Type

' Parsed compiler error/warning
Type CompilerError
    FilePath As String
    LineNumber As Long
    ErrorType As String         ' "error" or "warning"
    ErrorCode As Long
    Message As String
End Type

' Build result
Type BuildResult
    Success As Integer          ' boolean
    ExitCode As Long
    Output As String
    CommandLine As String
End Type

' Build configuration
Type BuildSettings
    FBCPath As String
    GDBPath As String
    TargetType As Long          ' 0=Console, 1=GUI
    Optimization As Long        ' 0=None, 1=O1, 2=O2, 3=O3
    ErrorChecking As Long       ' 0=None, 1=-e, 2=-ex, 3=-exx
    DebugInfo As Integer        ' boolean
    ExtraCompilerOpts As String
    IncludePaths As String
    LibraryPaths As String
End Type

' Editor settings
Type EditorSettings
    TabWidth As Long
    ShowLineNumbers As Integer  ' boolean
    DarkTheme As Integer        ' boolean
End Type

#EndIf
