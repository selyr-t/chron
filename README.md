# chron

*chron* is a SwiftUI app that converts a base tempo (entered in BPM, Hz, milliseconds, or samples) into a wide range of subdivisions and multiples, and shows each one in every unit as a reference table. This is intended as a convenience for usersn needing tempo-relative conversions on hand for any musical or other general purpose audio tools (think: delay time, LFO rate, loop-windows). Users can set a custom divisor for the subdivisions and multiples, and choose the samplerate that the samples column is calculated at to match their current project.


## Features

- **Tempo Conversion into Separate Time Units:** The tempo can be entered in BPM, Hz, milliseconds, or samples. The selected unit is the first column, where each subsequent unit follows to the right. Additionally, when the user changes the unit, the program maintains the entered value so that the tempo stays the same (ex: $120 \text{ BPM}$ becomes $2 \text{ Hz}$).

- **Custom Samplerats:** A dropdown menu provides standard samplerates ($22050$, $44100$, $48000$, or $96000$) as well as the option for custom rates to be entered when "Other" is selected.

- **Custom Divisor:** The divisor sets the first step away from one bar, and every later step doubles. Decimal divisors such as 2.5 are also accepted. Examples are below:

  | Divisor | Shortest | | Below 1 bar | 1 bar | Above 1 bar | | Longest |
  |:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
  | 2 | $\frac{1}{1024}$ | $\cdots$ | $\frac{1}{2}$ | $1\times$ | $2\times$ | $\cdots$ | $512\times$ |
  | 3 | $\frac{1}{1536}$ | $\cdots$ | $\frac{1}{3}$ | $1\times$ | $3\times$ | $\cdots$ | $768\times$ |
  | 2.5 | $\frac{1}{1280}$ | $\cdots$ | $\frac{1}{2.5}$ | $1\times$ | $2.5\times$ | $\cdots$ | $640\times$ |

- **Triplet and Dot Modifiers:** Checkboxes allow for added beat conversion granularities by way of providing dotted (single, double, triple) and triplet options, both of which stack.
    - **Triplet** multiplies every duration by $\frac{2}{3}$
    - **Dotted, double dotted, and triple dotted** multiply by $1.5$, $1.75$, and $1.875$ respectively. *A triplet combines with any one dot count*.

- **Clean Table Formatting:** The table scrolls with the base tempo appearing highlighted at the center.

## How the values are calculated

Every column is computed from the length of a row in seconds. The entered tempo gives the length $T$ of one beat:

| Unit | Beat length $T$ (seconds) |
|---|---|
| BPM | $60 / \text{BPM}$ |
| Hz | $1 / f$ |
| ms | $\text{ms} / 1000$ |
| samples | $\text{samples} / f_s$ |

A row that lasts $b$ beats lasts $T \cdot b$ seconds, where $b$ includes the divisor, and when added by the user, the triplet and dot factors. Each column then converts that length back into its own unit.

At 120 BPM and 48 kHz sampling rate:

| Row | BPM | Hz | ms | samples |
|---|---|---|---|---|
| 1x (1 bar) | 30 | 0.5 | 2,000 | 96,000 |
| 1/4 (beat) | 120 | 2 | 500 | 24,000 |
| 1/8 | 240 | 4 | 250 | 12,000 |
| 1/4..T | 102.857 | 1.71429 | 583.333 | 28,000 |

## Assumptions

- The entered tempo is the quarter note, which is the standard convention for BPM.
- One bar is limited four beats (4/4) at the moment.

## Requirements

- Xcode 15 or later
- macOS 14.0 or later

## Building

1. Clone the repository and open `chron.xcodeproj` in Xcode.
2. Select the `chron` target, open Signing & Capabilities, and select a team. A free Apple Account appears as a Personal Team.
3. Select My Mac as the run destination, and choose Product > Run.

## Project structure

| File | Contents |
|---|---|
| `chronApp.swift` | The app entry point (`@main`). |
| `ContentView.swift` | The input fields, the menus, the checkboxes, and the table. |
| `TempoMath.swift` | `TempoUnit` (unit conversions), `NoteModifiers` (triplet and dots), and `Subdivision` (the rows of the table). |
