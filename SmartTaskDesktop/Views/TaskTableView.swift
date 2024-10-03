import SwiftUI

struct TaskTableView: View {
    let tasks: [Task]
    
    var body: some View {
        List(tasks) { task in
            NavigationLink(destination: TaskDetailView(task: task)) {
                TaskRow(task: task)
            }
        }
    }
}

struct TaskRow: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(task.name)
                .font(.headline)
            Text(task.taskDescription)
                .font(.subheadline)
            Text("Deadline: \(task.deadline, style: .date)")
                .font(.caption)
        }
    }
}
