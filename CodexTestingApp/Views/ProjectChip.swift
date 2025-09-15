import SwiftUI

struct ProjectChip: View {
    let project: ProjectItem
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(project.emoji)
                Text(project.name)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.15) : Color.clear)
            .overlay(
                Capsule().stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3))
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct NewProjectChip: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Label("New", systemImage: "plus")
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Color.secondary.opacity(0.3))
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
