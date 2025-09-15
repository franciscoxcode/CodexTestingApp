import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""

    // Projects input and callbacks
    let projects: [ProjectItem]
    var onCreateProject: (String, String) -> ProjectItem
    var onSave: (_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date) -> Void

    // Selection state
    @State private var selectedProjectId: ProjectItem.ID?
    @State private var projectList: [ProjectItem] = []
    @State private var showingAddProject = false
    @State private var newProjectName: String = ""
    @State private var newProjectEmoji: String = ""
    @State private var showingEmojiPicker = false
    // Attributes
    @State private var difficulty: TaskDifficulty = .easy
    @State private var resistance: TaskResistance = .low
    @State private var estimated: TaskEstimatedTime = .short
    // Info toggles
    @State private var showDifficultyInfo = false
    @State private var showResistanceInfo = false
    @State private var showEstimatedInfo = false
    // Due date
    enum DuePreset { case today, tomorrow, weekend, nextWeek, custom }
    @State private var duePreset: DuePreset = .today
    @State private var dueDate: Date = TaskItem.defaultDueDate()
    @State private var showDueInfo = false
    @State private var showCustomDatePicker = false

    init(projects: [ProjectItem], onCreateProject: @escaping (String, String) -> ProjectItem, onSave: @escaping (_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date) -> Void) {
        self.projects = projects
        self.onCreateProject = onCreateProject
        self.onSave = onSave
        _selectedProjectId = State(initialValue: nil)
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

                    // Due Date
                    Section {
                        HStack(spacing: 8) {
                            Text("Due Date").font(.headline)
                            Button { showDueInfo.toggle() } label: { Image(systemName: "info.circle") }
                                .buttonStyle(.plain)
                                .popover(isPresented: $showDueInfo, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                                    Text("Pick when you plan to do it. You can change it anytime.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(12)
                                        .frame(maxWidth: 260)
                                }
                                .presentationCompactAdaptation(.popover)
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                SelectableChip(title: "Today", isSelected: duePreset == .today, color: .blue) {
                                    duePreset = .today
                                    dueDate = TaskItem.defaultDueDate()
                                    showCustomDatePicker = false
                                }
                                SelectableChip(title: "Tomorrow", isSelected: duePreset == .tomorrow, color: .blue) {
                                    duePreset = .tomorrow
                                    dueDate = TaskItem.defaultDueDate(nextDays(1))
                                    showCustomDatePicker = false
                                }
                                SelectableChip(title: "This weekend", isSelected: duePreset == .weekend, color: .blue) {
                                    duePreset = .weekend
                                    dueDate = TaskItem.defaultDueDate(upcomingSaturday())
                                    showCustomDatePicker = false
                                }
                                SelectableChip(title: "Next week", isSelected: duePreset == .nextWeek, color: .blue) {
                                    duePreset = .nextWeek
                                    dueDate = TaskItem.defaultDueDate(nextWeekMonday())
                                    showCustomDatePicker = false
                                }
                                SelectableChip(title: "Pick date…", isSelected: duePreset == .custom, color: .blue) {
                                    if duePreset != .custom {
                                        duePreset = .custom
                                        showCustomDatePicker = true
                                    } else {
                                        showCustomDatePicker.toggle()
                                    }
                                }
                            }
                        }
                        if duePreset == .custom && showCustomDatePicker {
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                        }
                    }

                    // Difficulty
                    Section {
                        HStack(spacing: 8) {
                            Text("🗡️ Difficulty").font(.headline)
                            Button { showDifficultyInfo.toggle() } label: { Image(systemName: "info.circle") }
                                .buttonStyle(.plain)
                                .popover(isPresented: $showDifficultyInfo, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                                    Text("Easy: fast and routine. Medium: several steps or moderate focus. Hard: challenging or unclear scope.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(12)
                                        .frame(maxWidth: 260)
                                }
                                .presentationCompactAdaptation(.popover)
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                SelectableChip(title: "Easy", isSelected: difficulty == .easy, color: .green) { difficulty = .easy }
                                SelectableChip(title: "Medium", isSelected: difficulty == .medium, color: .yellow) { difficulty = .medium }
                                SelectableChip(title: "Hard", isSelected: difficulty == .hard, color: .red) { difficulty = .hard }
                            }
                        }
                    }

                    // Resistance
                    Section {
                        HStack(spacing: 8) {
                            Text("😖 Resistance").font(.headline)
                            Button { showResistanceInfo.toggle() } label: { Image(systemName: "info.circle") }
                                .buttonStyle(.plain)
                                .popover(isPresented: $showResistanceInfo, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                                    Text("Low: eager to start. Medium: some friction. High: strong avoidance.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(12)
                                        .frame(maxWidth: 260)
                                }
                                .presentationCompactAdaptation(.popover)
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                SelectableChip(title: "Low", isSelected: resistance == .low, color: .green) { resistance = .low }
                                SelectableChip(title: "Medium", isSelected: resistance == .medium, color: .yellow) { resistance = .medium }
                                SelectableChip(title: "High", isSelected: resistance == .high, color: .red) { resistance = .high }
                            }
                        }
                    }

                    // Estimated Time
                    Section {
                        HStack(spacing: 8) {
                            Text("⏳ Estimated Time").font(.headline)
                            Button { showEstimatedInfo.toggle() } label: { Image(systemName: "info.circle") }
                                .buttonStyle(.plain)
                                .popover(isPresented: $showEstimatedInfo, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                                    Text("Define what Short/Medium/Long mean for you. Choose what feels right.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .padding(12)
                                        .frame(maxWidth: 260)
                                }
                                .presentationCompactAdaptation(.popover)
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                SelectableChip(title: "Short", isSelected: estimated == .short, color: .green) { estimated = .short }
                                SelectableChip(title: "Medium", isSelected: estimated == .medium, color: .yellow) { estimated = .medium }
                                SelectableChip(title: "Long", isSelected: estimated == .long, color: .red) { estimated = .long }
                            }
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
                    .offset(y: -140)
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
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let project = selectedProjectId.flatMap { id in projectList.first(where: { $0.id == id }) }
        onSave(title, project, difficulty, resistance, estimated, dueDate)
        dismiss()
    }

    private var canCreateProject: Bool {
        !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !newProjectEmoji.isEmpty
    }
}

// MARK: - Date helpers
private func nextWeekday(_ weekday: Int, from date: Date = Date()) -> Date {
    var cal = Calendar.current
    cal.firstWeekday = 1 // Sunday
    let current = cal.component(.weekday, from: date)
    var days = weekday - current
    if days <= 0 { days += 7 }
    return cal.date(byAdding: .day, value: days, to: date) ?? date
}

private func upcomingSaturday(from date: Date = Date()) -> Date {
    // In Gregorian, Saturday = 7
    let sat = 7
    var cal = Calendar.current
    cal.firstWeekday = 1
    let current = cal.component(.weekday, from: date)
    if current == sat { return date }
    return nextWeekday(sat, from: date)
}

private func nextWeekMonday(from date: Date = Date()) -> Date {
    // Monday = 2
    return nextWeekday(2, from: date)
}

private func nextDays(_ days: Int, from date: Date = Date()) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
}
