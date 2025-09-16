import SwiftUI

struct StoriesBar: View {
    let projects: [ProjectItem]
    let hasInbox: Bool
    @Binding var selectedFilter: ContentView.TaskFilter
    var onNew: () -> Void
    // New: tasks and current date scope for highlighting/reordering
    let tasks: [TaskItem]
    let dateScope: ContentView.DateScope
    var onProjectLongPress: ((ProjectItem) -> Void)? = nil

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                StoryItem(title: "New", emoji: "＋", isSelected: false) { onNew() }

                if hasInbox {
                    let isInboxSelected = selectedFilter == ContentView.TaskFilter.inbox
                    StoryItem(
                        title: "Unassigned",
                        emoji: "📥",
                        isSelected: isInboxSelected,
                        selectedRingGradient: isInboxSelected ? AngularGradient(gradient: Gradient(colors: [Color.yellow, Color.green, Color.yellow]), center: .center) : nil
                    ) {
                        selectedFilter = (selectedFilter == ContentView.TaskFilter.inbox) ? ContentView.TaskFilter.none : ContentView.TaskFilter.inbox
                    }
                }

                let isAllSelected = selectedFilter == ContentView.TaskFilter.none
                StoryItem(
                    title: "All",
                    emoji: "🗂️",
                    isSelected: isAllSelected,
                    selectedRingGradient: isAllSelected ? AngularGradient(gradient: Gradient(colors: [Color.yellow, Color.green, Color.yellow]), center: .center) : nil
                ) {
                    selectedFilter = ContentView.TaskFilter.none
                }

                let ordered = orderedProjects()
                ForEach(ordered, id: \.id) { project in
                    let hasActive = projectHasTasksForScope(project)
                    let dim = shouldDimProjects() ? !hasActive : false
                    ProjectStoryItem(
                        project: project,
                        isSelected: selectedFilter == ContentView.TaskFilter.project(project.id),
                        dimmed: dim,
                        hasActiveForScope: hasActive,
                        onTap: {
                            selectedFilter = (selectedFilter == ContentView.TaskFilter.project(project.id)) ? ContentView.TaskFilter.none : ContentView.TaskFilter.project(project.id)
                        }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.4).onEnded { pressed in onProjectLongPress?(project) }
                    )
                }
            }
            .padding(.leading, 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Helpers
extension StoriesBar {
    private func shouldDimProjects() -> Bool {
        switch dateScope {
        case .anytime: return false
        default: return true
        }
    }

    private func orderedProjects() -> [ProjectItem] {
        guard shouldDimProjects() else { return projects }
        let withTasks = projects.filter { projectHasTasksForScope($0) }
        let withoutTasks = projects.filter { !projectHasTasksForScope($0) }
        return withTasks + withoutTasks
    }

    private func projectHasTasksForScope(_ project: ProjectItem) -> Bool {
        let items = tasks.filter { $0.project?.id == project.id }
        switch dateScope {
        case .anytime:
            return !items.isEmpty
        case .today:
            let target = TaskItem.defaultDueDate()
            return items.contains { TaskItem.defaultDueDate($0.dueDate) == target }
        case .tomorrow:
            let target = normalize(addDays(1))
            return items.contains { TaskItem.defaultDueDate($0.dueDate) == target }
        case .weekend:
            let target = normalize(upcomingSaturday())
            return items.contains { TaskItem.defaultDueDate($0.dueDate) == target }
        case .custom(let d):
            let target = TaskItem.defaultDueDate(d)
            return items.contains { TaskItem.defaultDueDate($0.dueDate) == target }
        }
    }

    private func normalize(_ date: Date) -> Date {
        TaskItem.defaultDueDate(date)
    }

    private func addDays(_ days: Int, from date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    private func upcomingSaturday(from date: Date = Date()) -> Date {
        let sat = 7
        var cal = Calendar.current
        cal.firstWeekday = 1
        let current = cal.component(.weekday, from: date)
        if current == sat { return date }
        var diff = sat - current
        if diff <= 0 { diff += 7 }
        return cal.date(byAdding: .day, value: diff, to: date) ?? date
    }
}
