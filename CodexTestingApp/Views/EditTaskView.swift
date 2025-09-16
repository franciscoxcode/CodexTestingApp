import SwiftUI

struct EditTaskView: View {
    let task: TaskItem

    // Inputs
    let projects: [ProjectItem]
    var onCreateProject: (String, String) -> ProjectItem
    var onSave: (_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date, _ reminderAt: Date?, _ recurrence: RecurrenceRule?) -> Void
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    // State mirrors AddTaskView but seeded from task
    @State private var title: String
    @State private var projectList: [ProjectItem]
    @State private var selectedProjectId: ProjectItem.ID?

    @State private var difficulty: TaskDifficulty
    @State private var resistance: TaskResistance
    @State private var estimated: TaskEstimatedTime

    @State private var duePreset: DuePreset
    @State private var dueDate: Date
    @State private var showCustomDatePicker: Bool
    // Reminder
    @State private var hasReminder: Bool
    @State private var reminderTime: Date
    // Repeat (Phase 2 UI)
    @State private var repeatEnabled: Bool
    @State private var repeatInterval: Int
    @State private var repeatUnit: RecurrenceUnit
    @State private var repeatBasis: RecurrenceBasis
    @State private var repeatScope: RecurrenceScope
    @State private var repeatCountLimitEnabled: Bool
    @State private var repeatCountLimit: Int

    @State private var showingAddProject = false
    @State private var newProjectName: String = ""
    @State private var newProjectEmoji: String = ""
    @State private var newProjectColor: Color? = nil
    @State private var showingEmojiPicker = false

    // Info toggles
    @State private var showDifficultyInfo = false
    @State private var showResistanceInfo = false
    @State private var showEstimatedInfo = false
    @State private var showDueInfo = false

    init(task: TaskItem, projects: [ProjectItem], onCreateProject: @escaping (String, String) -> ProjectItem, onSave: @escaping (_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date, _ reminderAt: Date?, _ recurrence: RecurrenceRule?) -> Void, onDelete: (() -> Void)? = nil) {
        self.task = task
        self.projects = projects
        self.onCreateProject = onCreateProject
        self.onSave = onSave
        self.onDelete = onDelete

        _title = State(initialValue: task.title)
        _projectList = State(initialValue: projects)
        _selectedProjectId = State(initialValue: task.project?.id)
        _difficulty = State(initialValue: task.difficulty)
        _resistance = State(initialValue: task.resistance)
        _estimated = State(initialValue: task.estimatedTime)

        let preset = EditTaskView.presetFor(date: task.dueDate)
        _duePreset = State(initialValue: preset)
        _dueDate = State(initialValue: task.dueDate)
        _showCustomDatePicker = State(initialValue: preset == .custom)
        if let when = task.reminderAt {
            _hasReminder = State(initialValue: true)
            _reminderTime = State(initialValue: when)
        } else {
            _hasReminder = State(initialValue: false)
            _reminderTime = State(initialValue: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
        }

        if let r = task.recurrence {
            _repeatEnabled = State(initialValue: true)
            _repeatInterval = State(initialValue: r.interval)
            _repeatUnit = State(initialValue: r.unit)
            _repeatBasis = State(initialValue: r.basis)
            _repeatScope = State(initialValue: r.scope)
            _repeatCountLimitEnabled = State(initialValue: r.countLimit != nil)
            _repeatCountLimit = State(initialValue: r.countLimit ?? 5)
        } else {
            _repeatEnabled = State(initialValue: false)
            _repeatInterval = State(initialValue: 2)
            _repeatUnit = State(initialValue: .days)
            _repeatBasis = State(initialValue: .scheduled)
            _repeatScope = State(initialValue: .allDays)
            _repeatCountLimitEnabled = State(initialValue: false)
            _repeatCountLimit = State(initialValue: 5)
        }
    }

    private func shortDateLabel(_ date: Date) -> String {
        let cal = Calendar.current
        let now = Date()
        let normalized = TaskItem.defaultDueDate(date)
        if normalized == TaskItem.defaultDueDate(now) { return "Today" }
        if normalized == TaskItem.defaultDueDate(cal.date(byAdding: .day, value: 1, to: now) ?? now) { return "Tomorrow" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: normalized)
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

                    

                    Section {
                        HStack(spacing: 8) {
                            Text("Project").font(.headline)
                            Spacer()
                        }
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                NewProjectChip { showingAddProject = true }
                                ForEach(projectList) { project in
                                    ProjectChip(
                                        project: project,
                                        isSelected: selectedProjectId == project.id,
                                        onTap: {
                                            if selectedProjectId == project.id {
                                                selectedProjectId = nil
                                            } else {
                                                selectedProjectId = project.id
                                            }
                                        }
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
                                SelectableChip(title: (duePreset == .custom ? shortDateLabel(dueDate) : "Pick date…"), isSelected: duePreset == .custom, color: .blue) {
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
                                .onChangeCompat(of: dueDate) { _, new in
                                    dueDate = TaskItem.defaultDueDate(new)
                                    showCustomDatePicker = false
                                }
                        }
                    }

                    // Repeat (preview-only for Phase 2) -- already inserted below Due Date

                    // Reminder (moved after Repeat and main attributes)
                    Section {
                        HStack {
                            Toggle(isOn: $hasReminder) {
                                Text("Reminder")
                                    .font(.headline)
                            }
                            .onChange(of: hasReminder) { newValue in
                                if newValue { NotificationManager.shared.requestAuthorizationIfNeeded() }
                            }
                        }
                        if hasReminder {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                        }
                    }
                    // Repeat (preview-only for Phase 2)
                    Section {
                        Toggle("Repeat", isOn: $repeatEnabled)
                        if repeatEnabled {
                            HStack {
                                Stepper(value: $repeatInterval, in: 1...999) {
                                    Text("Every \(repeatInterval)")
                                }
                                Picker("Unit", selection: $repeatUnit) {
                                    Text("min").tag(RecurrenceUnit.minutes)
                                    Text("hr").tag(RecurrenceUnit.hours)
                                    Text("days").tag(RecurrenceUnit.days)
                                    Text("weeks").tag(RecurrenceUnit.weeks)
                                    Text("months").tag(RecurrenceUnit.months)
                                    Text("years").tag(RecurrenceUnit.years)
                                }
                                .pickerStyle(.menu)
                            }
                            Picker("From", selection: $repeatBasis) {
                                Text("Scheduled").tag(RecurrenceBasis.scheduled)
                                Text("Completion").tag(RecurrenceBasis.completion)
                            }
                            .pickerStyle(.segmented)
                            Picker("Scope", selection: $repeatScope) {
                                Text("All days").tag(RecurrenceScope.allDays)
                                Text("Weekdays").tag(RecurrenceScope.weekdaysOnly)
                                Text("Weekends").tag(RecurrenceScope.weekendsOnly)
                            }
                            .pickerStyle(.segmented)
                            Toggle("Limit repetitions", isOn: $repeatCountLimitEnabled)
                            if repeatCountLimitEnabled {
                                Stepper(value: $repeatCountLimit, in: 1...1000) {
                                    Text("Up to \(repeatCountLimit) times")
                                }
                            }
                            if let preview = repeatPreview() {
                                Text("Next: \(dateTimeFormatter.string(from: preview))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Difficulty
                    Section {
                        HStack(spacing: 8) {
                            Text("Difficulty").font(.headline)
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
                                SelectableChip(title: "Medium", isSelected: difficulty == .medium, color: .green) { difficulty = .medium }
                                SelectableChip(title: "Hard", isSelected: difficulty == .hard, color: .green) { difficulty = .hard }
                            }
                        }
                    }

                    // Resistance
                    Section {
                        HStack(spacing: 8) {
                            Text("Resistance").font(.headline)
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
                                SelectableChip(title: "Low", isSelected: resistance == .low, color: .purple) { resistance = .low }
                                SelectableChip(title: "Medium", isSelected: resistance == .medium, color: .purple) { resistance = .medium }
                                SelectableChip(title: "High", isSelected: resistance == .high, color: .purple) { resistance = .high }
                            }
                        }
                    }

                    // Estimated Time
                    Section {
                        HStack(spacing: 8) {
                            Text("Estimated Time").font(.headline)
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
                                SelectableChip(title: "Short", isSelected: estimated == .short, color: .yellow) { estimated = .short }
                                SelectableChip(title: "Medium", isSelected: estimated == .medium, color: .yellow) { estimated = .medium }
                                SelectableChip(title: "Long", isSelected: estimated == .long, color: .yellow) { estimated = .long }
                            }
                        }
                    }

                    // Delete Task (separate section at bottom)
                    Section {
                        Button(role: .destructive) {
                            onDelete?()
                            dismiss()
                        } label: {
                            Text("Delete Task")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }

                // Popup centered overlay (new project)
                if showingAddProject {
                    ZStack {
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
                                Button { showingEmojiPicker = true } label: {
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

                            // Color palette (creation preview only, horizontal scroll)
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
                                    let created = onCreateProject(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines), newProjectEmoji)
                                    projectList.append(created)
                                    selectedProjectId = created.id
                                    showingAddProject = false
                                    newProjectName = ""
                                    newProjectEmoji = ""
                                    newProjectColor = nil
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
                    .ignoresSafeArea(.keyboard)
                }
            }
            .navigationTitle("Edit Task")
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

    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func save() {
        let project = selectedProjectId.flatMap { id in projectList.first(where: { $0.id == id }) }
        let reminderAt = hasReminder ? combineDayAndTime(dueDate, reminderTime) : nil
        let recurrence = repeatRule()
        onSave(title, project, difficulty, resistance, estimated, dueDate, reminderAt, recurrence)
        dismiss()
    }

    private var canCreateProject: Bool {
        !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !newProjectEmoji.isEmpty
    }

    // MARK: - Helpers
    private enum DuePreset { case today, tomorrow, weekend, nextWeek, custom }

    private static func presetFor(date: Date) -> DuePreset {
        let normalized = TaskItem.defaultDueDate(date)
        if normalized == TaskItem.defaultDueDate() { return .today }
        if normalized == TaskItem.defaultDueDate(nextDays(1)) { return .tomorrow }
        if normalized == TaskItem.defaultDueDate(upcomingSaturday()) { return .weekend }
        if normalized == TaskItem.defaultDueDate(nextWeekMonday()) { return .nextWeek }
        return .custom
    }
}

// MARK: - Date helpers (duplicated from AddTaskView)
private func nextWeekday(_ weekday: Int, from date: Date = Date()) -> Date {
    var cal = Calendar.current
    cal.firstWeekday = 1 // Sunday
    let current = cal.component(.weekday, from: date)
    var days = weekday - current
    if days <= 0 { days += 7 }
    return cal.date(byAdding: .day, value: days, to: date) ?? date
}

private func upcomingSaturday(from date: Date = Date()) -> Date {
    let sat = 7
    var cal = Calendar.current
    cal.firstWeekday = 1
    let current = cal.component(.weekday, from: date)
    if current == sat { return date }
    return nextWeekday(sat, from: date)
}

private func nextWeekMonday(from date: Date = Date()) -> Date {
    return nextWeekday(2, from: date)
}

private func nextDays(_ days: Int, from date: Date = Date()) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
}

private func combineDayAndTime(_ day: Date, _ time: Date) -> Date {
    let cal = Calendar.current
    let d = TaskItem.defaultDueDate(day)
    let hm = cal.dateComponents([.hour, .minute], from: time)
    var comps = cal.dateComponents([.year, .month, .day], from: d)
    comps.hour = hm.hour
    comps.minute = hm.minute
    return cal.date(from: comps) ?? day
}

private func dateTimeFormatterFactory_Edit() -> DateFormatter {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .short
    return df
}

private var dateTimeFormatter: DateFormatter { dateTimeFormatterFactory_Edit() }

private extension EditTaskView {
    func repeatRule() -> RecurrenceRule? {
        guard repeatEnabled else { return nil }
        let anchor = TaskItem.defaultDueDate(dueDate)
        return RecurrenceRule(
            unit: repeatUnit,
            interval: repeatInterval,
            basis: repeatBasis,
            scope: repeatScope,
            countLimit: repeatCountLimitEnabled ? repeatCountLimit : nil,
            occurrencesDone: task.recurrence?.occurrencesDone ?? 0,
            anchor: task.recurrence?.anchor ?? anchor
        )
    }

    func repeatPreview() -> Date? {
        guard let rule = repeatRule() else { return nil }
        switch rule.basis {
        case .scheduled:
            return RecurrenceEngine.nextOccurrence(from: rule.anchor, rule: rule)
        case .completion:
            return RecurrenceEngine.nextOccurrence(from: Date(), rule: rule)
        }
    }
}

private var projectColorSwatches: [Color] { [.yellow, .green, .blue, .purple, .pink, .orange, .teal, .mint, .indigo, .red, .brown, .gray] }
