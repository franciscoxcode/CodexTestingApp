import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task")) {
                    TextField("Enter task title", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

