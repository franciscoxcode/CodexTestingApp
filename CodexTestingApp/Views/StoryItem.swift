import SwiftUI

struct StoryItem: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                    Text(emoji).font(.system(size: 24))
                }
                .frame(width: 56, height: 56)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                )

                Text(title)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: 64)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

