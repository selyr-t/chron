import SwiftUI
//-------------------------------------------------------------------------------------------------------------------
// This script is for a splash screen that is shown for a set `duration` before the main window of the program opens
// The image is the "Splash" image set in Assets.xcassets
//-------------------------------------------------------------------------------------------------------------------

// Splash ENUM
/// Sets the parameters
//-------------------------------------------------------------------------------------------------------------------
enum Splash {
    static let duration: Duration = .seconds(3)     /// have the image display for 3 seconds
    static let imageName = "Splash"                 /// set the image name to "Splash"
    static let windowID = "splash"                  /// set the splash window ID to "splash"
    static let mainWindowID = "main"                /// set the actual program window ID to "main"
    
    // The image is 1024 pixels square, which is 512 points on a display with 2 pixels per point
    static let displaySide: CGFloat = 512
}

#if os(macOS)
/// The content of the splash window. After `Splash.duration` it opens the main window and closes its own window.
struct SplashView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    /// `Splash.displaySide`, reduced to the visible screen when the screen is smaller, so that the
    /// whole image shows.
    static var sideLength: CGFloat {
        guard let screen = NSScreen.main else { return Splash.displaySide }
        let visible = screen.visibleFrame.size
        return min(Splash.displaySide, visible.width, visible.height)
    }

    var body: some View {
        Image(Splash.imageName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: Self.sideLength, height: Self.sideLength)
            .task {
                try? await Task.sleep(for: Splash.duration)
                openWindow(id: Splash.mainWindowID)
                dismissWindow(id: Splash.windowID)
            }
    }
}
#else
/// For an iPhone the app has one window, so the splash image is shown in it for `Splash.duration`and is then replaced by the main view.
struct SplashGate: View {
    @State private var isShowingSplash = true

    var body: some View {
        if isShowingSplash {
            Image(Splash.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: Splash.displaySide, maxHeight: Splash.displaySide)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .ignoresSafeArea()
                .task {
                    try? await Task.sleep(for: Splash.duration)
                    withAnimation { isShowingSplash = false }
                }
        } else {
            ContentView()
        }
    }
}
#endif
