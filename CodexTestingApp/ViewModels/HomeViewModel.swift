import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var tasks: [TaskItem] = []

    func addTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        tasks.append(TaskItem(title: trimmed))
    }
}
