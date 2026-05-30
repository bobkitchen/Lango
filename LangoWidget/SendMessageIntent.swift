import AppIntents
import Foundation
import WidgetKit

/// The single trigger that powers Lango's Siri voice path, CarPlay widget tap,
/// Home Screen widget tap, and main-app button taps.
///
/// **Driver-safety redline**: `authenticationPolicy = .alwaysAllowed` lets this
/// run on a locked device without prompting Face ID. Without it, every CarPlay
/// or Siri invocation would force the driver to unlock the phone — which is
/// the redline. The intent reads the slot's template name + recipient phone
/// from App Group storage and the Kapso API key from the shared Keychain,
/// then POSTs directly to Kapso.
struct SendMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "Send Lango Message"
    static let description: IntentDescription = IntentDescription(
        "Sends a preset WhatsApp message via Kapso."
    )

    static let openAppWhenRun: Bool = false
    // Use `let` to satisfy Swift 6 strict concurrency — the value is immutable
    // and `let` satisfies the protocol's `var` requirement.
    static let authenticationPolicy: IntentAuthenticationPolicy = .alwaysAllowed

    @Parameter(title: "Slot Index")
    var slotIndex: Int

    init() {
        self.slotIndex = 0
    }

    init(slotIndex: Int) {
        self.slotIndex = slotIndex
    }

    func perform() async throws -> some IntentResult {
        let store = SlotStore.shared
        let slots = store.loadSlots()
        guard slotIndex >= 0 && slotIndex < slots.count else {
            return .result()
        }

        let slot = slots[slotIndex]
        guard slot.isConfigured && slot.isEnabled else {
            return .result()
        }

        // Debounce repeat taps within the window.
        guard store.canSend(slotIndex: slotIndex) else {
            return .result()
        }

        store.setSlotState(slotIndex, state: .sending)

        do {
            try await MessageService.send(
                templateName: slot.templateName,
                recipientPhone: slot.recipientPhone
            )
            store.setSlotState(slotIndex, state: .sent)
        } catch {
            store.setSlotState(slotIndex, state: .failed)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: LangoConstants.widgetKind)
        return .result()
    }
}
