import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    var onProjectTap: ((ProjectItem) -> Void)? = nil
    var onToggle: ((TaskItem) -> Void)? = nil
    var showCompletedStyle: Bool = true

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
    }
}
