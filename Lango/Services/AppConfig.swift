import Foundation

/// Reads/writes Kapso configuration. Phone-number ID lives in App Group
/// UserDefaults (so the widget extension can read it). The Kapso API key
/// lives in the Keychain (with the shared access group).
///
/// Implemented as an enum (no instance state) — `UserDefaults(suiteName:)` is
/// thread-safe and cheap to resolve, and this avoids non-Sendable storage in
/// what would otherwise be a shared-mutable singleton under Swift 6.
enum AppConfig {
    private static var defaults: UserDefaults {
        UserDefaults(suiteName: LangoConstants.appGroupID) ?? .standard
    }

    /// The Kapso-managed WhatsApp Business phone-number ID (e.g. "1234567890").
    /// Found in the Kapso dashboard after Instant Setup. Not secret — just
    /// identifies which WhatsApp sender Kapso routes through.
    static var kapsoPhoneNumberID: String {
        get { defaults.string(forKey: LangoConstants.kapsoPhoneNumberIDKey) ?? "" }
        set {
            defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines),
                         forKey: LangoConstants.kapsoPhoneNumberIDKey)
        }
    }

    /// The Kapso platform API key. Stored in Keychain with
    /// `afterFirstUnlockThisDeviceOnly` so the locked-device AppIntent can read
    /// it from CarPlay or Siri without unlock. Shared with the widget
    /// extension via Keychain Access Group.
    static var kapsoAPIKey: String {
        KeychainService.getSecret() ?? ""
    }

    static func setKapsoAPIKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainService.deleteSecret()
        } else {
            try KeychainService.setSecret(trimmed)
        }
    }

    static var isConfigured: Bool {
        !kapsoPhoneNumberID.isEmpty && !kapsoAPIKey.isEmpty
    }
}
