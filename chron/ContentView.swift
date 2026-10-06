import SwiftUI

struct ContentView: View {
    @State private var unit: TempoUnit = .bpm
    @State private var value: Double = 120
    /// A preset sample rate, or nil when "Other" is selected.
    @State private var presetRate: Int? = 48000
    @State private var customRate: Double = 48000
    @State private var modifiers = NoteModifiers()
    /// The first step away from 1 bar; every later step doubles. 2 gives binary note values.
    @State private var divisor: Double = 2

    private static let presetRates = [22050, 44100, 48000, 96000]

    private var sampleRate: Double {
        presetRate.map(Double.init) ?? customRate
    }

    private var isSampleRateValid: Bool {
        sampleRate.isFinite && sampleRate > 0
    }

    /// A divisor of 1 or less would put every "x" row at or below 1 bar, so it is rejected.
    private var isDivisorValid: Bool {
        divisor.isFinite && divisor > 1
    }

    private var invalidEntryMessage: LocalizedStringKey {
        if !isSampleRateValid { return "Enter a sample rate greater than zero" }
        if !isDivisorValid { return "Enter a divisor greater than 1" }
        return "Enter a tempo greater than zero"
    }

    /// The duration of the entered beat in seconds, or nil when the entry has no finite duration.
    private var period: Double? {
        guard value.isFinite, value > 0, isSampleRateValid, isDivisorValid else { return nil }
        return unit.period(from: value, sampleRate: sampleRate)
    }

    /// The selected unit first, then the other units to its right.
    private var columns: [TempoUnit] {
        [unit] + TempoUnit.allCases.filter { $0 != unit }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputBar
                modifierBar
                Divider()
                if let period {
                    table(period: period)
                } else {
                    ContentUnavailableView(invalidEntryMessage, systemImage: "metronome")
                }
            }
            .navigationTitle("chron")
            // A new unit restates the same tempo: 120 BPM becomes 2 Hz, not 120 Hz.
            .onChange(of: unit) { oldUnit, newUnit in
                guard value.isFinite, value > 0, isSampleRateValid else { return }
                let seconds = oldUnit.period(from: value, sampleRate: sampleRate)
                value = newUnit.value(fromPeriod: seconds, sampleRate: sampleRate)
            }
            // A new sample rate also keeps the tempo: 24,000 samples at 48 kHz becomes
            // 22,050 samples at 44.1 kHz. Only an entry in samples depends on the rate.
            .onChange(of: sampleRate) { oldRate, newRate in
                guard unit == .samples, value.isFinite, value > 0,
                      oldRate.isFinite, oldRate > 0, newRate.isFinite, newRate > 0
                else { return }
                value = value / oldRate * newRate
            }
        }
    }

    private var inputBar: some View {
        HStack {
            // The bound value updates while the person types, whenever the text parses as a number.
            TextField("Tempo", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                .keyboardType(.decimalPad)
                #endif
                .frame(maxWidth: 140)
            Picker("Unit", selection: $unit) {
                ForEach(TempoUnit.allCases) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize()

            Spacer()

            if presetRate == nil {
                TextField("Sample rate", value: $customRate, format: .number)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(maxWidth: 100)
            }
            Picker("Sample rate", selection: $presetRate) {
                ForEach(Self.presetRates, id: \.self) { rate in
                    Text("\(rate) Hz").tag(Optional(rate))
                }
                Text("Other").tag(Int?.none)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .fixedSize()
        }
        .padding([.horizontal, .top])
        .padding(.bottom, 8)
    }

    private var modifierBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Divisor")
                TextField("Divisor", value: $divisor, format: .number)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(maxWidth: 80)
                Spacer()
            }
            checkboxes
        }
        .padding([.horizontal, .bottom])
    }

    private var checkboxes: some View {
        // Adaptive columns place the four checkboxes on one line when the window is wide enough
        // and wrap them onto two lines on a phone.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), alignment: .leading)],
                  alignment: .leading, spacing: 8) {
            Toggle("Triplet", isOn: $modifiers.isTriplet)
            Toggle("Dotted", isOn: dotBinding(1))
            Toggle("Double dotted", isOn: dotBinding(2))
            Toggle("Triple dotted", isOn: dotBinding(3))
        }
        .toggleStyle(CheckboxStyle())
    }

    /// Checking a dot count replaces any other dot count; unchecking it removes the dots.
    private func dotBinding(_ count: Int) -> Binding<Bool> {
        Binding(
            get: { modifiers.dots == count },
            set: { isOn in
                if isOn {
                    modifiers.dots = count
                } else if modifiers.dots == count {
                    modifiers.dots = 0
                }
            })
    }

    private func table(period: Double) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    row(label: Text("Division"),
                        cells: columns.map { Text($0.rawValue) },
                        isBeat: false)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Divider()
                    ForEach(Subdivision.ladder(divisor: divisor)) { subdivision in
                        let seconds = period * Subdivision.beatsPerBar * subdivision.bars
                            * modifiers.factor
                        row(label: label(for: subdivision),
                            cells: columns.map { column in
                                Text(column.value(fromPeriod: seconds, sampleRate: sampleRate),
                                     format: column.displayFormat)
                            },
                            isBeat: subdivision.isBeat)
                            .id(subdivision.id)
                    }
                }
            }
            #if os(iOS)
            .scrollDismissesKeyboard(.interactively)
            #endif
            .onAppear { proxy.scrollTo(Subdivision.beatID, anchor: .center) }
            .onChange(of: unit) { proxy.scrollTo(Subdivision.beatID, anchor: .center) }
            .onChange(of: divisor) { proxy.scrollTo(Subdivision.beatID, anchor: .center) }
        }
    }

    @ViewBuilder
    private func label(for subdivision: Subdivision) -> some View {
        let text = Text(subdivision.label + modifiers.suffix)
        if let caption = subdivision.caption {
            HStack(spacing: 6) {
                text
                Text(caption).font(.caption).foregroundStyle(.secondary)
            }
        } else {
            text
        }
    }

    /// One table row. The label column has a fixed width and the value columns share the
    /// remaining width equally, so that the columns align from row to row.
    private func row(label: some View, cells: [Text], isBeat: Bool) -> some View {
        HStack(spacing: 12) {
            label
                .frame(width: 110, alignment: .leading)
            ForEach(cells.indices, id: \.self) { index in
                cells[index]
                    .monospacedDigit()
                    .fontWeight(index == 0 ? .semibold : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isBeat ? Color.accentColor.opacity(0.18) : Color.clear)
    }
}

/// A checkbox that draws the same on iPhone and on the Mac. SwiftUI's own checkbox style
/// exists only on macOS.
struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? Color.accentColor : Color.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
