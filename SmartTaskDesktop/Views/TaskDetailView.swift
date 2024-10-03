import SwiftUI

struct TaskDetailView: View {
    @Bindable var task: Task
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditView = false
    
    var body: some View {
        Form {
            Section(header: Text("Task Details")) {
                Text(task.name)
                    .font(.headline)
                Text(task.taskDescription)
                Text("Deadline: \(task.deadline, style: .date)")
            }
            
            Section(header: Text("Subtasks")) {
                if let subtasks = task.subtasks, !subtasks.isEmpty {
                    ForEach(subtasks) { subtask in
                        Text(subtask.name)
                    }
                } else {
                    Text("No subtasks")
                }
            }
        }
        .navigationTitle("Task Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            AddEditTaskView(task: task)
        }
    }
}
