import SwiftUI

struct CompletedTasksView: View {
    let tasks: [TaskItem]
    var onUncomplete: (TaskItem) -> Void
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                // Sections grouped by completion day
                ForEach(groupedSections, id: \.title) { section in
                    Section(header: Text(section.title)) {
                        ForEach(section.items) { task in
                            TaskRow(task: task, onToggle: { _ in onUncomplete(task) }, showCompletedStyle: false)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Completed Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClose() }
                }
            }
        }
    }

    private var completed: [TaskItem] { tasks.filter { $0.isDone } }

    private var groupedSections: [(title: String, items: [TaskItem])] {
        let today = normalized(Date())
        let yesterday = normalized(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())

        // Group tasks by completion date; if missing, treat as today
        let withDate = completed.map { t -> (date: Date, task: TaskItem) in
            let d = t.completedAt ?? Date()
            return (normalized(d), t)
        }

        // Build dictionary by day
        let grouped = Dictionary(grouping: withDate, by: { $0.date })
        // Sort days descending
        let sortedDays = grouped.keys.sorted(by: >)

        return sortedDays.map { day in
            let title: String
            if day == today { title = "Today" }
            else if day == yesterday { title = "Yesterday" }
            else { title = headerFormatter.string(from: day) }
            let items = (grouped[day] ?? []).map { $0.task }.sorted { (a, b) in
                let da = a.completedAt ?? Date.distantPast
                let db = b.completedAt ?? Date.distantPast
                return da > db
            }
            return (title, items)
        }
    }

    private func normalized(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private var headerFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }
}
