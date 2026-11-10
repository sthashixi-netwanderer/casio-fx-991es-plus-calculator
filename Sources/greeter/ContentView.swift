import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Visual tokens
//
// Every colour and every font the calculator rides on is declared here.
// Views consume them by name; no literal colour or font past this block.

private enum C {
    // Surfaces — warm charcoal, deepest at the bottom.
    static let bg = Color(red: 0.071, green: 0.063, blue: 0.059)
    static let bgDeep = Color(red: 0.043, green: 0.039, blue: 0.036)

    // Key fills, three roles.
    static let keyDigit = Color(red: 0.161, green: 0.141, blue: 0.129)
    static let keyUtil = Color(red: 0.302, green: 0.271, blue: 0.243)
    static let keyFunc = Color(red: 0.106, green: 0.092, blue: 0.084)
    static let accent = Color(red: 1.0, green: 0.624, blue: 0.039)
    static let accentDeep = Color(red: 0.898, green: 0.490, blue: 0.0)

    // Inks.
    static let inkPrimary = Color.white
    static let inkRail = Color(red: 0.737, green: 0.706, blue: 0.667)
    static let inkSecondary = Color(red: 0.635, green: 0.598, blue: 0.557)
    static let inkOnAccent = Color(red: 0.129, green: 0.059, blue: 0.0)
    static let errorInk = Color(red: 1.0, green: 0.482, blue: 0.353)

    // Hairline edge on keys.
    static let edge = Color.white.opacity(0.07)
}

private enum F {
    static let display = Font.system(size: 64, weight: .light, design: .rounded).monospacedDigit()
    static let echo = Font.system(size: 15, weight: .medium).monospacedDigit()
    static let mode = Font.system(size: 13, weight: .semibold)
    static func mainKey(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
    static func railKey(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }
}

// MARK: - Haptics

private enum Haptics {
    #if canImport(UIKit)
    @MainActor
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor
    static func settle() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    #else
    @MainActor
    static func tap() {}

    @MainActor
    static func settle() {}
    #endif
}

// MARK: - Keys

enum CalcKey {
    case digit(String)
    case operation(String, String, (Double, Double) -> Double) // symbol, display, operator
    case unary(String, (Double) -> Double)
    case constant(Double)
    case toggleSign
    case percent
    case clearAll
    case angleMode
    case equals

    func perform(on engine: CalculatorEngine) {
        switch self {
        case .digit(let d): engine.digit(d)
        case .operation(let symbol, _, let op): engine.setBinary(symbol, op)
        case .unary(_, let f): engine.applyUnary(f)
        case .constant(let v): engine.setConstant(v)
        case .toggleSign: engine.negate()
        case .percent: engine.percent()
        case .clearAll: engine.clearAll()
        case .angleMode: engine.toggleAngleMode()
        case .equals: engine.equals()
        }
    }
}

// Swift cannot synthesise Hashable across closure payloads, so equality and
// hashing are keyed by role: what a key is and does, not which closure it holds.
extension CalcKey: Hashable {
    static func == (lhs: CalcKey, rhs: CalcKey) -> Bool {
        switch (lhs, rhs) {
        case (.digit(let a), .digit(let b)):
            return a == b
        case (.operation(let a, _, _), .operation(let b, _, _)):
            return a == b
        case (.unary(let a, _), .unary(let b, _)):
            return a == b
        case (.constant(let a), .constant(let b)):
            return a == b
        case (.toggleSign, .toggleSign), (.percent, .percent),
             (.clearAll, .clearAll), (.angleMode, .angleMode), (.equals, .equals):
            return true
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .digit(let d):
            hasher.combine(0); hasher.combine(d)
        case .operation(let symbol, _, _):
            hasher.combine(1); hasher.combine(symbol)
        case .unary(let label, _):
            hasher.combine(2); hasher.combine(label)
        case .constant(let v):
            hasher.combine(3); hasher.combine(v)
        case .toggleSign:
            hasher.combine(4)
        case .percent:
            hasher.combine(5)
        case .clearAll:
            hasher.combine(6)
        case .angleMode:
            hasher.combine(7)
        case .equals:
            hasher.combine(8)
        }
    }
}

// MARK: - Content view

struct ContentView: View {
    @StateObject private var engine = CalculatorEngine()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Settle spring when a pending calculation resolves into a value.
    @State private var landScale: CGFloat = 1
    @State private var hadPending = false

    var body: some View {
        VStack(spacing: 12) {
            displayTray
            Spacer(minLength: 8)
            pads
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [C.bg, C.bgDeep]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    // MARK: Display — the signature

    private var displayTray: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(engine.radiansMode ? "rad" : "deg")
                    .font(F.mode)
                    .foregroundColor(C.inkSecondary)
                    .accessibilityLabel(
                        Text("Angle mode \(engine.radiansMode ? "radians" : "degrees")")
                    )
                Spacer()
                Text(engine.preview)
                    .font(F.echo)
                    .foregroundColor(C.inkSecondary)
                    .lineLimit(1)
                    .opacity(engine.preview.isEmpty ? 0 : 1)
                    .accessibilityLabel(Text("Pending calculation \(engine.preview)"))
            }
            Text(engine.display)
                .font(F.display)
                .foregroundColor(engine.display == "Error" ? C.errorInk : C.inkPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.28)
                .scaleEffect(landScale)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onChange(of: engine.preview) { _ in
            if engine.preview.isEmpty {
                guard hadPending else { return }
                hadPending = false
                guard !reduceMotion else { return }
                Haptics.settle()
                landScale = 0.92
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    landScale = 1
                }
            } else {
                hadPending = true
            }
        }
    }

    // MARK: Pads — quiet rail, dominant main pad, bottom-flush

    private var pads: some View {
        HStack(alignment: .bottom, spacing: 10) {
            scientificPad
            mainPad
        }
    }

    // MARK: Key fills by role

    private enum KeyFill {
        static let digit = AnyShapeStyle(C.keyDigit)
        static let util = AnyShapeStyle(C.keyUtil)
        static let rail = AnyShapeStyle(C.keyFunc)
        static let accent = AnyShapeStyle(
            LinearGradient(
                gradient: Gradient(colors: [C.accent, C.accentDeep]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func keyButton(
        _ key: CalcKey,
        fill: AnyShapeStyle,
        ink: Color,
        labelFont: Font,
        height: CGFloat = 58,
        radius: CGFloat = 16
    ) -> some View {
        Button {
            if key.isEquals {
                Haptics.settle()
            } else {
                Haptics.tap()
            }
            key.perform(on: engine)
        } label: {
            keyLabel(key)
                .font(labelFont)
                .foregroundColor(ink)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(C.edge, lineWidth: 1)
                )
                .accessibilityLabel(key, on: engine)
        }
        .buttonStyle(KeyButtonStyle())
    }

    @ViewBuilder
    private func keyLabel(_ key: CalcKey) -> some View {
        switch key {
        case .toggleSign:
            Image(systemName: "plus.forwardslash.minus")
        case .clearAll:
            Text("AC")
        case .constant(Double.pi):
            Text("π")
        case .constant:
            Text("e")
        case .angleMode:
            Text(engine.radiansMode ? "DEG" : "RAD")
        default:
            Text(key.displayText)
        }
    }

    // MARK: Scientific rail — recessed, smaller, quiet, bottom-flush

    private var scientificPad: some View {
        let functionKeys: [[CalcKey]] = [
            [.unary("sin", { self.engine.sinFunction($0) }),
             .unary("cos", { self.engine.cosFunction($0) }),
             .unary("tan", { self.engine.tanFunction($0) })],
            [.unary("ln", engine.lnFunction),
             .unary("log", engine.logFunction),
             .unary("√", engine.sqrtFunction)],
            [.unary("x²", engine.squareFunction),
             .unary("1/x", engine.reciprocalFunction),
             .unary("x!", engine.factorialFunction)],
            [.constant(Double.pi),
             .constant(M_E),
             .angleMode],
        ]
        return VStack(spacing: 10) {
            ForEach(0..<functionKeys.count, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(functionKeys[row], id: \.self) { key in
                        keyButton(
                            key,
                            fill: KeyFill.rail,
                            ink: C.inkRail,
                            labelFont: F.railKey(15),
                            height: 52,
                            radius: 13
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Main pad — digits, utilities, accent operators

    private var mainPad: some View {
        let op = { (symbol: String, display: String, f: @escaping (Double, Double) -> Double) in
            CalcKey.operation(symbol, display, f)
        }
        let rows: [[CalcKey]] = [
            [.clearAll, .toggleSign, .percent, op("÷", "÷", *)],
            [.digit("7"), .digit("8"), .digit("9"), op("×", "×", *)],
            [.digit("4"), .digit("5"), .digit("6"), op("−", "−", -)],
            [.digit("1"), .digit("2"), .digit("3"), op("+", "+", +)],
        ]
        return VStack(spacing: 10) {
            ForEach(0..<rows.count, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(Array(rows[row].enumerated()), id: \.element) { pair in
                        roleKey(pair.element, row: row, column: pair.offset)
                    }
                }
            }
            HStack(spacing: 10) {
                roleKey(.digit("0"), row: 4, column: 0)
                roleKey(.digit("."), row: 4, column: 1)
                roleKey(.equals, row: 4, column: 2)
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Roles by position: the last column is accent, the top row is the
    /// utility tier, equals keeps the accent, everything else is a digit.
    @ViewBuilder
    private func roleKey(_ key: CalcKey, row: Int, column: Int) -> some View {
        if column == 3 || key.isEquals {
            keyButton(
                key,
                fill: KeyFill.accent,
                ink: C.inkOnAccent,
                labelFont: F.mainKey(24)
            )
        } else if row == 0 {
            keyButton(
                key,
                fill: KeyFill.util,
                ink: key.isClearAll ? C.accent : C.inkPrimary,
                labelFont: F.mainKey(key.isClearAll ? 19 : 21)
            )
        } else {
            keyButton(
                key,
                fill: KeyFill.digit,
                ink: C.inkPrimary,
                labelFont: F.mainKey(23)
            )
        }
    }
}

// MARK: - Labels

extension CalcKey {
    /// On-key text; symbol keys keep their glyphs.
    var displayText: String {
        switch self {
        case .digit(let d): return d
        case .operation(let symbol, let display, _): return display.isEmpty ? symbol : display
        case .unary(let label, _): return label
        case .percent: return "%"
        case .clearAll: return "AC"
        case .equals: return "="
        default: return ""
        }
    }

    var isClearAll: Bool {
        if case .clearAll = self { return true }
        return false
    }

    var isEquals: Bool {
        if case .equals = self { return true }
        return false
    }
}

extension View {
    /// VoiceOver sentence for each key.
    @ViewBuilder
    func accessibilityLabel(_ key: CalcKey, on engine: CalculatorEngine) -> some View {
        switch key {
        case .operation(let symbol, _, _):
            accessibilityLabel(Text(Self.voiceOverName(symbol)))
        case .unary(let glyph, _):
            accessibilityLabel(Text(Self.voiceOverUnary(glyph)))
        case .digit(let d):
            accessibilityLabel(Text(d == "." ? "decimal point" : "digit \(d)"))
        case .constant(Double.pi):
            accessibilityLabel(Text("pi"))
        case .constant:
            accessibilityLabel(Text("Euler's number"))
        case .toggleSign:
            accessibilityLabel(Text("toggle sign"))
        case .percent:
            accessibilityLabel(Text("percent"))
        case .clearAll:
            accessibilityLabel(Text("all clear"))
        case .angleMode:
            accessibilityLabel(Text(engine.radiansMode ? "switch to degrees" : "switch to radians"))
        case .equals:
            accessibilityLabel(Text("equals"))
        }
    }

    private static func voiceOverName(_ symbol: String) -> String {
        switch symbol {
        case "÷": return "divide"
        case "×": return "multiply"
        case "−": return "minus"
        case "+": return "plus"
        default: return symbol
        }
    }

    private static func voiceOverUnary(_ glyph: String) -> String {
        switch glyph {
        case "sin": return "sine"
        case "cos": return "cosine"
        case "tan": return "tangent"
        case "ln": return "natural logarithm"
        case "log": return "common logarithm"
        case "√": return "square root"
        case "x²": return "squared"
        case "1/x": return "reciprocal"
        case "x!": return "factorial"
        default: return glyph
        }
    }
}

// MARK: - Button style

private struct KeyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.68), value: configuration.isPressed)
    }
}
