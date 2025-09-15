import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""

    // Projects input and callbacks
    let projects: [ProjectItem]
    var onCreateProject: (String, String) -> ProjectItem
    var onSave: (_ title: String, _ project: ProjectItem) -> Void

    // Selection state
    @State private var selectedProjectId: ProjectItem.ID?
    @State private var projectList: [ProjectItem] = []
    @State private var showingAddProject = false
    @State private var newProjectName: String = ""
    @State private var newProjectEmoji: String = ""
    @State private var showingEmojiPicker = false

    init(projects: [ProjectItem], onCreateProject: @escaping (String, String) -> ProjectItem, onSave: @escaping (_ title: String, _ project: ProjectItem) -> Void) {
        self.projects = projects
        self.onCreateProject = onCreateProject
        self.onSave = onSave
        _selectedProjectId = State(initialValue: projects.first?.id)
        _projectList = State(initialValue: projects)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(header: Text("Task")) {
                        TextField("Enter task title", text: $title)
                            .textInputAutocapitalization(.sentences)
                            .submitLabel(.done)
                    }

                    Section(header: Text("Project")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                NewProjectChip { showingAddProject = true }
                                ForEach(projectList) { project in
                                    ProjectChip(
                                        project: project,
                                        isSelected: selectedProjectId == project.id,
                                        onTap: { selectedProjectId = project.id }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                // Popup centered overlay
                if showingAddProject {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("New Project").font(.headline)
                            Spacer()
                            Button {
                                showingAddProject = false
                                newProjectName = ""
                                newProjectEmoji = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        HStack(spacing: 12) {
                            Button {
                                showingEmojiPicker = true
                            } label: {
                                Text(newProjectEmoji.isEmpty ? "✨" : newProjectEmoji)
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)

                            TextField("Project name", text: $newProjectName)
                                .textInputAutocapitalization(.words)
                        }

                        HStack {
                            Spacer()
                            Button("Cancel") {
                                showingAddProject = false
                                newProjectName = ""
                                newProjectEmoji = ""
                            }
                            Button("Create") {
                                let created = onCreateProject(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines), newProjectEmoji)
                                projectList.append(created)
                                selectedProjectId = created.id
                                showingAddProject = false
                                newProjectName = ""
                                newProjectEmoji = ""
                            }
                            .disabled(!canCreateProject)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: 360)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 20)
                    .offset(y: -60)
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView { selected in
                    newProjectEmoji = selected
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedProjectId != nil
    }

    private func save() {
        guard let id = selectedProjectId, let project = projectList.first(where: { $0.id == id }) else { return }
        onSave(title, project)
        dismiss()
    }

    private var canCreateProject: Bool {
        !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !newProjectEmoji.isEmpty
    }
}
