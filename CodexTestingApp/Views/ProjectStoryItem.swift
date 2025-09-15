import SwiftUI

struct ProjectStoryItem: View {
    let project: ProjectItem
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                    Text(project.emoji)
                        .font(.system(size: 24))
                }
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )

                Text(project.name)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: 64)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

