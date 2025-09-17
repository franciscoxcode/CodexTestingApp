import SwiftUI

struct TaskNoteView: View {
    let taskId: UUID
    let taskTitle: String
    let initialMarkdown: String
    var autoSaveIntervalSeconds: TimeInterval = 3
    // Callbacks
    var onSave: (_ text: String) -> Void
    var onAutoSave: (_ text: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var lastSavedText: String
    @State private var lastSavedAt: Date? = nil
    @State private var isSaving: Bool = false

    init(taskId: UUID, taskTitle: String, initialMarkdown: String, autoSaveIntervalSeconds: TimeInterval = 8, onSave: @escaping (_ text: String) -> Void, onAutoSave: @escaping (_ text: String) -> Void) {
        self.taskId = taskId
        self.taskTitle = taskTitle
        self.initialMarkdown = initialMarkdown
        self.autoSaveIntervalSeconds = autoSaveIntervalSeconds
        self.onSave = onSave
        self.onAutoSave = onAutoSave
        _text = State(initialValue: initialMarkdown)
        _lastSavedText = State(initialValue: initialMarkdown)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Inline editor with placeholder
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemBackground))
                        .ignoresSafeArea(.keyboard, edges: .bottom)

                    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Start your note here…")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 18)
                            .padding(.top, 14)
                            .allowsHitTesting(false)
                    }
                }

                // Save status row
                HStack(spacing: 8) {
                    if isSaving { ProgressView().scaleEffect(0.8) }
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }
            .navigationTitle(taskTitle.isEmpty ? "Note" : taskTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndClose() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && initialMarkdown.isEmpty)
                }
                // Keyboard toolbar with quick actions (basic insertion for now)
                ToolbarItemGroup(placement: .keyboard) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            Button(action: { insertPrefix("# ") }) { Text("H1") }
                            Button(action: { insertPrefix("## ") }) { Text("H2") }
                            Button(action: { wrapSelection(with: "**") }) { Image(systemName: "bold") }
                            Button(action: { wrapSelection(with: "*") }) { Image(systemName: "italic") }
                            Button(action: { wrapSelection(with: "~~") }) { Image(systemName: "strikethrough") }
                            Button(action: { insertPrefix("- [ ] ") }) { Image(systemName: "checklist") }
                            Button(action: { insertPrefix("- ") }) { Text("•") }
                        }
                    }
                }
            }
            // Autosave timer
            .onReceive(Timer.publish(every: autoSaveIntervalSeconds, on: .main, in: .common).autoconnect()) { _ in
                autoSaveIfNeeded()
            }
            .onDisappear {
                autoSaveIfNeeded()
            }
        }
    }

    private var statusText: String {
        if isSaving { return "Saving…" }
        if lastSavedText == text, let when = lastSavedAt {
            let df = DateFormatter()
            df.timeStyle = .short
            df.dateStyle = .none
            return "Saved at \(df.string(from: when))"
        }
        return "Unsaved changes"
    }

    private func autoSaveIfNeeded() {
        guard text != lastSavedText else { return }
        isSaving = true
        onAutoSave(text)
        lastSavedText = text
        lastSavedAt = Date()
        isSaving = false
    }

    private func saveAndClose() {
        isSaving = true
        onSave(text)
        lastSavedText = text
        lastSavedAt = Date()
        isSaving = false
        dismiss()
    }

    // MARK: - Simple editing helpers
    private func insertPrefix(_ prefix: String) {
        if text.isEmpty { text = prefix } else { text = "\(prefix)\(text)" }
    }

    private func wrapSelection(with token: String) {
        // Without selection access in TextEditor, wrap the whole text as a basic behavior
        if text.isEmpty { text = token + token }
        else { text = token + text + token }
    }
}
