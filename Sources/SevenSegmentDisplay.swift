import SwiftUI

// MARK: - Seven Segment Display

/// Renders a string of digits and colons as a realistic 7-segment LED display.
/// Inactive segments are drawn faintly to mimic real hardware.

struct SevenSegmentDisplay: View {
    let text: String
    let digitHeight: CGFloat
    let activeColor: Color
    let inactiveColor: Color

    init(
        _ text: String,
        height: CGFloat = 70,
        activeColor: Color = Color(red: 0.2, green: 1.0, blue: 0.2),
        inactiveColor: Color = Color(red: 0.04, green: 0.12, blue: 0.04)
    ) {
        self.text = text
        self.digitHeight = height
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    var body: some View {
        HStack(spacing: digitHeight * 0.1) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, char in
                if char == ":" {
                    colonView
                } else if let digit = Int(String(char)) {
                    digitView(digit)
                }
            }
        }
    }

    private func digitView(_ digit: Int) -> some View {
        DigitCanvas(
            digit: digit,
            activeColor: activeColor,
            inactiveColor: inactiveColor
        )
        .frame(width: digitHeight * 0.55, height: digitHeight)
    }

    private var colonView: some View {
        let dotSize = digitHeight * 0.12
        return VStack(spacing: digitHeight * 0.22) {
            RoundedRectangle(cornerRadius: 2)
                .fill(activeColor)
                .frame(width: dotSize, height: dotSize)
            RoundedRectangle(cornerRadius: 2)
                .fill(activeColor)
                .frame(width: dotSize, height: dotSize)
        }
        .frame(width: dotSize + 4, height: digitHeight)
    }
}

// MARK: - Single Digit Canvas

/// Draws one 7-segment digit using Canvas paths with classic pointed/chamfered ends.
///
/// Segment layout:
///    aaa
///   f   b
///   f   b
///    ggg
///   e   c
///   e   c
///    ddd

struct DigitCanvas: View {
    let digit: Int
    let activeColor: Color
    let inactiveColor: Color

    //                         a      b      c      d      e      f      g
    private static let patterns: [[Bool]] = [
        /* 0 */ [true,  true,  true,  true,  true,  true,  false],
        /* 1 */ [false, true,  true,  false, false, false, false],
        /* 2 */ [true,  true,  false, true,  true,  false, true ],
        /* 3 */ [true,  true,  true,  true,  false, false, true ],
        /* 4 */ [false, true,  true,  false, false, true,  true ],
        /* 5 */ [true,  false, true,  true,  false, true,  true ],
        /* 6 */ [true,  false, true,  true,  true,  true,  true ],
        /* 7 */ [true,  true,  true,  false, false, false, false],
        /* 8 */ [true,  true,  true,  true,  true,  true,  true ],
        /* 9 */ [true,  true,  true,  true,  false, true,  true ],
    ]

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let t = h * 0.11
            let gap = h * 0.03
            let halfH = h / 2

            let seg = Self.patterns[min(digit, 9)]

            // a — top horizontal
            drawH(ctx: context, x: gap + t * 0.4, y: 0,
                  width: w - 2 * gap - t * 0.8, t: t, on: seg[0])

            // b — top-right vertical
            drawV(ctx: context, x: w - t, y: gap + t * 0.4,
                  height: halfH - 2 * gap - t * 0.2, t: t, on: seg[1])

            // c — bottom-right vertical
            drawV(ctx: context, x: w - t, y: halfH + gap,
                  height: halfH - 2 * gap - t * 0.2, t: t, on: seg[2])

            // d — bottom horizontal
            drawH(ctx: context, x: gap + t * 0.4, y: h - t,
                  width: w - 2 * gap - t * 0.8, t: t, on: seg[3])

            // e — bottom-left vertical
            drawV(ctx: context, x: 0, y: halfH + gap,
                  height: halfH - 2 * gap - t * 0.2, t: t, on: seg[4])

            // f — top-left vertical
            drawV(ctx: context, x: 0, y: gap + t * 0.4,
                  height: halfH - 2 * gap - t * 0.2, t: t, on: seg[5])

            // g — middle horizontal
            drawH(ctx: context, x: gap + t * 0.4, y: halfH - t / 2,
                  width: w - 2 * gap - t * 0.8, t: t, on: seg[6])
        }
    }

    /// Horizontal segment with pointed (hexagonal) ends
    private func drawH(ctx: GraphicsContext, x: CGFloat, y: CGFloat,
                       width: CGFloat, t: CGFloat, on: Bool) {
        let ht = t / 2
        var p = Path()
        p.move(to:    CGPoint(x: x,              y: y + ht))
        p.addLine(to: CGPoint(x: x + ht,         y: y))
        p.addLine(to: CGPoint(x: x + width - ht, y: y))
        p.addLine(to: CGPoint(x: x + width,       y: y + ht))
        p.addLine(to: CGPoint(x: x + width - ht, y: y + t))
        p.addLine(to: CGPoint(x: x + ht,         y: y + t))
        p.closeSubpath()
        ctx.fill(p, with: .color(on ? activeColor : inactiveColor))
    }

    /// Vertical segment with pointed (hexagonal) ends
    private func drawV(ctx: GraphicsContext, x: CGFloat, y: CGFloat,
                       height: CGFloat, t: CGFloat, on: Bool) {
        let ht = t / 2
        var p = Path()
        p.move(to:    CGPoint(x: x + ht, y: y))
        p.addLine(to: CGPoint(x: x + t,  y: y + ht))
        p.addLine(to: CGPoint(x: x + t,  y: y + height - ht))
        p.addLine(to: CGPoint(x: x + ht, y: y + height))
        p.addLine(to: CGPoint(x: x,      y: y + height - ht))
        p.addLine(to: CGPoint(x: x,      y: y + ht))
        p.closeSubpath()
        ctx.fill(p, with: .color(on ? activeColor : inactiveColor))
    }
}
