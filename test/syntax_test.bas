' FBEditor Syntax Highlighting Test
' This is a comment
#Include Once "crt.bi"
#Define MAX_SIZE 100

Dim Shared myVar As Integer = 42
Dim As String greeting = "Hello World!"
Dim As Double pi = 3.14159
Dim As Long hexVal = &hFF00

Type MyType
    x As Long
    y As Long
    name As String
End Type

Function Add(a As Integer, b As Integer) As Integer
    Return a + b
End Function

Sub PrintMessage(msg As String)
    Dim As Integer i
    For i = 1 To Len(msg)
        Print Mid(msg, i, 1);
    Next
    Print
End Sub

' Main program
Dim As MyType obj
obj.x = 10
obj.y = 20
obj.name = "Test Object"

If obj.x > 0 AndAlso obj.y > 0 Then
    PrintMessage("Both positive")
ElseIf obj.x = 0 OrElse obj.y = 0 Then
    PrintMessage("One is zero")
Else
    Print "Negative values"
End If

Dim As Integer result = Add(obj.x, obj.y)
Print "Sum = "; Str(result)

REM This is also a comment
Select Case result
    Case 0 To 10
        Print "Small"
    Case 11 To 100
        Print "Medium"
    Case Else
        Print "Large"
End Select

Sleep
