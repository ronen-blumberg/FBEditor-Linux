' FBEditor Linux - FreeBASIC Syntax Highlighter
' Uses GtkTextBuffer tags for coloring

#Ifndef __FBEDITOR_SYNTAX_BI__
#Define __FBEDITOR_SYNTAX_BI__

' Tag names
Const TAG_KEYWORD   = "syn_kw"
Const TAG_DATATYPE  = "syn_dt"
Const TAG_COMMENT   = "syn_cm"
Const TAG_STRING    = "syn_st"
Const TAG_NUMBER    = "syn_nm"
Const TAG_PREPROC   = "syn_pp"
Const TAG_FUNCTION  = "syn_fn"

' FreeBASIC keywords (pipe-delimited for fast matching)
Dim Shared gFBKeywords As String
Dim Shared gFBTypes As String
Dim Shared gFBFunctions As String

Sub InitSyntaxData()
    gFBKeywords = _
        "|abs|access|alias|and|andalso|any|append|as|asm|assert" + _
        "|base|beep|byref|byval" + _
        "|call|callocate|case|cast|cbyte|cdbl|cint|clng|clngint" + _
        "|close|cls|color|common|const|constructor|continue" + _
        "|cptr|cshort|csng|cubyte|cuint|culng|culngint|cushort" + _
        "|deallocate|declare|defined|delete|destructor|dim|do|dynamic" + _
        "|else|elseif|end|endif|enum|erase|err|error|event" + _
        "|exit|explicit|export|extends|extern" + _
        "|false|for|fre|freefile|function" + _
        "|get|gosub|goto" + _
        "|if|iif|implements|import|in|input|is" + _
        "|kill" + _
        "|lbound|let|lib|line|local|locate|lock|loop" + _
        "|mid|mod|mutexcreate|mutexdestroy|mutexlock|mutexunlock" + _
        "|naked|namespace|new|next|not" + _
        "|object|on|once|open|operator|option|or|orelse|output" + _
        "|overload|override" + _
        "|preserve|preset|print|private|property|protected|public|put" + _
        "|random|randomize|read|reallocate|redim|rem|reset|restore" + _
        "|resume|return|rmdir|run" + _
        "|scope|screen|seek|select|setenviron|sgn|shared|shell|sizeof" + _
        "|sleep|static|stdcall|step|stop|str|sub|swap" + _
        "|then|this|threadcreate|threadwait|to|true|type|typeof" + _
        "|ubound|union|unlock|until|using" + _
        "|va_arg|va_first|va_next|val|var|varptr|view|virtual" + _
        "|wait|wend|while|width|window|with|write" + _
        "|xor|"
    gFBTypes = _
        "|boolean|byte|double|integer|long|longint" + _
        "|pointer|ptr|short|single|string|ubyte" + _
        "|uinteger|ulong|ulongint|ushort|unsigned" + _
        "|wstring|zstring|hwnd|any|"
    gFBFunctions = _
        "|abs|acos|allocate|asin|atan2|atn|bin|chr|command|cos" + _
        "|cvd|cvi|cvl|cvlongint|cvs|date|dir|environ|eof|exp" + _
        "|fileattr|filecopy|filedatetime|fileexists|filelen|fix|format|frac" + _
        "|hex|hibyte|hiword|hour|inkey|inp|instr|instrrev|int" + _
        "|lcase|left|len|lof|log|lobyte|loword|ltrim" + _
        "|mkd|mki|mkl|mklongint|mks|mkshort|month|now|oct" + _
        "|peek|pmap|point|rgb|rgba|right|rnd|rtrim" + _
        "|sadd|second|seek|sin|space|spc|sqr|str|strptr" + _
        "|tab|tan|time|timer|trim|ucase" + _
        "|val|vallng|valint|valuint|valulng|varptr|weekday|write|year|"
End Sub

' Check if a word is a keyword
Function IsKeyword(w As String) As Integer
    Return InStr(gFBKeywords, "|" + LCase(w) + "|") > 0
End Function

Function IsDatatype(w As String) As Integer
    Return InStr(gFBTypes, "|" + LCase(w) + "|") > 0
End Function

Function IsBuiltinFunc(w As String) As Integer
    Return InStr(gFBFunctions, "|" + LCase(w) + "|") > 0
End Function

' Helper: is character part of a word?
Function IsWordChar(c As Long) As Integer
    Return (c >= Asc("A") AndAlso c <= Asc("Z")) OrElse _
           (c >= Asc("a") AndAlso c <= Asc("z")) OrElse _
           (c >= Asc("0") AndAlso c <= Asc("9")) OrElse _
           c = Asc("_")
End Function

Function IsDigitChar(c As Long) As Integer
    Return (c >= Asc("0") AndAlso c <= Asc("9"))
End Function

' Create syntax tags on a GtkTextBuffer
Sub CreateSyntaxTags(buf As GtkTextBuffer Ptr, isDark As Integer)
    If isDark Then
        gtk_text_buffer_create_tag(buf, TAG_KEYWORD,  "foreground", "#C678DD", "weight", Cast(Any Ptr, 700), NULL)
        gtk_text_buffer_create_tag(buf, TAG_DATATYPE, "foreground", "#E5C07B", NULL)
        gtk_text_buffer_create_tag(buf, TAG_COMMENT,  "foreground", "#5C6370", "style", Cast(Any Ptr, 2), NULL)  ' 2=italic
        gtk_text_buffer_create_tag(buf, TAG_STRING,   "foreground", "#98C379", NULL)
        gtk_text_buffer_create_tag(buf, TAG_NUMBER,   "foreground", "#D19A66", NULL)
        gtk_text_buffer_create_tag(buf, TAG_PREPROC,  "foreground", "#61AFEF", NULL)
        gtk_text_buffer_create_tag(buf, TAG_FUNCTION, "foreground", "#61AFEF", NULL)
    Else
        gtk_text_buffer_create_tag(buf, TAG_KEYWORD,  "foreground", "#7B0099", "weight", Cast(Any Ptr, 700), NULL)
        gtk_text_buffer_create_tag(buf, TAG_DATATYPE, "foreground", "#006B6B", NULL)
        gtk_text_buffer_create_tag(buf, TAG_COMMENT,  "foreground", "#008000", "style", Cast(Any Ptr, 2), NULL)
        gtk_text_buffer_create_tag(buf, TAG_STRING,   "foreground", "#A31515", NULL)
        gtk_text_buffer_create_tag(buf, TAG_NUMBER,   "foreground", "#B35E00", NULL)
        gtk_text_buffer_create_tag(buf, TAG_PREPROC,  "foreground", "#0000CC", NULL)
        gtk_text_buffer_create_tag(buf, TAG_FUNCTION, "foreground", "#0000CC", NULL)
    End If
End Sub

' Highlight a single line of text in the buffer
Sub HighlightLine(buf As GtkTextBuffer Ptr, lineNum As Long)
    Dim As GtkTextIter lineStart, lineEnd
    gtk_text_buffer_get_iter_at_line(buf, @lineStart, lineNum)
    lineEnd = lineStart
    If gtk_text_iter_forward_to_line_end(@lineEnd) = 0 Then Return

    ' Remove existing tags on this line
    gtk_text_buffer_remove_all_tags(buf, @lineStart, @lineEnd)

    ' Get line text
    Dim As ZString Ptr lineText = gtk_text_buffer_get_text(buf, @lineStart, @lineEnd, 0)
    If lineText = 0 Then Return
    Dim As String lt = *lineText
    g_free(lineText)

    Dim As Long lineLen = Len(lt)
    If lineLen = 0 Then Return

    Dim As Long i = 0
    Dim As Long lineOffset = gtk_text_iter_get_offset(@lineStart)

    While i < lineLen
        Dim As Long c = lt[i]

        ' Comment: ' or REM
        If c = Asc("'") Then
            Dim As GtkTextIter cmStart, cmEnd
            gtk_text_buffer_get_iter_at_offset(buf, @cmStart, lineOffset + i)
            gtk_text_buffer_get_iter_at_offset(buf, @cmEnd, lineOffset + lineLen)
            gtk_text_buffer_apply_tag_by_name(buf, TAG_COMMENT, @cmStart, @cmEnd)
            Exit While
        End If

        ' String: "..."
        If c = Asc("""") Then
            Dim As Long strStart = i
            i += 1
            While i < lineLen AndAlso lt[i] <> Asc("""")
                i += 1
            Wend
            If i < lineLen Then i += 1  ' skip closing quote
            Dim As GtkTextIter sStart, sEnd
            gtk_text_buffer_get_iter_at_offset(buf, @sStart, lineOffset + strStart)
            gtk_text_buffer_get_iter_at_offset(buf, @sEnd, lineOffset + i)
            gtk_text_buffer_apply_tag_by_name(buf, TAG_STRING, @sStart, @sEnd)
            Continue While
        End If

        ' Preprocessor: #keyword
        If c = Asc("#") AndAlso (i = 0 OrElse lt[i-1] = Asc(" ") OrElse lt[i-1] = Asc(!"\t")) Then
            Dim As Long ppStart = i
            i += 1
            While i < lineLen AndAlso IsWordChar(lt[i])
                i += 1
            Wend
            Dim As GtkTextIter pStart, pEnd
            gtk_text_buffer_get_iter_at_offset(buf, @pStart, lineOffset + ppStart)
            gtk_text_buffer_get_iter_at_offset(buf, @pEnd, lineOffset + i)
            gtk_text_buffer_apply_tag_by_name(buf, TAG_PREPROC, @pStart, @pEnd)
            Continue While
        End If

        ' Numbers: digits, &h hex, &b binary, &o octal
        If IsDigitChar(c) OrElse _
           (c = Asc("&") AndAlso i + 1 < lineLen AndAlso _
            (lt[i+1] = Asc("h") OrElse lt[i+1] = Asc("H") OrElse _
             lt[i+1] = Asc("b") OrElse lt[i+1] = Asc("B") OrElse _
             lt[i+1] = Asc("o") OrElse lt[i+1] = Asc("O"))) Then
            ' Make sure it's not part of a word
            If i = 0 OrElse IsWordChar(lt[i-1]) = 0 Then
                Dim As Long numStart = i
                If c = Asc("&") Then i += 2  ' skip &h / &b / &o
                While i < lineLen AndAlso (IsWordChar(lt[i]) OrElse lt[i] = Asc("."))
                    i += 1
                Wend
                Dim As GtkTextIter nStart, nEnd
                gtk_text_buffer_get_iter_at_offset(buf, @nStart, lineOffset + numStart)
                gtk_text_buffer_get_iter_at_offset(buf, @nEnd, lineOffset + i)
                gtk_text_buffer_apply_tag_by_name(buf, TAG_NUMBER, @nStart, @nEnd)
                Continue While
            End If
        End If

        ' Words: keywords, types, functions
        If IsWordChar(c) AndAlso IsDigitChar(c) = 0 Then
            Dim As Long wordStart = i
            While i < lineLen AndAlso IsWordChar(lt[i])
                i += 1
            Wend
            Dim As String word = Mid(lt, wordStart + 1, i - wordStart)

            Dim As String tagName = ""
            If IsKeyword(word) Then
                tagName = TAG_KEYWORD
            ElseIf IsDatatype(word) Then
                tagName = TAG_DATATYPE
            ElseIf IsBuiltinFunc(word) Then
                tagName = TAG_FUNCTION
            End If

            If Len(tagName) > 0 Then
                Dim As GtkTextIter wStart, wIterEnd
                gtk_text_buffer_get_iter_at_offset(buf, @wStart, lineOffset + wordStart)
                gtk_text_buffer_get_iter_at_offset(buf, @wIterEnd, lineOffset + i)
                gtk_text_buffer_apply_tag_by_name(buf, tagName, @wStart, @wIterEnd)
            End If

            ' Check for REM comment
            If LCase(word) = "rem" Then
                Dim As GtkTextIter cmStart, cmEnd
                gtk_text_buffer_get_iter_at_offset(buf, @cmStart, lineOffset + wordStart)
                gtk_text_buffer_get_iter_at_offset(buf, @cmEnd, lineOffset + lineLen)
                gtk_text_buffer_apply_tag_by_name(buf, TAG_COMMENT, @cmStart, @cmEnd)
                Exit While
            End If
            Continue While
        End If

        i += 1
    Wend
End Sub

' Highlight all visible lines (call after loading a file or switching tabs)
Sub HighlightAll(iGadget As Long)
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(iGadget))
    If tv = 0 Then Return
    Dim As GtkTextBuffer Ptr buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv))
    Dim As Long totalLines = gtk_text_buffer_get_line_count(buf)
    For i As Long = 0 To totalLines - 1
        HighlightLine(buf, i)
    Next
End Sub

' Highlight only the visible range (faster for large files)
Sub HighlightVisible(iGadget As Long)
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(iGadget))
    If tv = 0 Then Return
    Dim As GtkTextBuffer Ptr buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv))

    Dim As GdkRectangle visRect
    gtk_text_view_get_visible_rect(GTK_TEXT_VIEW(tv), @visRect)

    Dim As GtkTextIter startIter, endIter
    Dim As Long yy
    gtk_text_view_get_line_at_y(GTK_TEXT_VIEW(tv), @startIter, visRect.y, @yy)
    gtk_text_view_get_line_at_y(GTK_TEXT_VIEW(tv), @endIter, visRect.y + visRect.height, @yy)

    Dim As Long startLine = gtk_text_iter_get_line(@startIter)
    Dim As Long endLine = gtk_text_iter_get_line(@endIter)

    For i As Long = startLine To endLine
        HighlightLine(buf, i)
    Next
End Sub

' Highlight the line containing the cursor (call after edits)
Sub HighlightCurrentLine(iGadget As Long)
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(iGadget))
    If tv = 0 Then Return
    Dim As GtkTextBuffer Ptr buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv))
    Dim As GtkTextIter curIter
    Dim As GtkTextMark Ptr insertMark = gtk_text_buffer_get_insert(buf)
    gtk_text_buffer_get_iter_at_mark(buf, @curIter, insertMark)
    Dim As Long curLine = gtk_text_iter_get_line(@curIter)
    ' Highlight current line and neighbors (handles multi-line paste)
    Dim As Long startL = curLine - 1
    If startL < 0 Then startL = 0
    Dim As Long endL = curLine + 1
    Dim As Long totalLines = gtk_text_buffer_get_line_count(buf)
    If endL >= totalLines Then endL = totalLines - 1
    For i As Long = startL To endL
        HighlightLine(buf, i)
    Next
End Sub

' Initialize syntax highlighting on a gadget
Sub InitSyntaxHighlight(iGadget As Long, isDark As Integer)
    Dim As GtkWidget Ptr tv = Cast(GtkWidget Ptr, Gadgetid(iGadget))
    If tv = 0 Then Return
    Dim As GtkTextBuffer Ptr buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(tv))
    CreateSyntaxTags(buf, isDark)
End Sub

#EndIf
