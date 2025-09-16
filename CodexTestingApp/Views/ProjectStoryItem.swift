import SwiftUI

struct ProjectStoryItem: View {
    let project: ProjectItem
    let isSelected: Bool
    var dimmed: Bool = false
    var hasActiveForScope: Bool = false
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
                .frame(width: 58, height: 58)
                // Base subtle border inside to avoid clipping
                .overlay(
                    Circle()
                        .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                )
                // Gradient ring rules:
                // - Selected (always): yellow-green ring
                // - Not selected but has tasks for scope: blue-purple ring
                // - Otherwise: no gradient ring
                .overlay(
                    Group {
                        if isSelected {
                            Circle()
                                .strokeBorder(
                                    AngularGradient(
                                        gradient: Gradient(colors: [Color.yellow, Color.green, Color.yellow]),
                                        center: .center
                                    ),
                                    lineWidth: 4
                                )
                        } else if hasActiveForScope {
                            Circle()
                                .strokeBorder(
                                    AngularGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple, Color.blue]),
                                        center: .center
                                    ),
                                    lineWidth: 4
                                )
                        }
                    }
                )
                .padding(.top, 2) // ensure no top clipping even with thick stroke

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
