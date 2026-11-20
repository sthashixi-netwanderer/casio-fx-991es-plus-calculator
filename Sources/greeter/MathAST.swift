import Foundation

// MARK: - Slot Identification

public enum MathSlotID: Equatable, Hashable, Sendable {
    case root
    case fractionNumerator(UUID)
    case fractionDenominator(UUID)
    case exponentBase(UUID)
    case exponentPower(UUID)
    case radicalRadicand(UUID)
    case radicalIndex(UUID)
    case integralIntegrand(UUID)
    case integralLower(UUID)
    case integralUpper(UUID)
    case derivativeFunction(UUID)
    case derivativePoint(UUID)
    case summationExpr(UUID)
    case summationLower(UUID)
    case summationUpper(UUID)
    case logBase(UUID)
    case logArg(UUID)
    case parens(UUID)
    case functionArg(UUID)
    case mixedInteger(UUID)
    case mixedNumerator(UUID)
    case mixedDenominator(UUID)
}

// MARK: - AST Nodes

public indirect enum MathNode: Identifiable, Equatable, Sendable {
    case text(id: UUID, content: String)
    case fraction(id: UUID, num: [MathNode], den: [MathNode])
    case exponent(id: UUID, base: [MathNode], power: [MathNode])
    case radical(id: UUID, index: [MathNode]?, radicand: [MathNode])
    case integral(id: UUID, integrand: [MathNode], lower: [MathNode], upper: [MathNode])
    /// Numerical derivative template: function and evaluation point.
    case derivative(id: UUID, function: [MathNode], point: [MathNode])
    case summation(id: UUID, expr: [MathNode], lower: [MathNode], upper: [MathNode])
    case logBase(id: UUID, base: [MathNode], arg: [MathNode])
    case parens(id: UUID, children: [MathNode])
    case function(id: UUID, name: String, arg: [MathNode])
    /// Degree/minute/second marker inserted by the ° ' " key (fx-991ES: a postfix
    /// marker rendered positionally as °, ', " — the first marker of a group is °,
    /// the second ', the third ").
    case dmsMark(id: UUID, glyph: String)
    /// Mixed fraction template (SHIFT + a b/c): integer part with a stacked fraction.
    case mixedFraction(id: UUID, integer: [MathNode], num: [MathNode], den: [MathNode])

    public var id: UUID {
        switch self {
        case .text(let id, _): return id
        case .fraction(let id, _, _): return id
        case .exponent(let id, _, _): return id
        case .radical(let id, _, _): return id
        case .integral(let id, _, _, _): return id
        case .derivative(let id, _, _): return id
        case .summation(let id, _, _, _): return id
        case .logBase(let id, _, _): return id
        case .parens(let id, _): return id
        case .function(let id, _, _): return id
        case .dmsMark(let id, _): return id
        case .mixedFraction(let id, _, _, _): return id
        }
    }

    /// Every nested node array of this node. Used for size/depth accounting so
    /// a key that fires repeatedly cannot grow the expression without bound.
    public var childNodeArrays: [[MathNode]] {
        switch self {
        case .text, .dmsMark: return []
        case .fraction(_, let num, let den): return [num, den]
        case .exponent(_, let base, let power): return [base, power]
        case .radical(_, let index, let radicand): return (index.map { [$0] } ?? []) + [radicand]
        case .integral(_, let integrand, let lower, let upper): return [integrand, lower, upper]
        case .derivative(_, let function, let point): return [function, point]
        case .summation(_, let expr, let lower, let upper): return [expr, lower, upper]
        case .logBase(_, let base, let arg): return [base, arg]
        case .parens(_, let children): return [children]
        case .function(_, _, let arg): return [arg]
        case .mixedFraction(_, let integer, let num, let den): return [integer, num, den]
        }
    }

    /// True when the node can serve as a "value" that a fraction/exponent template
    /// may absorb as its base/numerator (fx-991ES: templates grab the value
    /// immediately left of the cursor — never an operator or marker).
    public var isValueNode: Bool {
        switch self {
        case .text(_, let content):
            let trimmed = content.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return false }
            if trimmed.allSatisfy({ ($0 >= "0" && $0 <= "9") || $0 == "." }) { return true }
            // Matrix variables are values too, so the x² / x³ / x⁻¹ keys (and
            // fraction templates) must grab them as a base (manual §11, §13).
            return ["MatA", "MatB", "MatC", "MatAns"].contains(trimmed)
        case .fraction, .exponent, .radical, .parens, .function, .mixedFraction:
            return true
        case .integral, .derivative, .summation, .logBase, .dmsMark:
            return false
        }
    }

    public func toLinearString() -> String {
        switch self {
        case .text(_, let content):
            return content
        case .fraction(_, let num, let den):
            let numStr = num.map { $0.toLinearString() }.joined()
            let denStr = den.map { $0.toLinearString() }.joined()
            return "(\(numStr))/(\(denStr))"
        case .exponent(_, let base, let power):
            let bStr = base.map { $0.toLinearString() }.joined()
            let pStr = power.map { $0.toLinearString() }.joined()
            return "(\(bStr))^(\(pStr))"
        case .radical(_, let index, let radicand):
            let radStr = radicand.map { $0.toLinearString() }.joined()
            if let index = index {
                let idxStr = index.map { $0.toLinearString() }.joined()
                return "((\(radStr))^(1÷(\(idxStr))))"
            }
            return "√(\(radStr))"
        case .integral(_, let integrand, let lower, let upper):
            let fStr = integrand.map { $0.toLinearString() }.joined()
            let lStr = lower.map { $0.toLinearString() }.joined()
            let uStr = upper.map { $0.toLinearString() }.joined()
            return "∫(\(fStr),\(lStr),\(uStr))"
        case .derivative(_, let function, let point):
            let fStr = function.map { $0.toLinearString() }.joined()
            let pStr = point.map { $0.toLinearString() }.joined()
            return "d/dx(\(fStr),\(pStr))"
        case .summation(_, let expr, let lower, let upper):
            let fStr = expr.map { $0.toLinearString() }.joined()
            let lStr = lower.map { $0.toLinearString() }.joined()
            let uStr = upper.map { $0.toLinearString() }.joined()
            return "Σ(\(fStr),\(lStr),\(uStr))"
        case .logBase(_, let base, let arg):
            let bStr = base.map { $0.toLinearString() }.joined()
            let aStr = arg.map { $0.toLinearString() }.joined()
            return "(log(\(aStr))÷log(\(bStr)))"
        case .parens(_, let children):
            let cStr = children.map { $0.toLinearString() }.joined()
            return "(\(cStr))"
        case .function(_, let name, let arg):
            let aStr = arg.map { $0.toLinearString() }.joined()
            return "\(name)(\(aStr))"
        case .dmsMark(_, let glyph):
            return glyph
        case .mixedFraction(_, let integer, let num, let den):
            let iStr = integer.map { $0.toLinearString() }.joined()
            let numStr = num.map { $0.toLinearString() }.joined()
            let denStr = den.map { $0.toLinearString() }.joined()
            if iStr.isEmpty {
                return "(\(numStr))/(\(denStr))"
            }
            return "(\(iStr)+(\(numStr))/(\(denStr)))"
        }
    }
}

// MARK: - Cursor Path

public struct CursorPath: Equatable, Sendable {
    public var slot: MathSlotID
    public var index: Int

    public init(slot: MathSlotID = .root, index: Int = 0) {
        self.slot = slot
        self.index = index
    }
}

// MARK: - AST Manager

public struct MathASTManager: Sendable {
    public var root: [MathNode]
    public var cursor: CursorPath

    public init(root: [MathNode] = [], cursor: CursorPath = CursorPath()) {
        self.root = root
        self.cursor = cursor
    }

    public func toLinearString() -> String {
        root.map { $0.toLinearString() }.joined()
    }

    // MARK: - Slot Node Retrieval & Mutation

    public func getNodes(in slot: MathSlotID) -> [MathNode] {
        if slot == .root { return root }
        return findSlot(slot: slot, in: root) ?? []
    }

    private func findSlot(slot: MathSlotID, in nodes: [MathNode]) -> [MathNode]? {
        for node in nodes {
            switch node {
            case .fraction(let id, let num, let den):
                if case .fractionNumerator(id) = slot { return num }
                if case .fractionDenominator(id) = slot { return den }
                if let res = findSlot(slot: slot, in: num) ?? findSlot(slot: slot, in: den) { return res }
            case .exponent(let id, let base, let power):
                if case .exponentBase(id) = slot { return base }
                if case .exponentPower(id) = slot { return power }
                if let res = findSlot(slot: slot, in: base) ?? findSlot(slot: slot, in: power) { return res }
            case .radical(let id, let index, let radicand):
                if case .radicalRadicand(id) = slot { return radicand }
                if let index = index, case .radicalIndex(id) = slot { return index }
                if let index = index, let res = findSlot(slot: slot, in: index) { return res }
                if let res = findSlot(slot: slot, in: radicand) { return res }
            case .integral(let id, let integrand, let lower, let upper):
                if case .integralIntegrand(id) = slot { return integrand }
                if case .integralLower(id) = slot { return lower }
                if case .integralUpper(id) = slot { return upper }
                if let res = findSlot(slot: slot, in: integrand) ?? findSlot(slot: slot, in: lower) ?? findSlot(slot: slot, in: upper) { return res }
            case .derivative(let id, let function, let point):
                if case .derivativeFunction(id) = slot { return function }
                if case .derivativePoint(id) = slot { return point }
                if let res = findSlot(slot: slot, in: function) ?? findSlot(slot: slot, in: point) { return res }
            case .summation(let id, let expr, let lower, let upper):
                if case .summationExpr(id) = slot { return expr }
                if case .summationLower(id) = slot { return lower }
                if case .summationUpper(id) = slot { return upper }
                if let res = findSlot(slot: slot, in: expr) ?? findSlot(slot: slot, in: lower) ?? findSlot(slot: slot, in: upper) { return res }
            case .logBase(let id, let base, let arg):
                if case .logBase(id) = slot { return base }
                if case .logArg(id) = slot { return arg }
                if let res = findSlot(slot: slot, in: base) ?? findSlot(slot: slot, in: arg) { return res }
            case .parens(let id, let children):
                if case .parens(id) = slot { return children }
                if let res = findSlot(slot: slot, in: children) { return res }
            case .function(let id, _, let arg):
                if case .functionArg(id) = slot { return arg }
                if let res = findSlot(slot: slot, in: arg) { return res }
            case .mixedFraction(let id, let integer, let num, let den):
                if case .mixedInteger(id) = slot { return integer }
                if case .mixedNumerator(id) = slot { return num }
                if case .mixedDenominator(id) = slot { return den }
                if let res = findSlot(slot: slot, in: integer) ?? findSlot(slot: slot, in: num) ?? findSlot(slot: slot, in: den) { return res }
            case .dmsMark:
                break
            case .text:
                break
            }
        }
        return nil
    }

    private mutating func updateSlot(slot: MathSlotID, transform: ([MathNode]) -> [MathNode]) {
        if slot == .root {
            root = transform(root)
            return
        }
        root = updateSlotIn(nodes: root, targetSlot: slot, transform: transform)
    }

    private func updateSlotIn(nodes: [MathNode], targetSlot: MathSlotID, transform: ([MathNode]) -> [MathNode]) -> [MathNode] {
        var updated = nodes
        for i in 0..<updated.count {
            switch updated[i] {
            case .fraction(let id, let num, let den):
                if case .fractionNumerator(id) = targetSlot {
                    updated[i] = .fraction(id: id, num: transform(num), den: den)
                    return updated
                } else if case .fractionDenominator(id) = targetSlot {
                    updated[i] = .fraction(id: id, num: num, den: transform(den))
                    return updated
                } else {
                    let newNum = updateSlotIn(nodes: num, targetSlot: targetSlot, transform: transform)
                    let newDen = updateSlotIn(nodes: den, targetSlot: targetSlot, transform: transform)
                    if newNum != num || newDen != den {
                        updated[i] = .fraction(id: id, num: newNum, den: newDen)
                        return updated
                    }
                }

            case .exponent(let id, let base, let power):
                if case .exponentBase(id) = targetSlot {
                    updated[i] = .exponent(id: id, base: transform(base), power: power)
                    return updated
                } else if case .exponentPower(id) = targetSlot {
                    updated[i] = .exponent(id: id, base: base, power: transform(power))
                    return updated
                } else {
                    let newBase = updateSlotIn(nodes: base, targetSlot: targetSlot, transform: transform)
                    let newPower = updateSlotIn(nodes: power, targetSlot: targetSlot, transform: transform)
                    if newBase != base || newPower != power {
                        updated[i] = .exponent(id: id, base: newBase, power: newPower)
                        return updated
                    }
                }

            case .radical(let id, let index, let radicand):
                if case .radicalRadicand(id) = targetSlot {
                    updated[i] = .radical(id: id, index: index, radicand: transform(radicand))
                    return updated
                } else if let index = index, case .radicalIndex(id) = targetSlot {
                    updated[i] = .radical(id: id, index: transform(index), radicand: radicand)
                    return updated
                } else {
                    let newIdx = index.map { updateSlotIn(nodes: $0, targetSlot: targetSlot, transform: transform) }
                    let newRad = updateSlotIn(nodes: radicand, targetSlot: targetSlot, transform: transform)
                    if newIdx != index || newRad != radicand {
                        updated[i] = .radical(id: id, index: newIdx, radicand: newRad)
                        return updated
                    }
                }

            case .integral(let id, let integrand, let lower, let upper):
                if case .integralIntegrand(id) = targetSlot {
                    updated[i] = .integral(id: id, integrand: transform(integrand), lower: lower, upper: upper)
                    return updated
                } else if case .integralLower(id) = targetSlot {
                    updated[i] = .integral(id: id, integrand: integrand, lower: transform(lower), upper: upper)
                    return updated
                } else if case .integralUpper(id) = targetSlot {
                    updated[i] = .integral(id: id, integrand: integrand, lower: lower, upper: transform(upper))
                    return updated
                } else {
                    let nI = updateSlotIn(nodes: integrand, targetSlot: targetSlot, transform: transform)
                    let nL = updateSlotIn(nodes: lower, targetSlot: targetSlot, transform: transform)
                    let nU = updateSlotIn(nodes: upper, targetSlot: targetSlot, transform: transform)
                    if nI != integrand || nL != lower || nU != upper {
                        updated[i] = .integral(id: id, integrand: nI, lower: nL, upper: nU)
                        return updated
                    }
                }

            case .derivative(let id, let function, let point):
                if case .derivativeFunction(id) = targetSlot {
                    updated[i] = .derivative(id: id, function: transform(function), point: point)
                    return updated
                } else if case .derivativePoint(id) = targetSlot {
                    updated[i] = .derivative(id: id, function: function, point: transform(point))
                    return updated
                } else {
                    let nF = updateSlotIn(nodes: function, targetSlot: targetSlot, transform: transform)
                    let nP = updateSlotIn(nodes: point, targetSlot: targetSlot, transform: transform)
                    if nF != function || nP != point {
                        updated[i] = .derivative(id: id, function: nF, point: nP)
                        return updated
                    }
                }

            case .summation(let id, let expr, let lower, let upper):
                if case .summationExpr(id) = targetSlot {
                    updated[i] = .summation(id: id, expr: transform(expr), lower: lower, upper: upper)
                    return updated
                } else if case .summationLower(id) = targetSlot {
                    updated[i] = .summation(id: id, expr: expr, lower: transform(lower), upper: upper)
                    return updated
                } else if case .summationUpper(id) = targetSlot {
                    updated[i] = .summation(id: id, expr: expr, lower: lower, upper: transform(upper))
                    return updated
                } else {
                    let nE = updateSlotIn(nodes: expr, targetSlot: targetSlot, transform: transform)
                    let nL = updateSlotIn(nodes: lower, targetSlot: targetSlot, transform: transform)
                    let nU = updateSlotIn(nodes: upper, targetSlot: targetSlot, transform: transform)
                    if nE != expr || nL != lower || nU != upper {
                        updated[i] = .summation(id: id, expr: nE, lower: nL, upper: nU)
                        return updated
                    }
                }

            case .logBase(let id, let base, let arg):
                if case .logBase(id) = targetSlot {
                    updated[i] = .logBase(id: id, base: transform(base), arg: arg)
                    return updated
                } else if case .logArg(id) = targetSlot {
                    updated[i] = .logBase(id: id, base: base, arg: transform(arg))
                    return updated
                } else {
                    let nB = updateSlotIn(nodes: base, targetSlot: targetSlot, transform: transform)
                    let nA = updateSlotIn(nodes: arg, targetSlot: targetSlot, transform: transform)
                    if nB != base || nA != arg {
                        updated[i] = .logBase(id: id, base: nB, arg: nA)
                        return updated
                    }
                }

            case .parens(let id, let children):
                if case .parens(id) = targetSlot {
                    updated[i] = .parens(id: id, children: transform(children))
                    return updated
                } else {
                    let nC = updateSlotIn(nodes: children, targetSlot: targetSlot, transform: transform)
                    if nC != children {
                        updated[i] = .parens(id: id, children: nC)
                        return updated
                    }
                }

            case .function(let id, let name, let arg):
                if case .functionArg(id) = targetSlot {
                    updated[i] = .function(id: id, name: name, arg: transform(arg))
                    return updated
                } else {
                    let nA = updateSlotIn(nodes: arg, targetSlot: targetSlot, transform: transform)
                    if nA != arg {
                        updated[i] = .function(id: id, name: name, arg: nA)
                        return updated
                    }
                }

            case .mixedFraction(let id, let integer, let num, let den):
                if case .mixedInteger(id) = targetSlot {
                    updated[i] = .mixedFraction(id: id, integer: transform(integer), num: num, den: den)
                    return updated
                } else if case .mixedNumerator(id) = targetSlot {
                    updated[i] = .mixedFraction(id: id, integer: integer, num: transform(num), den: den)
                    return updated
                } else if case .mixedDenominator(id) = targetSlot {
                    updated[i] = .mixedFraction(id: id, integer: integer, num: num, den: transform(den))
                    return updated
                } else {
                    let nI = updateSlotIn(nodes: integer, targetSlot: targetSlot, transform: transform)
                    let nN = updateSlotIn(nodes: num, targetSlot: targetSlot, transform: transform)
                    let nD = updateSlotIn(nodes: den, targetSlot: targetSlot, transform: transform)
                    if nI != integer || nN != num || nD != den {
                        updated[i] = .mixedFraction(id: id, integer: nI, num: nN, den: nD)
                        return updated
                    }
                }

            case .dmsMark:
                break

            case .text:
                break
            }
        }
        return updated
    }

    // MARK: - Insertion Operations

    public mutating func insertText(_ text: String) {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        var merged = false
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            if safeIdx > 0, case .text(let id, let prevContent) = updated[safeIdx - 1] {
                let isPrevDigit = prevContent.allSatisfy { ($0 >= "0" && $0 <= "9") || $0 == "." }
                let isCurDigit = text.allSatisfy { ($0 >= "0" && $0 <= "9") || $0 == "." }
                if isPrevDigit && isCurDigit {
                    updated[safeIdx - 1] = .text(id: id, content: prevContent + text)
                    merged = true
                    return updated
                }
            }
            let newNode = MathNode.text(id: UUID(), content: text)
            updated.insert(newNode, at: safeIdx)
            return updated
        }
        if !merged {
            cursor.index += 1
        }
    }

    public mutating func insertFraction() {
        guard !isAtCapacity else { return }
        let currentNodes = getNodes(in: cursor.slot)
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        if targetIndex > 0 && targetIndex <= currentNodes.count,
           currentNodes[targetIndex - 1].isValueNode {
            // Take the preceding value term as numerator (fx-991ES grabs the value
            // left of the cursor — never an operator or marker)
            let preceding = currentNodes[targetIndex - 1]
            updateSlot(slot: targetSlot) { nodes in
                var updated = nodes
                updated.remove(at: targetIndex - 1)
                let frac = MathNode.fraction(id: id, num: [preceding], den: [])
                updated.insert(frac, at: targetIndex - 1)
                return updated
            }
            // Move cursor to denominator
            cursor = CursorPath(slot: .fractionDenominator(id), index: 0)
        } else {
            // Empty fraction template
            let frac = MathNode.fraction(id: id, num: [], den: [])
            updateSlot(slot: targetSlot) { nodes in
                var updated = nodes
                let safeIdx = min(max(0, targetIndex), updated.count)
                updated.insert(frac, at: safeIdx)
                return updated
            }
            // Move cursor to numerator
            cursor = CursorPath(slot: .fractionNumerator(id), index: 0)
        }
    }

    /// ° ' " key during input: inserts one sexagesimal marker. The glyph is
    /// positional — the first marker after a value is °, the next ' (after the
    /// following digits), then " (fx-991ES input syntax: d°m's").
    public mutating func insertDMSMark() {
        guard !isAtCapacity else { return }
        let currentNodes = getNodes(in: cursor.slot)
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        // Scan backward over the current DMS group (markers separated by numeric
        // fields) to find the most recent marker, which governs the next glyph.
        var glyph = "°"
        var k = targetIndex - 1
        scan: while k >= 0 {
            switch currentNodes[k] {
            case .dmsMark(_, let prevGlyph):
                switch prevGlyph {
                case "°": glyph = "'"
                case "'": glyph = "\""
                default: glyph = "°"
                }
                break scan
            case .text(_, let content):
                let isNumeric = !content.isEmpty && content.allSatisfy { ($0 >= "0" && $0 <= "9") || $0 == "." }
                if isNumeric {
                    k -= 1
                    continue
                }
                break scan
            default:
                break scan
            }
        }
        let mark = MathNode.dmsMark(id: UUID(), glyph: glyph)
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(mark, at: safeIdx)
            return updated
        }
        cursor.index += 1
    }

    /// SHIFT + a b/c: mixed fraction template. A value immediately left of the
    /// cursor becomes the integer part (fx-991ES mixed template), cursor then
    /// moves to the numerator. Without a preceding value the cursor starts in
    /// the integer field.
    public mutating func insertMixedFraction() {
        guard !isAtCapacity else { return }
        let currentNodes = getNodes(in: cursor.slot)
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        if targetIndex > 0 && targetIndex <= currentNodes.count,
           currentNodes[targetIndex - 1].isValueNode {
            let preceding = currentNodes[targetIndex - 1]
            updateSlot(slot: targetSlot) { nodes in
                var updated = nodes
                updated.remove(at: targetIndex - 1)
                let mixed = MathNode.mixedFraction(id: id, integer: [preceding], num: [], den: [])
                updated.insert(mixed, at: targetIndex - 1)
                return updated
            }
            cursor = CursorPath(slot: .mixedNumerator(id), index: 0)
        } else {
            let mixed = MathNode.mixedFraction(id: id, integer: [], num: [], den: [])
            updateSlot(slot: targetSlot) { nodes in
                var updated = nodes
                let safeIdx = min(max(0, targetIndex), updated.count)
                updated.insert(mixed, at: safeIdx)
                return updated
            }
            cursor = CursorPath(slot: .mixedInteger(id), index: 0)
        }
    }

    public mutating func insertRadical(index: [MathNode]? = nil) {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        let rad = MathNode.radical(id: id, index: index, radicand: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(rad, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .radicalRadicand(id), index: 0)
    }

    public mutating func insertNthRoot() {
        guard !isAtCapacity else { return }
        let id = UUID()
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let node = MathNode.radical(id: id, index: [], radicand: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(node, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .radicalIndex(id), index: 0)
    }

    public mutating func insertCubeRoot() {
        guard !isAtCapacity else { return }
        let id = UUID()
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let node = MathNode.radical(id: id, index: [.text(id: UUID(), content: "3")], radicand: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(node, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .radicalRadicand(id), index: 0)
    }

    public mutating func insertExponent() {
        guard !isAtCapacity else { return }
        let currentNodes = getNodes(in: cursor.slot)
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        if targetIndex > 0 && targetIndex <= currentNodes.count,
           currentNodes[targetIndex - 1].isValueNode {
            let preceding = currentNodes[targetIndex - 1]
            updateSlot(slot: targetSlot) { nodes in
                var updated = nodes
                updated.remove(at: targetIndex - 1)
                let expNode = MathNode.exponent(id: id, base: [preceding], power: [])
                updated.insert(expNode, at: targetIndex - 1)
                return updated
            }
            cursor = CursorPath(slot: .exponentPower(id), index: 0)
        } else {
            let expNode = MathNode.exponent(id: id, base: [], power: [])
            updateSlot(slot: targetSlot) { nodes in
                var updated = nodes
                let safeIdx = min(max(0, targetIndex), updated.count)
                updated.insert(expNode, at: safeIdx)
                return updated
            }
            cursor = CursorPath(slot: .exponentPower(id), index: 0)
        }
    }

    /// SHIFT + ∫: numerical derivative template with a function field and a
    /// field for the point at which to evaluate it (reference §9.5).
    public mutating func insertDerivative() {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        let node = MathNode.derivative(id: id, function: [], point: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(node, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .derivativeFunction(id), index: 0)
    }

    public mutating func insertIntegral() {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        let integ = MathNode.integral(id: id, integrand: [], lower: [], upper: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(integ, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .integralIntegrand(id), index: 0)
    }

    public mutating func insertSummation() {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        let sumNode = MathNode.summation(id: id, expr: [], lower: [], upper: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(sumNode, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .summationExpr(id), index: 0)
    }

    public mutating func insertLogBase() {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        let node = MathNode.logBase(id: id, base: [], arg: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(node, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .logBase(id), index: 0)
    }

    public mutating func insertParens() {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        let node = MathNode.parens(id: id, children: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(node, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .parens(id), index: 0)
    }

    public mutating func insertFunction(_ name: String) {
        guard !isAtCapacity else { return }
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        let id = UUID()
        let node = MathNode.function(id: id, name: name, arg: [])
        updateSlot(slot: targetSlot) { nodes in
            var updated = nodes
            let safeIdx = min(max(0, targetIndex), updated.count)
            updated.insert(node, at: safeIdx)
            return updated
        }
        cursor = CursorPath(slot: .functionArg(id), index: 0)
    }

    // MARK: - Deletion

    public mutating func delete() {
        let currentNodes = getNodes(in: cursor.slot)
        let targetSlot = cursor.slot
        let targetIndex = cursor.index
        if targetIndex > 0 && targetIndex <= currentNodes.count {
            let target = currentNodes[targetIndex - 1]
            switch target {
            case .text(_, let content) where content.count > 1:
                var newContent = content
                newContent.removeLast()
                updateSlot(slot: targetSlot) { nodes in
                    var updated = nodes
                    updated[targetIndex - 1] = .text(id: target.id, content: newContent)
                    return updated
                }
            default:
                updateSlot(slot: targetSlot) { nodes in
                    var updated = nodes
                    updated.remove(at: targetIndex - 1)
                    return updated
                }
                cursor.index -= 1
            }
        } else if cursor.index == 0 && cursor.slot != .root {
            guard let parentInfo = findParentSlot(of: cursor.slot, in: root) else { return }
            let parentNodes = getNodes(in: parentInfo.parentSlot)
            guard parentInfo.nodeIndexInParent < parentNodes.count else { return }
            let enclosingNode = parentNodes[parentInfo.nodeIndexInParent]

            if currentNodes.isEmpty {
                var replacement: [MathNode] = []
                switch enclosingNode {
                case .fraction(let id, let num, let den):
                    if cursor.slot == .fractionDenominator(id) {
                        replacement = num
                    } else if cursor.slot == .fractionNumerator(id) && !den.isEmpty {
                        replacement = den
                    }
                case .exponent(_, let base, _):
                    replacement = base
                case .derivative(let id, let function, let point):
                    if cursor.slot == .derivativeFunction(id) {
                        replacement = function
                    } else if cursor.slot == .derivativePoint(id) {
                        replacement = point
                    }
                case .radical(let id, let index, _):
                    if cursor.slot == .radicalRadicand(id) && index != nil {
                        replacement = index ?? []
                    }
                default:
                    break
                }

                updateSlot(slot: parentInfo.parentSlot) { nodes in
                    var updated = nodes
                    updated.remove(at: parentInfo.nodeIndexInParent)
                    if !replacement.isEmpty {
                        updated.insert(contentsOf: replacement, at: parentInfo.nodeIndexInParent)
                    }
                    return updated
                }
                cursor = CursorPath(slot: parentInfo.parentSlot, index: parentInfo.nodeIndexInParent + replacement.count)
            } else {
                exitSlotLeft()
            }
        }
    }

    // MARK: - Navigation

    public mutating func moveLeft() {
        if cursor.index > 0 {
            cursor.index -= 1
            let nodes = getNodes(in: cursor.slot)
            if cursor.index < nodes.count {
                // If moving left onto a compound node, enter its rightmost child slot
                if let (subSlot, subCount) = rightmostChildSlot(of: nodes[cursor.index]) {
                    cursor = CursorPath(slot: subSlot, index: subCount)
                }
            }
        } else {
            exitSlotLeft()
        }
    }

    public mutating func moveRight() {
        let nodes = getNodes(in: cursor.slot)
        if cursor.index < nodes.count {
            let target = nodes[cursor.index]
            if let (subSlot, _) = leftmostChildSlot(of: target) {
                cursor = CursorPath(slot: subSlot, index: 0)
            } else {
                cursor.index += 1
            }
        } else {
            exitSlotRight()
        }
    }

    public mutating func moveUp() {
        switch cursor.slot {
        case .fractionDenominator(let id):
            let numNodes = getNodes(in: .fractionNumerator(id))
            cursor = CursorPath(slot: .fractionNumerator(id), index: min(cursor.index, numNodes.count))
        case .integralLower(let id):
            let intNodes = getNodes(in: .integralIntegrand(id))
            cursor = CursorPath(slot: .integralIntegrand(id), index: min(cursor.index, intNodes.count))
        case .integralIntegrand(let id):
            let upNodes = getNodes(in: .integralUpper(id))
            cursor = CursorPath(slot: .integralUpper(id), index: min(cursor.index, upNodes.count))
        case .derivativePoint(let id):
            let funcNodes = getNodes(in: .derivativeFunction(id))
            cursor = CursorPath(slot: .derivativeFunction(id), index: min(cursor.index, funcNodes.count))
        case .summationLower(let id):
            let exprNodes = getNodes(in: .summationExpr(id))
            cursor = CursorPath(slot: .summationExpr(id), index: min(cursor.index, exprNodes.count))
        case .summationExpr(let id):
            let upNodes = getNodes(in: .summationUpper(id))
            cursor = CursorPath(slot: .summationUpper(id), index: min(cursor.index, upNodes.count))
        case .logBase(let id):
            let argNodes = getNodes(in: .logArg(id))
            cursor = CursorPath(slot: .logArg(id), index: min(cursor.index, argNodes.count))
        case .exponentBase(let id):
            let powerNodes = getNodes(in: .exponentPower(id))
            cursor = CursorPath(slot: .exponentPower(id), index: min(cursor.index, powerNodes.count))
        case .mixedDenominator(let id):
            let numNodes = getNodes(in: .mixedNumerator(id))
            cursor = CursorPath(slot: .mixedNumerator(id), index: min(cursor.index, numNodes.count))
        case .mixedNumerator(let id):
            let intNodes = getNodes(in: .mixedInteger(id))
            cursor = CursorPath(slot: .mixedInteger(id), index: min(cursor.index, intNodes.count))
        default:
            break
        }
    }

    public mutating func moveDown() {
        switch cursor.slot {
        case .fractionNumerator(let id):
            let denNodes = getNodes(in: .fractionDenominator(id))
            cursor = CursorPath(slot: .fractionDenominator(id), index: min(cursor.index, denNodes.count))
        case .integralUpper(let id):
            let intNodes = getNodes(in: .integralIntegrand(id))
            cursor = CursorPath(slot: .integralIntegrand(id), index: min(cursor.index, intNodes.count))
        case .integralIntegrand(let id):
            let lowNodes = getNodes(in: .integralLower(id))
            cursor = CursorPath(slot: .integralLower(id), index: min(cursor.index, lowNodes.count))
        case .derivativeFunction(let id):
            let pointNodes = getNodes(in: .derivativePoint(id))
            cursor = CursorPath(slot: .derivativePoint(id), index: min(cursor.index, pointNodes.count))
        case .summationUpper(let id):
            let exprNodes = getNodes(in: .summationExpr(id))
            cursor = CursorPath(slot: .summationExpr(id), index: min(cursor.index, exprNodes.count))
        case .summationExpr(let id):
            let lowNodes = getNodes(in: .summationLower(id))
            cursor = CursorPath(slot: .summationLower(id), index: min(cursor.index, lowNodes.count))
        case .logArg(let id):
            let baseNodes = getNodes(in: .logBase(id))
            cursor = CursorPath(slot: .logBase(id), index: min(cursor.index, baseNodes.count))
        case .exponentPower:
            exitSlotRight()
        case .mixedInteger(let id):
            let numNodes = getNodes(in: .mixedNumerator(id))
            cursor = CursorPath(slot: .mixedNumerator(id), index: min(cursor.index, numNodes.count))
        case .mixedNumerator(let id):
            let denNodes = getNodes(in: .mixedDenominator(id))
            cursor = CursorPath(slot: .mixedDenominator(id), index: min(cursor.index, denNodes.count))
        default:
            break
        }
    }

    private func leftmostChildSlot(of node: MathNode) -> (MathSlotID, Int)? {
        switch node {
        case .fraction(let id, _, _): return (.fractionNumerator(id), 0)
        case .exponent(let id, let base, _): return base.isEmpty ? (.exponentPower(id), 0) : (.exponentBase(id), 0)
        case .radical(let id, let index, _): return index != nil ? (.radicalIndex(id), 0) : (.radicalRadicand(id), 0)
        case .integral(let id, _, _, _): return (.integralIntegrand(id), 0)
        case .derivative(let id, _, _): return (.derivativeFunction(id), 0)
        case .summation(let id, _, _, _): return (.summationExpr(id), 0)
        case .logBase(let id, _, _): return (.logBase(id), 0)
        case .parens(let id, _): return (.parens(id), 0)
        case .function(let id, _, _): return (.functionArg(id), 0)
        case .mixedFraction(let id, _, _, _): return (.mixedInteger(id), 0)
        case .text, .dmsMark: return nil
        }
    }

    private func rightmostChildSlot(of node: MathNode) -> (MathSlotID, Int)? {
        switch node {
        case .fraction(let id, _, let den): return (.fractionDenominator(id), den.count)
        case .exponent(let id, _, let power): return (.exponentPower(id), power.count)
        case .radical(let id, _, let radicand): return (.radicalRadicand(id), radicand.count)
        case .integral(let id, _, let lower, _): return (.integralLower(id), lower.count)
        case .derivative(let id, _, let point): return (.derivativePoint(id), point.count)
        case .summation(let id, _, let lower, _): return (.summationLower(id), lower.count)
        case .logBase(let id, _, let arg): return (.logArg(id), arg.count)
        case .parens(let id, let children): return (.parens(id), children.count)
        case .function(let id, _, let arg): return (.functionArg(id), arg.count)
        case .mixedFraction(let id, _, _, let den): return (.mixedDenominator(id), den.count)
        case .text, .dmsMark: return nil
        }
    }

    /// Move right out of the current field into the next field of the same
    /// template, in visual order. Only when every field has been visited does
    /// the cursor leave the template for the parent expression.
    private mutating func exitSlotRight() {
        switch cursor.slot {
        case .fractionNumerator(let id):
            cursor = CursorPath(slot: .fractionDenominator(id), index: 0)
            return
        case .exponentBase(let id):
            cursor = CursorPath(slot: .exponentPower(id), index: 0)
            return
        case .radicalIndex(let id):
            cursor = CursorPath(slot: .radicalRadicand(id), index: 0)
            return
        case .logBase(let id):
            cursor = CursorPath(slot: .logArg(id), index: 0)
            return
        case .integralIntegrand(let id):
            let lower = getNodes(in: .integralLower(id))
            cursor = CursorPath(slot: .integralLower(id), index: lower.count)
            return
        case .integralLower(let id):
            let upper = getNodes(in: .integralUpper(id))
            cursor = CursorPath(slot: .integralUpper(id), index: upper.count)
            return
        case .derivativeFunction(let id):
            let point = getNodes(in: .derivativePoint(id))
            cursor = CursorPath(slot: .derivativePoint(id), index: point.count)
            return
        case .summationExpr(let id):
            let lower = getNodes(in: .summationLower(id))
            cursor = CursorPath(slot: .summationLower(id), index: lower.count)
            return
        case .summationLower(let id):
            let upper = getNodes(in: .summationUpper(id))
            cursor = CursorPath(slot: .summationUpper(id), index: upper.count)
            return
        case .mixedInteger(let id):
            let numerator = getNodes(in: .mixedNumerator(id))
            cursor = CursorPath(slot: .mixedNumerator(id), index: numerator.count)
            return
        case .mixedNumerator(let id):
            let denominator = getNodes(in: .mixedDenominator(id))
            cursor = CursorPath(slot: .mixedDenominator(id), index: denominator.count)
            return
        default:
            break
        }
        guard let parentInfo = findParentSlot(of: cursor.slot, in: root) else { return }
        cursor = CursorPath(slot: parentInfo.parentSlot, index: parentInfo.nodeIndexInParent + 1)
    }

    /// Reverse of `exitSlotRight()` — step through the template's fields in
    /// reverse visual order before leaving for the parent expression.
    private mutating func exitSlotLeft() {
        switch cursor.slot {
        case .fractionDenominator(let id):
            let numerator = getNodes(in: .fractionNumerator(id))
            cursor = CursorPath(slot: .fractionNumerator(id), index: numerator.count)
            return
        case .exponentPower(let id):
            let base = getNodes(in: .exponentBase(id))
            cursor = CursorPath(slot: .exponentBase(id), index: base.count)
            return
        case .radicalRadicand(let id):
            if let parentInfo = findParentSlot(of: cursor.slot, in: root) {
                let parentNodes = getNodes(in: parentInfo.parentSlot)
                if parentInfo.nodeIndexInParent < parentNodes.count,
                   case .radical(_, let indexOpt, _) = parentNodes[parentInfo.nodeIndexInParent],
                   indexOpt != nil {
                    let idxNodes = getNodes(in: .radicalIndex(id))
                    cursor = CursorPath(slot: .radicalIndex(id), index: idxNodes.count)
                    return
                }
            }
        case .logArg(let id):
            let baseNodes = getNodes(in: .logBase(id))
            cursor = CursorPath(slot: .logBase(id), index: baseNodes.count)
            return
        case .integralUpper(let id):
            let lower = getNodes(in: .integralLower(id))
            cursor = CursorPath(slot: .integralLower(id), index: lower.count)
            return
        case .integralLower(let id):
            let integrand = getNodes(in: .integralIntegrand(id))
            cursor = CursorPath(slot: .integralIntegrand(id), index: integrand.count)
            return
        case .derivativePoint(let id):
            let function = getNodes(in: .derivativeFunction(id))
            cursor = CursorPath(slot: .derivativeFunction(id), index: function.count)
            return
        case .summationUpper(let id):
            let lower = getNodes(in: .summationLower(id))
            cursor = CursorPath(slot: .summationLower(id), index: lower.count)
            return
        case .summationLower(let id):
            let expr = getNodes(in: .summationExpr(id))
            cursor = CursorPath(slot: .summationExpr(id), index: expr.count)
            return
        case .mixedDenominator(let id):
            let numerator = getNodes(in: .mixedNumerator(id))
            cursor = CursorPath(slot: .mixedNumerator(id), index: numerator.count)
            return
        case .mixedNumerator(let id):
            let integer = getNodes(in: .mixedInteger(id))
            cursor = CursorPath(slot: .mixedInteger(id), index: integer.count)
            return
        default:
            break
        }
        guard let parentInfo = findParentSlot(of: cursor.slot, in: root) else { return }
        cursor = CursorPath(slot: parentInfo.parentSlot, index: parentInfo.nodeIndexInParent)
    }

    private struct ParentInfo {
        let parentSlot: MathSlotID
        let nodeIndexInParent: Int
    }

    private func findParentSlot(of targetSlot: MathSlotID, in nodes: [MathNode], currentSlot: MathSlotID = .root) -> ParentInfo? {
        for (i, node) in nodes.enumerated() {
            switch node {
            case .fraction(let id, let num, let den):
                if targetSlot == .fractionNumerator(id) || targetSlot == .fractionDenominator(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: num, currentSlot: .fractionNumerator(id)) ??
                    findParentSlot(of: targetSlot, in: den, currentSlot: .fractionDenominator(id)) {
                    return res
                }
            case .exponent(let id, let base, let power):
                if targetSlot == .exponentBase(id) || targetSlot == .exponentPower(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: base, currentSlot: .exponentBase(id)) ??
                    findParentSlot(of: targetSlot, in: power, currentSlot: .exponentPower(id)) {
                    return res
                }
            case .radical(let id, let index, let radicand):
                if targetSlot == .radicalRadicand(id) || (index != nil && targetSlot == .radicalIndex(id)) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let index = index, let res = findParentSlot(of: targetSlot, in: index, currentSlot: .radicalIndex(id)) {
                    return res
                }
                if let res = findParentSlot(of: targetSlot, in: radicand, currentSlot: .radicalRadicand(id)) {
                    return res
                }
            case .integral(let id, let integrand, let lower, let upper):
                if targetSlot == .integralIntegrand(id) || targetSlot == .integralLower(id) || targetSlot == .integralUpper(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: integrand, currentSlot: .integralIntegrand(id)) ??
                    findParentSlot(of: targetSlot, in: lower, currentSlot: .integralLower(id)) ??
                    findParentSlot(of: targetSlot, in: upper, currentSlot: .integralUpper(id)) {
                    return res
                }
            case .derivative(let id, let function, let point):
                if targetSlot == .derivativeFunction(id) || targetSlot == .derivativePoint(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: function, currentSlot: .derivativeFunction(id)) ??
                    findParentSlot(of: targetSlot, in: point, currentSlot: .derivativePoint(id)) {
                    return res
                }
            case .summation(let id, let expr, let lower, let upper):
                if targetSlot == .summationExpr(id) || targetSlot == .summationLower(id) || targetSlot == .summationUpper(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: expr, currentSlot: .summationExpr(id)) ??
                    findParentSlot(of: targetSlot, in: lower, currentSlot: .summationLower(id)) ??
                    findParentSlot(of: targetSlot, in: upper, currentSlot: .summationUpper(id)) {
                    return res
                }
            case .logBase(let id, let base, let arg):
                if targetSlot == .logBase(id) || targetSlot == .logArg(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: base, currentSlot: .logBase(id)) ??
                    findParentSlot(of: targetSlot, in: arg, currentSlot: .logArg(id)) {
                    return res
                }
            case .parens(let id, let children):
                if targetSlot == .parens(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: children, currentSlot: .parens(id)) {
                    return res
                }
            case .function(let id, _, let arg):
                if targetSlot == .functionArg(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: arg, currentSlot: .functionArg(id)) {
                    return res
                }
            case .mixedFraction(let id, let integer, let num, let den):
                if targetSlot == .mixedInteger(id) || targetSlot == .mixedNumerator(id) || targetSlot == .mixedDenominator(id) {
                    return ParentInfo(parentSlot: currentSlot, nodeIndexInParent: i)
                }
                if let res = findParentSlot(of: targetSlot, in: integer, currentSlot: .mixedInteger(id)) ??
                    findParentSlot(of: targetSlot, in: num, currentSlot: .mixedNumerator(id)) ??
                    findParentSlot(of: targetSlot, in: den, currentSlot: .mixedDenominator(id)) {
                    return res
                }
            case .dmsMark:
                break
            case .text:
                break
            }
        }
        return nil
    }

    // MARK: - Input Capacity
    //
    // The real fx-991ES PLUS has a limited expression buffer (roughly 99 display
    // characters / 79 key steps). Enforcing a comparable AST limit keeps input
    // responsive even if a key is held down and fires hundreds of times.

    public static let maxNodes = 160
    public static let maxDepth = 32

    private func countNodes(_ nodes: [MathNode]) -> Int {
        var total = 0
        for node in nodes {
            total += 1
            for child in node.childNodeArrays { total += countNodes(child) }
        }
        return total
    }

    private func depth(of nodes: [MathNode]) -> Int {
        var best = 0
        for node in nodes {
            var nodeDepth = 1
            for child in node.childNodeArrays {
                nodeDepth = Swift.max(nodeDepth, 1 + depth(of: child))
            }
            best = Swift.max(best, nodeDepth)
        }
        return best
    }

    public var nodeCount: Int { countNodes(root) }
    public var expressionDepth: Int { depth(of: root) }

    /// True when input capacity is nearly exhausted — the LCD cursor changes
    /// shape as a warning (fx-991ES: within roughly 10 bytes of the limit).
    public var isNearCapacity: Bool {
        nodeCount >= Self.maxNodes - 10 || expressionDepth >= Self.maxDepth - 2
    }

    /// True when the expression is as complex as this model allows. Input is
    /// ignored at that point; DEL / AC still work so the user can recover.
    public var isAtCapacity: Bool {
        nodeCount >= Self.maxNodes || expressionDepth >= Self.maxDepth
    }
}
