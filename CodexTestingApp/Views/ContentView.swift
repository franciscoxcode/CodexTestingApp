//
//  ContentView.swift
//  CodexTestingApp
//
//  Created by Francisco Jean on 15/09/25.
//

import SwiftUI
import Combine
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var isPresentingAdd = false
    @State private var isPresentingManageProjects = false
    @State private var editingTask: TaskItem?
    @State private var editingProject: ProjectItem?
    @State private var userPoints: Int = 0
    @State private var showingCompletedSheet = false
    @State private var pendingDeleteTask: TaskItem? = nil
    @State private var pendingRescheduleTask: TaskItem? = nil
    @State private var pendingMoveTask: TaskItem? = nil
    @State private var rescheduleDate: Date = TaskItem.defaultDueDate()
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
    // Anchor to trigger recalculation on day/phase changes
    @State private var timeAnchor: Date = Date()
    // Edit project popup state
    @State private var editProjectName: String = ""
    @State private var editProjectEmoji: String = ""
    @State private var editProjectColor: Color? = nil
    // Pending hide window for recently completed tasks
    @State private var pendingHideUntil: [UUID: Date] = [:]

    var body: some View {
        NavigationStack {
            VStack(spacing: 6) {
                // Row 1: top-right plus button
                HStack {
                    Spacer()
                    #if DEBUG
                    #if targetEnvironment(simulator)
                    Button {
                        viewModel.resetAndSeedSampleData()
                        userPoints = 0
                        UserDefaults.standard.set(0, forKey: "userPoints")
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.headline)
                    }
                    .accessibilityLabel("Reset Sample Data")
                    .padding(.trailing, 8)
                    #endif
                    #endif
                    Button {
                        isPresentingManageProjects = true
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.headline)
                    }
                    .accessibilityLabel("Manage Projects")
                    .padding(.trailing, 8)
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                    }
                    .accessibilityLabel("Add Task")
                }
                .padding(.horizontal, 8)
                

                // Row 2: title on left, points on right
                HStack(alignment: .center) {
                    Text("NoteBites")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    PointsBadge(points: userPoints, onTap: { showingCompletedSheet = true })
                }
                .padding(.top, 21)
                .padding(.bottom, 13)
                .padding(.horizontal, 8)

                // Row 3: projects bar
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
            .onChangeCompat(of: viewModel.tasks) { _, tasks in
                // If there are no inbox tasks anymore, clear inbox filter
                if selectedFilter == .inbox && !tasks.contains(where: { $0.project == nil }) {
                    selectedFilter = .none
                }
            }
            .alert(
                pendingDeleteTask.map { "Delete ‘\($0.title)’?" } ?? "Delete task?",
                isPresented: .init(get: { pendingDeleteTask != nil }, set: { if !$0 { pendingDeleteTask = nil } })
            ) {
                Button("Delete", role: .destructive) {
                    if let t = pendingDeleteTask {
                        viewModel.deleteTask(id: t.id)
                        pendingDeleteTask = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingDeleteTask = nil }
            } message: {
                if let t = pendingDeleteTask {
                    Text("This will permanently remove ‘\(t.title)’.")
                } else {
                    Text("This action cannot be undone.")
                }
            }
            .sheet(item: $editingTask) { task in
                editTaskSheet(task)
            }
            // Removed full-screen sheet for edit project; using overlay below
            .padding()
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
            .sheet(isPresented: $isPresentingManageProjects) {
                ManageProjectsView(projects: viewModel.projects) { ids in
                    viewModel.applyProjectOrder(idsInOrder: ids)
                }
            }
            .onAppear {
                // Load persisted points
                userPoints = UserDefaults.standard.integer(forKey: "userPoints")

                // Only seed sample data in Debug + Simulator to keep
                // physical devices/installations starting empty.
                #if DEBUG
                #if targetEnvironment(simulator)
                if viewModel.tasks.isEmpty {
                    viewModel.seedSampleData()
                }
                #endif
                #endif
            }
            // Refresh date-scoped views when app becomes active or clock changes significantly
            .onChangeCompat(of: scenePhase) { _, phase in
                if phase == .active {
                    timeAnchor = Date()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                timeAnchor = Date()
            }
            .onChangeCompat(of: userPoints) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "userPoints")
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
            .fullScreenCover(isPresented: $showingCompletedSheet) {
                completedSheet
            }
            .confirmationDialog(
                pendingMoveTask.map { "Move ‘\($0.title)’ to…" } ?? "Move to date",
                isPresented: .init(get: { pendingMoveTask != nil }, set: { if !$0 { pendingMoveTask = nil } })
            ) {
                if let t = pendingMoveTask {
                    let due = TaskItem.defaultDueDate(t.dueDate)
                    let today = TaskItem.defaultDueDate()
                    let tomorrow = TaskItem.defaultDueDate(nextDays(1))
                    let weekend = TaskItem.defaultDueDate(upcomingSaturday())
                    if due != today {
                        Button("Today") {
                            viewModel.setTaskDueDate(id: t.id, dueDate: today)
                            pendingMoveTask = nil
                        }
                    }
                    if due != tomorrow {
                        Button("Tomorrow") {
                            viewModel.setTaskDueDate(id: t.id, dueDate: tomorrow)
                            pendingMoveTask = nil
                        }
                    }
                    if due != weekend {
                        Button("Weekend") {
                            viewModel.setTaskDueDate(id: t.id, dueDate: weekend)
                            pendingMoveTask = nil
                        }
                    }
                    Button("Pick date") {
                        pendingRescheduleTask = t
                        rescheduleDate = t.dueDate
                        pendingMoveTask = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingMoveTask = nil }
            }
            .sheet(isPresented: .init(get: { pendingRescheduleTask != nil }, set: { if !$0 { pendingRescheduleTask = nil } })) {
                rescheduleSheet
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
        _ = timeAnchor // depend on anchor so date-based filters refresh
        // Base by date scope
        let scoped: [TaskItem] = {
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
        }()
        // Hide completed tasks except during grace window
        let now = Date()
        return scoped.filter { task in
            guard task.isDone else { return true }
            if let until = pendingHideUntil[task.id], until > now { return true }
            return false
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
                    onLongPress: { _ in },
                    onProjectTap: { project in selectedFilter = .project(project.id) },
                    onToggle: { task in handleToggle(task) },
                    onEdit: { task in editingTask = task },
                    onDelete: { task in pendingDeleteTask = task },
                    onMoveMenu: { task in pendingMoveTask = task }
                )
            }
        } else {
            if filteredTasks.isEmpty {
                ContentUnavailableView("No tasks yet", systemImage: "checklist", description: Text("Tap + to add your first task."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                switch (selectedFilter, dateScope) {
                case (.project, .anytime):
                    TasksByDueDateView(
                        tasks: filteredTasks,
                        onLongPress: { _ in },
                        onProjectTap: { project in selectedFilter = .project(project.id) },
                        onToggle: { task in handleToggle(task) },
                        onEdit: { task in editingTask = task },
                        onDelete: { task in pendingDeleteTask = task },
                        onMoveMenu: { task in pendingMoveTask = task }
                    )
                    .id(timeAnchor) // force regrouping headers on day change
                default:
                    TaskFlatListView(
                        title: headerTitle,
                        tasks: filteredTasks,
                        onLongPress: { _ in },
                        onProjectTap: { project in selectedFilter = .project(project.id) },
                        onToggle: { task in handleToggle(task) },
                        onEdit: { task in editingTask = task },
                        onDelete: { task in pendingDeleteTask = task },
                        onMoveMenu: { task in pendingMoveTask = task }
                    )
                }
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
            },
            onDelete: {
                viewModel.deleteTask(id: task.id)
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
                            ForEach(Array(projectColorSwatches.enumerated()), id: \.offset) { pair in
                                let color = pair.element
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
                            ForEach(Array(projectColorOptions.enumerated()), id: \.offset) { pair in
                                let opt = pair.element
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
                        Button(role: .destructive) {
                            if let p = editingProject {
                                // If currently filtered by this project, reset filter
                                if case .project(let id) = selectedFilter, id == p.id {
                                    selectedFilter = .none
                                }
                                viewModel.deleteProject(id: p.id)
                                editingProject = nil
                            }
                        } label: {
                            Text("Delete")
                        }
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

    // Toggle handler + points logic
    private func handleToggle(_ task: TaskItem) {
        let wasDone = task.isDone
        viewModel.toggleTaskDone(id: task.id)
        let delta = points(for: task)
        if !wasDone {
            userPoints += delta
            // Show for ~2 seconds before hiding from lists
            let until = Date().addingTimeInterval(2)
            pendingHideUntil[task.id] = until
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // If still completed, remove grace period so it disappears
                if let current = viewModel.tasks.first(where: { $0.id == task.id }), current.isDone {
                    pendingHideUntil[task.id] = nil
                }
            }
        } else {
            userPoints -= delta
            if userPoints < 0 { userPoints = 0 }
            // Cancel any pending hide if user reverted
            pendingHideUntil[task.id] = nil
        }
    }

    private func points(for task: TaskItem) -> Int {
        let difficultyPoints: Int = {
            switch task.difficulty {
            case .easy: return 10
            case .medium: return 20
            case .hard: return 35
            }
        }()
        let resistancePoints: Int = {
            switch task.resistance {
            case .low: return 5
            case .medium: return 10
            case .high: return 20
            }
        }()
        let timePoints: Int = {
            switch task.estimatedTime {
            case .short: return 5
            case .medium: return 10
            case .long: return 15
            }
        }()
        return difficultyPoints + resistancePoints + timePoints
    }

    // Completed tasks sheet
    @ViewBuilder
    private var completedSheet: some View {
        CompletedTasksView(
            tasks: viewModel.tasks,
            onUncomplete: { task in handleToggle(task) },
            onClose: { showingCompletedSheet = false }
        )
    }

    // Reschedule date picker sheet
    @ViewBuilder
    private var rescheduleSheet: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Cancel") { pendingRescheduleTask = nil }
                Spacer()
                Text("Pick Date").font(.headline)
                Spacer()
                Button("Save") {
                    if let t = pendingRescheduleTask {
                        viewModel.setTaskDueDate(id: t.id, dueDate: rescheduleDate)
                    }
                    pendingRescheduleTask = nil
                }
            }
            .padding(.horizontal)

            DatePicker("", selection: $rescheduleDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 332)
                .clipped()
                .padding(.horizontal)
                .animation(.none, value: rescheduleDate)
        }
        .padding(.vertical, 8)
        .presentationDetents([.height(420)])
        .presentationDragIndicator(.visible)
    }
}

// Simple points badge view (top-right)
private struct PointsBadge: View {
    let points: Int
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(.yellow)
            Text("\(points)")
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .overlay(
            Capsule().stroke(Color.secondary.opacity(0.3))
        )
        .clipShape(Capsule())
        .onTapGesture { onTap?() }
    }
}

// (TitleWithPoints removed; using in-content header row instead)
