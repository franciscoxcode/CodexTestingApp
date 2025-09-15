import SwiftUI

struct TaskRow: View {
    let task: TaskItem

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(task.isDone ? .green : .secondary)
            Text(task.title)
            Spacer(minLength: 8)
            if let project = task.project {
                HStack(spacing: 4) {
                    Text(project.emoji)
                    Text(project.name)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .listRowSeparator(.hidden)
    }
}

