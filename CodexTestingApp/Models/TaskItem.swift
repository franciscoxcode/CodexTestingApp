import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
    var project: ProjectItem?

    init(id: UUID = UUID(), title: String, isDone: Bool = false, project: ProjectItem? = nil) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.project = project
    }
}
