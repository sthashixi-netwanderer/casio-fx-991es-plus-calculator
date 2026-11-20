import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Visual Tokens (Casio fx-991ES PLUS 2nd Edition)

enum CasioTheme {
    // Housing / Chassis (sampled from fx-991ES PLUS 2nd edition: dark matte slate)
    static let chassis = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let chassisBezel = Color(red: 0.18, green: 0.19, blue: 0.22)
    static let solarCell = Color(red: 0.24, green: 0.14, blue: 0.12)
    static let solarGrid = Color.white.opacity(0.14)

    // LCD Display (sampled from photo: crisp light greenish LCD glass)
    static let lcdBackground = Color(red: 0.845, green: 0.916, blue: 0.855)
    static let lcdBackgroundOff = Color(red: 0.22, green: 0.25, blue: 0.22)
    static let lcdBezel = Color(red: 0.08, green: 0.09, blue: 0.11)
    static let lcdTextActive = Color(red: 0.07, green: 0.09, blue: 0.13)
    static let lcdTextDim = Color(red: 0.07, green: 0.09, blue: 0.13).opacity(0.16)

    // Key Fills
    static let keyStandard = Color(red: 0.18, green: 0.19, blue: 0.21)
    static let keyStandardBevel = Color.white.opacity(0.10)
    static let keyDelAc = Color(red: 0.53, green: 0.72, blue: 0.35) // Authentic Casio Lime Green
    static let keyDelAcInk = Color(red: 0.05, green: 0.16, blue: 0.04) // Dark text for DEL and AC
    static let keyReplay = Color(red: 0.38, green: 0.41, blue: 0.45)
    static let keyEquals = Color(red: 0.22, green: 0.24, blue: 0.27)

    // Secondary / Modifier Inks
    static let inkShift = Color(red: 0.98, green: 0.82, blue: 0.22) // Yellow Gold
    static let inkAlpha = Color(red: 0.88, green: 0.32, blue: 0.44) // Magenta / Red
    static let inkWhite = Color.white
    static let inkSilver = Color(red: 0.76, green: 0.78, blue: 0.82)
    static let inkBlue = Color(red: 0.28, green: 0.65, blue: 0.90) // Base-N blue labels
}

// MARK: - Key Glyphs & Faces

/// Face of the fx-991ES PLUS ∫ key: the integral sign followed by a stacked
/// pair of small boxes (upper/lower limits) and a filled integrand bar — the
/// hardware does not print "dx" on the key cap itself.
struct IntegrationKeyFace: View {
    var body: some View {
        HStack(alignment: .center, spacing: 1.5) {
            Text("∫")
                .font(.system(size: 17, weight: .light, design: .serif))
                .italic()

            VStack(alignment: .center, spacing: 0.5) {
                RoundedRectangle(cornerRadius: 0.5)
                    .stroke(Color.white.opacity(0.95), lineWidth: 0.9)
                    .frame(width: 5.5, height: 4.5)
                RoundedRectangle(cornerRadius: 0.5)
                    .stroke(Color.white.opacity(0.95), lineWidth: 0.9)
                    .frame(width: 5.5, height: 4.5)
            }

            Rectangle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 7, height: 2.5)
                .offset(y: 1)
        }
        .foregroundColor(CasioTheme.inkWhite)
    }
}

/// Yellow SHIFT label of the ∫ key. On the hardware d/dx is engraved as a
/// stacked fraction (d over dx with a rule), not as the plain text "d/dx".
struct DerivativeShiftLabel: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("d")
                .font(.system(size: 6, weight: .bold))
            Rectangle()
                .fill(CasioTheme.inkShift)
                .frame(width: 8, height: 0.7)
            Text("dx")
                .font(.system(size: 6, weight: .bold))
        }
        .foregroundColor(CasioTheme.inkShift)
    }
}

struct FractionKeyFace: View {
    var body: some View {
        VStack(spacing: 1.5) {
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
                .frame(width: 8, height: 6)
            Rectangle()
                .fill(Color.white.opacity(0.92))
                .frame(width: 10, height: 1)
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
                .frame(width: 8, height: 6)
        }
        .foregroundColor(CasioTheme.inkWhite)
    }
}

struct SqrtKeyFace: View {
    var body: some View {
        HStack(spacing: 1.5) {
            Text("√")
                .font(.system(size: 13, weight: .regular))
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
                .frame(width: 7, height: 7)
        }
        .foregroundColor(CasioTheme.inkWhite)
    }
}

struct PowerKeyFace: View {
    var body: some View {
        HStack(alignment: .top, spacing: 1) {
            Text("x")
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .italic()
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.white.opacity(0.92), lineWidth: 1)
                .frame(width: 6, height: 6)
                .offset(y: -3)
        }
        .foregroundColor(CasioTheme.inkWhite)
    }
}

struct LogBaseKeyFace: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 1.5) {
            Text("log")
                .font(.system(size: 10, weight: .semibold))
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.white.opacity(0.92), lineWidth: 0.9)
                .frame(width: 5.5, height: 5.5)
                .offset(y: 2)
            RoundedRectangle(cornerRadius: 1)
                .stroke(Color.white.opacity(0.92), lineWidth: 0.9)
                .frame(width: 6.5, height: 8)
                .offset(y: -1)
        }
        .foregroundColor(CasioTheme.inkWhite)
    }
}

// MARK: - Haptics

private enum CasioHaptics {
    #if canImport(UIKit)
    @MainActor
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    @MainActor
    static func firm() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    #else
    @MainActor static func tap() {}
    @MainActor static func firm() {}
    #endif
}

// MARK: - Main Calculator View

struct ContentView: View {
    @StateObject private var engine = CalculatorEngine()
    @State private var codeBuffer: String = ""
    @State private var tableScrollIndex: Int = 0

    private var isPromptActive: Bool {
        switch engine.menuState {
        case .eqnCoeffPrompt, .calcPrompt, .solvePrompt:
            return true
        case .tablePrompt(let step) where step > 0 && step < 4:
            return true
        case .matrixDimPrompt, .matrixCellEditor:
            return true
        default:
            return false
        }
    }

    var body: some View {
        ZStack {
            CasioTheme.chassis
                .ignoresSafeArea()

            VStack(spacing: 6) {
                // Header (Branding & Solar Cell)
                casioHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                // LCD Screen
                casioScreen
                    .padding(.horizontal, 14)

                Spacer(minLength: 2)

                // Keypad Matrix
                casioKeypad
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: 440)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header View

    private var casioHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("CASIO")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .tracking(1.5)
                    .foregroundColor(CasioTheme.inkWhite)

                HStack(spacing: 4) {
                    Text("fx-991ES PLUS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.inkSilver)
                    Text("2nd edition")
                        .font(.system(size: 9, weight: .semibold, design: .default))
                        .foregroundColor(CasioTheme.inkSilver.opacity(0.8))
                }

                Text("NATURAL-V.P.A.M.")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .italic()
                    .foregroundColor(CasioTheme.inkSilver.opacity(0.7))
            }

            Spacer()

            // Solar Cell Simulator
            solarPanel
        }
    }

    private var solarPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [CasioTheme.solarCell, Color(red: 0.16, green: 0.10, blue: 0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 88, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(CasioTheme.chassisBezel, lineWidth: 1.5)
                )

            HStack(spacing: 18) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(CasioTheme.solarGrid)
                        .frame(width: 1, height: 22)
                }
            }
        }
    }

    // MARK: - LCD Display Screen

    private var casioScreen: some View {
        ZStack {
            // LCD Glass Rim
            RoundedRectangle(cornerRadius: 10)
                .fill(CasioTheme.lcdBezel)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(CasioTheme.chassisBezel, lineWidth: 2)
                )

            // Inner LCD
            RoundedRectangle(cornerRadius: 6)
                .fill(engine.isOff ? CasioTheme.lcdBackgroundOff : CasioTheme.lcdBackground)
                .padding(6)
                .overlay(
                    Group {
                        if !engine.isOff {
                            VStack(alignment: .leading, spacing: 3) {
                                // Annunciator Status Bar
                                annunciatorBar

                                // LCD Content (Menu or Expression/Result)
                                if engine.menuState != .none {
                                    menuDisplayView
                                } else {
                                    expressionDisplayView
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                    }
                )
        }
        .frame(height: 128)
    }

    // MARK: - Annunciator Bar

    private var annunciatorBar: some View {
        HStack(spacing: 6) {
            annunciator("S", active: engine.shiftActive)
            annunciator("A", active: engine.alphaActive)
            annunciator("M", active: engine.hasMemory)
            annunciator("STO", active: engine.waitingForSto)
            annunciator("RCL", active: engine.waitingForRcl)
            Spacer()
            annunciator("CMPLX", active: engine.activeMode == .cmplx)
            annunciator("STAT", active: engine.activeMode == .stat)
            annunciator("MAT", active: engine.activeMode == .matrix)
            annunciator("VCT", active: engine.activeMode == .vector)
            annunciator(engine.baseNType.rawValue, active: engine.activeMode == .baseN)
            annunciator("D", active: engine.angleUnit == .deg)
            annunciator("R", active: engine.angleUnit == .rad)
            annunciator("G", active: engine.angleUnit == .gra)
            annunciator("Fix", active: isFixFormat)
            annunciator("Sci", active: isSciFormat)
            annunciator("Math", active: engine.isMthIO)
            annunciator("Disp", active: engine.isShowingIntermediate)
            annunciator("▲", active: !engine.history.isEmpty)
            annunciator("▼", active: engine.historyIndex >= 0)
        }
        .frame(height: 12)
    }

    private func annunciator(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(active ? CasioTheme.lcdTextActive : CasioTheme.lcdTextDim)
    }

    private var isFixFormat: Bool {
        if case .fix = engine.displayFormat { return true }
        return false
    }

    private var isSciFormat: Bool {
        if case .sci = engine.displayFormat { return true }
        return false
    }

    // MARK: - Expression & Result Display

    private var expressionDisplayView: some View {
        VStack(spacing: 0) {
            // Expression Line (Top, Left-aligned, with 2D Cursor in MthIO)
            HStack(spacing: 0) {
                if engine.activeMode == .baseN {
                    Text("\(engine.baseNType.rawValue) ")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                }

                if engine.isMthIO {
                    ScrollView(.horizontal, showsIndicators: false) {
                        MathASTView(
                            nodes: engine.astManager.root,
                            slot: .root,
                            cursor: engine.astManager.cursor,
                            fontSize: 16,
                            // The blinking cursor disappears once a result is shown
                            showCursor: !engine.isShowingResult,
                            isNearCapacity: engine.astManager.isNearCapacity,
                            onCursorMove: { path in engine.moveCursor(to: path) }
                        )
                        .padding(.vertical, 2)
                    }
                } else {
                    // LineIO: map a tap to the nearest character position.
                    MathText(
                        engine.isShowingResult ? engine.expression : renderedExpression,
                        fontSize: 16,
                        weight: .medium
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let charWidth: CGFloat = 16 * 0.6
                                let idx = Int(value.location.x / charWidth)
                                engine.setLinearCursorPosition(idx)
                            }
                    )
                }
                Spacer(minLength: 0)
                // Continuation marker when the input expression exceeds the
                // visible LCD width (reference §8.2).
                if engine.expression.count > 22 {
                    Text("▶")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(CasioTheme.lcdTextActive)
                }
            }
            .frame(minHeight: 38, maxHeight: 46, alignment: .leading)

            Spacer(minLength: 0)

            // Result / Error Line (Bottom, Right-aligned)
            HStack(spacing: 0) {
                if engine.isError {
                    Text(engine.result)
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Spacer()
                    Text("[AC]:Cancel")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                } else {
                    // Continuation marker for a result wider than the LCD.
                    // Right-aligned long results clip on the left.
                    if engine.result.count > 13 {
                        Text("◀")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(CasioTheme.lcdTextActive)
                    }
                    Spacer(minLength: 0)
                    if let mat = engine.matrixResult {
                        MatrixResultView(matrix: mat)
                    } else if let vec = engine.vectorResult {
                        Text(vec.linearString)
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(CasioTheme.lcdTextActive)
                    } else if let exact = engine.exactResult, !engine.isShowingDecimal, !engine.isShowingDMS, engine.isMthIO {
                        MathASTView(
                            nodes: exact.toMathNodes(mixed: engine.fractionDisplay == .mixed),
                            slot: .root,
                            cursor: nil,
                            fontSize: 20,
                            showCursor: false
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, 2)
                    } else {
                        // Long results scroll horizontally but stay right-aligned
                        // while they fit (reference §8.2).
                        GeometryReader { geo in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    Spacer(minLength: 0)
                                    MathText(engine.result, fontSize: 26, weight: .semibold)
                                }
                                .frame(minWidth: geo.size.width)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36, maxHeight: 44, alignment: .trailing)
        }
    }

    private var renderedExpression: String {
        let expr = engine.expression
        let pos = engine.cursorPosition
        let chars = Array(expr)
        if chars.isEmpty {
            return "_"
        }
        let safePos = min(max(0, pos), chars.count)
        let prefix = String(chars[0..<safePos])
        let suffix = String(chars[safePos..<chars.count])
        // INS/overwrite mode uses a block cursor on the LCD.
        let cursor = engine.isOverwriteMode ? "▮" : "_"
        return prefix + cursor + suffix
    }

    // MARK: - Menu Display View

    private var menuDisplayView: some View {
        VStack(alignment: .leading, spacing: 2) {
            switch engine.menuState {
            case .modeMenu:
                Text("1:COMP    2:CMPLX   3:STAT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("4:BASE-N  5:EQN     6:MATRIX")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("7:TABLE   8:VECTOR")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .setupMenu(let page):
                if page == 1 {
                    Text("1:MthIO 2:LineIO 3:Deg 4:Rad")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("5:Gra   6:Fix    7:Sci 8:Norm")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("[\(engine.angleUnit.rawValue.uppercased()) \(engine.mathOutputStyle == .mathO ? "MathO" : "LineO") Norm\(engine.normMode.rawValue)] ▼Next")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                } else {
                    Text("1:ab/c 2:d/c 3:CMPLX 4:STAT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("5:Disp 6:CONT")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("[\(engine.fractionDisplay.rawValue) \(engine.complexFormat.rawValue) FREQ:\(engine.statFrequencyEnabled ? "ON" : "OFF")]")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                }

            case .mthIOMenu:
                Text("MthIO")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("1:MathO  2:LineO")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .fixPrompt:
                Text("Fix 0 ~ 9 ?")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .sciPrompt:
                Text("Sci 0 ~ 9 ?")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .normPrompt:
                Text("Norm")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("1:Norm 1  2:Norm 2")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .dispFormatMenu:
                Text("Disp")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("1:Dot  2:Comma")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .statFreqMenu:
                Text("STAT FREQ")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("1:ON  2:OFF")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .contrastPrompt:
                Text("Contrast (0 ~ 9)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("\(codeBuffer.isEmpty ? String(engine.contrastLevel) : codeBuffer)_")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .clrPrompt:
                Text("Reset: 1:Setup 2:Memory 3:All")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("[AC]:Cancel  [=]:OK")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .constPrompt:
                Text("CONST 01 ~ 40 ? [\(codeBuffer)]")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .convPrompt:
                Text("CONV 01 ~ 40 ? [\(codeBuffer)]")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .statTypeMenu:
                Text("1:1-VAR  2:A+BX  3:_+CX²")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                MathText("4:ln X   5:e^X   6:A·B^X", fontSize: 11, weight: .bold)
                MathText("7:A·X^B  8:1/X", fontSize: 11, weight: .bold)

            case .statSubMenu:
                Text(engine.isPairedStat ? "1:A  2:B  3:r  4:ymax" : "1:x̄  2:Σx  3:min  4:max")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text(engine.isPairedStat ? "5:σx  6:Data" : "5:σx  6:Data")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .statDataEditor(let row):
                Text("STAT  X\(engine.isPairedStat ? "/Y" : "")  row \(row + 1)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("\(codeBuffer)_")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("n=\(engine.statData.count)  [=]next  [AC]done")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .cmplxMenu:
                Text("1:arg    2:Abs    3:Conjg")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("4:▶r∠θ   5:▶a+bi")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .cmplxFormatMenu:
                Text("CMPLX")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("1:a+bi   2:r∠θ")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .eqnTypeMenu:
                Text("1:anX+bnY=cn 2:anX+bnY+cnZ=dn")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("3:aX²+bX+c=0 4:aX³+bX²+cX+d=0")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .matrixMenu:
                Text("1:Dim  2:Data 3:MatA 4:MatB")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("5:MatC 6:MatAns 7:det 8:Trn")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .matrixDimSelect, .matrixDataSelect:
                Text("1:MatA  2:MatB  3:MatC")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("[AC]:Cancel")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .matrixDimPrompt(let name):
                Text("\(name)  m×n?")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("1:3×3 2:3×2 3:3×1 4:2×3")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("5:2×2 6:2×1 7:1×3 8:1×2 9:1×1")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("\(codeBuffer.isEmpty ? engine.dimsString(for: name) : codeBuffer)_")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("[=]:OK  [AC]:Cancel")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .matrixCellEditor(let name, let row, let col):
                matrixCellEditorView(name: name, row: row, col: col)

            case .vectorMenu:
                Text("1:Dim  2:Data 3:VctA 4:VctB")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("5:VctC 6:VctAns 7:Dot")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .vectorDimSelect, .vectorDataSelect:
                Text("1:VctA  2:VctB  3:VctC")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("[AC]:Cancel")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .vectorDimPrompt(let name):
                Text("\(name)  Dim? (2 or 3)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("\(codeBuffer.isEmpty ? "2" : codeBuffer)_")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .vectorComponentEditor(let name, let index):
                let v = engine.vectorValue(for: name)
                Text("\(name)[\(index + 1)] = \(v.dim > index ? CasioEvaluator.format(v[index], format: .norm) : "")_")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("Vct\(name.suffix(1))  \(v.linearString)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .authenticityView:
                Text("ID: 991ES-2ND-042517EE37E0")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("wes.casio.com/calc/")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("[AC]:Return")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .eqnCoeffPrompt(let type, let name, let idx):
                Text("EQN \(type) [Coeff \(idx + 1)]")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("\(name) = \(codeBuffer.isEmpty ? "0" : codeBuffer)_")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .eqnSolutionView(let solutions, let index):
                Text("EQN Solution (\(index + 1)/\(solutions.count))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text(solutions[index])
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .tablePrompt(let step):
                if step == 0 {
                    Text("f(X) =")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    MathText("\(engine.expression)_", fontSize: 14, weight: .bold)
                } else if step == 1 {
                    Text("Start?")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("\(codeBuffer.isEmpty ? "\(engine.tableStartVal)" : codeBuffer)_")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                } else if step == 2 {
                    Text("End?")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("\(codeBuffer.isEmpty ? "\(engine.tableEndVal)" : codeBuffer)_")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                } else if step == 3 {
                    Text("Step?")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("\(codeBuffer.isEmpty ? "\(engine.tableStepVal)" : codeBuffer)_")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                } else {
                    let safeIdx = min(max(0, tableScrollIndex), max(0, engine.tableRows.count - 1))
                    let row = engine.tableRows.isEmpty ? (x: 0.0, fx: 0.0) : engine.tableRows[safeIdx]
                    Text("Row \(safeIdx + 1)/\(engine.tableRows.count)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("X=\(CasioEvaluator.format(row.x, format: engine.displayFormat))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Text("f(X)=\(CasioEvaluator.format(row.fx, format: engine.displayFormat))")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                }

            case .calcPrompt(let varName, _):
                Text("\(String(varName))?")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("\(codeBuffer.isEmpty ? "\(engine.variables[varName] ?? 0)" : codeBuffer)_")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .solvePrompt(let guess):
                Text("Solve for X")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("X? \(codeBuffer.isEmpty ? "\(guess)" : codeBuffer)_")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .solveResult(let root, let residual):
                Text("X = \(CasioEvaluator.format(root, format: engine.displayFormat))")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("L - R = \(CasioEvaluator.format(residual, format: engine.displayFormat))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// fx-991ES style matrix grid editor: the whole matrix is shown with the
    /// active cell highlighted and its typed value in place.
    private func matrixCellEditorView(name: String, row: Int, col: Int) -> some View {
        let m = engine.matrixValue(for: name)
        let cellWidth: CGFloat = m.cols >= 3 ? 44 : 64
        let fontSize: CGFloat = m.cols >= 3 ? 10 : 12
        return VStack(alignment: .leading, spacing: 2) {
            Text("\(name)  \(m.rows)×\(m.cols)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(CasioTheme.lcdTextActive)
            ForEach(1...max(1, m.rows), id: \.self) { r in
                HStack(spacing: 4) {
                    ForEach(1...max(1, m.cols), id: \.self) { c in
                        let isCurrent = (r == row && c == col)
                        let base = CasioEvaluator.format(engine.matrixCellValue(name: name, row: r, col: c), format: engine.displayFormat)
                        let text = isCurrent ? (codeBuffer.isEmpty ? base + "_" : codeBuffer + "_") : base
                        Text(isCurrent ? "[\(text)]" : text)
                            .font(.system(size: fontSize, weight: isCurrent ? .heavy : .semibold, design: .monospaced))
                            .foregroundColor(CasioTheme.lcdTextActive)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .frame(width: isCurrent ? cellWidth + 10 : cellWidth, alignment: .center)
                    }
                }
            }
            Text("[=]:Next  [AC]:Exit")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(CasioTheme.lcdTextActive)
        }
    }

    // MARK: - Keypad Matrix

    private var casioKeypad: some View {
        VStack(spacing: 6) {
            // Upper Tier: SHIFT, ALPHA, CALC, ∫dx, REPLAY D-PAD, MODE, ON, x⁻¹, log_■ ■
            upperTier

            // Scientific Function Grid (3 Rows × 6 Keys)
            functionGrid

            // Main Numeric & Operator Pad (4 Rows × 5 Keys)
            mainNumberPad
        }
    }

    // MARK: - Upper Control & Wing Tier

    private var upperTier: some View {
        HStack(alignment: .top, spacing: 6) {
            // Left Wing (flanking D-Pad)
            VStack(spacing: 3) {
                // Round metallic buttons: SHIFT & ALPHA
                HStack(spacing: 8) {
                    metallicCircleButton(title: "SHIFT", titleColor: CasioTheme.inkShift) {
                        CasioHaptics.tap()
                        engine.toggleShift()
                    }
                    metallicCircleButton(title: "ALPHA", titleColor: CasioTheme.inkAlpha) {
                        CasioHaptics.tap()
                        engine.toggleAlpha()
                    }
                }
                .frame(maxWidth: .infinity)

                // CALC and ∫ sit side by side in the left wing (fx-991ES PLUS)
                HStack(spacing: 4) {
                    wingButton(shift: "SOLVE", alpha: "=", label: "CALC") {
                        if engine.shiftActive {
                            engine.shiftActive = false
                            engine.startSolve()
                        } else if engine.alphaActive {
                            engine.alphaActive = false
                            if engine.isMthIO {
                                engine.insertASTText("=")
                            } else {
                                engine.insert("=")
                            }
                        } else {
                            engine.startCalc()
                        }
                    }

                    // ∫ key: integral template with stacked limit boxes,
                    // matching the fx-991ES PLUS key cap.
                    wingButtonCustom(shiftFraction: true, alpha: ":") {
                        IntegrationKeyFace()
                    } action: {
                        if engine.shiftActive {
                            engine.shiftActive = false
                            if engine.isMthIO {
                                engine.insertASTDerivative()
                            } else {
                                engine.insert("d/dx(")
                            }
                        } else if engine.alphaActive {
                            engine.alphaActive = false
                            if engine.isMthIO {
                                engine.insertASTText(":")
                            } else {
                                engine.insert(":")
                            }
                        } else {
                            if engine.isMthIO {
                                engine.insertASTIntegral()
                            } else {
                                engine.insert("∫(")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Center: Replay D-Pad
            replayPad
                .frame(width: 86, height: 86)
                .padding(.top, 2)

            // Right Wing (flanking D-Pad)
            VStack(spacing: 3) {
                // Round metallic buttons: MODE SETUP & ON
                HStack(spacing: 8) {
                    metallicCircleButton(title: "MODE", shiftTitle: "SETUP", titleColor: .white, shiftColor: CasioTheme.inkShift) {
                        CasioHaptics.tap()
                        if engine.shiftActive {
                            engine.shiftActive = false
                            engine.openSetupMenu()
                        } else {
                            engine.openModeMenu()
                        }
                    }
                    metallicCircleButton(title: "ON", titleColor: .white) {
                        CasioHaptics.firm()
                        engine.turnOn()
                    }
                }
                .frame(maxWidth: .infinity)

                // x⁻¹ and logₐb sit side by side in the right wing
                HStack(spacing: 4) {
                    wingButton(shift: "x!", alpha: "", label: "x⁻¹") {
                        if engine.shiftActive {
                            engine.shiftActive = false
                            if engine.isMthIO {
                                engine.insertASTText("!")
                            } else {
                                engine.insert("!")
                            }
                        } else {
                            if engine.isMthIO {
                                engine.insertASTExponent()
                                engine.insertASTText("-1")
                                engine.moveCursorRight()
                            } else {
                                engine.insert("^(-1)")
                            }
                        }
                    }

                    wingButtonCustom(shift: "Σ", alpha: "") {
                        LogBaseKeyFace()
                    } action: {
                        if engine.shiftActive {
                            engine.shiftActive = false
                            if engine.isMthIO {
                                engine.insertASTSummation()
                            } else {
                                engine.insert("Σ(")
                            }
                        } else {
                            if engine.isMthIO {
                                engine.insertASTLogBase()
                            } else {
                                engine.insert("log(")
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Replay D-Pad

    private var replayPad: some View {
        ZStack {
            // Outer Bezel Rim
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.16), Color(white: 0.09)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 86, height: 86)
                .overlay(
                    Circle().stroke(CasioTheme.chassisBezel, lineWidth: 1.5)
                )

            // Inner Rocker Disc
            Circle()
                .fill(
                    RadialGradient(
                        colors: [CasioTheme.keyReplay, Color(red: 0.22, green: 0.24, blue: 0.27)],
                        center: .center,
                        startRadius: 6,
                        endRadius: 42
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)

            // Tactile dot grips at the diagonals
            ForEach([45.0, 135.0, 225.0, 315.0], id: \.self) { angle in
                tactileDotCluster
                    .rotationEffect(.degrees(angle))
            }

            // Center Branding
            Text("REPLAY")
                .font(.system(size: 7, weight: .bold, design: .default))
                .foregroundColor(CasioTheme.inkSilver)

            // Up & Down Buttons
            VStack {
                Button {
                    CasioHaptics.tap()
                    handleReplayUp()
                } label: {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkSilver)
                        .frame(width: 32, height: 22)
                }
                Spacer()
                Button {
                    CasioHaptics.tap()
                    handleReplayDown()
                } label: {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkSilver)
                        .frame(width: 32, height: 22)
                }
            }
            .frame(height: 74)

            // Left & Right Buttons
            HStack {
                Button {
                    CasioHaptics.tap()
                    if case .matrixCellEditor = engine.menuState {
                        engine.moveMatrixCell(dx: -1, dy: 0)
                    } else {
                        engine.moveCursorLeft()
                    }
                } label: {
                    Image(systemName: "arrowtriangle.left.fill")
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkSilver)
                        .frame(width: 22, height: 32)
                }
                Spacer()
                Button {
                    CasioHaptics.tap()
                    if case .matrixCellEditor = engine.menuState {
                        engine.moveMatrixCell(dx: 1, dy: 0)
                    } else {
                        engine.moveCursorRight()
                    }
                } label: {
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkSilver)
                        .frame(width: 22, height: 32)
                }
            }
            .frame(width: 74)
        }
    }

    private var tactileDotCluster: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Circle().fill(Color.white.opacity(0.20)).frame(width: 1.8, height: 1.8)
                Circle().fill(Color.white.opacity(0.20)).frame(width: 1.8, height: 1.8)
            }
            HStack(spacing: 2) {
                Circle().fill(Color.white.opacity(0.20)).frame(width: 1.8, height: 1.8)
                Circle().fill(Color.white.opacity(0.20)).frame(width: 1.8, height: 1.8)
            }
        }
        .offset(y: -28)
    }

    private func handleReplayUp() {
        if case .matrixCellEditor = engine.menuState {
            engine.moveMatrixCell(dx: 0, dy: -1)
        } else if case .eqnSolutionView(let solutions, let index) = engine.menuState {
            let prev = max(0, index - 1)
            engine.menuState = .eqnSolutionView(solutions: solutions, index: prev)
        } else if case .tablePrompt(let step) = engine.menuState, step == 4 {
            if !engine.tableRows.isEmpty && tableScrollIndex > 0 {
                tableScrollIndex -= 1
            }
        } else if engine.isMthIO && engine.moveCursorUp() {
            // Navigated up within 2D AST slots
        } else {
            engine.moveHistoryUp()
        }
    }

    private func handleReplayDown() {
        if case .matrixCellEditor = engine.menuState {
            engine.moveMatrixCell(dx: 0, dy: 1)
        } else if case .eqnSolutionView(let solutions, let index) = engine.menuState {
            let next = min(solutions.count - 1, index + 1)
            engine.menuState = .eqnSolutionView(solutions: solutions, index: next)
        } else if case .tablePrompt(let step) = engine.menuState, step == 4 {
            if !engine.tableRows.isEmpty && tableScrollIndex < engine.tableRows.count - 1 {
                tableScrollIndex += 1
            }
        } else if case .setupMenu(let page) = engine.menuState {
            engine.openSetupMenu(page: page == 1 ? 2 : 1)
        } else if engine.isMthIO && engine.moveCursorDown() {
            // Navigated down within 2D AST slots
        } else {
            engine.moveHistoryDown()
        }
    }

    // MARK: - Lower Scientific Function Grid (3 Rows × 6 Keys)

    private var functionGrid: some View {
        VStack(spacing: 4) {
            // Row 1: ■/□, √□, x², xˣ (power), log, ln
            HStack(spacing: 4) {
                funcKeyCustom(shift: "d/c", alpha: "") {
                    FractionKeyFace()
                } action: {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        // SHIFT + fraction = d/c: improper-fraction result format command
                        engine.applyImproperFractionFormat()
                    } else if engine.isMthIO {
                        engine.insertASTFraction()
                    } else {
                        engine.insert("÷")
                    }
                }
                funcKeyCustom(shift: "∛", alpha: "") {
                    SqrtKeyFace()
                } action: {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTCubeRoot()
                        } else {
                            engine.insert("∛(")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTRadical()
                        } else {
                            engine.insert("√(")
                        }
                    }
                }
                funcKey("x²", shift: "x³", alpha: "DEC") {
                    if engine.activeMode == .baseN {
                        engine.setBaseN(.dec)
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTExponent()
                            engine.insertASTText("3")
                            engine.moveCursorRight()
                        } else {
                            engine.insert("³")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTExponent()
                            engine.insertASTText("2")
                            engine.moveCursorRight()
                        } else {
                            engine.insert("²")
                        }
                    }
                }
                funcKeyCustom(shift: "ʸ√x", alpha: "HEX") {
                    PowerKeyFace()
                } action: {
                    if engine.activeMode == .baseN {
                        engine.setBaseN(.hex)
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTNthRoot()
                        } else {
                            engine.insert("^(1÷")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTExponent()
                        } else {
                            engine.insert("^(")
                        }
                    }
                }
                funcKey("log", shift: "10ˣ", alpha: "BIN") {
                    if engine.activeMode == .baseN {
                        engine.setBaseN(.bin)
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTText("10")
                            engine.insertASTExponent()
                        } else {
                            engine.insert("10^(")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTFunction("log")
                        } else {
                            engine.insert("log(")
                        }
                    }
                }
                funcKey("ln", shift: "eˣ", alpha: "OCT") {
                    if engine.activeMode == .baseN {
                        engine.setBaseN(.oct)
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTText("e")
                            engine.insertASTExponent()
                        } else {
                            engine.insert("e^(")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTFunction("ln")
                        } else {
                            engine.insert("ln(")
                        }
                    }
                }
            }

            // Row 2: (-), ° ' ", hyp, sin, cos, tan
            HStack(spacing: 4) {
                // ∠ is a purple CMPLX-mode marking, not a yellow SHIFT legend.
                funcKey("(-)", shift: "∠", shiftColor: .purple, alpha: "A") {
                    if interceptVariableCapture("A") { return }
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("∠")
                    } else if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("A")
                    } else if isPromptActive {
                        codeBuffer.append("-")
                    } else if engine.isMthIO {
                        engine.insertASTText("-")
                    } else {
                        engine.insert("-")
                    }
                }
                funcKey("° ' \"", alpha: "B") {
                    if interceptVariableCapture("B") { return }
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.primeFactorize()
                    } else if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("B")
                    } else {
                        // Input: insert sexagesimal marker (d°m's" syntax).
                        // On a result: toggle decimal ⇔ DMS display (manual p.23).
                        engine.insertDMSMark()
                    }
                }
                funcKey("hyp", shift: "Abs", alpha: "C") {
                    if interceptVariableCapture("C") { return }
                    if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("C")
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTFunction("Abs")
                        } else {
                            engine.insert("abs(")
                        }
                    } else {
                        // hyp waits for sin/cos/tan like the real key flow
                        engine.waitingForHyp.toggle()
                    }
                }
                funcKey("sin", shift: "sin⁻¹", alpha: "D") {
                    if interceptVariableCapture("D") { return }
                    if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("D")
                    } else if engine.waitingForHyp {
                        engine.waitingForHyp = false
                        let inverse = engine.shiftActive
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTFunction(inverse ? "sinh⁻¹" : "sinh")
                        } else {
                            engine.insert(inverse ? "sinh⁻¹(" : "sinh(")
                        }
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTFunction("sin⁻¹")
                        } else {
                            engine.insert("sin⁻¹(")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTFunction("sin")
                        } else {
                            engine.insert("sin(")
                        }
                    }
                }
                funcKey("cos", shift: "cos⁻¹", alpha: "E") {
                    if interceptVariableCapture("E") { return }
                    if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("E")
                    } else if engine.waitingForHyp {
                        engine.waitingForHyp = false
                        let inverse = engine.shiftActive
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTFunction(inverse ? "cosh⁻¹" : "cosh")
                        } else {
                            engine.insert(inverse ? "cosh⁻¹(" : "cosh(")
                        }
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTFunction("cos⁻¹")
                        } else {
                            engine.insert("cos⁻¹(")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTFunction("cos")
                        } else {
                            engine.insert("cos(")
                        }
                    }
                }
                funcKey("tan", shift: "tan⁻¹", alpha: "F") {
                    if interceptVariableCapture("F") { return }
                    if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("F")
                    } else if engine.waitingForHyp {
                        engine.waitingForHyp = false
                        let inverse = engine.shiftActive
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTFunction(inverse ? "tanh⁻¹" : "tanh")
                        } else {
                            engine.insert(inverse ? "tanh⁻¹(" : "tanh(")
                        }
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTFunction("tan⁻¹")
                        } else {
                            engine.insert("tan⁻¹(")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTFunction("tan")
                        } else {
                            engine.insert("tan(")
                        }
                    }
                }
            }

            // Row 3: RCL, ENG, (, ), S<=>D, M+
            HStack(spacing: 4) {
                funcKey("RCL", shift: "STO", alpha: "") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.waitingForSto = true
                    } else {
                        // RCL captures the next variable key to recall its value
                        engine.waitingForRcl = true
                    }
                }
                funcKey("ENG", shift: "←", alpha: "i") {
                    if engine.alphaActive || engine.activeMode == .cmplx {
                        engine.alphaActive = false
                        if engine.isMthIO {
                            engine.insertASTText("i")
                        } else {
                            engine.insert("i")
                        }
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        // SHIFT+ENG (←): shift the decimal point left
                        engine.shiftEng(left: true)
                    } else {
                        // ENG: shift the decimal point right, three places at a time
                        engine.shiftEng(left: false)
                    }
                }
                funcKey("(", shift: "%", alpha: "") {
                    if engine.alphaActive {
                        engine.alphaActive = false
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTText("%")
                        } else {
                            engine.insert("%")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTParens()
                        } else {
                            engine.insert("(")
                        }
                    }
                }
                funcKey(")", shift: ",", alpha: "X") {
                    if interceptVariableCapture("X") { return }
                    if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("X")
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTText(",")
                        } else {
                            engine.insert(",")
                        }
                    } else {
                        if engine.isMthIO {
                            engine.insertASTText(")")
                        } else {
                            engine.insert(")")
                        }
                    }
                }
                funcKey("S⇔D", shift: "ab/c⇔d/c", alpha: "Y") {
                    if interceptVariableCapture("Y") { return }
                    if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("Y")
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        // SHIFT+S⇔D: improper ⇔ mixed fraction display
                        engine.toggleImproperMixed()
                    } else {
                        engine.toggleSD()
                    }
                }
                funcKey("M+", shift: "M-", alpha: "M") {
                    if interceptVariableCapture("M") { return }
                    if engine.alphaActive {
                        engine.alphaActive = false
                        handleVariableKey("M")
                    } else if engine.shiftActive {
                        engine.shiftActive = false
                        engine.subtractMemory()
                    } else {
                        engine.addMemory()
                    }
                }
            }
        }
    }

    private func handleVariableKey(_ varName: Character) {
        engine.handleVariableSelection(varName)
    }

    /// STO / RCL capture the next variable key without ALPHA (real key flow)
    private func interceptVariableCapture(_ varName: Character) -> Bool {
        if engine.waitingForSto || engine.waitingForRcl {
            engine.handleVariableSelection(varName)
            return true
        }
        return false
    }

    // MARK: - Main Number Pad (4 Rows × 5 Keys)

    private var mainNumberPad: some View {
        VStack(spacing: 4) {
            // Row 1: 7, 8, 9, DEL, AC
            HStack(spacing: 5) {
                digitKey("7", shift: "CONST")
                digitKey("8", shift: "CONV")
                digitKey("9", shift: "CLR")
                casioButton(
                    label: "DEL",
                    shiftLabel: "INS",
                    alphaLabel: "",
                    fill: CasioTheme.keyDelAc,
                    ink: CasioTheme.keyDelAcInk,
                    labelFont: .system(size: 14, weight: .bold),
                    height: 35
                ) {
                    CasioHaptics.tap()
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.toggleInsertOverwrite()
                    } else if !codeBuffer.isEmpty {
                        codeBuffer.removeLast()
                    } else {
                        engine.delete()
                    }
                }
                casioButton(
                    label: "AC",
                    shiftLabel: "OFF",
                    alphaLabel: "",
                    fill: CasioTheme.keyDelAc,
                    ink: CasioTheme.keyDelAcInk,
                    labelFont: .system(size: 14, weight: .bold),
                    height: 35
                ) {
                    CasioHaptics.firm()
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.turnOff()
                    } else if engine.menuState != .none {
                        engine.menuState = .none
                        codeBuffer = ""
                    } else {
                        engine.clearAll()
                        codeBuffer = ""
                    }
                }
            }

            // Row 2: 4, 5, 6, ×, ÷
            HStack(spacing: 5) {
                digitKey("4", shift: "MATRIX")
                digitKey("5", shift: "VECTOR")
                digitKey("6", shift: "")
                opKey("×", shift: "nPr")
                opKey("÷", shift: "nCr")
            }

            // Row 3: 1, 2, 3, +, −
            HStack(spacing: 5) {
                digitKey("1", shift: "STAT")
                digitKey("2", shift: "CMPLX")
                digitKey("3", shift: "BASE-N")
                opKey("+", shift: "Pol")
                opKey("−", shift: "Rec")
            }

            // Row 4: 0, ., ×10ˣ, Ans, =
            HStack(spacing: 5) {
                digitKey("0", shift: "Rnd")
                digitKey(".", shift: "Ran#", alpha: "RanInt#")
                casioButton(label: "×10ˣ", shiftLabel: "π", alphaLabel: "e", height: 35) {
                    CasioHaptics.tap()
                    if engine.shiftActive {
                        engine.shiftActive = false
                        if engine.isMthIO {
                            engine.insertASTText("π")
                        } else {
                            engine.insert("π")
                        }
                    } else if engine.alphaActive {
                        engine.alphaActive = false
                        if engine.isMthIO {
                            engine.insertASTText("e")
                        } else {
                            engine.insert("e")
                        }
                    } else {
                        if engine.isMthIO {
                            // Build a real exponent template so the LCD shows ×10ⁿ
                            // with a raised exponent instead of a literal caret.
                            engine.insertASTText("×")
                            engine.insertASTText("10")
                            engine.insertASTExponent()
                        } else {
                            engine.insert("×10^")
                        }
                    }
                }
                casioButton(label: "Ans", shiftLabel: "DRG▶", alphaLabel: "", height: 35) {
                    CasioHaptics.tap()
                    if engine.shiftActive {
                        engine.shiftActive = false
                        // DRG▶: convert the displayed result between Deg/Rad/Gra
                        engine.convertResultAngleUnit()
                    } else {
                        if engine.isMthIO {
                            engine.insertASTText("Ans")
                        } else {
                            engine.insert("Ans")
                        }
                    }
                }
                casioButton(
                    label: "=",
                    shiftLabel: "",
                    alphaLabel: "",
                    fill: CasioTheme.keyEquals,
                    ink: CasioTheme.inkWhite,
                    labelFont: .system(size: 20, weight: .bold),
                    height: 35
                ) {
                    CasioHaptics.firm()
                    switch engine.menuState {
                    case .clrPrompt:
                        engine.selectMenuOption(3) // Reset all
                    case .eqnCoeffPrompt:
                        let val = Double(codeBuffer) ?? 0
                        codeBuffer = ""
                        engine.advanceEqnCoeff(val: val)
                    case .statDataEditor(let row):
                        let val = Double(codeBuffer) ?? 0
                        codeBuffer = ""
                        engine.commitStatValue(val, row: row)
                    case .matrixDimPrompt:
                        let buf = codeBuffer
                        codeBuffer = ""
                        engine.confirmMatrixDim(buffer: buf)
                    case .matrixCellEditor:
                        let val = Double(codeBuffer) ?? 0
                        codeBuffer = ""
                        engine.commitMatrixCell(val: val)
                    case .vectorDimPrompt(let name):
                        let dim = Int(codeBuffer) ?? 0
                        codeBuffer = ""
                        engine.confirmVectorDim(name, dim: dim)
                    case .vectorComponentEditor:
                        let val = Double(codeBuffer) ?? 0
                        codeBuffer = ""
                        engine.commitVectorComponent(val)
                    case .tablePrompt(let step):
                        if step == 0 {
                            engine.advanceTablePrompt()
                        } else {
                            let val = Double(codeBuffer)
                            codeBuffer = ""
                            engine.advanceTablePrompt(val: val)
                        }
                    case .calcPrompt:
                        let val = Double(codeBuffer) ?? 0
                        codeBuffer = ""
                        engine.advanceCalc(val: val)
                    case .solvePrompt:
                        let guess = Double(codeBuffer) ?? (engine.variables["X"] ?? 0)
                        codeBuffer = ""
                        engine.executeSolve(guess: guess)
                    default:
                        engine.evaluate()
                    }
                }
            }
        }
    }

    // MARK: - Reusable Key Building Blocks

    private func metallicCircleButton(
        title: String,
        shiftTitle: String = "",
        titleColor: Color = CasioTheme.inkWhite,
        shiftColor: Color = CasioTheme.inkShift,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 1) {
            HStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundColor(titleColor)
                if !shiftTitle.isEmpty {
                    Text(shiftTitle)
                        .font(.system(size: 7, weight: .heavy))
                        .foregroundColor(shiftColor)
                }
            }
            .frame(height: 9)

            Button(action: action) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.65),
                                Color(white: 0.38),
                                Color(white: 0.52)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 29, height: 29)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 1, x: 0, y: 1)
            }
            .buttonStyle(CasioButtonStyle())
        }
    }

    private func wingButton(
        shift: String = "",
        alpha: String = "",
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 1) {
            HStack {
                if !shift.isEmpty {
                    Text(shift)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(CasioTheme.inkShift)
                }
                Spacer(minLength: 0)
                if !alpha.isEmpty {
                    Text(alpha)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(CasioTheme.inkAlpha)
                }
            }
            .frame(height: 9)
            .padding(.horizontal, 3)

            Button(action: {
                CasioHaptics.tap()
                action()
            }) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CasioTheme.inkWhite)
                    .frame(maxWidth: .infinity, minHeight: 25, maxHeight: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(CasioTheme.keyStandard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(CasioTheme.keyStandardBevel, lineWidth: 1)
                    )
            }
            .buttonStyle(CasioButtonStyle())
        }
    }

    private func wingButtonCustom<Content: View>(
        shift: String = "",
        shiftFraction: Bool = false,
        alpha: String = "",
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 1) {
            HStack {
                if shiftFraction {
                    DerivativeShiftLabel()
                } else if !shift.isEmpty {
                    Text(shift)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(CasioTheme.inkShift)
                }
                Spacer(minLength: 0)
                if !alpha.isEmpty {
                    Text(alpha)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(CasioTheme.inkAlpha)
                }
            }
            .frame(height: 9)
            .padding(.horizontal, 3)

            Button(action: {
                CasioHaptics.tap()
                action()
            }) {
                content()
                    .frame(maxWidth: .infinity, minHeight: 25, maxHeight: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(CasioTheme.keyStandard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(CasioTheme.keyStandardBevel, lineWidth: 1)
                    )
            }
            .buttonStyle(CasioButtonStyle())
        }
    }

    private func funcKey(
        _ label: String,
        shift: String = "",
        shiftColor: Color = CasioTheme.inkShift,
        alpha: String = "",
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 1) {
            HStack {
                if !shift.isEmpty {
                    Text(shift)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(shiftColor)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if !alpha.isEmpty {
                    Text(alpha)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(alpha == "DEC" || alpha == "HEX" || alpha == "BIN" || alpha == "OCT" ? CasioTheme.inkBlue : CasioTheme.inkAlpha)
                        .lineLimit(1)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 1)

            Button(action: {
                CasioHaptics.tap()
                action()
            }) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(CasioTheme.inkWhite)
                    .frame(maxWidth: .infinity, minHeight: 25, maxHeight: 27)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(CasioTheme.keyStandard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(CasioTheme.keyStandardBevel, lineWidth: 1)
                    )
            }
            .buttonStyle(CasioButtonStyle())
        }
    }

    private func funcKeyCustom<Content: View>(
        shift: String = "",
        alpha: String = "",
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 1) {
            HStack {
                if !shift.isEmpty {
                    Text(shift)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(CasioTheme.inkShift)
                        .lineLimit(1)
            }
            Spacer(minLength: 0)
            if !alpha.isEmpty {
                Text(alpha)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(alpha == "DEC" || alpha == "HEX" || alpha == "BIN" || alpha == "OCT" ? CasioTheme.inkBlue : CasioTheme.inkAlpha)
                    .lineLimit(1)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 1)

        Button(action: {
            CasioHaptics.tap()
            action()
        }) {
            content()
                .frame(maxWidth: .infinity, minHeight: 25, maxHeight: 27)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(CasioTheme.keyStandard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(CasioTheme.keyStandardBevel, lineWidth: 1)
                )
        }
        .buttonStyle(CasioButtonStyle())
    }
}

    private func digitKey(_ digit: String, shift: String = "", alpha: String = "") -> some View {
        casioButton(label: digit, shiftLabel: shift, alphaLabel: alpha, labelFont: .system(size: 19, weight: .semibold), height: 35) {
            CasioHaptics.tap()

            // Handle active prompts that accumulate numeric input
            switch engine.menuState {
            case .constPrompt:
                codeBuffer.append(digit)
                if codeBuffer.count == 2 {
                    if let code = Int(codeBuffer) {
                        engine.insertConstant(code: code)
                    }
                    engine.menuState = .none
                    codeBuffer = ""
                }
                return

            case .convPrompt:
                codeBuffer.append(digit)
                if codeBuffer.count == 2 {
                    if let code = Int(codeBuffer) {
                        engine.applyConversion(code: code)
                    }
                    engine.menuState = .none
                    codeBuffer = ""
                }
                return

            case .eqnCoeffPrompt, .calcPrompt, .solvePrompt, .statDataEditor:
                codeBuffer.append(digit)
                return

            case .matrixDimPrompt, .matrixCellEditor, .vectorDimPrompt, .vectorComponentEditor:
                codeBuffer.append(digit)
                return

            case .tablePrompt(let step) where step > 0 && step < 4:
                codeBuffer.append(digit)
                return

            default:
                break
            }

            // Handle SHIFT functions for digit keys
            if engine.shiftActive {
                engine.shiftActive = false
                switch shift {
                case "CONST":
                    engine.menuState = .constPrompt
                    codeBuffer = ""
                    return
                case "CONV":
                    engine.menuState = .convPrompt
                    codeBuffer = ""
                    return
                case "CLR":
                    engine.menuState = .clrPrompt
                    return
                case "MATRIX":
                    engine.menuState = .matrixMenu
                    return
                case "VECTOR":
                    engine.menuState = .vectorMenu
                    return
                case "STAT":
                    // SHIFT+1 selects the type when entering STAT; once in STAT
                    // it opens the statistics calculation menu (manual §6.3).
                    engine.menuState = engine.activeMode == .stat ? .statSubMenu : .statTypeMenu
                    return
                case "CMPLX":
                    engine.menuState = .cmplxMenu
                    return
                case "BASE":
                    // SHIFT+3 enters BASE-N mode (decimal base) like the real menu
                    engine.enterBaseNMode()
                    return
                case "Rnd":
                    // SHIFT+0 rounds the displayed value to the display digits
                    engine.roundDisplayed()
                    return
                case "Ran#":
                    engine.insert("Ran#")
                    return
                default: break
                }
            }

            // Handle ALPHA functions for digit keys
            if engine.alphaActive {
                engine.alphaActive = false
                if alpha.hasPrefix("RanInt") {
                    if engine.isMthIO {
                        engine.insertASTFunction("RanInt")
                    } else {
                        engine.insert("RanInt(")
                    }
                    return
                }
            }

            if engine.menuState != .none, let n = Int(digit) {
                engine.selectMenuOption(n)
                return
            }

            // Normal digit entry
            if engine.isMthIO {
                engine.insertASTText(digit)
            } else {
                engine.insert(digit)
            }
        }
    }

    private func opKey(_ symbol: String, shift: String = "") -> some View {
        casioButton(label: symbol, shiftLabel: shift, alphaLabel: "", labelFont: .system(size: 19, weight: .semibold), height: 35) {
            CasioHaptics.tap()
            if engine.shiftActive {
                engine.shiftActive = false
                switch shift {
                case "nPr":
                    if engine.isMthIO { engine.insertASTText("P") } else { engine.insert(" nPr ") }
                case "nCr":
                    if engine.isMthIO { engine.insertASTText("C") } else { engine.insert(" nCr ") }
                case "Pol":
                    if engine.isMthIO { engine.insertASTFunction("Pol") } else { engine.insert("Pol(") }
                case "Rec":
                    if engine.isMthIO { engine.insertASTFunction("Rec") } else { engine.insert("Rec(") }
                default:
                    if engine.isMthIO { engine.insertASTText(symbol) } else { engine.insert(symbol) }
                }
            } else if case .matrixDimPrompt = engine.menuState, symbol == "×" {
                // m×n entry inside the matrix dimension prompt
                codeBuffer.append("×")
            } else {
                if engine.isMthIO {
                    engine.insertASTText(symbol)
                } else {
                    engine.insert(symbol)
                }
            }
        }
    }

    // MARK: - Reusable Casio Button Component

    private func casioButton(
        label: String,
        shiftLabel: String = "",
        alphaLabel: String = "",
        fill: Color = CasioTheme.keyStandard,
        ink: Color = CasioTheme.inkWhite,
        labelFont: Font = .system(size: 12, weight: .semibold),
        height: CGFloat = 30,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 1) {
            // Secondary labels above key
            HStack {
                if !shiftLabel.isEmpty {
                    Text(shiftLabel)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(CasioTheme.inkShift)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if !alphaLabel.isEmpty {
                    Text(alphaLabel)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(alphaLabel == "DEC" || alphaLabel == "HEX" || alphaLabel == "BIN" || alphaLabel == "OCT" ? CasioTheme.inkBlue : CasioTheme.inkAlpha)
                        .lineLimit(1)
                }
            }
            .frame(height: 9)
            .padding(.horizontal, 2)

            // Physical Button Cap
            Button(action: action) {
                Text(label)
                    .font(labelFont)
                    .foregroundColor(ink)
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(CasioTheme.keyStandardBevel, lineWidth: 1)
                    )
            }
            .buttonStyle(CasioButtonStyle())
        }
    }
}

// MARK: - Button Press Style

private struct CasioButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
