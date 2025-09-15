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

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if viewModel.tasks.isEmpty {
                    ContentUnavailableView("No tasks yet", systemImage: "checklist", description: Text("Tap + to add your first task."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.tasks) { task in
                        TaskRow(task: task)
                    }
                    .listStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Tasks")
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
                    onSave: { title, project, difficulty, resistance, estimated in
                        viewModel.addTask(title: title, project: project, difficulty: difficulty, resistance: resistance, estimatedTime: estimated)
                    }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
