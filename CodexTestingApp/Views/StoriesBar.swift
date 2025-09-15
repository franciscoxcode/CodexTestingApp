import SwiftUI

struct StoriesBar: View {
    let projects: [ProjectItem]
    let hasInbox: Bool
    @Binding var selectedFilter: ContentView.TaskFilter
    var onNew: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                StoryItem(title: "New", emoji: "＋", isSelected: false) { onNew() }

                if hasInbox {
                    StoryItem(title: "Unassigned", emoji: "📥", isSelected: selectedFilter == ContentView.TaskFilter.inbox) {
                        selectedFilter = (selectedFilter == ContentView.TaskFilter.inbox) ? ContentView.TaskFilter.none : ContentView.TaskFilter.inbox
                    }
                }

                StoryItem(title: "All", emoji: "🗂️", isSelected: selectedFilter == ContentView.TaskFilter.none) {
                    selectedFilter = ContentView.TaskFilter.none
                }

                ForEach(projects) { project in
                    ProjectStoryItem(
                        project: project,
                        isSelected: selectedFilter == ContentView.TaskFilter.project(project.id),
                        onTap: {
                            selectedFilter = (selectedFilter == ContentView.TaskFilter.project(project.id)) ? ContentView.TaskFilter.none : ContentView.TaskFilter.project(project.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 4)
    }
}
