import Foundation

enum SlotState: String, Codable {
    case idle
    case sending
    case sent
    case failed
}

/// A configurable trigger surface. The slot holds the Meta template name and
/// recipient phone for one WhatsApp send. Routing lives on-device — the
/// AppIntent reads these fields and posts directly to Kapso.
struct MessageSlot: Codable, Identifiable {
    let id: UUID
    var label: String
    var icon: String
    /// Meta template name (e.g. "gate_open"). Must match an approved template
    /// in the Kapso dashboard.
    var templateName: String
    /// Recipient phone number, international format, digits only (no `+`,
    /// no spaces). E.g. "2547XXXXXXXX" for a Kenyan number.
    var recipientPhone: String
    var isEnabled: Bool
    var lastSentAt: Date?
    var slotState: SlotState
    var stateTimestamp: Date?
    var slotIndex: Int?

    init(
        slotIndex: Int,
        label: String? = nil,
        icon: String? = nil,
        templateName: String? = nil,
        recipientPhone: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.label = label ?? LangoConstants.defaultLabels[slotIndex]
        self.icon = icon ?? LangoConstants.defaultIcons[slotIndex]
        self.templateName = templateName ?? LangoConstants.defaultTemplateNames[slotIndex]
        self.recipientPhone = recipientPhone ?? ""
        self.isEnabled = isEnabled
        self.slotState = .idle
        self.stateTimestamp = nil
        self.lastSentAt = nil
        self.slotIndex = slotIndex
    }

    /// A slot is configured once it has both a template name and a recipient.
    /// Kapso/Meta is the source of truth for whether the template is approved
    /// — a typo here yields a Kapso error at send time.
    var isConfigured: Bool {
        !templateName.isEmpty && !recipientPhone.isEmpty
    }
}
