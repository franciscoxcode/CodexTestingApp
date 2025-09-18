import SwiftUI

struct TasksByTagView: View {
    let tasks: [TaskItem]
    var onLongPress: (TaskItem) -> Void
    var onProjectTap: (ProjectItem) -> Void
    var onToggle: (TaskItem) -> Void
    var onEdit: (TaskItem) -> Void = { _ in }
    var onDelete: (TaskItem) -> Void = { _ in }
    var onMoveMenu: (TaskItem) -> Void = { _ in }
    var onOpenNote: (TaskItem) -> Void = { _ in }

    var body: some View {
        List {
            ForEach(sections, id: \.title) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.items) { task in
                        TaskRow(
                            task: task,
                            onProjectTap: { project in onProjectTap(project) },
                            onToggle: { _ in onToggle(task) },
                            onEdit: { _ in onEdit(task) },
                            onDelete: { _ in onDelete(task) },
                            onMoveMenu: { _ in onMoveMenu(task) },
                            onOpenNote: { _ in onOpenNote(task) }
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var sections: [(title: String, items: [TaskItem])] {
        // Group by tag (case-insensitive), with nil/empty under "Untagged"
        enum Key: Hashable { case tag(String), untagged }
        let grouped: [Key: [TaskItem]] = Dictionary(grouping: tasks) { t in
            if let raw = t.tag?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty {
                return .tag(raw.lowercased())
            }
            return .untagged
        }
        // Determine display names for tag keys
        func displayName(for key: Key, sample: [TaskItem]) -> String {
            switch key {
            case .untagged:
                return "Untagged"
            case .tag:
                // Try to use the first non-empty original casing from sample items
                if let name = sample.compactMap({ $0.tag?.trimmingCharacters(in: .whitespacesAndNewlines) }).first(where: { !$0.isEmpty }) {
                    return "#" + name
                }
                return "#—"
            }
        }
        // Sort keys: tags alphabetically by display name, then Untagged last
        let orderedKeys: [Key] = grouped.keys.sorted { a, b in
            switch (a, b) {
            case (.untagged, .untagged): return false
            case (.untagged, _): return true   // Put Untagged first
            case (_, .untagged): return false
            case (.tag, .tag):
                let da = displayName(for: a, sample: grouped[a] ?? [])
                let db = displayName(for: b, sample: grouped[b] ?? [])
                return da.localizedCaseInsensitiveCompare(db) == .orderedAscending
            }
        }
        // Preserve insertion order within each group (Dictionary(grouping:) preserves order of original array)
        return orderedKeys.map { key in
            let items = grouped[key] ?? []
            let title = displayName(for: key, sample: items)
            return (title, items)
        }
    }
}
