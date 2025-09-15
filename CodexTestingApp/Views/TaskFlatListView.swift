import SwiftUI

struct TaskFlatListView: View {
    let title: String
    let tasks: [TaskItem]
    var onLongPress: (TaskItem) -> Void
    var onProjectTap: (ProjectItem) -> Void

    var body: some View {
        List {
            Section(header: Text(title)) {
                ForEach(tasks) { task in
                    TaskRow(task: task, onProjectTap: { project in onProjectTap(project) })
                        .contentShape(Rectangle())
                        .onLongPressGesture { onLongPress(task) }
                }
            }
        }
        .listStyle(.plain)
    }
}

