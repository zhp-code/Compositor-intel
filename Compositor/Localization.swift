import Foundation

/// Looks up `key` in the app's string catalog and returns the translation for the
/// current language, or `key` itself when there is none. Used for text that reaches
/// the screen through a `String` (a custom control's title, a menu built in AppKit)
/// rather than a SwiftUI string literal, which is localized automatically.
func loc(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

extension RawRepresentable where RawValue == String {
    /// The value as shown in the interface. `rawValue` is what gets written to the
    /// project, so it stays English; `displayName` looks it up in the catalog so a
    /// persisted identifier can appear in another language without touching saved files.
    var displayName: String { loc(rawValue) }
}
