import SwiftUI

struct TasksByDueDateView: View {
    let tasks: [TaskItem]
    var onLongPress: (TaskItem) -> Void
    var onProjectTap: (ProjectItem) -> Void
    var onToggle: (TaskItem) -> Void

    var body: some View {
        List {
            ForEach(sections, id: \.title) { section in
                Section(header: Text(section.title)) {
                    ForEach(section.items) { task in
                        TaskRow(
                            task: task,
                            onProjectTap: { project in onProjectTap(project) },
                            onToggle: { _ in onToggle(task) }
                        )
                        .contentShape(Rectangle())
                        .onLongPressGesture { onLongPress(task) }
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var sections: [(title: String, items: [TaskItem])] {
        let today = TaskItem.defaultDueDate()
        // Group by normalized due date
        let grouped = Dictionary(grouping: tasks) { TaskItem.defaultDueDate($0.dueDate) }
        let keys = grouped.keys

        // Custom order: Today first, then future ascending, then past ascending
        let orderedDates = keys.sorted { a, b in
            if a == today && b != today { return true }
            if b == today && a != today { return false }
            if a >= today && b < today { return true }
            if b >= today && a < today { return false }
            return a < b
        }

        return orderedDates.map { date in
            let title: String
            if date == today { title = "Today" }
            else if date == TaskItem.defaultDueDate(Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) { title = "Tomorrow" }
            else { title = headerFormatter.string(from: date) }
            let items = (grouped[date] ?? []).sorted { $0.title < $1.title }
            return (title, items)
        }
    }

    private var headerFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }
}

