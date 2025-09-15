import SwiftUI

struct TaskRow: View {
    let task: TaskItem
    var onProjectTap: ((ProjectItem) -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isDone ? .green : .secondary)
            Text(task.title)
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
