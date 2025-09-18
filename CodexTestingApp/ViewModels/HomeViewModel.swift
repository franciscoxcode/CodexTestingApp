import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []
    @Published var projects: [ProjectItem] = []
    @Published var lastGeneratedOccurrence: TaskItem? = nil
    private var proposedNextOccurrence: TaskItem? = nil
    private var cancellables: Set<AnyCancellable> = []
    // Notify UI when a next occurrence is generated
    let nextOccurrence = PassthroughSubject<TaskItem, Never>()

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
            guard !tasks[i].isDone else { continue }
            let due = TaskItem.defaultDueDate(tasks[i].dueDate)
            if let rule = tasks[i].recurrence {
                switch rule.basis {
                case .scheduled:
                    // Advance scheduled tasks forward to today or next valid by scope
                    if due < today {
                        var next = due
                        // Prevent runaway loops by capping iterations
                        var steps = 0
                        while next < today && steps < 512 {
                            next = nextOccurrenceDay(from: next, rule: rule)
                            steps += 1
                        }
                        // If scope excludes today (e.g., weekendsOnly and today is weekday), move to next valid
                        next = adjustByScopeIfNeeded(next, scope: rule.scope)
                        if next != tasks[i].dueDate {
                            tasks[i].dueDate = next
                            // Align reminder to the same time (if any)
                            if let when = tasks[i].reminderAt {
                                tasks[i].reminderAt = alignReminderTime(toDay: next, from: when)
                            }
                            changed = true
                        }
                    }
                case .completion:
                    // Keep it visible today until completed
                    if due < today {
                        tasks[i].dueDate = today
                        if let when = tasks[i].reminderAt {
                            tasks[i].reminderAt = alignReminderTime(toDay: today, from: when)
                        }
                        changed = true
                    }
                }
            } else if due < today {
                tasks[i].dueDate = today
                changed = true
            }
        }
        if changed { saveTasks() }
    }

    // Compute next occurrence day from a given day according to rule (>= days granularity)
    private func nextOccurrenceDay(from baseDay: Date, rule: RecurrenceRule) -> Date {
        RecurrenceEngine.nextOccurrence(from: baseDay, rule: rule)
    }

    private func adjustByScopeIfNeeded(_ day: Date, scope: RecurrenceScope) -> Date {
        switch scope {
        case .allDays: return day
        case .weekdaysOnly:
            let wd = Calendar.current.component(.weekday, from: day)
            if wd == 7 || wd == 1 { // weekend
                // move to next Monday
                var d = day
                while true {
                    d = Calendar.current.date(byAdding: .day, value: 1, to: d) ?? d
                    let w = Calendar.current.component(.weekday, from: d)
                    if w != 7 && w != 1 { return d }
                }
            }
            return day
        case .weekendsOnly:
            let wd = Calendar.current.component(.weekday, from: day)
            if wd == 7 || wd == 1 { return day }
            // move to next Saturday
            var d = day
            while true {
                d = Calendar.current.date(byAdding: .day, value: 1, to: d) ?? d
                let w = Calendar.current.component(.weekday, from: d)
                if w == 7 { return d }
            }
        }
    }

    private func alignReminderTime(toDay day: Date, from timeSource: Date) -> Date {
        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: timeSource)
        var comps = cal.dateComponents([.year, .month, .day], from: TaskItem.defaultDueDate(day))
        comps.hour = hm.hour
        comps.minute = hm.minute
        return cal.date(from: comps) ?? day
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

    // Persist a project-scoped tag in the project's catalog
    func addTag(toProject id: UUID, tag: String) {
        guard let idx = projects.firstIndex(where: { $0.id == id }) else { return }
        let normalized = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        var p = projects[idx]
        var set = Set((p.tags ?? []).map { $0 })
        // case-insensitive uniqueness
        if !set.contains(where: { $0.compare(normalized, options: .caseInsensitive) == .orderedSame }) {
            set.insert(normalized)
            p.tags = Array(set).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            projects[idx] = p
            saveProjects()
        }
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
                tasks[i].tag = nil
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
        dueDate: Date = TaskItem.defaultDueDate(),
        reminderAt: Date? = nil,
        recurrence: RecurrenceRule? = nil,
        tag: String? = nil
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let finalTag: String? = (project != nil) ? (tag?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty) : nil
        let task = TaskItem(title: trimmed, isDone: false, project: project, difficulty: difficulty, resistance: resistance, estimatedTime: estimatedTime, dueDate: dueDate, reminderAt: reminderAt, recurrence: recurrence, noteMarkdown: nil, noteUpdatedAt: nil, tag: finalTag)
        tasks.append(task)
        saveTasks()
        if let _ = task.reminderAt { NotificationManager.shared.scheduleReminder(for: task) }
    }

    func updateTask(
        id: UUID,
        title: String,
        project: ProjectItem?,
        difficulty: TaskDifficulty,
        resistance: TaskResistance,
        estimatedTime: TaskEstimatedTime,
        dueDate: Date,
        reminderAt: Date?,
        recurrence: RecurrenceRule?
    ) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        var current = tasks[idx]
        let previousProjectId = current.project?.id
        current.title = title
        current.project = project
        if previousProjectId != project?.id {
            current.tag = nil
        }
        current.difficulty = difficulty
        current.resistance = resistance
        current.estimatedTime = estimatedTime
        current.dueDate = dueDate
        current.recurrence = recurrence
        current.reminderAt = reminderAt
        tasks[idx] = current
        saveTasks()
        // Reschedule notification
        NotificationManager.shared.cancelReminder(for: id)
        if let _ = current.reminderAt, !current.isDone { NotificationManager.shared.scheduleReminder(for: current) }
    }

    // Update or create the markdown note attached to a task
    func updateTaskNote(id: UUID, noteMarkdown: String) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].noteMarkdown = noteMarkdown
        tasks[idx].noteUpdatedAt = Date()
        // Persist immediately; Combine sink will also save, but we want durability for autosave
        saveTasks()
    }

    func toggleTaskDone(id: UUID) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].isDone.toggle()
        if tasks[idx].isDone {
            tasks[idx].completedAt = Date()
            NotificationManager.shared.cancelReminder(for: id)
            // Handle recurrence: generate next occurrence if applicable and within limit
            if var rule = tasks[idx].recurrence {
                let doneCount = rule.occurrencesDone + 1
                if let limit = rule.countLimit, doneCount >= limit {
                    // Do not create a next one; keep history only
                } else {
                    // Propose next occurrence task (do not append yet)
                    let nextDT = nextDateTimeAfterCompletion(for: tasks[idx], rule: rule)
                    var nextRecurrence = rule
                    nextRecurrence.occurrencesDone = doneCount
                    let proposal = TaskItem(
                        title: tasks[idx].title,
                        isDone: false,
                        project: tasks[idx].project,
                        difficulty: tasks[idx].difficulty,
                        resistance: tasks[idx].resistance,
                        estimatedTime: tasks[idx].estimatedTime,
                        dueDate: TaskItem.defaultDueDate(nextDT),
                        reminderAt: tasks[idx].reminderAt != nil ? nextDT : nil,
                        recurrence: nextRecurrence
                    )
                    proposedNextOccurrence = proposal
                    nextOccurrence.send(proposal)
                    DispatchQueue.main.async { [weak self] in self?.lastGeneratedOccurrence = proposal }
                }
            }
        } else {
            tasks[idx].completedAt = nil
            // If task becomes incomplete and its due date is in the past, move it to Today immediately
            let today = TaskItem.defaultDueDate()
            if TaskItem.defaultDueDate(tasks[idx].dueDate) < today {
                tasks[idx].dueDate = today
                // If there's a reminder, move it to today's date at the same time
                if let when = tasks[idx].reminderAt {
                    tasks[idx].reminderAt = alignReminder(when, toDay: today)
                }
            }
            // Reschedule reminder if present and in the future
            NotificationManager.shared.cancelReminder(for: id)
            if let _ = tasks[idx].reminderAt { NotificationManager.shared.scheduleReminder(for: tasks[idx]) }
        }
        saveTasks()
    }

    // Compute next datetime for the next occurrence after completion
    private func nextDateTimeAfterCompletion(for task: TaskItem, rule: RecurrenceRule) -> Date {
        let now = task.completedAt ?? Date()
        switch rule.unit {
        case .minutes:
            return Calendar.current.date(byAdding: .minute, value: rule.interval, to: now) ?? now
        case .hours:
            return Calendar.current.date(byAdding: .hour, value: rule.interval, to: now) ?? now
        case .days, .weeks, .months, .years:
            // For >= day, compute next day from appropriate base then align reminder time if present
            let baseDay: Date = (rule.basis == .completion) ? TaskItem.defaultDueDate(now) : TaskItem.defaultDueDate(task.dueDate)
            let nextDay = nextOccurrenceDay(from: baseDay, rule: rule)
            if let when = task.reminderAt {
                return alignReminderTime(toDay: nextDay, from: when)
            }
            return nextDay
        }
    }

    // Confirm and create the proposed next occurrence (called from UI Accept/Edit)
    func confirmNextOccurrence(_ proposed: TaskItem) {
        // Ensure we create the latest proposed if available
        let toCreate = proposedNextOccurrence ?? proposed
        tasks.append(toCreate)
        saveTasks()
        if toCreate.reminderAt != nil { NotificationManager.shared.scheduleReminder(for: toCreate) }
        proposedNextOccurrence = nil
    }

    func setTaskDueDate(id: UUID, dueDate: Date) {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        let newDay = TaskItem.defaultDueDate(dueDate)
        tasks[idx].dueDate = newDay
        if let when = tasks[idx].reminderAt {
            tasks[idx].reminderAt = alignReminder(when, toDay: newDay)
        }
        saveTasks()
        // Reschedule reminder if present
        NotificationManager.shared.cancelReminder(for: id)
        if let _ = tasks[idx].reminderAt, !tasks[idx].isDone { NotificationManager.shared.scheduleReminder(for: tasks[idx]) }
    }

    func deleteTask(id: UUID) {
        tasks.removeAll { $0.id == id }
        NotificationManager.shared.cancelReminder(for: id)
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
            addTask(title: title, project: project, difficulty: diffs[di % diffs.count], resistance: ress[ri % ress.count], estimatedTime: times[ti % times.count], dueDate: due, reminderAt: nil)
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
            // Restore/schedule pending reminders for future dates
            for t in tasks where t.reminderAt != nil && !(t.isDone) {
                NotificationManager.shared.cancelReminder(for: t.id)
                NotificationManager.shared.scheduleReminder(for: t)
            }
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

    // MARK: - Reminder helpers
    private func alignReminder(_ reminder: Date, toDay day: Date) -> Date {
        let cal = Calendar.current
        let hm = cal.dateComponents([.hour, .minute], from: reminder)
        var comps = cal.dateComponents([.year, .month, .day], from: day)
        comps.hour = hm.hour
        comps.minute = hm.minute
        return cal.date(from: comps) ?? day
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
