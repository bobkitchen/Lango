import SwiftUI

struct SlotEditorView: View {
    @Binding var slot: MessageSlot
    let slotIndex: Int
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let commonIcons = [
        "house.and.flag.fill", "car.fill", "checkmark.seal.fill",
        "paperplane.fill", "bubble.left.fill", "location.fill",
        "house.fill", "building.2.fill", "key.fill",
        "clock.fill", "heart.fill", "star.fill",
        "bell.fill", "hand.wave.fill", "figure.walk",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Button Appearance") {
                    TextField("Label", text: $slot.label)
                        .textInputAutocapitalization(.words)
                    iconPicker
                }

                Section {
                    TextField("gate_open", text: $slot.templateName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Template Name")
                } footer: {
                    Text("The approved Meta template name in Kapso (e.g. `gate_open`, `eta_arriving`, `arrived`). A typo here yields a Kapso error at send time.")
                }

                Section {
                    TextField("2547XXXXXXXX", text: $slot.recipientPhone)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.numberPad)
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Recipient Phone")
                } footer: {
                    Text("International format, digits only — no `+`, no spaces. Example: `2547XXXXXXXX` for a Kenyan number.")
                }

                Section {
                    Toggle("Enabled", isOn: $slot.isEnabled)
                }

                if slotIndex == 0 {
                    Section {
                        Label("Slot 1 is the canonical gate-open slot. The Siri phrase \"Hey Siri, open the gate\" is wired to this slot's position.", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Slot \(slotIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(!slot.isConfigured)
                }
            }
        }
    }

    @ViewBuilder
    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(commonIcons, id: \.self) { iconName in
                    Button {
                        slot.icon = iconName
                    } label: {
                        Image(systemName: iconName)
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(slot.icon == iconName ? accentColor.opacity(0.2) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(slot.icon == iconName ? accentColor : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var accentColor: Color {
        let c = LangoConstants.slotColors[slotIndex % LangoConstants.slotColors.count]
        return Color(red: c.red, green: c.green, blue: c.blue)
    }
}
