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
                scopeButton(title: "Pick date", isActive: isCustomScope(dateScope)) {
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
                        dateScope = .custom(TaskItem.defaultDueDate(new))
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
}
