import SwiftUI

struct ProjectStoryItem: View {
    let project: ProjectItem
    let isSelected: Bool
    var highlightColor: Color? = nil
    var dimmed: Bool = false
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
                        .stroke(
                            isSelected ? Color.blue : (highlightColor ?? Color.secondary.opacity(0.3)),
                            lineWidth: isSelected ? 2 : (highlightColor != nil ? 2 : 1)
                        )
                )

                Text(project.name)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: 64)
                    .foregroundStyle(.primary)
            }
            .opacity(dimmed ? 0.45 : 1)
        }
        .buttonStyle(.plain)
    }
}
