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
    var difficulty: TaskDifficulty
    var resistance: TaskResistance
    var estimatedTime: TaskEstimatedTime
    var dueDate: Date
    // Optional recurrence configuration (Phase 1)
    var recurrence: RecurrenceRule? = nil
    // Optional reminder datetime for local notification
    var reminderAt: Date? = nil

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
        recurrence: RecurrenceRule? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.completedAt = nil
        self.project = project
        self.difficulty = difficulty
        self.resistance = resistance
        self.estimatedTime = estimatedTime
        self.dueDate = dueDate
        self.reminderAt = reminderAt
        self.recurrence = recurrence
    }

    static func defaultDueDate(_ date: Date = Date()) -> Date {
        // Normalize to start of day to avoid time-of-day variability
        Calendar.current.startOfDay(for: date)
    }
}
