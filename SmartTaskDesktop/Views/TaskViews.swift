import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @State private var selectedView: ViewType = .calendar
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
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            switch mode {
            case .month:
                monthView
            case .week:
                weekView
            case .day:
                dayView
            }
        }
        .background(Color(.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            Button(action: { moveMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(dateFormatter.string(from: currentMonth))
                .font(.headline)
            Spacer()
            Button(action: { moveMonth(by: 1) }) {
                Image(systemName: "chevron.right")
            }
            
            Picker("View", selection: $mode) {
                Text("Month").tag(ContentView.CalendarMode.month)
                Text("Week").tag(ContentView.CalendarMode.week)
                Text("Day").tag(ContentView.CalendarMode.day)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
        }
        .padding()
    }
    
    private var monthView: some View {
        VStack(spacing: 0) {
            dayOfWeekHeader
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                    } else {
                        Color.clear
                    }
                }
            }
        }
    }
    
    private var weekView: some View {
        VStack(spacing: 0) {
            dayOfWeekHeader
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Calendar.current.daysOfWeek(for: selectedDate), id: \.self) { date in
                        dayRow(for: date)
                    }
                }
            }
        }
    }
    
    private var dayView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<24) { hour in
                    hourRow(for: hour)
                }
            }
        }
    }
    
    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDate(date, inSameDayAs: Date())
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        
        return VStack {
            Text(String(calendar.component(.day, from: date)))
                .font(.system(size: 14))
                .foregroundColor(isToday ? .blue : .primary)
                .frame(height: 20)
            
            tasksForDate(date)
        }
        .frame(height: 100)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .border(Color.gray.opacity(0.2), width: 0.5)
        .onTapGesture {
            selectedDate = date
        }
    }
    
    private func dayRow(for date: Date) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1])
                .frame(width: 50, alignment: .leading)
            
            tasksForDate(date)
        }
        .frame(height: 100)
        .border(Color.gray.opacity(0.2), width: 0.5)
    }
    
    private func hourRow(for hour: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(hour):00")
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, 8)
            
            tasksForHour(hour)
        }
        .frame(height: 60)
        .border(Color.gray.opacity(0.2), width: 0.5)
    }
    
    private func tasksForDate(_ date: Date) -> some View {
        let dayTasks = tasks.filter { calendar.isDate($0.deadline, inSameDayAs: date) }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(dayTasks) { task in
                Text(task.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .padding(2)
                    .background(taskColor(for: task))
                    .cornerRadius(2)
            }
        }
    }
    
    private func tasksForHour(_ hour: Int) -> some View {
        let hourTasks = tasks.filter {
            calendar.component(.hour, from: $0.deadline) == hour &&
            calendar.isDate($0.deadline, inSameDayAs: selectedDate)
        }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(hourTasks) { task in
                Text(task.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .padding(2)
                    .background(taskColor(for: task))
                    .cornerRadius(2)
            }
        }
    }
    
    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .font(.caption)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
            }
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else {
            return []
        }
        
        let dateInterval = DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end)
        return calendar.generateDates(for: dateInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
            .map { date in
                if calendar.isDate(date, equalTo: monthInterval.start, toGranularity: .month) ||
                   calendar.isDate(date, equalTo: monthInterval.end, toGranularity: .month) {
                    return date
                }
                return nil
            }
    }
    
    private func moveMonth(by months: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: months, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func taskColor(for task: Task) -> Color {
        .blue.opacity(0.3)
    }
}

extension Calendar {
    func generateDates(for dateInterval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates = [dateInterval.start]
        
        enumerateDates(startingAfter: dateInterval.start,
                       matching: components,
                       matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date < dateInterval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
    
    func daysOfWeek(for date: Date) -> [Date] {
        guard let weekInterval = dateInterval(of: .weekOfYear, for: date) else { return [] }
        return generateDates(for: weekInterval, matching: DateComponents(hour: 0, minute: 0, second: 0))
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
