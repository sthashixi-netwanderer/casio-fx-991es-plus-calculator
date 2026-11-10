import Foundation
#if canImport(Combine)
import Combine
public typealias ObservableObjectProtocol = ObservableObject
#else
public protocol ObservableObjectProtocol: AnyObject {}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif

// MARK: - Enums

public enum AngleUnit: String, CaseIterable {
    case deg = "D"
    case rad = "R"
    case gra = "G"

    public func toRadians(_ val: Double) -> Double {
        switch self {
        case .deg: return val * .pi / 180.0
        case .rad: return val
        case .gra: return val * .pi / 200.0
        }
    }

    public func fromRadians(_ rad: Double) -> Double {
        switch self {
        case .deg: return rad * 180.0 / .pi
        case .rad: return rad
        case .gra: return rad * 200.0 / .pi
        }
    }
}

public enum DisplayFormat: Equatable {
    case norm
    case fix(Int)
    case sci(Int)
    case eng
}

public enum CalcMode: String, CaseIterable {
    case comp = "COMP"
    case stat = "STAT"
    case table = "TABLE"
    case eqn = "EQN"
}

public enum MenuState: Equatable {
    case none
    case modeMenu
    case setupMenu
    case fixPrompt
    case sciPrompt
}

public struct EvalResult {
    public let value: Double?
    public let error: String?

    public init(value: Double? = nil, error: String? = nil) {
        self.value = value
        self.error = error
    }
}

// MARK: - Casio Infix Evaluator

public enum CasioEvaluator {
    private enum Token: Equatable {
        case number(Double)
        case identifier(String)
        case binaryOp(String, Int, Bool) // symbol, precedence, rightAssociative
        case prefixFunc(String)
        case postfixOp(String)
        case openParen
        case closeParen
    }

    public static func evaluate(_ expr: String, angleUnit: AngleUnit, lastAnswer: Double = 0) -> EvalResult {
        let trimmed = expr.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return EvalResult(value: 0)
        }

        let tokens: [Token]
        do {
            tokens = try tokenize(trimmed, lastAnswer: lastAnswer)
        } catch {
            return EvalResult(error: "Syntax ERROR")
        }

        let rpn: [Token]
        do {
            rpn = try shuntingYard(tokens)
        } catch {
            return EvalResult(error: "Syntax ERROR")
        }

        return evaluateRPN(rpn, angleUnit: angleUnit)
    }

    private static func tokenize(_ expr: String, lastAnswer: Double) throws -> [Token] {
        var tokens: [Token] = []
        let chars = Array(expr)
        var i = 0

        func peek() -> Character? {
            return i < chars.count ? chars[i] : nil
        }

        func advance() -> Character {
            let c = chars[i]
            i += 1
            return c
        }

        while i < chars.count {
            let c = chars[i]

            if c.isWhitespace {
                i += 1
                continue
            }

            // Numbers: digits and decimal point
            if (c >= "0" && c <= "9") || c == "." {
                var numStr = ""
                while i < chars.count && ((chars[i] >= "0" && chars[i] <= "9") || chars[i] == ".") {
                    numStr.append(advance())
                }
                guard let num = Double(numStr) else { throw NSError(domain: "Parse", code: 1) }

                // Check implicit multiplication with previous token
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 2, false))
                }
                tokens.append(.number(num))
                continue
            }

            // Negative sign vs subtraction
            if c == "-" || c == "−" {
                i += 1
                let isUnary: Bool
                if let last = tokens.last {
                    switch last {
                    case .binaryOp, .openParen, .prefixFunc:
                        isUnary = true
                    default:
                        isUnary = false
                    }
                } else {
                    isUnary = true
                }

                if isUnary {
                    tokens.append(.prefixFunc("neg"))
                } else {
                    tokens.append(.binaryOp("−", 1, false))
                }
                continue
            }

            // Parentheses
            if c == "(" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 2, false))
                }
                tokens.append(.openParen)
                i += 1
                continue
            }

            if c == ")" {
                tokens.append(.closeParen)
                i += 1
                continue
            }

            // Operators
            if c == "+" {
                tokens.append(.binaryOp("+", 1, false))
                i += 1
                continue
            }
            if c == "×" || c == "*" {
                tokens.append(.binaryOp("×", 2, false))
                i += 1
                continue
            }
            if c == "÷" || c == "/" {
                tokens.append(.binaryOp("÷", 2, false))
                i += 1
                continue
            }
            if c == "^" {
                tokens.append(.binaryOp("^", 3, true))
                i += 1
                continue
            }

            // Postfix powers and factorials
            if c == "²" {
                tokens.append(.postfixOp("²"))
                i += 1
                continue
            }
            if c == "³" {
                tokens.append(.postfixOp("³"))
                i += 1
                continue
            }
            if c == "!" {
                tokens.append(.postfixOp("!"))
                i += 1
                continue
            }
            if c == "%" {
                tokens.append(.postfixOp("%"))
                i += 1
                continue
            }

            // Constants
            if c == "π" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 2, false))
                }
                tokens.append(.number(.pi))
                i += 1
                continue
            }
            if c == "e" && (i + 1 == chars.count || !chars[i + 1].isLetter) {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 2, false))
                }
                tokens.append(.number(M_E))
                i += 1
                continue
            }

            // Square root symbol
            if c == "√" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 2, false))
                }
                tokens.append(.prefixFunc("√"))
                i += 1
                continue
            }
            if c == "∛" {
                if let last = tokens.last, canImplicitMultiplyBefore(last) {
                    tokens.append(.binaryOp("×", 2, false))
                }
                tokens.append(.prefixFunc("∛"))
                i += 1
                continue
            }

            // Word tokens: sin, cos, tan, log, ln, Ans, etc.
            var word = ""
            while i < chars.count && (chars[i].isLetter || chars[i] == "⁻" || chars[i] == "¹") {
                word.append(advance())
            }

            if !word.isEmpty {
                if word == "Ans" {
                    if let last = tokens.last, canImplicitMultiplyBefore(last) {
                        tokens.append(.binaryOp("×", 2, false))
                    }
                    tokens.append(.number(lastAnswer))
                } else if ["sin", "cos", "tan", "asin", "acos", "atan", "sin⁻¹", "cos⁻¹", "tan⁻¹", "log", "ln", "abs"].contains(word) {
                    if let last = tokens.last, canImplicitMultiplyBefore(last) {
                        tokens.append(.binaryOp("×", 2, false))
                    }
                    tokens.append(.prefixFunc(word))
                } else {
                    tokens.append(.identifier(word))
                }
                continue
            }

            // Unknown character
            i += 1
        }

        return tokens
    }

    private static func canImplicitMultiplyBefore(_ token: Token) -> Bool {
        switch token {
        case .number, .closeParen, .postfixOp:
            return true
        default:
            return false
        }
    }

    private static func shuntingYard(_ tokens: [Token]) throws -> [Token] {
        var output: [Token] = []
        var opStack: [Token] = []

        for token in tokens {
            switch token {
            case .number:
                output.append(token)
            case .prefixFunc:
                opStack.append(token)
            case .postfixOp:
                output.append(token)
            case .binaryOp(_, let prec1, let rightAssoc1):
                while let top = opStack.last {
                    if case .binaryOp(_, let prec2, _) = top {
                        if (rightAssoc1 && prec1 < prec2) || (!rightAssoc1 && prec1 <= prec2) {
                            output.append(opStack.removeLast())
                            continue
                        }
                    } else if case .prefixFunc = top {
                        output.append(opStack.removeLast())
                        continue
                    }
                    break
                }
                opStack.append(token)
            case .openParen:
                opStack.append(token)
            case .closeParen:
                var matched = false
                while let top = opStack.last {
                    if top == .openParen {
                        matched = true
                        _ = opStack.removeLast()
                        if let next = opStack.last, case .prefixFunc = next {
                            output.append(opStack.removeLast())
                        }
                        break
                    }
                    output.append(opStack.removeLast())
                }
                if !matched {
                    throw NSError(domain: "Parenthesis mismatch", code: 2)
                }
            case .identifier:
                throw NSError(domain: "Unknown identifier", code: 3)
            }
        }

        while let top = opStack.removeLastIfPresent() {
            if top == .openParen || top == .closeParen {
                throw NSError(domain: "Parenthesis mismatch", code: 4)
            }
            output.append(top)
        }

        return output
    }

    private static func evaluateRPN(_ rpn: [Token], angleUnit: AngleUnit) -> EvalResult {
        var stack: [Double] = []

        for token in rpn {
            switch token {
            case .number(let val):
                stack.append(val)

            case .postfixOp(let op):
                guard let val = stack.popLast() else { return EvalResult(error: "Syntax ERROR") }
                switch op {
                case "²":
                    stack.append(val * val)
                case "³":
                    stack.append(val * val * val)
                case "!":
                    guard val >= 0, val.rounded(.down) == val, val <= 170 else {
                        return EvalResult(error: "Math ERROR")
                    }
                    var fact = 1.0
                    if val > 1 {
                        for k in 2...Int(val) { fact *= Double(k) }
                    }
                    stack.append(fact)
                case "%":
                    stack.append(val / 100.0)
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            case .prefixFunc(let f):
                guard let val = stack.popLast() else { return EvalResult(error: "Syntax ERROR") }
                switch f {
                case "neg":
                    stack.append(-val)
                case "√":
                    guard val >= 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.sqrt(val))
                case "∛":
                    stack.append(val < 0 ? -Foundation.pow(-val, 1.0 / 3.0) : Foundation.pow(val, 1.0 / 3.0))
                case "sin":
                    stack.append(Foundation.sin(angleUnit.toRadians(val)))
                case "cos":
                    stack.append(Foundation.cos(angleUnit.toRadians(val)))
                case "tan":
                    let rad = angleUnit.toRadians(val)
                    if abs(Foundation.cos(rad)) < 1e-14 { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.tan(rad))
                case "asin", "sin⁻¹":
                    guard val >= -1.0 && val <= 1.0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(angleUnit.fromRadians(Foundation.asin(val)))
                case "acos", "cos⁻¹":
                    guard val >= -1.0 && val <= 1.0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(angleUnit.fromRadians(Foundation.acos(val)))
                case "atan", "tan⁻¹":
                    stack.append(angleUnit.fromRadians(Foundation.atan(val)))
                case "ln":
                    guard val > 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.log(val))
                case "log":
                    guard val > 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(Foundation.log10(val))
                case "abs":
                    stack.append(abs(val))
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            case .binaryOp(let op, _, _):
                guard let right = stack.popLast(), let left = stack.popLast() else {
                    return EvalResult(error: "Syntax ERROR")
                }
                switch op {
                case "+":
                    stack.append(left + right)
                case "−", "-":
                    stack.append(left - right)
                case "×", "*":
                    stack.append(left * right)
                case "÷", "/":
                    guard right != 0 else { return EvalResult(error: "Math ERROR") }
                    stack.append(left / right)
                case "^":
                    if left < 0 && right.rounded(.down) != right {
                        return EvalResult(error: "Math ERROR")
                    }
                    let r = Foundation.pow(left, right)
                    guard r.isFinite else { return EvalResult(error: "Math ERROR") }
                    stack.append(r)
                default:
                    return EvalResult(error: "Syntax ERROR")
                }

            default:
                return EvalResult(error: "Syntax ERROR")
            }
        }

        guard stack.count == 1, let finalVal = stack.first, finalVal.isFinite else {
            return EvalResult(error: "Math ERROR")
        }

        return EvalResult(value: finalVal)
    }

    public static func format(_ val: Double, format: DisplayFormat) -> String {
        guard val.isFinite else { return "Math ERROR" }
        if val == 0 { return "0" }

        switch format {
        case .fix(let d):
            return String(format: "%.\(d)f", val)
        case .sci(let d):
            return String(format: "%.\(max(0, d - 1))e", val)
        case .eng:
            let exp = Int(floor(Foundation.log10(abs(val))))
            let engExp = exp >= 0 ? (exp / 3) * 3 : ((exp - 2) / 3) * 3
            let mantissa = val / Foundation.pow(10.0, Double(engExp))
            return "\(String(format: "%.6g", mantissa))×10^\(engExp)"
        case .norm:
            let mag = abs(val)
            if mag >= 1e10 || mag < 1e-2 {
                return String(format: "%.6g", val)
            }
            // Eliminate trailing zeros if decimal
            let formatted = String(format: "%.10g", val)
            return formatted
        }
    }
}

private extension Array {
    mutating func removeLastIfPresent() -> Element? {
        return isEmpty ? nil : removeLast()
    }
}

// MARK: - Calculator Engine

public final class CalculatorEngine: ObservableObjectProtocol {
    @Published public var expression: String = ""
    @Published public var cursorPosition: Int = 0
    @Published public var result: String = "0"
    @Published public var angleUnit: AngleUnit = .deg
    @Published public var displayFormat: DisplayFormat = .norm
    @Published public var activeMode: CalcMode = .comp
    @Published public var menuState: MenuState = .none

    @Published public var shiftActive: Bool = false
    @Published public var alphaActive: Bool = false
    @Published public var hasMemory: Bool = false
    @Published public var isError: Bool = false

    private var memoryValue: Double = 0 {
        didSet { hasMemory = memoryValue != 0 }
    }
    public var lastAnswer: Double = 0

    public init() {}

    // MARK: - Editing & Cursor

    public func insert(_ text: String) {
        if isError {
            isError = false
            expression = ""
            cursorPosition = 0
        }

        let chars = Array(expression)
        let pos = min(max(0, cursorPosition), chars.count)
        let prefix = String(chars[0..<pos])
        let suffix = String(chars[pos..<chars.count])

        expression = prefix + text + suffix
        cursorPosition = pos + text.count
    }

    public func delete() {
        if isError {
            clearAll()
            return
        }

        let chars = Array(expression)
        guard cursorPosition > 0 && !chars.isEmpty else { return }

        let pos = min(cursorPosition, chars.count)
        var newChars = chars
        newChars.remove(at: pos - 1)
        expression = String(newChars)
        cursorPosition = pos - 1
    }

    public func clearAll() {
        expression = ""
        cursorPosition = 0
        result = "0"
        isError = false
        menuState = .none
        shiftActive = false
        alphaActive = false
    }

    public func turnOn() {
        clearAll()
    }

    public func moveCursorLeft() {
        if cursorPosition > 0 {
            cursorPosition -= 1
        }
    }

    public func moveCursorRight() {
        if cursorPosition < expression.count {
            cursorPosition += 1
        }
    }

    // MARK: - Evaluation

    public func evaluate() {
        guard !expression.isEmpty else { return }

        let eval = CasioEvaluator.evaluate(expression, angleUnit: angleUnit, lastAnswer: lastAnswer)
        if let err = eval.error {
            isError = true
            result = err
        } else if let val = eval.value {
            isError = false
            lastAnswer = val
            result = CasioEvaluator.format(val, format: displayFormat)
        }
        shiftActive = false
        alphaActive = false
    }

    // MARK: - Modifiers

    public func toggleShift() {
        shiftActive.toggle()
        if shiftActive { alphaActive = false }
    }

    public func toggleAlpha() {
        alphaActive.toggle()
        if alphaActive { shiftActive = false }
    }

    // MARK: - Menus

    public func openModeMenu() {
        menuState = (menuState == .modeMenu) ? .none : .modeMenu
    }

    public func openSetupMenu() {
        menuState = (menuState == .setupMenu) ? .none : .setupMenu
    }

    public func selectMenuOption(_ number: Int) {
        switch menuState {
        case .modeMenu:
            switch number {
            case 1: activeMode = .comp
            case 2: activeMode = .stat
            case 3: activeMode = .table
            case 4: activeMode = .eqn
            default: break
            }
            menuState = .none

        case .setupMenu:
            switch number {
            case 1, 2:
                // MthIO / LineIO
                menuState = .none
            case 3:
                angleUnit = .deg
                menuState = .none
            case 4:
                angleUnit = .rad
                menuState = .none
            case 5:
                angleUnit = .gra
                menuState = .none
            case 6:
                menuState = .fixPrompt
            case 7:
                menuState = .sciPrompt
            case 8:
                displayFormat = .norm
                menuState = .none
            default: break
            }

        case .fixPrompt:
            let d = min(max(0, number), 9)
            displayFormat = .fix(d)
            menuState = .none
            if !isError, let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
                result = CasioEvaluator.format(val, format: displayFormat)
            }

        case .sciPrompt:
            let d = min(max(0, number), 9)
            displayFormat = .sci(d)
            menuState = .none
            if !isError, let val = Double(result.replacingOccurrences(of: "×10^", with: "e")) {
                result = CasioEvaluator.format(val, format: displayFormat)
            }

        case .none:
            break
        }
    }

    // MARK: - Memory

    public func addMemory() {
        if let val = Double(result) {
            memoryValue += val
        }
    }

    public func subtractMemory() {
        if let val = Double(result) {
            memoryValue -= val
        }
    }

    public func recallMemory() {
        insert(CasioEvaluator.format(memoryValue, format: displayFormat))
    }

    public func storeMemory() {
        if let val = Double(result) {
            memoryValue = val
        }
    }

    // MARK: - Special Function Helpers

    public func toggleSD() {
        // Toggle standard / decimal display representation
        if displayFormat == .norm {
            displayFormat = .fix(4)
        } else {
            displayFormat = .norm
        }
        if !isError, let val = Double(result) {
            result = CasioEvaluator.format(val, format: displayFormat)
        }
    }

    public func cycleEng() {
        displayFormat = (displayFormat == .eng) ? .norm : .eng
        if !isError, let val = Double(result) {
            result = CasioEvaluator.format(val, format: displayFormat)
        }
    }
}
