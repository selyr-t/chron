import Foundation

/// The four ways to state a tempo. Each unit converts to and from the duration of one beat in
/// seconds, so that every column is computed from the same duration. Only `samples` uses the
/// sample rate.
enum TempoUnit: String, CaseIterable, Identifiable {
    case bpm = "BPM"
    case hertz = "Hz"
    case milliseconds = "ms"
    case samples = "samples"

    var id: Self { self }

    /// The duration of one beat, in seconds, for a tempo stated in this unit.
    func period(from value: Double, sampleRate: Double) -> Double {
        switch self {
        case .bpm: 60 / value
        case .hertz: 1 / value
        case .milliseconds: value / 1000
        case .samples: value / sampleRate
        }
    }

    /// The tempo in this unit for a beat that lasts `seconds`.
    func value(fromPeriod seconds: Double, sampleRate: Double) -> Double {
        switch self {
        case .bpm: 60 / seconds
        case .hertz: 1 / seconds
        case .milliseconds: seconds * 1000
        case .samples: seconds * sampleRate
        }
    }

    /// Sample counts show every whole sample and up to two decimal places, because a delay
    /// line is set in whole or fractional samples. The other units show at most six significant
    /// digits, because their values span from about 0.001 to about 1,000,000.
    var displayFormat: FloatingPointFormatStyle<Double> {
        self == .samples
            ? .number.precision(.fractionLength(0...2))
            : .number.precision(.significantDigits(1...6))
    }
}

/// Triplet and dot modifiers. A triplet fits three notes into the time of two, so it multiplies
/// a duration by 2/3. A note with n dots lasts 2 - 2^-n times its plain value: 1.5 for one dot,
/// 1.75 for two, and 1.875 for three. The dot counts exclude one another, because a note carries
/// one number of dots; a triplet combines with any of them.
struct NoteModifiers: Equatable {
    var isTriplet = false
    /// 0 to 3.
    var dots = 0

    var factor: Double {
        let dotFactor = 2 - Double(sign: .plus, exponent: -dots, significand: 1)
        return (isTriplet ? 2.0 / 3.0 : 1) * dotFactor
    }

    /// "." for each dot and "T" for a triplet, as in "1/4..T" for a double-dotted triplet quarter.
    var suffix: String {
        String(repeating: ".", count: dots) + (isTriplet ? "T" : "")
    }
}

/// One row of the table. Rows are measured in bars of 4/4: 1 bar is four beats, and the entered
/// tempo is the beat, a quarter of a bar.
struct Subdivision: Identifiable {
    enum Kind {
        case bar
        case beat
        case step
    }

    /// The row's duration as a fraction or multiple of one bar.
    let bars: Double
    let kind: Kind
    let label: String

    /// The row's duration as a fraction or multiple of one bar is unique within a table, so it
    /// identifies the row.
    var id: Double { bars }

    var isBeat: Bool { kind == .beat }

    var caption: String? {
        switch kind {
        case .bar: "1 bar"
        case .beat: "beat"
        case .step: nil
        }
    }

    static let beatsPerBar = 4.0
    static let beatID = 1 / beatsPerBar

    /// With the default divisor of 2, nine rows above 1 bar reach 512x and ten rows below it reach
    /// 1/1024, which is the range of the original table.
    static let stepsAbove = 9
    static let stepsBelow = 10

    /// The ladder for `divisor` N: N, 2N, 4N ... bars above 1 bar, and 1/N, 1/2N, 1/4N ... of a bar
    /// below it, longest first. The first step away from 1 bar is N and every later step doubles, so
    /// N = 3 gives 3x, 6x, 12x and N = 2.5 gives 1/2.5, 1/5, 1/10. N = 2 gives the binary note values.
    /// The beat row (1/4) is added when the ladder does not already contain it, so that the entered
    /// tempo always has a row.
    static func ladder(divisor: Double) -> [Subdivision] {
        var rows = [Subdivision(bars: 1, kind: .bar, label: "1x")]
        for n in 0..<stepsAbove {
            let multiple = divisor * Double(sign: .plus, exponent: n, significand: 1)
            rows.append(Subdivision(bars: multiple, kind: .step, label: format(multiple) + "x"))
        }
        for n in 0..<stepsBelow {
            let denominator = divisor * Double(sign: .plus, exponent: n, significand: 1)
            rows.append(Subdivision(bars: 1 / denominator, kind: .step,
                                    label: "1/" + format(denominator)))
        }
        if let index = rows.firstIndex(where: { isSameDuration($0.bars, beatID) }) {
            rows[index] = Subdivision(bars: beatID, kind: .beat, label: rows[index].label)
        } else {
            rows.append(Subdivision(bars: beatID, kind: .beat, label: "1/4"))
        }
        return rows.sorted { $0.bars > $1.bars }
    }

    /// Up to three decimal places and no thousands separator, so that labels read "1/2.5" and "640x".
    private static func format(_ number: Double) -> String {
        number.formatted(.number.precision(.fractionLength(0...3)).grouping(.never))
    }

    /// A relative comparison, because 1/N computed for some N differs from 0.25 in the last bit.
    private static func isSameDuration(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) <= 1e-12 * max(abs(a), abs(b))
    }
}
