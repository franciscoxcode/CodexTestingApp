import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    var onProjectTap: ((ProjectItem) -> Void)? = nil
    var onToggle: ((TaskItem) -> Void)? = nil
    var onEdit: ((TaskItem) -> Void)? = nil
    var onDelete: ((TaskItem) -> Void)? = nil
    var onMoveMenu: ((TaskItem) -> Void)? = nil
    var onOpenNote: ((TaskItem) -> Void)? = nil
    var showCompletedStyle: Bool = true
    // Optional trailing info (e.g., +points in Completed list)
    var trailingInfo: String? = nil
    // Control whether to show project name next to emoji
    var showProjectName: Bool = true
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
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

            HStack(spacing: 8) {
                if let project = task.project {
                    Button(action: { onProjectTap?(project) }) {
                        HStack(spacing: 4) {
                            Text(project.emoji)
                            if showProjectName {
                                Text(project.name)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                if let info = trailingInfo {
                    Text(info)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onOpenNote?(task) }
        .listRowSeparator(.hidden)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onMoveMenu?(task)
            } label: {
                Label("Move to date", systemImage: "calendar.badge.clock")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                onEdit?(task)
            } label: {
                Label("Edit Task", systemImage: "pencil")
            }
            .tint(.green)
        }
    }
}

// No local date helpers needed for single move menu action
