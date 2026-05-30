import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var kapsoPhoneNumberID: String = ""
    @State private var kapsoAPIKey: String = ""
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. 1234567890",
                              text: $kapsoPhoneNumberID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.numberPad)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Kapso Phone Number ID")
                } footer: {
                    Text("Found in Kapso dashboard → Phone Numbers after Instant Setup. Identifies which WhatsApp sender Kapso routes through. Stored in App Group UserDefaults.")
                }

                Section {
                    SecureField("Kapso API key", text: $kapsoAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Kapso API Key")
                } footer: {
                    Text("Stored in the iOS Keychain (after-first-unlock-this-device-only) and shared with the widget extension via Keychain Access Group. Sent as the `X-API-Key` header on every Kapso call.")
                }

                Section {
                    safetyChecklist
                } header: {
                    Text("Driver-safety checklist")
                } footer: {
                    Text("These iPhone Settings are required for Lango to fire while the phone is locked in your pocket. iOS occasionally resets \"Allow Siri When Locked\" — re-check after major updates.")
                }

                if let saveError {
                    Section {
                        Label(saveError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                kapsoPhoneNumberID = AppConfig.kapsoPhoneNumberID
                kapsoAPIKey = AppConfig.kapsoAPIKey
            }
        }
    }

    private var safetyChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            checklistRow("Settings → Siri → Listen for \u{201C}Hey Siri\u{201D}: ON")
            checklistRow("Settings → Siri → Allow Siri When Locked: ON")
            checklistRow("Settings → Siri → Press Side Button for Siri: ON")
        }
        .font(.footnote)
    }

    private func checklistRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
            Text(text)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func save() {
        AppConfig.kapsoPhoneNumberID = kapsoPhoneNumberID
        do {
            try AppConfig.setKapsoAPIKey(kapsoAPIKey)
            dismiss()
        } catch {
            saveError = "Failed to save API key: \(error)"
        }
    }
}
