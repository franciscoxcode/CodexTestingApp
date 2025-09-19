import Foundation

enum TaskDifficulty: String, Codable, CaseIterable { case easy, medium, hard }
enum TaskResistance: String, Codable, CaseIterable { case low, medium, high }
enum TaskEstimatedTime: String, Codable, CaseIterable { case short, medium, long }

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
    var completedAt: Date? = nil
    var project: ProjectItem?
    // Optional single tag scoped to the task's project
    var tag: String? = nil
    var difficulty: TaskDifficulty
    var resistance: TaskResistance
    var estimatedTime: TaskEstimatedTime
    var dueDate: Date
    // Optional recurrence configuration (Phase 1)
    var recurrence: RecurrenceRule? = nil
    // Optional reminder datetime for local notification
    var reminderAt: Date? = nil
    // Optional markdown note linked to the task
    var noteMarkdown: String? = nil
    var noteUpdatedAt: Date? = nil

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        project: ProjectItem? = nil,
        difficulty: TaskDifficulty = .easy,
        resistance: TaskResistance = .low,
        estimatedTime: TaskEstimatedTime = .short,
        dueDate: Date = TaskItem.defaultDueDate(),
        reminderAt: Date? = nil,
        recurrence: RecurrenceRule? = nil,
        noteMarkdown: String? = nil,
        noteUpdatedAt: Date? = nil,
        tag: String? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.completedAt = nil
        self.project = project
        self.tag = tag
        self.difficulty = difficulty
        self.resistance = resistance
        self.estimatedTime = estimatedTime
        self.dueDate = dueDate
        self.reminderAt = reminderAt
        self.recurrence = recurrence
        self.noteMarkdown = noteMarkdown
        self.noteUpdatedAt = noteUpdatedAt
    }

    static func defaultDueDate(_ date: Date = Date()) -> Date {
        // Normalize to start of day to avoid time-of-day variability
        Calendar.current.startOfDay(for: date)
    }
}
