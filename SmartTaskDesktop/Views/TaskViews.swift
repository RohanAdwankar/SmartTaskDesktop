import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var selectedView: ViewType = .table
    @State private var calendarMode: CalendarMode = .month
    @State private var showingAddTask = false
    
    enum ViewType {
        case table, calendar
    }
    
    enum CalendarMode {
        case month, week, day
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedView) {
                    Text("Table").tag(ViewType.table)
                    Text("Calendar").tag(ViewType.calendar)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.1))
                
                if selectedView == .table {
                    TaskTableView(tasks: tasks)
                } else {
                    CalendarView(tasks: tasks, mode: $calendarMode)
                }
            }
            .navigationTitle("Task Manager")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddTask = true }) {
                        Label("Add Task", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddEditTaskView()
            }
        }
        .accentColor(.blue)
    }
}

struct CalendarView: View {
    let tasks: [Task]
    @Binding var mode: ContentView.CalendarMode
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack {
            Picker("Calendar Mode", selection: $mode) {
                Text("Month").tag(ContentView.CalendarMode.month)
                Text("Week").tag(ContentView.CalendarMode.week)
                Text("Day").tag(ContentView.CalendarMode.day)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: mode == .day ? [.date, .hourAndMinute] : [.date]
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            
            List {
                ForEach(filteredTasks) { task in
                    TaskRow(task: task)
                        .listRowBackground(Color(nsColor: .controlBackgroundColor).opacity(0.1))
                }
            }
            .listStyle(PlainListStyle())
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    var filteredTasks: [Task] {
        tasks.filter { task in
            let taskDate = Calendar.current.startOfDay(for: task.deadline)
            let selectedDay = Calendar.current.startOfDay(for: selectedDate)
            return taskDate == selectedDay
        }
    }
}

struct TaskTableView: View {
    let tasks: [Task]
    
    var body: some View {
        List(tasks) { task in
            NavigationLink(destination: TaskDetailView(task: task)) {
                TaskRow(task: task)
            }
            .listRowBackground(Color(nsColor: .controlBackgroundColor).opacity(0.1))
        }
        .listStyle(PlainListStyle())
    }
}

struct TaskRow: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(task.name)
                .font(.headline)
                .foregroundColor(.primary)
            Text(task.taskDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Deadline: \(task.deadline, style: .date)")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 5)
    }
}

struct TaskDetailView: View {
    @Bindable var task: Task
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
                Section(header: Text("Task Details").foregroundColor(.blue)) {
                    TextField("Task Name", text: $name)
                    TextField("Description", text: $taskDescription)
                    DatePicker("Deadline", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle(task == nil ? "Add Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(name.isEmpty)
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
        .accentColor(.blue)
    }
    
    private func saveTask() {
        if let task = task {
            // Update existing task
            task.name = name
            task.taskDescription = taskDescription
            task.deadline = deadline
        } else {
            // Create new task
            let newTask = Task(name: name, taskDescription: taskDescription, deadline: deadline)
            modelContext.insert(newTask)
        }
        dismiss()
    }
}
