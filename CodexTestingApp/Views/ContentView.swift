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
    enum TaskFilter: Equatable {
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
    // Secondary date scope filter
    enum DateScope: Equatable {
        case anytime
        case today
        case tomorrow
        case weekend
        case custom(Date)
    }
    @State private var dateScope: DateScope = .today
    @State private var showScopeDatePicker = false
    @State private var scopeCustomDate: Date = TaskItem.defaultDueDate()

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                StoriesBar(projects: viewModel.projects, hasInbox: hasInbox, selectedFilter: $selectedFilter) {
                    showingAddProject = true
                }

                DateScopeBar(dateScope: $dateScope, showScopeDatePicker: $showScopeDatePicker, scopeCustomDate: $scopeCustomDate)

                contentList
            }
            .onChange(of: viewModel.tasks) { _ in
                // If there are no inbox tasks anymore, clear inbox filter
                if selectedFilter == .inbox && !viewModel.tasks.contains(where: { $0.project == nil }) {
                    selectedFilter = .none
                }
            }
            .sheet(item: $editingTask) { task in
                editTaskSheet(task)
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
                newProjectOverlay()
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

// MARK: - Helpers
private func nextDays(_ days: Int, from date: Date = Date()) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
}

private func isCustomScope(_ scope: ContentView.DateScope) -> Bool {
    if case .custom(_) = scope { return true } else { return false }
}

private func upcomingSaturday(from date: Date = Date()) -> Date {
    let sat = 7 // Saturday in Gregorian
    var cal = Calendar.current
    cal.firstWeekday = 1 // Sunday
    let current = cal.component(.weekday, from: date)
    if current == sat { return date }
    var days = sat - current
    if days <= 0 { days += 7 }
    return cal.date(byAdding: .day, value: days, to: date) ?? date
}

// MARK: - ContentView helpers extracted to reduce type-check complexity
extension ContentView {
    private var hasInbox: Bool {
        viewModel.tasks.contains { $0.project == nil }
    }

    private var baseTasks: [TaskItem] {
        switch selectedFilter {
        case .none:
            return viewModel.tasks
        case .inbox:
            return viewModel.tasks.filter { $0.project == nil }
        case .project(let id):
            return viewModel.tasks.filter { $0.project?.id == id }
        }
    }

    private var filteredTasks: [TaskItem] {
        switch dateScope {
        case .anytime:
            return baseTasks
        case .today:
            let today: Date = TaskItem.defaultDueDate()
            return baseTasks.filter { TaskItem.defaultDueDate($0.dueDate) == today }
        case .tomorrow:
            let target: Date = TaskItem.defaultDueDate(nextDays(1))
            return baseTasks.filter { TaskItem.defaultDueDate($0.dueDate) == target }
        case .weekend:
            let target: Date = TaskItem.defaultDueDate(upcomingSaturday())
            return baseTasks.filter { TaskItem.defaultDueDate($0.dueDate) == target }
        case .custom(let d):
            let target: Date = TaskItem.defaultDueDate(d)
            return baseTasks.filter { TaskItem.defaultDueDate($0.dueDate) == target }
        }
    }

    private var headerTitle: String {
        switch selectedFilter {
        case .project(let id):
            return viewModel.projects.first(where: { $0.id == id })?.name ?? "Project"
        case .inbox:
            return "Unassigned"
        case .none:
            return ""
        }
    }

    @ViewBuilder
    private var contentList: some View {
        if selectedFilter == .none {
            if viewModel.tasks.isEmpty {
                ContentUnavailableView("No tasks yet", systemImage: "checklist", description: Text("Tap + to add your first task."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                AllTaskSectionsView(
                    projects: viewModel.projects,
                    tasks: filteredTasks,
                    onLongPress: { task in editingTask = task },
                    onProjectTap: { project in selectedFilter = .project(project.id) }
                )
            }
        } else {
            if filteredTasks.isEmpty {
                ContentUnavailableView("No tasks yet", systemImage: "checklist", description: Text("Tap + to add your first task."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TaskFlatListView(
                    title: headerTitle,
                    tasks: filteredTasks,
                    onLongPress: { task in editingTask = task },
                    onProjectTap: { project in selectedFilter = .project(project.id) }
                )
            }
        }
    }

    @ViewBuilder
    private func editTaskSheet(_ task: TaskItem) -> some View {
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

    @ViewBuilder
    private func newProjectOverlay() -> some View {
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
                            let created: ProjectItem = viewModel.addProject(name: newProjectName.trimmingCharacters(in: .whitespacesAndNewlines), emoji: newProjectEmoji)
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
}
