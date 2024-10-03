import SwiftUI

struct AddEditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var taskDescription = ""
    @State private var deadline = Date()
    
    var task: Task?
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Task Name", text: $name)
                TextField("Description", text: $taskDescription)
                DatePicker("Deadline", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle(task == nil ? "Add Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                }
            }
            .onAppear {
                if let task = task {
                    name = task.name
                    taskDescription = task.taskDescription
                    deadline = task.deadline
                }
            }
        }
    }
    
    private func saveTask() {
        if let task = task {
            // update
            task.name = name
            task.taskDescription = taskDescription
            task.deadline = deadline
        } else {
            // create
            let newTask = Task(name: name, taskDescription: taskDescription, deadline: deadline)
            modelContext.insert(newTask)
        }
        dismiss()
    }
}
