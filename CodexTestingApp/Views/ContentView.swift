//
//  ContentView.swift
//  CodexTestingApp
//
//  Created by Francisco Jean on 15/09/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var isPresentingAdd = false
    @State private var editingTask: TaskItem?
    private enum TaskFilter: Equatable {
        case none
        case inbox
        case project(ProjectItem.ID)
    }
    @State private var selectedFilter: TaskFilter = .none
    // New project popup state
    @State private var showingAddProject = false
    @State private var newProjectName: String = ""
    @State private var newProjectEmoji: String = ""
    @State private var showingEmojiPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                let hasInbox = viewModel.tasks.contains { $0.project == nil }
                // Project stories bar (always visible)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        // New (always first)
                        StoryItem(title: "New", emoji: "＋", isSelected: false) {
                            showingAddProject = true
                        }
                        // Inbox (second) — only if there are unassigned tasks
                        if hasInbox {
                            StoryItem(title: "Inbox", emoji: "📥", isSelected: selectedFilter == .inbox) {
                                selectedFilter = (selectedFilter == .inbox) ? .none : .inbox
                            }
                        }
                        // All (third)
                        StoryItem(title: "All", emoji: "🗂️", isSelected: selectedFilter == .none) {
                            selectedFilter = .none
                        }

                        // Projects
                        ForEach(viewModel.projects) { project in
                            ProjectStoryItem(
                                project: project,
                                isSelected: selectedFilter == .project(project.id),
                                onTap: {
                                    selectedFilter = (selectedFilter == .project(project.id)) ? .none : .project(project.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.vertical, 4)

                // Filter tasks
                let tasksToShow: [TaskItem] = {
                    switch selectedFilter {
                    case .none:
                        return viewModel.tasks
                    case .inbox:
                        return viewModel.tasks.filter { $0.project == nil }
                    case .project(let id):
                        return viewModel.tasks.filter { $0.project?.id == id }
                    }
                }()

                if tasksToShow.isEmpty {
                    ContentUnavailableView("No tasks yet", systemImage: "checklist", description: Text("Tap + to add your first task."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(tasksToShow) { task in
                        TaskRow(task: task, onProjectTap: { project in
                            selectedFilter = .project(project.id)
                        })
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                editingTask = task
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .onChange(of: viewModel.tasks) { _ in
                // If there are no inbox tasks anymore, clear inbox filter
                if selectedFilter == .inbox && !viewModel.tasks.contains(where: { $0.project == nil }) {
                    selectedFilter = .none
                }
            }
            .sheet(item: $editingTask) { task in
                EditTaskView(
                    task: task,
                    projects: viewModel.projects,
                    onCreateProject: { name, emoji in
                        viewModel.addProject(name: name, emoji: emoji)
                    },
                    onSave: { title, project, difficulty, resistance, estimated, dueDate in
                        viewModel.updateTask(
                            id: task.id,
                            title: title,
                            project: project,
                            difficulty: difficulty,
                            resistance: resistance,
                            estimatedTime: estimated,
                            dueDate: dueDate
                        )
                    }
                )
            }
            .padding()
            .navigationTitle("NoteBites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Task")
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddTaskView(
                    projects: viewModel.projects,
                    onCreateProject: { name, emoji in
                        viewModel.addProject(name: name, emoji: emoji)
                    },
                    onSave: { title, project, difficulty, resistance, estimated, dueDate in
                        viewModel.addTask(title: title, project: project, difficulty: difficulty, resistance: resistance, estimatedTime: estimated, dueDate: dueDate)
                    }
                )
            }
            .onAppear {
                if viewModel.tasks.isEmpty {
                    viewModel.seedSampleData()
                }
            }
            // New Project popup overlay
            .overlay(alignment: .center) {
                if showingAddProject {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()

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
                                Button { showingEmojiPicker = true } label: {
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
                                    let created = viewModel.addProject(name: newProjectName.trimmingCharacters(in: .whitespacesAndNewlines), emoji: newProjectEmoji)
                                    // select the newly created project
                                    selectedFilter = .project(created.id)
                                    showingAddProject = false
                                    newProjectName = ""
                                    newProjectEmoji = ""
                                }
                                .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newProjectEmoji.isEmpty)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: 360)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(radius: 20)
                        .offset(y: -140)
                    }
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
}

#Preview {
    ContentView()
}
