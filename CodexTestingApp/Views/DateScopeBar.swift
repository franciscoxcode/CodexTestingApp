import SwiftUI

struct DateScopeBar: View {
    @Binding var dateScope: ContentView.DateScope
    @Binding var showScopeDatePicker: Bool
    @Binding var scopeCustomDate: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                scopeButton(title: "Anytime", isActive: dateScope == .anytime) {
                    dateScope = .anytime
                    showScopeDatePicker = false
                }
                scopeButton(title: "Today", isActive: dateScope == .today) {
                    dateScope = .today
                    showScopeDatePicker = false
                }
                scopeButton(title: "Tomorrow", isActive: dateScope == .tomorrow) {
                    dateScope = .tomorrow
                    showScopeDatePicker = false
                }
                scopeButton(title: "Weekend", isActive: dateScope == .weekend) {
                    dateScope = .weekend
                    showScopeDatePicker = false
                }
                let pickTitle: String = {
                    if case .custom(let d) = dateScope { return shortDateLabel(d) }
                    return "Pick date"
                }()
                scopeButton(title: pickTitle, isActive: isCustomScope(dateScope)) {
                    switch dateScope {
                    case .custom:
                        showScopeDatePicker.toggle()
                    default:
                        dateScope = .custom(scopeCustomDate)
                        showScopeDatePicker = true
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if showScopeDatePicker {
                DatePicker("", selection: $scopeCustomDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .onChangeCompat(of: scopeCustomDate) { _, new in
                        let normalized = TaskItem.defaultDueDate(new)
                        let today = TaskItem.defaultDueDate()
                        let tomorrow = TaskItem.defaultDueDate(nextDays(1))
                        let weekend = TaskItem.defaultDueDate(upcomingSaturday())
                        if normalized == today {
                            dateScope = .today
                        } else if normalized == tomorrow {
                            dateScope = .tomorrow
                        } else if normalized == weekend {
                            dateScope = .weekend
                        } else {
                            dateScope = .custom(normalized)
                        }
                        DispatchQueue.main.async { showScopeDatePicker = false }
                    }
            }
        }
        .padding(.leading, 20)
        .padding(.top, 10)
        .padding(.bottom, 0)
    }

    private func scopeButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundStyle(isActive ? Color.blue : Color.secondary)
                .underline(isActive, color: .blue)
        }
        .buttonStyle(.plain)
    }

    // Local helper to avoid cross-file dependency
    private func isCustomScope(_ scope: ContentView.DateScope) -> Bool {
        if case .custom(_) = scope { return true } else { return false }
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

    private func nextDays(_ days: Int, from date: Date = Date()) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    private func upcomingSaturday(from date: Date = Date()) -> Date {
        let sat = 7
        var cal = Calendar.current
        cal.firstWeekday = 1
        let current = cal.component(.weekday, from: date)
        if current == sat { return date }
        var diff = sat - current
        if diff <= 0 { diff += 7 }
        return cal.date(byAdding: .day, value: diff, to: date) ?? date
    }
}
