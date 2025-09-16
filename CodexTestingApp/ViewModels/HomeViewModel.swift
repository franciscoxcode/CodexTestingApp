import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var projects: [ProjectItem] = []
    private var cancellables: Set<AnyCancellable> = []

    init() {
        loadProjects()
        loadTasks()
        // Migration: ensure completedAt is set for done tasks
        var mutated = false
        for i in tasks.indices {
            if tasks[i].isDone && tasks[i].completedAt == nil {
                tasks[i].completedAt = Date()
                mutated = true
            }
        }
        if mutated { saveTasks() }

        // Persist on changes
        $projects
            .dropFirst()
            .sink { [weak self] _ in self?.saveProjects() }
            .store(in: &cancellables)

        $tasks
            .dropFirst()
            .sink { [weak self] _ in self?.saveTasks() }
            .store(in: &cancellables)
    }

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

    func toggleTaskDone(id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].isDone.toggle()
        if tasks[idx].isDone {
            tasks[idx].completedAt = Date()
        } else {
            tasks[idx].completedAt = nil
        }
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
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

    // MARK: - Persistence
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var tasksFileURL: URL { documentsDirectory.appendingPathComponent("tasks.json") }
    private var projectsFileURL: URL { documentsDirectory.appendingPathComponent("projects.json") }

    private func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: tasksFileURL, options: [.atomic])
        } catch {
            print("Failed to save tasks: \(error)")
        }
    }

    private func saveProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: projectsFileURL, options: [.atomic])
        } catch {
            print("Failed to save projects: \(error)")
        }
    }

    private func loadTasks() {
        do {
            let url = tasksFileURL
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([TaskItem].self, from: data)
            self.tasks = decoded
        } catch {
            print("Failed to load tasks: \(error)")
        }
    }

    private func loadProjects() {
        do {
            let url = projectsFileURL
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([ProjectItem].self, from: data)
            self.projects = decoded
        } catch {
            print("Failed to load projects: \(error)")
        }
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
