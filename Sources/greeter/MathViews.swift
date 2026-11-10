import SwiftUI

// MARK: - Recursive Math AST LCD View

public struct MathASTView: View {
    public let nodes: [MathNode]
    public let slot: MathSlotID
    public let cursor: CursorPath?
    public let fontSize: CGFloat
    public let showCursor: Bool

    public init(
        nodes: [MathNode],
        slot: MathSlotID = .root,
        cursor: CursorPath? = nil,
        fontSize: CGFloat = 16,
        showCursor: Bool = true
    ) {
        self.nodes = nodes
        self.slot = slot
        self.cursor = cursor
        self.fontSize = fontSize
        self.showCursor = showCursor
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

                    nodeView(for: nodes[i])
                }

                // Cursor at end of slot
                if showCursor && isSlotFocused && cursor?.index == nodes.count {
                    cursorBar
                }
            }
        }
    }

    @ViewBuilder
    private var emptySlotPlaceholder: some View {
        ZStack {
            if slot != .root {
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(
                        isSlotFocused ? CasioTheme.lcdTextActive : CasioTheme.lcdTextDim,
                        style: StrokeStyle(lineWidth: 1, dash: [2, 1.5])
                    )
                    .frame(width: max(8, fontSize * 0.75), height: max(10, fontSize * 0.9))
            }

            if showCursor && isSlotFocused {
                cursorBar
            }
        }
    }

    private var cursorBar: some View {
        Rectangle()
            .fill(CasioTheme.lcdTextActive)
            .frame(width: 1.6, height: fontSize + 2)
    }

    @ViewBuilder
    private func nodeView(for node: MathNode) -> some View {
        switch node {
        case .text(_, let content):
            Text(content)
                .font(.system(size: fontSize, weight: .semibold, design: .monospaced))
                .foregroundColor(CasioTheme.lcdTextActive)

        case .fraction(let id, let num, let den):
            FractionNodeView(
                id: id,
                num: num,
                den: den,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

        case .exponent(let id, let base, let power):
            ExponentNodeView(
                id: id,
                base: base,
                power: power,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

        case .radical(let id, let index, let radicand):
            RadicalNodeView(
                id: id,
                index: index,
                radicand: radicand,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

        case .integral(let id, let integrand, let lower, let upper):
            IntegralNodeView(
                id: id,
                integrand: integrand,
                lower: lower,
                upper: upper,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

        case .summation(let id, let expr, let lower, let upper):
            SummationNodeView(
                id: id,
                expr: expr,
                lower: lower,
                upper: upper,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

        case .logBase(let id, let base, let arg):
            LogBaseNodeView(
                id: id,
                base: base,
                arg: arg,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

        case .parens(let id, let children):
            ParensNodeView(
                id: id,
                children: children,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

        case .function(let id, let name, let arg):
            FunctionNodeView(
                id: id,
                name: name,
                arg: arg,
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )
        }
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

    public var body: some View {
        VStack(spacing: 2) {
            // Numerator
            MathASTView(
                nodes: num,
                slot: .fractionNumerator(id),
                cursor: cursor,
                fontSize: fontSize * 0.88,
                showCursor: showCursor
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
                showCursor: showCursor
            )
        }
        .padding(.horizontal, 1.5)
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

    public var body: some View {
        HStack(alignment: .top, spacing: 0.5) {
            // Base
            MathASTView(
                nodes: base,
                slot: .exponentBase(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
            )

            // Power (elevated and scaled down)
            MathASTView(
                nodes: power,
                slot: .exponentPower(id),
                cursor: cursor,
                fontSize: fontSize * 0.72,
                showCursor: showCursor
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

    public var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Root index (if nth root)
            if let index = index {
                MathASTView(
                    nodes: index,
                    slot: .radicalIndex(id),
                    cursor: cursor,
                    fontSize: fontSize * 0.62,
                    showCursor: showCursor
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
                    showCursor: showCursor
                )
                .padding(.horizontal, 1)
            }
        }
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
                        showCursor: showCursor
                    )
                    Spacer(minLength: 0)
                    MathASTView(
                        nodes: lower,
                        slot: .integralLower(id),
                        cursor: cursor,
                        fontSize: fontSize * 0.65,
                        showCursor: showCursor
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
                showCursor: showCursor
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

    public var body: some View {
        HStack(spacing: 2) {
            VStack(spacing: 1) {
                // Upper limit
                MathASTView(
                    nodes: upper,
                    slot: .summationUpper(id),
                    cursor: cursor,
                    fontSize: fontSize * 0.65,
                    showCursor: showCursor
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
                    showCursor: showCursor
                )
            }

            // Expression
            MathASTView(
                nodes: expr,
                slot: .summationExpr(id),
                cursor: cursor,
                fontSize: fontSize,
                showCursor: showCursor
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
                showCursor: showCursor
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
                showCursor: showCursor
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
                showCursor: showCursor
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
                showCursor: showCursor
            )

            Text(")")
                .font(.system(size: fontSize * 0.92, weight: .semibold))
                .foregroundColor(CasioTheme.lcdTextActive)
        }
    }
}
