import SwiftUI

struct TaskFlatListView: View {
    let title: String
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
            Section(header: Text(title)) {
                ForEach(tasks) { task in
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
        .listStyle(.plain)
    }
}
