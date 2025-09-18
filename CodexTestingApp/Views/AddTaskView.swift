import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""

    // Projects input and callbacks
    let projects: [ProjectItem]
    // All tasks (for computing project-scoped existing tags)
    let tasks: [TaskItem]
    var onCreateProject: (String, String) -> ProjectItem
    var onSave: (_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date, _ reminderAt: Date?) -> Void
    var onSaveFull: ((_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date, _ reminderAt: Date?, _ tag: String?, _ recurrence: RecurrenceRule?) -> Void)? = nil

    // Selection state
    @State private var selectedProjectId: ProjectItem.ID?
    @State private var projectList: [ProjectItem] = []
    @State private var showingAddProject = false
    @State private var newProjectName: String = ""
    @State private var newProjectEmoji: String = ""
    @State private var newProjectColor: Color? = nil
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
    // Reminder
    @State private var hasReminder: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    // Tag (scoped to selected project)
    @State private var tagText: String = ""
    @State private var showNewTagSheet: Bool = false
    @State private var newTagName: String = ""
    // Repeat (Phase 2 UI)
    @State private var repeatEnabled: Bool = false
    @State private var repeatInterval: Int = 2
    @State private var repeatUnit: RecurrenceUnit = .days
    @State private var repeatBasis: RecurrenceBasis = .scheduled
    @State private var repeatScope: RecurrenceScope = .allDays
    @State private var repeatCountLimitEnabled: Bool = false
    @State private var repeatCountLimit: Int = 5

    init(projects: [ProjectItem], tasks: [TaskItem], preSelectedProjectId: ProjectItem.ID? = nil, onCreateProject: @escaping (String, String) -> ProjectItem, onSaveWithReminder: @escaping (_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date, _ reminderAt: Date?) -> Void) {
        self.projects = projects
        self.tasks = tasks
        self.onCreateProject = onCreateProject
        self.onSave = onSaveWithReminder
        _selectedProjectId = State(initialValue: preSelectedProjectId)
        _projectList = State(initialValue: projects)
    }

    // Full initializer including recurrence
    init(projects: [ProjectItem], tasks: [TaskItem], preSelectedProjectId: ProjectItem.ID? = nil, onCreateProject: @escaping (String, String) -> ProjectItem, onSaveFull: @escaping (_ title: String, _ project: ProjectItem?, _ difficulty: TaskDifficulty, _ resistance: TaskResistance, _ estimated: TaskEstimatedTime, _ dueDate: Date, _ reminderAt: Date?, _ tag: String?, _ recurrence: RecurrenceRule?) -> Void) {
        self.projects = projects
        self.tasks = tasks
        self.onCreateProject = onCreateProject
        self.onSave = { title, project, difficulty, resistance, estimated, dueDate, reminderAt in
            onSaveFull(title, project, difficulty, resistance, estimated, dueDate, reminderAt, nil, nil)
        }
        self.onSaveFull = onSaveFull
        _selectedProjectId = State(initialValue: preSelectedProjectId)
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

                    Section {
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
                        // Hashtags row (project-scoped), similar to Project chips
                        if selectedProjectId != nil {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    NewTagChip { showNewTagSheet = true }
                                    ForEach(existingProjectTags, id: \.self) { tag in
                                        let isSelected = (normalizedSelectedTag == tag)
                                        SelectableChip(title: "#\(tag)", isSelected: isSelected, color: .blue) {
                                            if isSelected { tagText = "" } else { tagText = tag }
                                        }
                                    }
                                }
                            }
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
                                    // Normalize and auto-close picker after selection
                                    dueDate = TaskItem.defaultDueDate(new)
                                    showCustomDatePicker = false
                                }
                        }
                    }

                    // Reminder
                    Section {
                        HStack {
                            Toggle(isOn: $hasReminder) {
                                Text("Reminder")
                                    .font(.headline)
                            }
                            .onChange(of: hasReminder) { newValue in
                                if newValue {
                                    NotificationManager.shared.requestAuthorizationIfNeeded()
                                }
                            }
                        }
                        if hasReminder {
                            DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                        }
                    }

                    // Repeat (clear copy)
                    Section {
                        Toggle("Repeat", isOn: $repeatEnabled)
                        if repeatEnabled {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Frequency").font(.headline)
                                HStack {
                                    Stepper(value: $repeatInterval, in: 1...999) { Text("Every \(repeatInterval)") }
                                    Picker("Unit", selection: $repeatUnit) {
                                        Text("Minutes").tag(RecurrenceUnit.minutes)
                                        Text("Hours").tag(RecurrenceUnit.hours)
                                        Text("Days").tag(RecurrenceUnit.days)
                                        Text("Weeks").tag(RecurrenceUnit.weeks)
                                        Text("Months").tag(RecurrenceUnit.months)
                                        Text("Years").tag(RecurrenceUnit.years)
                                    }
                                    .pickerStyle(.menu)
                                }

                                Text("When to schedule the next").font(.headline)
                                Picker("", selection: $repeatBasis) {
                                    Text("When I complete it").tag(RecurrenceBasis.completion)
                                    Text("On the scheduled date").tag(RecurrenceBasis.scheduled)
                                }
                                .pickerStyle(.segmented)
                                Group {
                                    if repeatBasis == .completion {
                                        Text("The next date is calculated from when you complete the task.")
                                    } else {
                                        Text("The next date advances by the selected frequency, even if you don't complete it.")
                                    }
                                }
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                                Text("Days to consider").font(.headline)
                                Picker("", selection: $repeatScope) {
                                    Text("All days").tag(RecurrenceScope.allDays)
                                    Text("Weekdays only").tag(RecurrenceScope.weekdaysOnly)
                                    Text("Weekends only").tag(RecurrenceScope.weekendsOnly)
                                }
                                .pickerStyle(.segmented)

                                Text("Repetition limit").font(.headline)
                                Toggle("Limit repetitions", isOn: $repeatCountLimitEnabled)
                                if repeatCountLimitEnabled {
                                    Stepper(value: $repeatCountLimit, in: 1...1000) { Text("Up to \(repeatCountLimit) times") }
                                }

                                Text("Next").font(.headline)
                                if let preview = repeatPreview() {
                                    Text("\(dateTimeFormatter.string(from: preview))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("—").font(.caption).foregroundStyle(.secondary)
                                }
                            }
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
                                SelectableChip(title: "Medium", isSelected: difficulty == .medium, color: .green) { difficulty = .medium }
                                SelectableChip(title: "Hard", isSelected: difficulty == .hard, color: .green) { difficulty = .hard }
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
                                SelectableChip(title: "Low", isSelected: resistance == .low, color: .purple) { resistance = .low }
                                SelectableChip(title: "Medium", isSelected: resistance == .medium, color: .purple) { resistance = .medium }
                                SelectableChip(title: "High", isSelected: resistance == .high, color: .purple) { resistance = .high }
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
                                SelectableChip(title: "Short", isSelected: estimated == .short, color: .yellow) { estimated = .short }
                                SelectableChip(title: "Medium", isSelected: estimated == .medium, color: .yellow) { estimated = .medium }
                                SelectableChip(title: "Long", isSelected: estimated == .long, color: .yellow) { estimated = .long }
                            }
                        }
                    }

                    // Repeat (clearer copy)
                    Section {
                        Toggle("Repeat", isOn: $repeatEnabled)
                        if repeatEnabled {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Frequency").font(.headline)
                                HStack {
                                    Stepper(value: $repeatInterval, in: 1...999) { Text("Every \(repeatInterval)") }
                                    Picker("Unit", selection: $repeatUnit) {
                                        Text("Minutes").tag(RecurrenceUnit.minutes)
                                        Text("Hours").tag(RecurrenceUnit.hours)
                                        Text("Days").tag(RecurrenceUnit.days)
                                        Text("Weeks").tag(RecurrenceUnit.weeks)
                                        Text("Months").tag(RecurrenceUnit.months)
                                        Text("Years").tag(RecurrenceUnit.years)
                                    }
                                    .pickerStyle(.menu)
                                }
                                Text("Example: every 2 days, every 3 hours, every 6 months.")
                                    .font(.footnote).foregroundStyle(.secondary)

                                Text("When to schedule the next").font(.headline)
                                Picker("", selection: $repeatBasis) {
                                    Text("When I complete it").tag(RecurrenceBasis.completion)
                                    Text("On the scheduled date").tag(RecurrenceBasis.scheduled)
                                }
                                .pickerStyle(.segmented)
                                Text("Whether the next occurs from completion time or cadence.")
                                    .font(.footnote).foregroundStyle(.secondary)

                                Text("Days to consider").font(.headline)
                                Picker("", selection: $repeatScope) {
                                    Text("All days").tag(RecurrenceScope.allDays)
                                    Text("Weekdays only").tag(RecurrenceScope.weekdaysOnly)
                                    Text("Weekends only").tag(RecurrenceScope.weekendsOnly)
                                }
                                .pickerStyle(.segmented)
                                Text("Weekdays: Mon–Fri. Weekends: Sat–Sun (anchored to Saturdays).")
                                    .font(.footnote).foregroundStyle(.secondary)

                                Text("Repetition limit").font(.headline)
                                Toggle("Limit repetitions", isOn: $repeatCountLimitEnabled)
                                if repeatCountLimitEnabled {
                                    Stepper(value: $repeatCountLimit, in: 1...1000) {
                                        Text("Up to \(repeatCountLimit) times")
                                    }
                                }

                                Text("Next").font(.headline)
                                if let preview = repeatPreview() {
                                    Text("\(dateTimeFormatter.string(from: preview))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("—").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                }
                // Popup centered overlay
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
                    .ignoresSafeArea(.keyboard) // keep overlay fixed when keyboard appears
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
        .onChangeCompat(of: selectedProjectId) { _, _ in
            // Clear tag when switching projects
            tagText = ""
        }
        .sheet(isPresented: $showNewTagSheet) {
            VStack(spacing: 12) {
                HStack {
                    Button("Cancel") { showNewTagSheet = false; newTagName = "" }
                    Spacer()
                    Text("New Tag").font(.headline)
                    Spacer()
                    Button("Save") {
                        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            let normalized = trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed
                            tagText = normalized
                        }
                        newTagName = ""
                        showNewTagSheet = false
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                TextField("#Tag name", text: $newTagName)
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)
                Spacer(minLength: 0)
            }
            .presentationDetents([.height(160)])
            .presentationDragIndicator(.visible)
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let project = selectedProjectId.flatMap { id in projectList.first(where: { $0.id == id }) }
        let reminderAt = hasReminder ? combineDayAndTime(dueDate, reminderTime) : nil
        let recurrence = repeatRule()
        if let full = onSaveFull {
            let tagToUse = (project != nil) ? tagText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty : nil
            full(title, project, difficulty, resistance, estimated, dueDate, reminderAt, tagToUse, recurrence)
        } else {
            onSave(title, project, difficulty, resistance, estimated, dueDate, reminderAt)
        }
        dismiss()
    }

    private var existingProjectTags: [String] {
        guard let pid = selectedProjectId else { return [] }
        let raw = tasks.filter { $0.project?.id == pid }.compactMap { $0.tag?.trimmingCharacters(in: .whitespacesAndNewlines) }
        let unique = Array(Set(raw.filter { !$0.isEmpty }))
        return unique.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var normalizedSelectedTag: String? {
        tagText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private var canCreateProject: Bool {
        !newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !newProjectEmoji.isEmpty
    }
}

// MARK: - Date helpers
private var projectColorSwatches: [Color] { [.yellow, .green, .blue, .purple, .pink, .orange, .teal, .mint, .indigo, .red, .brown, .gray] }

private func shortDateLabel(_ date: Date) -> String {
    let cal = Calendar.current
    let now = Date()
    let normalized = TaskItem.defaultDueDate(date)
    if normalized == TaskItem.defaultDueDate(now) { return "Today" }
    if normalized == TaskItem.defaultDueDate(cal.date(byAdding: .day, value: 1, to: now) ?? now) { return "Tomorrow" }
    let df = DateFormatter()
    df.dateFormat = "MMM d" // concise
    return df.string(from: normalized)
}

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

private func combineDayAndTime(_ day: Date, _ time: Date) -> Date {
    let cal = Calendar.current
    let d = TaskItem.defaultDueDate(day)
    let hm = cal.dateComponents([.hour, .minute], from: time)
    var comps = cal.dateComponents([.year, .month, .day], from: d)
    comps.hour = hm.hour
    comps.minute = hm.minute
    return cal.date(from: comps) ?? day
}

private func dateTimeFormatterFactory() -> DateFormatter {
    let df = DateFormatter()
    df.dateStyle = .medium
    df.timeStyle = .short
    return df
}

private var dateTimeFormatter: DateFormatter { dateTimeFormatterFactory() }

private extension AddTaskView {
    func repeatRule() -> RecurrenceRule? {
        guard repeatEnabled else { return nil }
        let anchor = TaskItem.defaultDueDate(dueDate)
        return RecurrenceRule(
            unit: repeatUnit,
            interval: repeatInterval,
            basis: repeatBasis,
            scope: repeatScope,
            countLimit: repeatCountLimitEnabled ? repeatCountLimit : nil,
            occurrencesDone: 0,
            anchor: anchor
        )
    }

    func repeatPreview() -> Date? {
        guard let rule = repeatRule() else { return nil }
        switch rule.basis {
        case .scheduled:
            return RecurrenceEngine.nextOccurrence(from: rule.anchor, rule: rule)
        case .completion:
            // Preview from now (hypothetical completion)
            return RecurrenceEngine.nextOccurrence(from: Date(), rule: rule)
        }
    }
}
