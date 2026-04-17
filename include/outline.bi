' FBEditor Linux - Code Outline Parser
' Parses FreeBASIC source code for SUB/FUNCTION/TYPE/ENUM definitions

#Ifndef __FBEDITOR_OUTLINE_BI__
#Define __FBEDITOR_OUTLINE_BI__

Const MAX_OUTLINE_ITEMS = 512

Type OutlineItem
    itemName As String
    category As String   ' "Procedures", "Types", "Enums", "Constants"
    prefix As String     ' "Sub", "Function", "Type", etc.
    lineNum As Long
End Type

Dim Shared gOutline(MAX_OUTLINE_ITEMS - 1) As OutlineItem
Dim Shared gOutlineCount As Long = 0

' Parse source code and fill the outline array
Sub ParseOutline(code As String)
    gOutlineCount = 0
    If Len(code) = 0 Then Return

    Dim As Long lineNum = 0
    Dim As Long codeLen = Len(code)
    Dim As Long i = 1
    Dim As Integer inType = 0, inEnum = 0

    ' Process line by line
    Do While i <= codeLen AndAlso gOutlineCount < MAX_OUTLINE_ITEMS
        ' Extract one line
        Dim As Long eol = InStr(i, code, Chr(10))
        If eol = 0 Then eol = codeLen + 1
        Dim As String rawLine = Mid(code, i, eol - i)
        i = eol + 1
        lineNum += 1

        Dim As String ln = LTrim(rawLine)
        If Len(ln) = 0 Then Continue Do

        ' Skip comments
        If Left(ln, 1) = "'" Then Continue Do
        If UCase(Left(ln, 4)) = "REM " Then Continue Do

        Dim As String upper = UCase(ln)

        ' Track End Type / End Enum
        If Left(upper, 8) = "END TYPE" Then inType = 0 : Continue Do
        If Left(upper, 8) = "END ENUM" Then inEnum = 0 : Continue Do

        ' Skip lines inside Type/Enum bodies
        If inType OrElse inEnum Then Continue Do

        ' --- TYPE definition ---
        If Left(upper, 5) = "TYPE " Then
            ' Make sure it's "TYPE Name" not "TYPE AS ..."
            Dim As String rest = LTrim(Mid(ln, 5))
            Dim As String upperRest = UCase(rest)
            If Left(upperRest, 3) <> "AS " Then
                ' Extract type name (first word)
                Dim As Long sp = InStr(rest, " ")
                Dim As String typeName
                If sp > 0 Then
                    typeName = Left(rest, sp - 1)
                Else
                    typeName = rest
                End If
                If Len(typeName) > 0 Then
                    gOutline(gOutlineCount).itemName = typeName
                    gOutline(gOutlineCount).category = "Types"
                    gOutline(gOutlineCount).prefix = "Type"
                    gOutline(gOutlineCount).lineNum = lineNum
                    gOutlineCount += 1
                    inType = -1
                End If
            End If
            Continue Do
        End If

        ' --- ENUM definition ---
        If Left(upper, 5) = "ENUM " OrElse upper = "ENUM" Then
            Dim As String enumName = LTrim(Mid(ln, 5))
            Dim As Long sp = InStr(enumName, " ")
            If sp > 0 Then enumName = Left(enumName, sp - 1)
            If Len(enumName) = 0 Then enumName = "(anonymous)"
            gOutline(gOutlineCount).itemName = enumName
            gOutline(gOutlineCount).category = "Enums"
            gOutline(gOutlineCount).prefix = "Enum"
            gOutline(gOutlineCount).lineNum = lineNum
            gOutlineCount += 1
            inEnum = -1
            Continue Do
        End If

        ' --- SUB definition ---
        If Left(upper, 4) = "SUB " Then
            Dim As String rest = LTrim(Mid(ln, 4))
            ' Extract sub name (up to '(' or space)
            Dim As Long paren = InStr(rest, "(")
            Dim As Long sp = InStr(rest, " ")
            Dim As Long endPos = Len(rest) + 1
            If paren > 0 AndAlso paren < endPos Then endPos = paren
            If sp > 0 AndAlso sp < endPos Then endPos = sp
            Dim As String subName = Left(rest, endPos - 1)
            If Len(subName) > 0 Then
                gOutline(gOutlineCount).itemName = subName
                gOutline(gOutlineCount).category = "Procedures"
                gOutline(gOutlineCount).prefix = "Sub"
                gOutline(gOutlineCount).lineNum = lineNum
                gOutlineCount += 1
            End If
            Continue Do
        End If

        ' --- FUNCTION definition ---
        If Left(upper, 9) = "FUNCTION " Then
            Dim As String rest = LTrim(Mid(ln, 9))
            Dim As Long paren = InStr(rest, "(")
            Dim As Long sp = InStr(rest, " ")
            Dim As Long endPos = Len(rest) + 1
            If paren > 0 AndAlso paren < endPos Then endPos = paren
            If sp > 0 AndAlso sp < endPos Then endPos = sp
            Dim As String funcName = Left(rest, endPos - 1)
            If Len(funcName) > 0 Then
                gOutline(gOutlineCount).itemName = funcName
                gOutline(gOutlineCount).category = "Procedures"
                gOutline(gOutlineCount).prefix = "Function"
                gOutline(gOutlineCount).lineNum = lineNum
                gOutlineCount += 1
            End If
            Continue Do
        End If

        ' --- CONST definition ---
        If Left(upper, 6) = "CONST " Then
            Dim As String rest = LTrim(Mid(ln, 6))
            ' Skip "As" type declarations
            If UCase(Left(rest, 3)) = "AS " Then Continue Do
            Dim As Long eq = InStr(rest, "=")
            Dim As Long sp = InStr(rest, " ")
            Dim As Long endPos = Len(rest) + 1
            If eq > 0 AndAlso eq < endPos Then endPos = eq
            If sp > 0 AndAlso sp < endPos Then endPos = sp
            Dim As String constName = Trim(Left(rest, endPos - 1))
            If Len(constName) > 0 Then
                gOutline(gOutlineCount).itemName = constName
                gOutline(gOutlineCount).category = "Constants"
                gOutline(gOutlineCount).prefix = "Const"
                gOutline(gOutlineCount).lineNum = lineNum
                gOutlineCount += 1
            End If
            Continue Do
        End If

        ' --- DECLARE SUB/FUNCTION ---
        If Left(upper, 8) = "DECLARE " Then
            Dim As String rest = LTrim(Mid(ln, 8))
            Dim As String upperRest = UCase(rest)
            Dim As String declType = ""
            Dim As String declName = ""
            If Left(upperRest, 4) = "SUB " Then
                declType = "Declare Sub"
                rest = LTrim(Mid(rest, 4))
            ElseIf Left(upperRest, 9) = "FUNCTION " Then
                declType = "Declare Function"
                rest = LTrim(Mid(rest, 9))
            End If
            If Len(declType) > 0 Then
                Dim As Long paren = InStr(rest, "(")
                Dim As Long sp = InStr(rest, " ")
                Dim As Long endPos = Len(rest) + 1
                If paren > 0 AndAlso paren < endPos Then endPos = paren
                If sp > 0 AndAlso sp < endPos Then endPos = sp
                declName = Left(rest, endPos - 1)
                If Len(declName) > 0 Then
                    gOutline(gOutlineCount).itemName = declName
                    gOutline(gOutlineCount).category = "Declares"
                    gOutline(gOutlineCount).prefix = declType
                    gOutline(gOutlineCount).lineNum = lineNum
                    gOutlineCount += 1
                End If
            End If
            Continue Do
        End If

        ' --- #Define ---
        If Left(upper, 8) = "#DEFINE " Then
            Dim As String rest = LTrim(Mid(ln, 8))
            Dim As Long sp = InStr(rest, " ")
            Dim As Long paren = InStr(rest, "(")
            Dim As Long endPos = Len(rest) + 1
            If sp > 0 AndAlso sp < endPos Then endPos = sp
            If paren > 0 AndAlso paren < endPos Then endPos = paren
            Dim As String defName = Left(rest, endPos - 1)
            If Len(defName) > 0 Then
                gOutline(gOutlineCount).itemName = defName
                gOutline(gOutlineCount).category = "Defines"
                gOutline(gOutlineCount).prefix = "#Define"
                gOutline(gOutlineCount).lineNum = lineNum
                gOutlineCount += 1
            End If
            Continue Do
        End If
    Loop
End Sub

#EndIf
