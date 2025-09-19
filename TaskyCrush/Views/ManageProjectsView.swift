import SwiftUI

struct ManageProjectsView: View {
    let projects: [ProjectItem]
    var onApplyOrder: ([UUID]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var ordered: [ProjectItem] = []
    @State private var editMode: EditMode = .active

    var body: some View {
        NavigationStack {
            List {
                ForEach(ordered, id: \.id) { project in
                    HStack(spacing: 10) {
                        Text(project.emoji)
                        Text(project.name)
                        Spacer()
                    }
                }
                .onMove(perform: move)
            }
            .navigationTitle("Manage Projects")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { applyAndClose() }
                }
            }
            .onAppear { syncOrdered() }
            // Always show reordering handles; no need to tap Edit first
            .environment(\.editMode, $editMode)
        }
    }

    private func syncOrdered() {
        ordered = projects.sorted { a, b in
            let ak = (a.sortOrder ?? Int.max, a.name)
            let bk = (b.sortOrder ?? Int.max, b.name)
            return ak < bk
        }
    }

    private func move(from: IndexSet, to: Int) {
        ordered.move(fromOffsets: from, toOffset: to)
    }

    private func applyAndClose() {
        let ids = ordered.map { $0.id }
        onApplyOrder(ids)
        dismiss()
    }
}
