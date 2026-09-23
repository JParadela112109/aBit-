import SwiftUI

enum ABitTheme {
    static let ink = Color(red: 0.05, green: 0.07, blue: 0.07)
    static let inkElevated = Color(red: 0.09, green: 0.12, blue: 0.11)
    static let chalk = Color(red: 0.93, green: 0.95, blue: 0.94)
    static let mist = Color(red: 0.70, green: 0.78, blue: 0.74)
    static let lime = Color(red: 0.72, green: 0.88, blue: 0.29)
    static let limeDeep = Color(red: 0.55, green: 0.72, blue: 0.18)
    static let glow = Color(red: 0.35, green: 0.55, blue: 0.42).opacity(0.45)

    static let display = Font.system(.largeTitle, design: .serif).weight(.bold)
    static let title = Font.system(.title2, design: .serif).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
    static let caption = Font.system(.caption, design: .rounded).weight(.medium)
}
