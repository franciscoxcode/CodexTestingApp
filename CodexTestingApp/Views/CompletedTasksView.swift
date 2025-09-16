import SwiftUI

struct CompletedTasksView: View {
    let tasks: [TaskItem]
    var onUncomplete: (TaskItem) -> Void
    var onClose: () -> Void
    var onProjectTap: (ProjectItem) -> Void = { _ in }

    // Single-day view state
    @State private var selectedDay: Date = Calendar.current.startOfDay(for: Date())
    @State private var showPicker: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 4) {
                // Screen title with extra top padding
                Text("Completed Tasks")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.top, 8)

                // Header controls: prev day, title (tap to pick), next day, Today
                headerControls
                    .padding(.top, 25)
                    .padding(.bottom, 8)

                List {
                    ForEach(itemsForSelectedDay) { task in
                        let pts = points(for: task)
                        TaskRow(
                            task: task,
                            onProjectTap: { project in onProjectTap(project) },
                            onToggle: { _ in onUncomplete(task) },
                            showCompletedStyle: false,
                            trailingInfo: "+\(pts)",
                            showProjectName: false
                        )
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onClose() }
                }
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: $showPicker) {
                VStack {
                    HStack {
                        Button("Cancel") { showPicker = false }
                        Spacer()
                        Text("Pick Date").font(.headline)
                        Spacer()
                        Button("Done") { showPicker = false }
                    }
                    .padding(.horizontal)
                    DatePicker("", selection: $selectedDay, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .onChangeCompat(of: selectedDay) { _, new in selectedDay = normalized(new) }
                        .padding(.horizontal)
                }
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Single-day computed views
    private var completed: [TaskItem] { tasks.filter { $0.isDone } }

    private var itemsForSelectedDay: [TaskItem] {
        let day = normalized(selectedDay)
        return completed.filter { normalized($0.completedAt ?? Date()) == day }
            .sorted { (a, b) in
                let da = a.completedAt ?? Date.distantPast
                let db = b.completedAt ?? Date.distantPast
                return da > db
            }
    }

    private var dayTitle: String {
        let day = normalized(selectedDay)
        let today = normalized(Date())
        let yesterday = normalized(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if day == today { return "Today" }
        if day == yesterday { return "Yesterday" }
        return headerFormatter.string(from: day)
    }

    private var dayTotalPoints: Int {
        itemsForSelectedDay.reduce(0) { $0 + points(for: $1) }
    }

    // (section header no longer used; total points chip moved to headerControls)

    private func normalized(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private var headerFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }

    // Points calculation mirrors ContentView.points(for:)
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

    // MARK: - Header controls
    @ViewBuilder
    private var headerControls: some View {
        let today = normalized(Date())
        HStack(spacing: 12) {
            Button(action: { selectedDay = normalized(addDays(-1, from: selectedDay)) }) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Button(action: { showPicker = true }) {
                HStack(spacing: 6) {
                    Text(dayTitle).font(.headline)
                    Image(systemName: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Button(action: { selectedDay = normalized(addDays(1, from: selectedDay)) }) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
            .disabled(normalized(selectedDay) >= today)

            Spacer()

            if normalized(selectedDay) != today {
                Button("Today") { selectedDay = today }
                    .buttonStyle(.bordered)
                    .font(.caption)
            }

            // Daily total points chip aligned to far right
            HStack(spacing: 6) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundStyle(.yellow)
                Text("\(dayTotalPoints)")
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
        }
        .padding(.horizontal)
    }

    private func addDays(_ days: Int, from date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}
