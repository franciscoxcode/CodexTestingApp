import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var projects: [ProjectItem] = []

    @discardableResult
    func addProject(name: String, emoji: String) -> ProjectItem {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let project = ProjectItem(name: trimmedName, emoji: trimmedEmoji.isEmpty ? "📁" : trimmedEmoji)
        projects.append(project)
        return project
    }

    func updateProject(id: UUID, name: String, emoji: String, colorName: String?) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        var p = projects[idx]
        p.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        p.emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        p.colorName = colorName
        projects[idx] = p
    }

    func addTask(
        title: String,
        project: ProjectItem?,
        difficulty: TaskDifficulty = .easy,
        resistance: TaskResistance = .low,
        estimatedTime: TaskEstimatedTime = .short,
        dueDate: Date = TaskItem.defaultDueDate()
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(title: trimmed, isDone: false, project: project, difficulty: difficulty, resistance: resistance, estimatedTime: estimatedTime, dueDate: dueDate))
    }

    func updateTask(
        id: UUID,
        title: String,
        project: ProjectItem?,
        difficulty: TaskDifficulty,
        resistance: TaskResistance,
        estimatedTime: TaskEstimatedTime,
        dueDate: Date
    ) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        var current = tasks[idx]
        current.title = title
        current.project = project
        current.difficulty = difficulty
        current.resistance = resistance
        current.estimatedTime = estimatedTime
        current.dueDate = dueDate
        tasks[idx] = current
    }

    // Seed sample data for testing
    func seedSampleData() {
        guard tasks.isEmpty else { return }

        let work = addProject(name: "Work", emoji: "🚀")
        let personal = addProject(name: "Personal", emoji: "🏡")
        let study = addProject(name: "Study", emoji: "📚")
        // New: Weekend-only project (no tasks today/tomorrow)
        let weekendProject = addProject(name: "Weekend", emoji: "🎉")

        let today = TaskItem.defaultDueDate()
        let tomorrow = TaskItem.defaultDueDate(Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let saturday = TaskItem.defaultDueDate(upcomingSaturday())

        let difficulties: [TaskDifficulty] = [.easy, .medium, .hard]
        let resistances: [TaskResistance] = [.low, .medium, .high]
        let times: [TaskEstimatedTime] = [.short, .medium, .long]
        let projectsCycle: [ProjectItem?] = [work, personal, study]

        let titles = [
            "Prepare sprint board", "Email client follow-up", "Write project brief",
            "Grocery shopping", "Laundry and folding", "Clean workspace",
            "Study SwiftUI", "Practice algorithms", "Review design patterns",
            "Plan weekend trip", "Book dentist appointment", "Read one chapter",
            "Refactor view model", "Fix UI glitch", "Add unit tests",
            "Workout session", "Meditation 10 min", "Call family",
            "Organize photos", "Backup laptop"
        ]

        for i in 0..<20 {
            let title = titles[i]
            let project = projectsCycle[i % projectsCycle.count]
            let diff = difficulties[i % difficulties.count]
            let res = resistances[i % resistances.count]
            let time = times[i % times.count]
            let date = (i % 2 == 0) ? today : tomorrow
            addTask(title: title, project: project, difficulty: diff, resistance: res, estimatedTime: time, dueDate: date)
        }

        // Add 3 weekend tasks for the weekend-only project
        addTask(title: "Plan weekend picnic", project: weekendProject, dueDate: saturday)
        addTask(title: "Hike the trail", project: weekendProject, dueDate: saturday)
        addTask(title: "Movie night prep", project: weekendProject, dueDate: saturday)
    }
}

// MARK: - Date helpers for seeding
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
