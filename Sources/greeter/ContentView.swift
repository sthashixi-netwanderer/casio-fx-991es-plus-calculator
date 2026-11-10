import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Visual Tokens (Casio fx-991ES PLUS 2nd Edition)

private enum CasioTheme {
    // Housing / Chassis
    static let chassis = Color(red: 0.10, green: 0.11, blue: 0.12)
    static let chassisBezel = Color(red: 0.15, green: 0.16, blue: 0.17)
    static let solarCell = Color(red: 0.22, green: 0.15, blue: 0.13)
    static let solarGrid = Color.white.opacity(0.12)

    // LCD Display
    static let lcdBackground = Color(red: 0.54, green: 0.61, blue: 0.49)
    static let lcdBezel = Color(red: 0.08, green: 0.09, blue: 0.10)
    static let lcdTextActive = Color(red: 0.10, green: 0.14, blue: 0.10)
    static let lcdTextDim = Color(red: 0.10, green: 0.14, blue: 0.10).opacity(0.18)

    // Key Fills
    static let keyStandard = Color(red: 0.18, green: 0.19, blue: 0.20)
    static let keyStandardBevel = Color.white.opacity(0.08)
    static let keyDelAc = Color(red: 0.44, green: 0.66, blue: 0.22)
    static let keyReplay = Color(red: 0.45, green: 0.47, blue: 0.50)

    // Secondary / Modifier Inks
    static let inkShift = Color(red: 0.98, green: 0.78, blue: 0.18) // Bright Yellow
    static let inkAlpha = Color(red: 0.92, green: 0.28, blue: 0.42) // Magenta/Red
    static let inkWhite = Color.white
    static let inkSilver = Color(red: 0.75, green: 0.77, blue: 0.80)
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

// MARK: - Content View

struct ContentView: View {
    @StateObject private var engine = CalculatorEngine()

    var body: some View {
        ZStack {
            CasioTheme.chassis
                .ignoresSafeArea()

            VStack(spacing: 8) {
                // Header (Branding & Solar Cell)
                casioHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                // LCD Screen
                casioScreen
                    .padding(.horizontal, 14)

                Spacer(minLength: 4)

                // Keypad Matrix
                casioKeypad
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
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
                .fill(CasioTheme.lcdBackground)
                .padding(6)
                .overlay(
                    VStack(alignment: .leading, spacing: 4) {
                        // Annunciator Status Bar
                        annunciatorBar

                        // LCD Content (Menu or Expression/Result)
                        if engine.menuState != .none {
                            menuDisplayView
                        } else {
                            expressionDisplayView
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                )
        }
        .frame(height: 122)
    }

    // MARK: - Annunciator Bar

    private var annunciatorBar: some View {
        HStack(spacing: 7) {
            annunciator("S", active: engine.shiftActive)
            annunciator("A", active: engine.alphaActive)
            annunciator("M", active: engine.hasMemory)
            annunciator("STO", active: engine.shiftActive)
            Spacer()
            annunciator("D", active: engine.angleUnit == .deg)
            annunciator("R", active: engine.angleUnit == .rad)
            annunciator("G", active: engine.angleUnit == .gra)
            annunciator("Fix", active: isFixFormat)
            annunciator("Sci", active: isSciFormat)
            annunciator("Math", active: true)
            annunciator("▲", active: false)
            annunciator("▼", active: false)
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
        VStack(spacing: 2) {
            // Expression Line (Top, Left-aligned, with Cursor)
            HStack(spacing: 0) {
                Text(renderedExpression)
                    .font(.system(size: 17, weight: .medium, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                    .lineLimit(1)
                Spacer()
            }
            .frame(height: 26)

            Spacer()

            // Result / Error Line (Bottom, Right-aligned)
            HStack {
                if engine.isError {
                    Text(engine.result)
                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                    Spacer()
                    Text("[AC]:Cancel")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                } else {
                    Spacer()
                    Text(engine.result)
                        .font(.system(size: 32, weight: .semibold, design: .monospaced))
                        .foregroundColor(CasioTheme.lcdTextActive)
                        .lineLimit(1)
                        .minimumScaleFactor(0.3)
                }
            }
            .frame(height: 40)
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
        return prefix + "_" + suffix
    }

    // MARK: - Menu Display View

    private var menuDisplayView: some View {
        VStack(alignment: .leading, spacing: 3) {
            switch engine.menuState {
            case .modeMenu:
                Text("1:COMP    2:STAT")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("3:TABLE   4:EQN")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .setupMenu:
                Text("1:MthIO 2:LineIO 3:Deg")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("4:Rad   5:Gra    6:Fix")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)
                Text("7:Sci   8:Norm")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .fixPrompt:
                Text("Fix 0 ~ 9 ?")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .sciPrompt:
                Text("Sci 0 ~ 9 ?")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(CasioTheme.lcdTextActive)

            case .none:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: - Keypad Matrix

    private var casioKeypad: some View {
        VStack(spacing: 6) {
            // Control Tier (SHIFT, ALPHA, Replay D-Pad, MODE, ON)
            controlTier
                .padding(.bottom, 2)

            // Scientific Function Grid (3 Rows)
            scientificTier

            // Main Numeric & Operator Pad (4 Rows)
            mainNumberPad
        }
    }

    // MARK: - Control Tier

    private var controlTier: some View {
        HStack(spacing: 12) {
            // Left: SHIFT and ALPHA
            VStack(spacing: 5) {
                casioButton(label: "SHIFT", shiftLabel: "", alphaLabel: "", ink: CasioTheme.inkShift, height: 26) {
                    CasioHaptics.tap()
                    engine.toggleShift()
                }
                casioButton(label: "ALPHA", shiftLabel: "", alphaLabel: "", ink: CasioTheme.inkAlpha, height: 26) {
                    CasioHaptics.tap()
                    engine.toggleAlpha()
                }
            }
            .frame(width: 60)

            Spacer()

            // Center: Replay D-Pad
            replayPad

            Spacer()

            // Right: MODE SETUP and ON
            VStack(spacing: 5) {
                casioButton(label: "MODE", shiftLabel: "SETUP", alphaLabel: "", height: 26) {
                    CasioHaptics.tap()
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.openSetupMenu()
                    } else {
                        engine.openModeMenu()
                    }
                }
                casioButton(label: "ON", shiftLabel: "", alphaLabel: "", height: 26) {
                    CasioHaptics.firm()
                    engine.turnOn()
                }
            }
            .frame(width: 60)
        }
    }

    // MARK: - Replay D-Pad

    private var replayPad: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [CasioTheme.keyReplay.opacity(0.9), CasioTheme.chassisBezel],
                        center: .center,
                        startRadius: 4,
                        endRadius: 42
                    )
                )
                .frame(width: 82, height: 82)
                .overlay(
                    Circle().stroke(CasioTheme.chassisBezel, lineWidth: 2)
                )

            Text("REPLAY")
                .font(.system(size: 8, weight: .bold, design: .default))
                .foregroundColor(CasioTheme.inkWhite.opacity(0.6))

            // Directional Buttons
            VStack {
                Button {
                    CasioHaptics.tap()
                } label: {
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkWhite)
                        .frame(width: 32, height: 22)
                }
                Spacer()
                Button {
                    CasioHaptics.tap()
                } label: {
                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(180))
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkWhite)
                        .frame(width: 32, height: 22)
                }
            }
            .frame(height: 78)

            HStack {
                Button {
                    CasioHaptics.tap()
                    engine.moveCursorLeft()
                } label: {
                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(-90))
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkWhite)
                        .frame(width: 22, height: 32)
                }
                Spacer()
                Button {
                    CasioHaptics.tap()
                    engine.moveCursorRight()
                } label: {
                    Image(systemName: "triangle.fill")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 8))
                        .foregroundColor(CasioTheme.inkWhite)
                        .frame(width: 22, height: 32)
                }
            }
            .frame(width: 78)
        }
    }

    // MARK: - Scientific Function Grid

    private var scientificTier: some View {
        VStack(spacing: 5) {
            // Function Row 1
            HStack(spacing: 6) {
                funcKey("■/□", shift: "∛", alpha: "") {
                    engine.insert("÷")
                }
                funcKey("√", shift: "∛", alpha: "") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("∛(")
                    } else {
                        engine.insert("√(")
                    }
                }
                funcKey("x²", shift: "x³", alpha: "") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("³")
                    } else {
                        engine.insert("²")
                    }
                }
                funcKey("x^■", shift: "ʸ√x", alpha: "") {
                    engine.insert("^(")
                }
                funcKey("log", shift: "10^■", alpha: "") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("10^(")
                    } else {
                        engine.insert("log(")
                    }
                }
                funcKey("ln", shift: "e^■", alpha: "") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("e^(")
                    } else {
                        engine.insert("ln(")
                    }
                }
            }

            // Function Row 2
            HStack(spacing: 6) {
                funcKey("(-)", shift: "", alpha: "A") {
                    if engine.alphaActive { engine.alphaActive = false }
                    engine.insert("-")
                }
                funcKey("° ' \"", shift: "←", alpha: "B") {
                    if engine.alphaActive { engine.alphaActive = false }
                    engine.insert("°")
                }
                funcKey("hyp", shift: "", alpha: "C") {
                    if engine.alphaActive { engine.alphaActive = false }
                }
                funcKey("sin", shift: "sin⁻¹", alpha: "D") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("sin⁻¹(")
                    } else {
                        engine.insert("sin(")
                    }
                }
                funcKey("cos", shift: "cos⁻¹", alpha: "E") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("cos⁻¹(")
                    } else {
                        engine.insert("cos(")
                    }
                }
                funcKey("tan", shift: "tan⁻¹", alpha: "F") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("tan⁻¹(")
                    } else {
                        engine.insert("tan(")
                    }
                }
            }

            // Function Row 3
            HStack(spacing: 6) {
                funcKey("RCL", shift: "STO", alpha: "") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.storeMemory()
                    } else {
                        engine.recallMemory()
                    }
                }
                funcKey("ENG", shift: "←", alpha: "") {
                    engine.cycleEng()
                }
                funcKey("(", shift: "%", alpha: "X") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("%")
                    } else {
                        engine.insert("(")
                    }
                }
                funcKey(")", shift: ",", alpha: "Y") {
                    engine.insert(")")
                }
                funcKey("S<=>D", shift: "a b/c", alpha: "") {
                    engine.toggleSD()
                }
                funcKey("M+", shift: "M-", alpha: "M") {
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.subtractMemory()
                    } else {
                        engine.addMemory()
                    }
                }
            }
        }
    }

    private func funcKey(_ label: String, shift: String, alpha: String, action: @escaping () -> Void) -> some View {
        casioButton(label: label, shiftLabel: shift, alphaLabel: alpha, height: 29) {
            CasioHaptics.tap()
            action()
        }
    }

    // MARK: - Main Number Pad

    private var mainNumberPad: some View {
        VStack(spacing: 5) {
            // Row 1: 7, 8, 9, DEL, AC
            HStack(spacing: 6) {
                digitKey("7", shift: "CONST")
                digitKey("8", shift: "CONV")
                digitKey("9", shift: "CLR")
                casioButton(label: "DEL", shiftLabel: "INS", alphaLabel: "", fill: CasioTheme.keyDelAc, height: 36) {
                    CasioHaptics.tap()
                    engine.delete()
                }
                casioButton(label: "AC", shiftLabel: "OFF", alphaLabel: "", fill: CasioTheme.keyDelAc, height: 36) {
                    CasioHaptics.firm()
                    engine.clearAll()
                }
            }

            // Row 2: 4, 5, 6, ×, ÷
            HStack(spacing: 6) {
                digitKey("4", shift: "MATRIX")
                digitKey("5", shift: "VECTOR")
                digitKey("6", shift: "")
                opKey("×", shift: "nPr")
                opKey("÷", shift: "nCr")
            }

            // Row 3: 1, 2, 3, +, −
            HStack(spacing: 6) {
                digitKey("1", shift: "STAT")
                digitKey("2", shift: "CMPLX")
                digitKey("3", shift: "BASE")
                opKey("+", shift: "Pol")
                opKey("−", shift: "Rec")
            }

            // Row 4: 0, ., ×10^x, Ans, =
            HStack(spacing: 6) {
                digitKey("0", shift: "Rnd")
                digitKey(".", shift: "Ran#", alpha: "RanInt")
                casioButton(label: "×10^x", shiftLabel: "π", alphaLabel: "e", height: 36) {
                    CasioHaptics.tap()
                    if engine.shiftActive {
                        engine.shiftActive = false
                        engine.insert("π")
                    } else if engine.alphaActive {
                        engine.alphaActive = false
                        engine.insert("e")
                    } else {
                        engine.insert("×10^")
                    }
                }
                casioButton(label: "Ans", shiftLabel: "DRG▶", alphaLabel: "", height: 36) {
                    CasioHaptics.tap()
                    engine.insert("Ans")
                }
                casioButton(label: "=", shiftLabel: "", alphaLabel: "", height: 36) {
                    CasioHaptics.firm()
                    engine.evaluate()
                }
            }
        }
    }

    private func digitKey(_ digit: String, shift: String = "", alpha: String = "") -> some View {
        casioButton(label: digit, shiftLabel: shift, alphaLabel: alpha, labelFont: .system(size: 20, weight: .semibold), height: 36) {
            CasioHaptics.tap()
            if engine.menuState != .none, let n = Int(digit) {
                engine.selectMenuOption(n)
            } else if engine.shiftActive && shift == "π" {
                engine.shiftActive = false
                engine.insert("π")
            } else {
                engine.insert(digit)
            }
        }
    }

    private func opKey(_ symbol: String, shift: String = "") -> some View {
        casioButton(label: symbol, shiftLabel: shift, alphaLabel: "", labelFont: .system(size: 19, weight: .semibold), height: 36) {
            CasioHaptics.tap()
            engine.insert(symbol)
        }
    }

    // MARK: - Reusable Casio Button Component

    private func casioButton(
        label: String,
        shiftLabel: String = "",
        alphaLabel: String = "",
        fill: Color = CasioTheme.keyStandard,
        ink: Color = CasioTheme.inkWhite,
        labelFont: Font = .system(size: 13, weight: .semibold),
        height: CGFloat = 32,
        action: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 1) {
            // Secondary labels above key
            HStack {
                if !shiftLabel.isEmpty {
                    Text(shiftLabel)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(CasioTheme.inkShift)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if !alphaLabel.isEmpty {
                    Text(alphaLabel)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(CasioTheme.inkAlpha)
                        .lineLimit(1)
                }
            }
            .frame(height: 10)
            .padding(.horizontal, 2)

            // Physical Button Cap
            Button(action: action) {
                Text(label)
                    .font(labelFont)
                    .foregroundColor(ink)
                    .frame(maxWidth: .infinity, maxHeight: height)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(fill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
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
