import SwiftUI

struct EditProjectView: View {
    let project: ProjectItem
    var onSave: (_ name: String, _ emoji: String, _ colorName: String?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var colorName: String?
    @State private var showingEmojiPicker = false

    init(project: ProjectItem, onSave: @escaping (_ name: String, _ emoji: String, _ colorName: String?) -> Void) {
        self.project = project
        self.onSave = onSave
        _name = State(initialValue: project.name)
        _emoji = State(initialValue: project.emoji)
        _colorName = State(initialValue: project.colorName)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project")) {
                    HStack(spacing: 12) {
                        Button { showingEmojiPicker = true } label: {
                            ZStack {
                                Circle().fill(colorFromName(colorName) ?? Color.clear)
                                Circle().fill(.ultraThinMaterial)
                                Text(emoji.isEmpty ? "✨" : emoji)
                                    .font(.system(size: 24))
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)

                        TextField("Project name", text: $name)
                            .textInputAutocapitalization(.words)
                    }

                    // Color palette (horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(colorOptions, id: \.name) { swatch in
                                let isSelected = (colorName == swatch.name)
                                Button {
                                    colorName = isSelected ? nil : swatch.name
                                } label: {
                                    Circle()
                                        .fill(swatch.color)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            Circle().strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .navigationTitle("Edit Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(name, emoji, colorName); dismiss() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || emoji.isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView { selected in
                    emoji = selected
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var colorOptions: [(name: String, color: Color)] {
        [
            ("yellow", .yellow), ("green", .green), ("blue", .blue), ("purple", .purple), ("pink", .pink),
            ("orange", .orange), ("teal", .teal), ("mint", .mint), ("indigo", .indigo), ("red", .red),
            ("brown", .brown), ("gray", .gray)
        ]
    }

    private func colorFromName(_ name: String?) -> Color? {
        guard let name = name else { return nil }
        switch name {
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "orange": return .orange
        case "teal": return .teal
        case "mint": return .mint
        case "indigo": return .indigo
        case "red": return .red
        case "brown": return .brown
        case "gray": return .gray
        default: return nil
        }
    }
}

