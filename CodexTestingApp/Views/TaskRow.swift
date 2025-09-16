import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    var onProjectTap: ((ProjectItem) -> Void)? = nil
    var onToggle: ((TaskItem) -> Void)? = nil
    var onEdit: ((TaskItem) -> Void)? = nil
    var onDelete: ((TaskItem) -> Void)? = nil
    var showCompletedStyle: Bool = true
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Button(action: { onToggle?(task) }) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? .green : .secondary)
            }
            .buttonStyle(.plain)
            let renderAsDone = showCompletedStyle && task.isDone
            Text(task.title)
                .strikethrough(renderAsDone, color: .secondary)
                .foregroundStyle(renderAsDone ? .secondary : .primary)
            Spacer(minLength: 8)
            if let project = task.project {
                Button(action: { onProjectTap?(project) }) {
                    HStack(spacing: 4) {
                        Text(project.emoji)
                        Text(project.name)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .listRowSeparator(.hidden)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            // Full swipe triggers the first action (Delete)
            Button {
                // Defer actual delete to parent via callback (parent shows confirm)
                onDelete?(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)

            Button {
                onEdit?(task)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
        }
    }
}
