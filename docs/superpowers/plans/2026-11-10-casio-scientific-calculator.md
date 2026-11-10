# Casio fx-991ES PLUS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform the calculator into an authentic Casio fx-991ES PLUS scientific calculator with natural mathematical expression input, dual-line LCD with annunciators, signature keypad styling, and interactive MODE/SETUP menus.

**Architecture:** Infix expression evaluation engine (tokenizer + shunting-yard algorithm) with angle unit and decimal format support, powering a realistic SwiftUI Casio hardware shell with LCD annunciators and modifier keys.

**Tech Stack:** Swift 6, SwiftUI, cross-compiled for iOS using `xtool dev build`.

**Spec:** docs/superpowers/specs/2026-11-10-casio-scientific-calculator-design.md

## Global Constraints
- Target platform: iOS via `xtool` (`xtool dev build`).
- Build command must complete cleanly with exit code 0 (`xtool dev build`).
- Colors, labels, and layout must accurately match the Casio fx-991ES PLUS 2nd Edition photo.

## Review Focus
- Division by zero and domain errors (e.g. `√(−1)`, `ln(0)`) must display `Math ERROR` cleanly without crashing.
- Trigonometric functions must respect the active angle mode: `Deg` ($\sin(30) = 0.5$), `Rad` ($\sin(\pi/6) = 0.5$), and `Gra` ($\sin(50) = 0.5$).
- Operator precedence ($2 + 3 \times 4 = 14$) and nested parentheses must calculate accurately.
- `DEL` must delete tokens at the cursor position without index out-of-bounds errors; `AC` must clear expression and result.
- `SHIFT` and `ALPHA` states must toggle their respective LCD annunciators (`S`, `A`) and auto-reset upon executing secondary operations.

---

### Task 1: Casio Expression Engine & State Machine

**Files:**
- Modify: `Sources/greeter/Calculator.swift`

**Interfaces:**
- Produces:
  - `enum AngleUnit { case deg, rad, gra }`
  - `enum DisplayFormat { case norm, fix(Int), sci(Int) }`
  - `enum CalcMode: String { case comp = "COMP", stat = "STAT", table = "TABLE", eqn = "EQN" }`
  - `enum MenuState { case none, modeMenu, setupMenu, fixPrompt, sciPrompt }`
  - `final class CalculatorEngine: ObservableObject`
    - `@Published var expression: String`
    - `@Published var cursorPosition: Int`
    - `@Published var result: String`
    - `@Published var angleUnit: AngleUnit`
    - `@Published var displayFormat: DisplayFormat`
    - `@Published var activeMode: CalcMode`
    - `@Published var menuState: MenuState`
    - `@Published var shiftActive: Bool`
    - `@Published var alphaActive: Bool`
    - `@Published var hasMemory: Bool`
    - `@Published var isError: Bool`
    - `func insert(_ text: String)`
    - `func delete()`
    - `func clearAll()`
    - `func turnOn()`
    - `func toggleShift()`
    - `func toggleAlpha()`
    - `func openModeMenu()`
    - `func openSetupMenu()`
    - `func selectMenuOption(_ number: Int)`
    - `func moveCursorLeft()`
    - `func moveCursorRight()`
    - `func evaluate()`
    - `func addMemory()`
    - `func subtractMemory()`
    - `func recallMemory()`

- [x] **Step 1: Implement Tokenizer, Evaluator, and State Machine in `Sources/greeter/Calculator.swift`**
  - Implement infix tokenization (numbers, operators `+`, `−`, `×`, `÷`, `^`, functions `sin`, `cos`, `tan`, `sin⁻¹`, `cos⁻¹`, `tan⁻¹`, `log`, `ln`, `√`, `∛`, `x²`, `x⁻¹`, `!`, constants `π`, `e`, `Ans`, parentheses).
  - Implement Shunting-Yard algorithm and RPN evaluator respecting operator precedence and `AngleUnit`.
  - Implement number formatting respecting `DisplayFormat` (`Norm`, `Fix`, `Sci`).
  - Implement `MenuState` transitions for `MODE` and `SETUP`.

- [x] **Step 2: Verify `Calculator.swift` compiles cleanly with `xtool dev build`**
  - Run: `xtool dev build`
  - Expected: Build complete! (0 errors)

---

### Task 2: Casio LCD Display & Annunciators View

**Files:**
- Modify: `Sources/greeter/ContentView.swift`

**Interfaces:**
- Consumes: `CalculatorEngine` from `Calculator.swift`
- Produces:
  - `struct CasioLCDView: View`
    - Greenish-gray LCD glass background (`Color(red: 0.54, green: 0.61, blue: 0.49)`).
    - Top Annunciator row: `S`, `A`, `M`, `STO`, `D`, `R`, `G`, `Fix`, `Sci`, `Math` (highlighted black when active, faint/dim when inactive).
    - Two-line display:
      - Line 1: Expression string with blinking cursor indicator (`_`) or interactive menu options (`1:COMP 2:STAT...`).
      - Line 2: Large monospaced digit result, right-aligned, or `Math ERROR` with `[AC]:Cancel`.

- [x] **Step 1: Implement `CasioLCDView` in `Sources/greeter/ContentView.swift`**
  - Create the dual-line Casio LCD styling with authentic bezel, annunciator status row, and menu screen rendering.

- [x] **Step 2: Verify `ContentView.swift` compiles with `xtool dev build`**
  - Run: `xtool dev build`
  - Expected: Build complete!

---

### Task 3: Casio Casing, Solar Cell, Replay D-Pad, and Keypad Matrix

**Files:**
- Modify: `Sources/greeter/ContentView.swift`

**Interfaces:**
- Consumes: `CasioLCDView`, `CalculatorEngine`
- Produces:
  - `struct CasioHeaderView: View`: White CASIO logo, "fx-991ES PLUS", "NATURAL-V.P.A.M.", "2nd edition", and solar cell grid.
  - `struct ReplayPadView: View`: Metallic circular 4-way D-Pad with directional arrows (`▲`, `▼`, `◀`, `▶`).
  - `struct CasioKeyView: View`: Key component displaying primary label, yellow top-left SHIFT label, and magenta top-right ALPHA label.
  - Complete keypad layout:
    - Control row: `SHIFT`, `ALPHA`, Replay D-pad, `MODE SETUP`, `ON`.
    - Function rows: `■/□`, `√`, `x²`, `x^■`, `log`, `ln`, `(-)`, `° ' "`, `hyp`, `sin`, `cos`, `tan`, `RCL`, `ENG`, `(`, `)`, `S<=>D`, `M+`.
    - Numeric pad: `7`, `8`, `9`, lime green `DEL`, lime green `AC`, `4`, `5`, `6`, `×`, `÷`, `1`, `2`, `3`, `+`, `−`, `0`, `.`, `×10^x`, `Ans`, `=`.

- [x] **Step 1: Implement full Casio hardware chassis and keypad in `Sources/greeter/ContentView.swift`**
  - Build the contoured outer shell, solar cell header, D-pad, and 5-tier keypad with Casio button styling and color coding.
  - Wire all button taps to `engine.handleKey(...)`.

- [x] **Step 2: Verify build and layout with `xtool dev build`**
  - Run: `xtool dev build`
  - Expected: Build complete!

---

### Task 4: Verification and Edge Case Testing

**Files:**
- Test / Verification via: `xtool dev build` and engine unit validation

- [x] **Step 1: Run `xtool dev build`**
  - Run: `xtool dev build`
  - Expected: Exit code 0, binary output in `xtool/greeter.app`.

- [x] **Step 2: Inspect code for review focus items**
  - Verify division by zero yields `Math ERROR`.
  - Verify angle conversions for $\sin(30^\circ)$, $\sin(\pi/6\text{ rad})$, $\sin(50\text{ gra})$.
  - Verify `SHIFT` + `MODE` opens `SETUP` menu and correctly sets `Deg`, `Rad`, `Gra`, `Fix`, `Sci`, `Norm`.
