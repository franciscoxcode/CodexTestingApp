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
        // Migration: ensure completedAt is set for done tasks
        var mutated = false
        for i in tasks.indices {
            if tasks[i].isDone && tasks[i].completedAt == nil {
                tasks[i].completedAt = Date()
                mutated = true
            }
        }
        if mutated { saveTasks() }

        // Migration: assign sortOrder to projects that don't have it yet
        migrateProjectSortOrderIfNeeded()

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

    private func migrateProjectSortOrderIfNeeded() {
        var changed = false
        // If any project lacks sortOrder, assign sequentially in current array order
        if projects.contains(where: { $0.sortOrder == nil }) {
            for (idx, var p) in projects.enumerated() {
                if p.sortOrder == nil {
                    p.sortOrder = idx
                    if let i = projects.firstIndex(where: { $0.id == p.id }) {
                        projects[i] = p
                    }
                    changed = true
                }
            }
        }
        if changed { saveProjects() }
    }

    // Move any incomplete tasks whose due date is before today up to today.
    // Idempotent: running multiple times per day does nothing after first pass.
    func rolloverIncompletePastDueTasksToToday() {
        let today = TaskItem.defaultDueDate()
        var changed = false
        for i in tasks.indices {
            if !tasks[i].isDone && TaskItem.defaultDueDate(tasks[i].dueDate) < today {
                tasks[i].dueDate = today
                changed = true
            }
        }
        if changed { saveTasks() }
    }

    @discardableResult
    func addProject(name: String, emoji: String) -> ProjectItem {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let project = ProjectItem(name: trimmedName, emoji: trimmedEmoji.isEmpty ? "📁" : trimmedEmoji)
        projects.append(project)
        // Persist immediately to avoid losing data if app is killed before Combine sink fires
        saveProjects()
        return project
    }

    func updateProject(id: UUID, name: String, emoji: String, colorName: String?) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        var p = projects[idx]
        p.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        p.emoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        p.colorName = colorName
        projects[idx] = p
        saveProjects()
    }

    // Apply user-defined order by assigning consecutive sortOrder values
    func applyProjectOrder(idsInOrder: [UUID]) {
        var orderMap: [UUID: Int] = [:]
        for (i, id) in idsInOrder.enumerated() { orderMap[id] = i }
        for i in projects.indices {
            let id = projects[i].id
            if let newOrder = orderMap[id] {
                projects[i].sortOrder = newOrder
            }
        }
        saveProjects()
    }

    func deleteProject(id: UUID) {
        // Remove the project from list
        projects.removeAll { $0.id == id }
        // Unassign any tasks that referenced this project
        for i in tasks.indices {
            if tasks[i].project?.id == id {
                tasks[i].project = nil
            }
        }
        // Persist both since tasks may have been modified
        saveProjects()
        saveTasks()
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
        saveTasks()
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
        saveTasks()
    }

    func toggleTaskDone(id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].isDone.toggle()
        if tasks[idx].isDone {
            tasks[idx].completedAt = Date()
        } else {
            tasks[idx].completedAt = nil
            // If task becomes incomplete and its due date is in the past, move it to Today immediately
            let today = TaskItem.defaultDueDate()
            if TaskItem.defaultDueDate(tasks[idx].dueDate) < today {
                tasks[idx].dueDate = today
            }
        }
        saveTasks()
    }

    func setTaskDueDate(id: UUID, dueDate: Date) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].dueDate = TaskItem.defaultDueDate(dueDate)
        saveTasks()
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        saveTasks()
    }

    // Seed sample data for testing
    func seedSampleData() {
        guard tasks.isEmpty else { return }

        // Projects
        let work = addProject(name: "Work", emoji: "🚀")
        let personal = addProject(name: "Personal", emoji: "🏡")
        let study = addProject(name: "Study", emoji: "📚")
        let chores = addProject(name: "Chores", emoji: "🧺")
        let weekendFun = addProject(name: "Weekend Fun", emoji: "🎉")
        let futureOnly = addProject(name: "Someday", emoji: "🛰") // no today/tomorrow
        _ = addProject(name: "Empty", emoji: "🎯") // No tasks at all

        // Dates
        let today = TaskItem.defaultDueDate()
        let tomorrow = TaskItem.defaultDueDate(Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let saturday = TaskItem.defaultDueDate(upcomingSaturday())
        let next3 = TaskItem.defaultDueDate(Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date())
        let next5 = TaskItem.defaultDueDate(Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date())

        // Helpers
        let diffs: [TaskDifficulty] = [.easy, .medium, .hard]
        let ress: [TaskResistance] = [.low, .medium, .high]
        let times: [TaskEstimatedTime] = [.short, .medium, .long]

        func add(_ title: String, _ project: ProjectItem?, _ due: Date, _ di: Int, _ ri: Int, _ ti: Int) {
            addTask(title: title, project: project, difficulty: diffs[di % diffs.count], resistance: ress[ri % ress.count], estimatedTime: times[ti % times.count], dueDate: due)
        }

        // Work: mix of today/tomorrow
        add("Prepare sprint board", work, today, 1, 0, 2)
        add("Write project brief", work, tomorrow, 2, 1, 1)
        add("Review pull requests", work, today, 0, 1, 0)

        // Personal: today + weekend
        add("Grocery shopping", personal, today, 0, 0, 1)
        add("Book dentist", personal, tomorrow, 1, 2, 0)
        add("Family brunch", personal, saturday, 0, 0, 2)

        // Study: today/tomorrow mix
        add("Study SwiftUI", study, today, 2, 1, 1)
        add("Practice algorithms", study, tomorrow, 2, 2, 2)
        add("Read design patterns", study, today, 1, 1, 2)

        // Chores: mostly today
        add("Laundry and folding", chores, today, 0, 1, 1)
        add("Clean workspace", chores, today, 1, 0, 0)

        // Weekend fun: only weekend
        add("Plan picnic", weekendFun, saturday, 0, 0, 1)
        add("Hike the trail", weekendFun, saturday, 1, 1, 2)
        add("Movie night prep", weekendFun, saturday, 0, 0, 0)

        // Future only: tasks beyond tomorrow
        add("Refactor old module", futureOnly, next3, 2, 2, 2)
        add("Research new API", futureOnly, next5, 1, 1, 1)

        // Unassigned tasks: today/tomorrow
        add("Meditation 10 min", nil, today, 0, 0, 0)
        add("Backup laptop", nil, tomorrow, 1, 1, 1)
    }

    // Developer helper: clear storage and reseed diverse sample set
    func resetAndSeedSampleData() {
        // Clear in-memory
        tasks.removeAll()
        projects.removeAll()
        // Remove persisted files
        try? FileManager.default.removeItem(at: tasksFileURL)
        try? FileManager.default.removeItem(at: projectsFileURL)
        // Reseed
        seedSampleData()
        // Persist immediately
        saveProjects()
        saveTasks()
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
