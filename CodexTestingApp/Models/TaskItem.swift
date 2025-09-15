import Foundation

enum TaskDifficulty: String, Codable, CaseIterable { case easy, medium, hard }
enum TaskResistance: String, Codable, CaseIterable { case low, medium, high }
enum TaskEstimatedTime: String, Codable, CaseIterable { case short, medium, long }

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
    var project: ProjectItem?
    var difficulty: TaskDifficulty
    var resistance: TaskResistance
    var estimatedTime: TaskEstimatedTime

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        project: ProjectItem? = nil,
        difficulty: TaskDifficulty = .easy,
        resistance: TaskResistance = .low,
        estimatedTime: TaskEstimatedTime = .short
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.project = project
        self.difficulty = difficulty
        self.resistance = resistance
        self.estimatedTime = estimatedTime
    }
}
