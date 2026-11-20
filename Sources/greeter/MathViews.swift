import SwiftUI

// MARK: - Superscript-aware linear math text

/// Renders a linear math string the way the fx-991ES LCD does: exponent
/// notation written internally with `^` is drawn as a raised, smaller glyph
/// instead of a literal caret (e.g. `1.23×10^5` → 1.23×10⁵, `A·B^X` → A·Bˣ).
///
/// The `^` character is kept in the stored expression because the evaluator
/// relies on it; only the *display* converts it to true superscript form.
public struct MathText: View {
    public let text: String
    public let fontSize: CGFloat
    public let weight: Font.Weight
    public let design: Font.Design
    public let color: Color

    public init(
        _ text: String,
        fontSize: CGFloat = 16,
        weight: Font.Weight = .semibold,
        design: Font.Design = .monospaced,
        color: Color? = nil
    ) {
        self.text = text
        self.fontSize = fontSize
        self.weight = weight
        self.design = design
        self.color = color ?? CasioTheme.lcdTextActive
    }

    private struct Piece {
        let content: String
        let isSuperscript: Bool
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(Self.parse(text).enumerated()), id: \.offset) { _, piece in
                Text(piece.content)
                    .font(.system(
                        size: piece.isSuperscript ? fontSize * 0.72 : fontSize,
                        weight: weight,
                        design: design
                    ))
                    .offset(y: piece.isSuperscript ? -fontSize * 0.34 : 0)
            }
        }
        // Hug the text like Text does, so a surrounding Spacer can push the
        // result to the right edge of the LCD (as on the fx-991ES).
        .fixedSize()
        .foregroundColor(color)
    }

    /// Split a linear expression into normal and raised pieces, consuming the
    /// caret. Handles `10^3`, `X^2`, `×10^-5`, `(MatA)^(-1)` and a bare `×10^`
    /// (rendered with an empty superscript box while the exponent is pending).
    private static func parse(_ text: String) -> [Piece] {
        var pieces: [Piece] = []
        var normal = ""
        let chars = Array(text)
        var i = 0

        func flushNormal() {
            if !normal.isEmpty {
                pieces.append(Piece(content: normal, isSuperscript: false))
                normal = ""
            }
        }

        while i < chars.count {
            guard chars[i] == "^" else {
                normal.append(chars[i])
                i += 1
                continue
            }

            flushNormal()
            i += 1 // consume the caret — it is never shown on the LCD

            var exponent = ""
            if i < chars.count && chars[i] == "(" {
                // Parenthesized exponent: keep inner grouping, drop the outer pair.
                var depth = 0
                var collected = ""
                while i < chars.count {
                    let c = chars[i]
                    if c == "(" {
                        depth += 1
                        if depth > 1 { collected.append(c) }
                    } else if c == ")" {
                        depth -= 1
                        if depth == 0 { i += 1; break }
                        collected.append(c)
                    } else {
                        collected.append(c)
                    }
                    i += 1
                }
                exponent = collected
            } else {
                if i < chars.count && (chars[i] == "-" || chars[i] == "−" || chars[i] == "+") {
                    exponent.append(chars[i] == "-" ? "−" : chars[i])
                    i += 1
                }
                while i < chars.count && (chars[i].isNumber || chars[i].isLetter || chars[i] == ".") {
                    exponent.append(chars[i])
                    i += 1
                }
            }

            pieces.append(Piece(content: exponent.isEmpty ? "□" : exponent, isSuperscript: true))
        }

        flushNormal()
        return pieces
    }
}

// MARK: - Recursive Math AST LCD View

public struct MathASTView: View {
    public let nodes: [MathNode]
    public let slot: MathSlotID
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?
    public let isNearCapacity: Bool

    public init(
        nodes: [MathNode],
        slot: MathSlotID = .root,
        cursor: CursorPath? = nil,
        fontSize: CGFloat = 16,
        showCursor: Bool = true,
        isNearCapacity: Bool = false,
        onCursorMove: ((CursorPath) -> Void)? = nil
    ) {
        self.nodes = nodes
        self.slot = slot
        self.cursor = cursor
        self.fontSize = fontSize
        self.showCursor = showCursor
        self.isNearCapacity = isNearCapacity
        self.onCursorMove = onCursorMove
    }

    private var isSlotFocused: Bool {
        cursor?.slot == slot
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 1) {
            if nodes.isEmpty {
                // Empty placeholder slot
                emptySlotPlaceholder
            } else {
                ForEach(0..<nodes.count, id: \.self) { i in
                    // Cursor before this node
                    if showCursor && isSlotFocused && cursor?.index == i {
                        cursorBar
                    }

                    tappableNode(nodeView(for: nodes[i]), at: i)
                }

                // Cursor at end of slot
                if showCursor && isSlotFocused && cursor?.index == nodes.count {
                    cursorBar
                }
            }
        }
        // Hug the expression instead of filling the offered width. Without
        // this, a surrounding ScrollView / full-width frame stretches the
        // fraction vinculum (and radical overline) across the whole LCD.
        .fixedSize()
    }

    /// Adds two invisible hit targets over a node so a tap on its left half
    /// places the cursor before it and a tap on its right half after it.
    @ViewBuilder
    private func tappableNode<Content: View>(_ content: Content, at index: Int) -> some View {
        content
            .contentShape(Rectangle())
            .background(
                GeometryReader { _ in
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { onCursorMove?(CursorPath(slot: slot, index: index)) }
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { onCursorMove?(CursorPath(slot: slot, index: index + 1)) }
                    }
                }
            )
    }

    @ViewBuilder
    private var emptySlotPlaceholder: some View {
        ZStack {
            if slot != .root {
                // Empty template slots are drawn as solid, clearly visible boxes
                // on the fx-991ES LCD (fraction, Σ, ∫, radicals, etc.). The old
                // 16%-opacity dashed outline made the unfocused Σ limit fields
                // invisible, so the template appeared to be missing fields.
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(
                        CasioTheme.lcdTextActive.opacity(isSlotFocused ? 1.0 : 0.7),
                        lineWidth: 1
                    )
                    .frame(width: max(9, fontSize * 0.9), height: max(11, fontSize * 1.05))
            }

            if showCursor && isSlotFocused {
                cursorBar
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onCursorMove?(CursorPath(slot: slot, index: 0)) }
    }

    private var cursorBar: some View {
        Rectangle()
            .fill(CasioTheme.lcdTextActive)
            .frame(width: isNearCapacity ? 5 : 1.6, height: fontSize + 2)
    }

    @ViewBuilder
    private func nodeView(for node: MathNode) -> some View {
        switch node {
        case .text(_, let content):
            MathText(content, fontSize: fontSize, weight: .semibold)

        case .fraction(let id, let num, let den):
            FractionNodeView(
                id: id,
                num: num,
                den: den,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .exponent(let id, let base, let power):
            ExponentNodeView(
                id: id,
                base: base,
                power: power,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .radical(let id, let index, let radicand):
            RadicalNodeView(
                id: id,
                index: index,
                radicand: radicand,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .derivative(let id, let function, let point):
            DerivativeNodeView(
                id: id,
                function: function,
                point: point,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove,
                isNearCapacity: isNearCapacity
            )

        case .integral(let id, let integrand, let lower, let upper):
            IntegralNodeView(
                id: id,
                integrand: integrand,
                lower: lower,
                upper: upper,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .summation(let id, let expr, let lower, let upper):
            SummationNodeView(
                id: id,
                expr: expr,
                lower: lower,
                upper: upper,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .logBase(let id, let base, let arg):
            LogBaseNodeView(
                id: id,
                base: base,
                arg: arg,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .parens(let id, let children):
            ParensNodeView(
                id: id,
                children: children,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .function(let id, let name, let arg):
            FunctionNodeView(
                id: id,
                name: name,
                arg: arg,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

        case .dmsMark(_, let glyph):
            // Sexagesimal marker rendered positionally as °, ' or "
            Text(glyph)
                .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
                .foregroundColor(CasioTheme.lcdTextActive)

        case .mixedFraction(let id, let integer, let num, let den):
            MixedFractionNodeView(
                id: id,
                integer: integer,
                num: num,
                den: den,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )
        }
    }
}

// MARK: - Mixed Fraction View (SHIFT + a b/c template)

public struct MixedFractionNodeView: View {
    public let id: UUID
    public let integer: [MathNode]
    public let num: [MathNode]
    public let den: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(alignment: .bottom, spacing: 1) {
            // Integer part
            MathASTView(
                nodes: integer,
                slot: .mixedInteger(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

            // Stacked proper fraction
            VStack(spacing: 2) {
                MathASTView(
                    nodes: num,
                    slot: .mixedNumerator(id),
                    cursor: cursor,
                    fontSize: fontSize * 0.88,
                    showCursor: showCursor,
                    onCursorMove: onCursorMove
                )

                Rectangle()
                    .fill(CasioTheme.lcdTextActive)
                    .frame(height: 1.4)

                MathASTView(
                    nodes: den,
                    slot: .mixedDenominator(id),
                    cursor: cursor,
                    fontSize: fontSize * 0.88,
                    showCursor: showCursor,
                    onCursorMove: onCursorMove
                )
            }
            .padding(.horizontal, 1.5)
            .fixedSize()
        }
        .fixedSize()
    }
}

// MARK: - Fraction View

public struct FractionNodeView: View {
    public let id: UUID
    public let num: [MathNode]
    public let den: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        VStack(spacing: 2) {
            // Numerator
            MathASTView(
                nodes: num,
                slot: .fractionNumerator(id),
                cursor: cursor,
                fontSize: fontSize * 0.88,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

            // Horizontal division vinculum
            Rectangle()
                .fill(CasioTheme.lcdTextActive)
                .frame(height: 1.4)

            // Denominator
            MathASTView(
                nodes: den,
                slot: .fractionDenominator(id),
                cursor: cursor,
                fontSize: fontSize * 0.88,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )
        }
        .padding(.horizontal, 1.5)
        .fixedSize()
    }
}

// MARK: - Exponent View

public struct ExponentNodeView: View {
    public let id: UUID
    public let base: [MathNode]
    public let power: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(alignment: .top, spacing: 0.5) {
            // Base
            MathASTView(
                nodes: base,
                slot: .exponentBase(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

            // Power (elevated and scaled down)
            MathASTView(
                nodes: power,
                slot: .exponentPower(id),
                cursor: cursor,
                fontSize: fontSize * 0.72,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )
            .offset(y: -fontSize * 0.38)
        }
    }
}

// MARK: - Radical View

public struct RadicalNodeView: View {
    public let id: UUID
    public let index: [MathNode]?
    public let radicand: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Root index (if nth root)
            if let index = index {
                MathASTView(
                    nodes: index,
                    slot: .radicalIndex(id),
                    cursor: cursor,
                    fontSize: fontSize * 0.62,
                    showCursor: showCursor,
                    onCursorMove: onCursorMove
                )
                .offset(y: -fontSize * 0.42)
            }

            // Radical hook symbol
            Text("√")
                .font(.system(size: fontSize * 1.15, weight: .light))
                .foregroundColor(CasioTheme.lcdTextActive)
                .offset(y: 0.5)

            // Overhead horizontal vinculum bar covering the radicand
            VStack(spacing: 0) {
                Rectangle()
                    .fill(CasioTheme.lcdTextActive)
                    .frame(height: 1.3)

                MathASTView(
                    nodes: radicand,
                    slot: .radicalRadicand(id),
                    cursor: cursor,
                    fontSize: fontSize,
                    showCursor: showCursor,
                    onCursorMove: onCursorMove
                )
                .padding(.horizontal, 1)
            }
            .fixedSize()
        }
        .fixedSize()
    }
}

// MARK: - Derivative View

/// SHIFT + ∫ numerical derivative template: d/dx(function)|point.
public struct DerivativeNodeView: View {
    public let id: UUID
    public let function: [MathNode]
    public let point: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?
    public let isNearCapacity: Bool

    public var body: some View {
        HStack(alignment: .center, spacing: 2) {
            VStack(spacing: 0) {
                Text("d")
                    .font(.system(size: fontSize * 0.62, weight: .semibold))
                Rectangle()
                    .fill(CasioTheme.lcdTextActive)
                    .frame(width: fontSize * 0.7, height: 1)
                Text("dx")
                    .font(.system(size: fontSize * 0.62, weight: .semibold))
            }
            Text("(")
                .font(.system(size: fontSize, weight: .light))
            MathASTView(
                nodes: function,
                slot: .derivativeFunction(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                isNearCapacity: isNearCapacity,
                onCursorMove: onCursorMove
            )
            Text(")")
                .font(.system(size: fontSize, weight: .light))
            Text("|")
                .font(.system(size: fontSize * 1.2, weight: .light))
            MathASTView(
                nodes: point,
                slot: .derivativePoint(id),
                cursor: cursor,
                fontSize: fontSize * 0.8,
                showCursor: showCursor,
                isNearCapacity: isNearCapacity,
                onCursorMove: onCursorMove
            )
        }
        .foregroundColor(CasioTheme.lcdTextActive)
        .fixedSize()
    }
}

// MARK: - Integral View

public struct IntegralNodeView: View {
    public let id: UUID
    public let integrand: [MathNode]
    public let lower: [MathNode]
    public let upper: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(spacing: 2) {
            // Integral symbol with upper/lower bounds
            HStack(spacing: 1) {
                Text("∫")
                    .font(.system(size: fontSize * 1.3, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(CasioTheme.lcdTextActive)

                VStack(alignment: .leading, spacing: 2) {
                    MathASTView(
                        nodes: upper,
                        slot: .integralUpper(id),
                        cursor: cursor,
                        fontSize: fontSize * 0.65,
                        showCursor: showCursor,
                        onCursorMove: onCursorMove
                    )
                    Spacer(minLength: 0)
                    MathASTView(
                        nodes: lower,
                        slot: .integralLower(id),
                        cursor: cursor,
                        fontSize: fontSize * 0.65,
                        showCursor: showCursor,
                        onCursorMove: onCursorMove
                    )
                }
                .frame(height: fontSize * 1.5)
            }

            // Integrand
            MathASTView(
                nodes: integrand,
                slot: .integralIntegrand(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

            Text("dx")
                .font(.system(size: fontSize * 0.85, weight: .medium, design: .serif))
                .italic()
                .foregroundColor(CasioTheme.lcdTextActive)
        }
    }
}

// MARK: - Summation View

public struct SummationNodeView: View {
    public let id: UUID
    public let expr: [MathNode]
    public let lower: [MathNode]
    public let upper: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(spacing: 2) {
            VStack(spacing: 1) {
                // Upper limit
                MathASTView(
                    nodes: upper,
                    slot: .summationUpper(id),
                    cursor: cursor,
                    fontSize: fontSize * 0.65,
                    showCursor: showCursor,
                    onCursorMove: onCursorMove
                )

                Text("Σ")
                    .font(.system(size: fontSize * 1.15, weight: .bold))
                    .foregroundColor(CasioTheme.lcdTextActive)

                // Lower limit
                MathASTView(
                    nodes: lower,
                    slot: .summationLower(id),
                    cursor: cursor,
                    fontSize: fontSize * 0.65,
                    showCursor: showCursor,
                    onCursorMove: onCursorMove
                )
            }

            // Expression
            MathASTView(
                nodes: expr,
                slot: .summationExpr(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )
        }
    }
}

// MARK: - LogBase View

public struct LogBaseNodeView: View {
    public let id: UUID
    public let base: [MathNode]
    public let arg: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(alignment: .bottom, spacing: 1) {
            Text("log")
                .font(.system(size: fontSize * 0.9, weight: .semibold))
                .foregroundColor(CasioTheme.lcdTextActive)

            // Subscript base
            MathASTView(
                nodes: base,
                slot: .logBase(id),
                cursor: cursor,
                fontSize: fontSize * 0.68,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )
            .offset(y: 2)

            // Argument inside parens
            Text("(")
                .font(.system(size: fontSize, weight: .light))
                .foregroundColor(CasioTheme.lcdTextActive)
            MathASTView(
                nodes: arg,
                slot: .logArg(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )
            Text(")")
                .font(.system(size: fontSize, weight: .light))
                .foregroundColor(CasioTheme.lcdTextActive)
        }
    }
}

// MARK: - Parens View

public struct ParensNodeView: View {
    public let id: UUID
    public let children: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(spacing: 1) {
            Text("(")
                .font(.system(size: fontSize * 1.05, weight: .light))
                .foregroundColor(CasioTheme.lcdTextActive)

            MathASTView(
                nodes: children,
                slot: .parens(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

            Text(")")
                .font(.system(size: fontSize * 1.05, weight: .light))
                .foregroundColor(CasioTheme.lcdTextActive)
        }
    }
}

// MARK: - Function View

public struct FunctionNodeView: View {
    public let id: UUID
    public let name: String
    public let arg: [MathNode]
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool
    public let onCursorMove: ((CursorPath) -> Void)?

    public var body: some View {
        HStack(spacing: 1) {
            Text("\(name)(")
                .font(.system(size: fontSize * 0.92, weight: .semibold))
                .foregroundColor(CasioTheme.lcdTextActive)

            MathASTView(
                nodes: arg,
                slot: .functionArg(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor,
                onCursorMove: onCursorMove
            )

            Text(")")
                .font(.system(size: fontSize * 0.92, weight: .semibold))
                .foregroundColor(CasioTheme.lcdTextActive)
        }
    }
}

// MARK: - Matrix Result Display

/// Matrix result rendered as the bracketed grid the fx-991ES shows after a
/// matrix calculation:  [1  2]
///                      [3  4]
public struct MatrixResultView: View {
    public let matrix: Matrix

    public init(matrix: Matrix) {
        self.matrix = matrix
    }

    public var body: some View {
        let large = matrix.rows > 2 || matrix.cols > 2
        let size: CGFloat = large ? 11 : 14
        return VStack(alignment: .trailing, spacing: 1) {
            ForEach(0..<max(1, matrix.rows), id: \.self) { r in
                HStack(spacing: 6) {
                    Text("[")
                    ForEach(0..<max(1, matrix.cols), id: \.self) { c in
                        Text(CasioEvaluator.format(matrix.elements[r][c], format: .norm))
                            .frame(minWidth: 18, alignment: .center)
                    }
                    Text("]")
                }
            }
        }
        .font(.system(size: size, weight: .semibold, design: .monospaced))
        .foregroundColor(CasioTheme.lcdTextActive)
        .lineLimit(1)
        .minimumScaleFactor(0.4)
    }
}
