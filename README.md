# FBEditor Linux v0.2.0

A FreeBASIC IDE for Linux 64-bit, written entirely in FreeBASIC using the Window9 GUI library. Ported from the original [FBEditor for Windows](https://github.com/ronen-blumberg/FBEditor) (VB.NET/.NET Framework 4.8).

![Platform](https://img.shields.io/badge/Platform-Linux_64--bit-blue)
![Language](https://img.shields.io/badge/Language-FreeBASIC-green)
![GUI](https://img.shields.io/badge/GUI-Window9-orange)
![Lines](https://img.shields.io/badge/Lines_of_Code-3.7K-brightgreen)

---

## Screenshots

Launch the IDE and open a FreeBASIC source file to see:

- Full syntax highlighting with 7 color categories
- Line numbers in the left margin
- Code outline panel showing procedures, types, enums, defines
- Toolbar with quick-access buttons
- Output panel with compiler results
- Dark and light theme support

---

## Features

### Editor

- **FreeBASIC syntax highlighting** with 7 categories:
  - Keywords (purple, bold): `Dim`, `Sub`, `Function`, `If`, `Then`, `For`, `Next`, `Type`, `End`, etc.
  - Data types (yellow): `Integer`, `String`, `Long`, `Double`, `Boolean`, `Byte`, etc.
  - Comments (green, italic): `' comment` and `REM comment`
  - Strings (green): `"text in quotes"`
  - Numbers (orange): `42`, `3.14`, `&hFF00`, `&b1010`
  - Preprocessor (blue): `#Include`, `#Define`, `#If`, `#EndIf`, etc.
  - Built-in functions (blue): `Len`, `Mid`, `Str`, `Val`, `InStr`, `Chr`, etc.
- **Line numbers** in the left gutter margin, matching theme colors
- **Auto-indent** on Enter key (matches previous line's whitespace)
- **Auto-complete** (Ctrl+Space) with popup listing matching keywords, types, and built-in functions
- **Find & Replace** dialog (Ctrl+F / Ctrl+H) with match case, wrap-around, find next/previous
- **Go To Line** (Ctrl+G) via input dialog
- **Comment toggle** (Ctrl+/) — comments or uncomments the current line/selection
- **Select line** (Ctrl+L) — selects the entire current line
- **Duplicate line** (Ctrl+D) — duplicates the current line below
- **Delete line** (Ctrl+Shift+K) — deletes the current line
- **Move line** up/down — via Edit menu
- **Word wrap toggle** — via View menu
- **Monospace font** with configurable name and size
- **Zoom in/out** (Ctrl+NumPad+/- or View menu), reset to default (Ctrl+0)
- **Editor font chooser** — pick any installed system font via View > Editor Font
- **Undo/Redo** — Ctrl+Z / Ctrl+Y (handled natively by GtkTextView)
- **Cut/Copy/Paste/Select All** — Ctrl+X / Ctrl+C / Ctrl+V / Ctrl+A (native GTK clipboard)
- **Indent / Unindent selection** — Ctrl+] / Ctrl+[ on the current line or multi-line selection
- **Current-line highlight** — subtly shades the line under the cursor
- **Bracket matching** — highlights the matching `()`, `[]`, `{}` when the cursor sits on one
- **Insert / Overwrite toggle** — Ins key toggles modes; status bar shows `INS` / `OVR`
- **Drag & drop** — drop `.bas` or `.bi` files from your file manager onto the editor to open them
- **Smooth scrolling** — non-blocking event loop with deferred UI updates for responsive scrolling
- **Responsive builds** — the IDE pumps GTK events while `fbc` runs so the window stays live

### Multi-File Editing

- **Tabbed file switching** via combo box dropdown at the top of the editor
- **Ctrl+PageDown / Ctrl+PageUp** — cycle through open file tabs
- **Project tree** (left panel, top) — shows all open files; double-click to switch
- **Modified file indicator** — `*` prefix in title bar, file combo, and project tree
- **Save All** (Ctrl+Shift+S) — saves all modified files at once
- **Close file** (Ctrl+W) with unsaved-changes prompt
- **Up to 32 files** open simultaneously

### Code Outline

- **Live code outline panel** (left panel, bottom) showing the structure of your code:
  - Procedures (Sub, Function)
  - Types
  - Enums
  - Constants
  - Declares
  - Defines (#Define)
- **Double-click** any item to jump directly to that line in the editor
- **Refresh** with F4 or View > Refresh Outline

### Build System

- **Compile** (Ctrl+F5) — compiles the current file with `fbc`
- **Compile & Run** (F6) — compiles and launches the executable
- **Run** (Ctrl+F6) — runs the last built executable without recompiling
- **Auto-save** — all modified files are saved before building
- **Compiler output** displayed in the Output panel with error/warning messages
- **Clickable errors** — double-click a compiler error in the Output panel to jump to that line
- **Auto-jump to first error** on build failure
- **Error count** shown in status bar after build
- **Build Options dialog** (Build > Build Options) with:
  - Target type: Console Application / GUI Application (-s gui)
  - Optimization level: None / O1 / O2 / O3
  - Error checking: None / -e / -ex / -exx
  - Debug info: -g checkbox
  - Extra compiler flags (free text)
  - Include paths (-i)
  - Library paths (-p)
- **Set FBC Path** dialog to locate the FreeBASIC compiler
- **Auto-detection** of `fbc` at `/usr/local/bin/fbc` or `/usr/bin/fbc`

### Debugger (Foundation)

- **Debug menu** with keyboard shortcuts:
  - Start / Continue (F5)
  - Stop (Shift+F5)
  - Step Over (F10)
  - Step Into (F11)
  - Step Out (Shift+F11)
  - Toggle Breakpoint (F9)
- **Debug output tab** with GDB command input field
- **Batch-mode GDB execution** — runs program under GDB and captures output
- **Auto-detection** of GDB at `/usr/bin/gdb` or `/usr/local/bin/gdb`
- Note: Full interactive GDB/MI stepping (breakpoints, locals, call stack) requires async threaded pipe I/O and is planned for a future version

### Toolbar

Quick-access buttons with GTK stock icons:
- New, Open, Save
- Undo, Redo
- Find
- Build, Run

### Themes

- **Dark theme** and **Light theme** — toggle with View > Toggle Dark/Light Theme
- Applies to: editor, output panel, debug panel, project tree, code outline, line number gutter
- **Dark theme colors** (One Dark inspired):
  - Editor background: #1E2128
  - Keywords: #C678DD (purple)
  - Types: #E5C07B (yellow)
  - Comments: #5C6370 (grey italic)
  - Strings: #98C379 (green)
  - Numbers: #D19A66 (orange)
  - Preprocessor/Functions: #61AFEF (blue)
- Theme preference is saved and restored across sessions

### Session Persistence

All settings are saved to `~/.config/fbeditor/` and restored on next launch:
- Window position and size
- All splitter positions (project tree width, outline height, output panel height)
- Editor font name and size
- Dark/light theme, word-wrap, auto-indent preferences
- FBC and GDB compiler paths
- Build options (target type, optimization, debug info, etc.)
- Recent files list (File > Recent Files submenu)
- **Open file set** — all files that were open are reopened on next launch, with the previously-active file selected

### Preferences

Central **Preferences** dialog (View > Preferences... or `Ctrl+,`) for:
- Tab width
- Editor font name and size
- Dark theme on/off
- Word wrap on/off
- Auto-indent on Enter on/off
- Show line numbers (persisted)

### Status Bar

Three-section status bar showing:
- **Left**: Status messages (Ready, file opened, build result, error count)
- **Center**: `Ln: 42/500  Col: 12` — current line / total lines, column position
  - When text is selected: `Sel: 128 chars, 5 lines`
  - When file is modified: `[*]` indicator
- **Right**: File encoding (UTF-8)

---

## Keyboard Shortcuts

### File Operations

| Shortcut | Action |
|---|---|
| Ctrl+N | New File |
| Ctrl+O | Open File |
| Ctrl+S | Save |
| Ctrl+Shift+S | Save All |
| Ctrl+W | Close File |
| Ctrl+PageDown | Next File Tab |
| Ctrl+PageUp | Previous File Tab |

### Editor

| Shortcut | Action |
|---|---|
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Ctrl+X / Ctrl+C / Ctrl+V | Cut / Copy / Paste |
| Ctrl+A | Select All |
| Ctrl+Space | Auto-Complete |
| Ctrl+F | Find |
| Ctrl+H | Find & Replace |
| F3 | Find Next |
| Ctrl+G | Go To Line |
| Ctrl+/ | Toggle Comment |
| Ctrl+L | Select Line |
| Ctrl+D | Duplicate Line |
| Ctrl+Shift+K | Delete Line |
| Ctrl+] / Ctrl+[ | Indent / Unindent selection |
| Ctrl+, | Preferences |
| Ins | Toggle Insert / Overwrite |
| Ctrl+NumPad+ | Zoom In |
| Ctrl+NumPad- | Zoom Out |
| Ctrl+0 | Reset Zoom |

### Build & Run

| Shortcut | Action |
|---|---|
| Ctrl+F5 | Compile |
| F6 | Compile & Run |
| Ctrl+F6 | Run (No Compile) |
| F4 | Refresh Code Outline |

### Debugger

| Shortcut | Action |
|---|---|
| F5 | Start / Continue |
| Shift+F5 | Stop |
| F10 | Step Over |
| F11 | Step Into |
| Shift+F11 | Step Out |
| F9 | Toggle Breakpoint |

---

## Requirements

- **Linux 64-bit** (tested on Debian 13 / x86_64)
- **FreeBASIC Compiler** 1.10+ — [Download](https://www.freebasic.net/wiki/CompilerInstalling)
- **Window9 Library for Linux** — included at `/home/ronen/freebasic/window9_linux/`
- **GTK 2.x development libraries** — typically pre-installed on most Linux distributions
- **GDB** (optional, for debugging) — `sudo apt install gdb`

### System Libraries

The following are required at runtime (usually already installed):
- `libgtk2.0-0` — GTK 2.x runtime
- `libcairo2` — 2D graphics library
- `libpango1.0-0` — Text rendering
- `libglib2.0-0` — GLib utilities

---

## Installation

### Building from Source

```bash
cd /home/ronen/freebasic/FBEditor-linux
make debug       # Build with debug info and runtime checks
make release     # Build optimized release
make run         # Build and run
make clean       # Remove built binary
```

The compiled binary is `fbeditor` in the project root.

### Running

```bash
# Run the IDE
./fbeditor

# Open a file directly
./fbeditor /path/to/your/file.bas

# Or double-click fbeditor in your file manager
```

### Build Dependencies

- FreeBASIC compiler (`fbc`) version 1.10+
- Window9 library (`libwindow9.a`) at `/home/ronen/freebasic/window9_linux/`
- Window9 include files at `/home/ronen/freebasic/window9_linux/include/`

---

## Project Structure

```
FBEditor-linux/
├── Makefile                   Build configuration
├── README.md                  This file
├── CLAUDE.md                  AI assistant context file
├── fbeditor                   Compiled binary (after build)
├── src/
│   └── main.bas               Main application (~3,000 lines)
├── include/
│   ├── types.bi               Core data types
│   ├── syntax.bi              Syntax highlighting engine
│   └── outline.bi             Code outline parser
└── test/
    ├── hello.bas              Simple test program
    └── syntax_test.bas        Syntax highlighting test file
```

### Architecture

The application is a single-threaded GTK2 GUI application with a non-blocking event loop:

- **main.bas** — Contains all UI creation (window, menus, toolbar, splitters, gadgets), event handling, file operations, build system, find/replace, auto-complete, and theme management
- **syntax.bi** — FreeBASIC syntax highlighter using GtkTextBuffer tags. Highlights keywords, types, comments, strings, numbers, preprocessor directives, and built-in functions. Supports both dark and light theme color schemes
- **outline.bi** — Source code parser that extracts Sub, Function, Type, Enum, Const, Declare, and #Define definitions with line numbers for the code outline panel
- **types.bi** — Shared data type definitions (OpenFileInfo, BuildSettings, EditorSettings, CompilerError, BuildResult)

### Event Loop Design

The IDE uses `Windowevent()` (non-blocking) instead of `Waitevent()` (blocking) to keep scrolling smooth:

1. Process one Window9 event per iteration
2. When no events are pending, drain remaining GTK events, process deferred updates (status bar, modify check, syntax highlighting), then sleep 2ms
3. Mouse wheel events immediately drain the GTK queue to prevent scroll lag
4. Expensive operations (status bar update, modify check, syntax re-highlight) are deferred via dirty flags and only executed when the event queue is empty

### Line Numbers

Line numbers are drawn using GtkTextView's left border window (`GTK_TEXT_WINDOW_LEFT`) with a custom `expose-event` callback. The callback iterates only visible lines and uses a static PangoLayout to avoid per-frame allocation.

### Syntax Highlighting

Highlighting uses GtkTextBuffer tags created at initialization. Each tag has foreground color and optional weight/style properties. When text changes, only the current line and its neighbors are re-highlighted (deferred to idle). Full re-highlighting occurs when switching files or opening a new file.

### Window9 Integration

Window9 is a FreeBASIC GUI library that wraps GTK2. Key Window9 functions used:
- `Openwindow` / `Windowbounds` / `Centerwindow` — window management
- `Create_menu` / `Menutitle` / `Menuitem` / `Menubar` — menu system
- `Createtoolbar` / `Toolbarstandardbutton` — toolbar with GTK stock icons
- `SplitterGadget` / `SplitterGadgetAddGadget` — resizable split panels
- `Editorgadget` / `Setgadgettext` / `Getgadgettext` — text editor (GtkTextView)
- `Treeviewgadget` / `Addtreeviewitem` — tree views for project/outline
- `Comboboxgadget` — file tab selector
- `Panelgadget` — tabbed output panel
- `Statusbargadget` / `Setstatusbarfield` — status bar
- `Containergadget` — container for grouping widgets
- `Addkeyboardshortcut` — keyboard shortcut registration
- `Windowevent` / `Waitevent` / `Eventnumber` / `Eventhwnd` — event loop
- `ConfigCreate` / `ConfigLoad` / `ConfigSave` — INI-style settings persistence
- `Openfilerequester` / `Savefilerequester` — file dialogs
- `Inputbox` / `Messbox` / `Fontrequester` — dialog boxes

### GTK2 Direct API Usage

Some features require direct GTK2 API calls (via FreeBASIC's `Declare` bindings in `gtk/gtk.bi`):
- `gtk_text_view_set_border_window_size` — line number margin
- `gtk_text_view_get_visible_rect` / `gtk_text_view_get_line_at_y` — visible range for line numbers
- `gtk_text_buffer_create_tag` / `gtk_text_buffer_apply_tag_by_name` — syntax highlighting
- `gtk_text_view_set_wrap_mode` — word wrap toggle
- `gtk_drag_dest_set` / `g_signal_connect("drag-data-received")` — drag & drop
- `gtk_paint_layout` / `pango_layout_set_text` — line number rendering
- `gtk_events_pending` / `gtk_main_iteration_do` — event queue draining for smooth scroll

---

## Configuration Files

All configuration is stored in `~/.config/fbeditor/`:

| File | Purpose |
|---|---|
| `settings.ini` | All IDE settings (window state, editor prefs, build options, compiler paths) |
| `recent.txt` | Recent files list (one path per line, up to 10) |
| `session.txt` | List of files that were open at last exit + active-file index |

### settings.ini Format

```ini
[Build]
DebugInfo=-1
FBCPath=/usr/local/bin/fbc
GDBPath=/usr/bin/gdb
TargetType=0

[Editor]
DarkTheme=-1
FontName=Monospace
FontSize=11
TabWidth=4

[Window]
H=750
SplitLeft=200
SplitMain=220
SplitRight=500
W=1200
X=50
Y=50
```

---

## Comparison with Original FBEditor (Windows)

| Feature | Windows (VB.NET) | Linux (FreeBASIC) |
|---|---|---|
| Language | VB.NET (.NET 4.8) | FreeBASIC |
| GUI toolkit | WinForms | Window9 (GTK2) |
| Editor component | ScintillaNET | GtkTextView + custom highlighting |
| Lines of code | ~12,200 | ~3,100 |
| Syntax highlighting | Scintilla lexer | GtkTextBuffer tags |
| Line numbers | Scintilla margin | GtkTextView border window |
| Auto-complete | Scintilla popup | Window9 popup window |
| Code folding | Scintilla folding | Not yet implemented |
| Form designer | Full WYSIWYG | Not yet implemented |
| GDB debugger | Full GDB/MI async | Basic batch mode |
| AI Chat | Claude API | Not yet implemented |
| Installer | Inno Setup | N/A (single binary) |

---

## Known Limitations

- **No code folding** — GtkTextView doesn't support folding natively; would require custom implementation
- **No syntax highlighting for very large files** — full re-highlight on file open may be slow for files >10K lines
- **GDB debugger is batch-mode only** — full interactive debugging with breakpoints, stepping, and variable inspection requires async threaded GDB/MI communication
- **No form designer** — the Window9 visual form designer from the Windows version is not yet ported
- **No AI Chat** — Claude API integration is not yet implemented
- **Alt+Up/Down for move line** — arrow key shortcuts don't work with Window9's `Addkeyboardshortcut`; available via Edit menu
- **WebGadget stub** — Window9's WebGadget requires `libwebkitgtk-1.0` which is no longer available on modern Linux; a stub library is provided

---

## Version History

### v0.2.0 (April 2026)

**New features:**
- Cut / Copy / Paste / Select All via native GTK clipboard (menu + shortcuts)
- Indent / Unindent selection (Ctrl+]/Ctrl+[) on current line or multi-line selection
- Current-line background highlighting (theme-aware)
- Bracket matching highlight for `()`, `[]`, `{}` — respects strings and line comments
- Insert / Overwrite mode toggle with `Ins` key; status bar shows `INS` / `OVR`
- **Session restore** — reopens previously-open files and restores the active file
- **Preferences dialog** (Ctrl+,) — tab width, font, dark theme, word wrap, auto-indent
- About dialog now shows live FBC/GDB versions, open-file counts, and config path
- Persist word-wrap and auto-indent settings across sessions
- Exit via File > Exit now prompts for unsaved changes (previously closed without asking)
- Responsive UI during builds — pumps GTK events while `fbc` is running

**Bug fixes:**
- **Save All** (Ctrl+Shift+S) no longer silently discards unsaved edits on the active file
- **Find Next / Find Previous** no longer get stuck re-finding the current selection; status bar reports wrap vs. line number
- **Replace One** only replaces when the current selection truly matches the search text, preventing accidental insertions
- Comment / Uncomment block now handles selections that don't end in a newline

### v0.1.0 (April 2026)
- Initial Linux port from VB.NET FBEditor
- Full FreeBASIC syntax highlighting with 7 categories
- Line numbers with dark/light theme support
- Code outline panel (Procedures, Types, Enums, Constants, Defines, Declares)
- Auto-indent, auto-complete, find/replace, go to line
- Comment toggle, select/duplicate/delete line
- Multi-file editing with tab switching
- Build system with clickable compiler errors
- Build options dialog
- Toolbar with GTK stock icons
- Dark/light theme toggle
- Drag & drop file opening
- Command-line file opening
- Session persistence (window state, splitter positions, font, theme, build options)
- Recent files menu
- Save All, file cycling with Ctrl+PageUp/Down
- Resizable window with proper panel auto-resize
- Non-blocking event loop for smooth scrolling

---

## License

Copyright 2026 Ronen Blumberg. All rights reserved.

Permission is granted to use, copy, and distribute this software for any purpose, provided that the copyright notice and license appear in all copies or substantial portions of the software.

This software is provided "as-is" without warranty of any kind.

---

## Author

**Ronen Blumberg**

Built with FreeBASIC + Window9 for the FreeBASIC community.
