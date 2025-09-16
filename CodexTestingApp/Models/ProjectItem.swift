import Foundation

struct ProjectItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var emoji: String
    // Optional stored color name for future use (e.g., background)
    var colorName: String? = nil

    init(id: UUID = UUID(), name: String, emoji: String, colorName: String? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorName = colorName
    }
}
