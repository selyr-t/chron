import SwiftUI

@main
struct chronApp: App {
    var body: some Scene {
        #if os(macOS)
        // The main window does not open at launch; the splash window opens it after 3 seconds.
        // It stays the first scene, so the app keeps running after the splash window closes.
        WindowGroup(id: Splash.mainWindowID) {
            ContentView()
        }
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
        // 650 x 850 points, centered on the screen. On a screen whose visible area is smaller,
        // the window shrinks to fit, so that its title bar and bottom edge stay on screen.
        .defaultWindowPlacement { _, context in
            let display = context.defaultDisplay.visibleRect
            let size = CGSize(width: min(650, display.width), height: min(850, display.height))
            let position = CGPoint(x: display.midX - size.width / 2,
                                   y: display.midY - size.height / 2)
            return WindowPlacement(position, size: size)
        }

        // A borderless window that is exactly the size of the image, centered on the screen.
        Window("chron", id: Splash.windowID) {
            SplashView()
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
        .defaultWindowPlacement { content, context in
            let display = context.defaultDisplay.visibleRect
            let size = content.sizeThatFits(.unspecified)
            let position = CGPoint(x: display.midX - size.width / 2,
                                   y: display.midY - size.height / 2)
            return WindowPlacement(position, size: size)
        }
        #else
        WindowGroup {
            SplashGate()
        }
        #endif
    }
}
