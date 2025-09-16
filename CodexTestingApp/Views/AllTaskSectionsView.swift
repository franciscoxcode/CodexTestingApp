import SwiftUI

struct AllTaskSectionsView: View {
    let projects: [ProjectItem]
    let tasks: [TaskItem]
    var onLongPress: (TaskItem) -> Void
    var onProjectTap: (ProjectItem) -> Void
    var onToggle: (TaskItem) -> Void
    var onEdit: (TaskItem) -> Void = { _ in }
    var onDelete: (TaskItem) -> Void = { _ in }
    var onMoveMenu: (TaskItem) -> Void = { _ in }

    var body: some View {
        List {
            ForEach(projects) { project in
                let items = tasks.filter { $0.project?.id == project.id }
                if !items.isEmpty {
                    Section(header: Text(project.name)) {
                        ForEach(items) { task in
                            TaskRow(
                                task: task,
                                onProjectTap: { _ in onProjectTap(project) },
                                onToggle: { _ in onToggle(task) },
                                onEdit: { _ in onEdit(task) },
                                onDelete: { _ in onDelete(task) },
                                onMoveMenu: { _ in onMoveMenu(task) }
                            )
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            let unassigned = tasks.filter { $0.project == nil }
            if !unassigned.isEmpty {
                Section(header: Text("Unassigned")) {
                    ForEach(unassigned) { task in
                        TaskRow(task: task,
                                onToggle: { _ in onToggle(task) },
                                onEdit: { _ in onEdit(task) },
                                onDelete: { _ in onDelete(task) },
                                onMoveMenu: { _ in onMoveMenu(task) })
                            .contentShape(Rectangle())
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
