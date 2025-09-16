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
    @State private var editingProject: ProjectItem?
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
    @State private var newProjectColor: Color? = nil
    @State private var showingEmojiPicker = false
    @State private var isPickingForEdit = false
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
    // Edit project popup state
    @State private var editProjectName: String = ""
    @State private var editProjectEmoji: String = ""
    @State private var editProjectColor: Color? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                StoriesBar(projects: viewModel.projects, hasInbox: hasInbox, selectedFilter: $selectedFilter, onNew: {
                    showingAddProject = true
                }, tasks: viewModel.tasks, dateScope: dateScope, onProjectLongPress: { project in
                    editingProject = project
                    editProjectName = project.name
                    editProjectEmoji = project.emoji
                    editProjectColor = colorFromName(project.colorName)
                })

                DateScopeBar(dateScope: $dateScope, showScopeDatePicker: $showScopeDatePicker, scopeCustomDate: $scopeCustomDate)

                contentList
            }
            .onChange(of: viewModel.tasks) { _, tasks in
                // If there are no inbox tasks anymore, clear inbox filter
                if selectedFilter == .inbox && !tasks.contains(where: { $0.project == nil }) {
                    selectedFilter = .none
                }
            }
            .sheet(item: $editingTask) { task in
                editTaskSheet(task)
            }
            // Removed full-screen sheet for edit project; using overlay below
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
                let preselectedId: ProjectItem.ID? = {
                    if case .project(let id) = selectedFilter { return id }
                    return nil
                }()
                AddTaskView(
                    projects: viewModel.projects,
                    preSelectedProjectId: preselectedId,
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
            .overlay(alignment: .center) { newProjectOverlay() }
            .overlay(alignment: .center) { editProjectOverlay() }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView { selected in
                    if editingProject != nil && isPickingForEdit {
                        editProjectEmoji = selected
                    } else {
                        newProjectEmoji = selected
                    }
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
    private var projectColorSwatches: [Color] {
        [.yellow, .green, .blue, .purple, .pink, .orange, .teal, .mint, .indigo, .red, .brown, .gray]
    }
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
                            newProjectColor = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 12) {
                        Button {
                            isPickingForEdit = false
                            showingEmojiPicker = true
                        } label: {
                            ZStack {
                                Circle().fill(newProjectColor ?? Color.clear)
                                Circle().fill(.ultraThinMaterial)
                                Text(newProjectEmoji.isEmpty ? "✨" : newProjectEmoji)
                                    .font(.system(size: 24))
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)

                        TextField("Project name", text: $newProjectName)
                            .textInputAutocapitalization(.words)
                    }

                    // Color palette (horizontal scroll to avoid overflow)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(projectColorSwatches.enumerated()), id: \.offset) { _, color in
                                let isSelected = (newProjectColor?.description == color.description)
                                Button {
                                    if isSelected { newProjectColor = nil } else { newProjectColor = color }
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            Circle().strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Spacer()
                        Button("Cancel") {
                            showingAddProject = false
                            newProjectName = ""
                            newProjectEmoji = ""
                            newProjectColor = nil
                        }
                        Button("Create") {
                            let created: ProjectItem = viewModel.addProject(name: newProjectName.trimmingCharacters(in: .whitespacesAndNewlines), emoji: newProjectEmoji)
                            // select the newly created project
                            selectedFilter = .project(created.id)
                            showingAddProject = false
                            newProjectName = ""
                            newProjectEmoji = ""
                            newProjectColor = nil
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

    @ViewBuilder
    private func editProjectOverlay() -> some View {
        if let project = editingProject {
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Edit Project").font(.headline)
                        Spacer()
                        Button {
                            editingProject = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 12) {
                        Button {
                            isPickingForEdit = true
                            showingEmojiPicker = true
                        } label: {
                            ZStack {
                                Circle().fill(editProjectColor ?? Color.clear)
                                Circle().fill(.ultraThinMaterial)
                                Text(editProjectEmoji.isEmpty ? "✨" : editProjectEmoji)
                                    .font(.system(size: 24))
                            }
                            .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)

                        TextField("Project name", text: $editProjectName)
                            .textInputAutocapitalization(.words)
                    }

                    // Color palette (horizontal scroll)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(projectColorOptions.enumerated()), id: \.offset) { _, opt in
                                let isSelected = colorsEqual(editProjectColor, opt.color)
                                Button {
                                    editProjectColor = isSelected ? nil : opt.color
                                } label: {
                                    Circle()
                                        .fill(opt.color)
                                        .frame(width: 22, height: 22)
                                        .overlay(
                                            Circle().strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Spacer()
                        Button("Cancel") {
                            editingProject = nil
                        }
                        Button("Save") {
                            viewModel.updateProject(
                                id: project.id,
                                name: editProjectName,
                                emoji: editProjectEmoji,
                                colorName: colorName(from: editProjectColor)
                            )
                            editingProject = nil
                        }
                        .disabled(editProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editProjectEmoji.isEmpty)
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

    // Color helpers for edit mapping
    private var projectColorOptions: [(name: String, color: Color)] {
        [
            ("yellow", .yellow), ("green", .green), ("blue", .blue), ("purple", .purple), ("pink", .pink),
            ("orange", .orange), ("teal", .teal), ("mint", .mint), ("indigo", .indigo), ("red", .red), ("brown", .brown), ("gray", .gray)
        ]
    }

    private func colorFromName(_ name: String?) -> Color? {
        guard let name = name else { return nil }
        return projectColorOptions.first(where: { $0.name == name })?.color
    }

    private func colorName(from color: Color?) -> String? {
        guard let color = color else { return nil }
        return projectColorOptions.first(where: { $0.color.description == color.description })?.name
    }

    private func colorsEqual(_ a: Color?, _ b: Color?) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (x?, y?): return x.description == y.description
        default: return false
        }
    }
}
