import SwiftUI

struct StoryItem: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    var selectedRingGradient: AngularGradient? = nil
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                    Text(emoji).font(.system(size: 24))
                }
                .frame(width: selectedRingGradient != nil ? 58 : 56, height: selectedRingGradient != nil ? 58 : 56)
                // Base subtle inner border
                .overlay(
                    Circle().strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                )
                // Selected gradient ring (if provided), otherwise default solid selection ring
                .overlay(
                    Group {
                        if isSelected, let gradient = selectedRingGradient {
                            Circle()
                                .strokeBorder(gradient, lineWidth: 4)
                        } else {
                            Circle()
                                .stroke(isSelected ? Color.blue : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                        }
                    }
                )
                .padding(.top, selectedRingGradient != nil ? 2 : 0)

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
