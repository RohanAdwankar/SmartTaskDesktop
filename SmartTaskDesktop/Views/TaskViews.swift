import SwiftUI
import SwiftData

// Define a custom color scheme
extension Color {
    static let primaryColor = Color.blue
    static let accentColor = Color.orange
    static let backgroundColor = Color(NSColor.windowBackgroundColor)
    static let secondaryBackgroundColor = Color(NSColor.controlBackgroundColor)
    static let taskBackgroundColor = Color(NSColor.controlBackgroundColor).opacity(0.5)
}

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
                // Updated Picker with consistent padding and background color
                Picker("View", selection: $selectedView) {
                    Text("Table").tag(ViewType.table)
                    Text("Calendar").tag(ViewType.calendar)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(8)
                .padding(.horizontal)

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
                    .tint(Color.accentColor)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddEditTaskView()
            }
            .accentColor(Color.accentColor)
            .background(Color.backgroundColor)
        }
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
                .background(Color.secondaryBackgroundColor)

            switch mode {
            case .month:
                monthView
            case .week:
                weekView
            case .day:
                dayView
            }
        }
        .background(Color.backgroundColor)
    }

    private var headerView: some View {
        HStack {
            Button(action: { moveMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
            Spacer()
            Text(dateFormatter.string(from: currentMonth))
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Button(action: { moveMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.primary)
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
            // Adjusted LazyVGrid to remove spacing and padding
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date = date {
                        dayCell(for: date)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .border(Color.gray.opacity(0.2), width: 0.5)
                    } else {
                        // Use Color.clear to maintain the grid structure
                        Color.clear
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .border(Color.gray.opacity(0.2), width: 0.5)
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
                    ForEach(calendar.daysOfWeek(for: selectedDate), id: \.self) { date in
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

        return VStack(spacing: 2) {
            Text(String(calendar.component(.day, from: date)))
                .font(.system(size: 14))
                .foregroundColor(isToday ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(isToday ? Color.accentColor : Color.clear)
                .clipShape(Circle())
                .padding(4)

            Spacer()

            tasksForDate(date)
                .padding(4)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle()) // Ensures the entire cell is tappable
        .onTapGesture {
            selectedDate = date
        }
    }

    private func dayRow(for date: Date) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1])
                .frame(width: 50, alignment: .leading)
                .padding(.leading, 4)
                .foregroundColor(.secondary)

            tasksForDate(date)
                .padding(4)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(8)
                .shadow(radius: 1)
        }
        .frame(height: 100)
        .padding(.horizontal)
    }

    private func hourRow(for hour: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(hour):00")
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, 8)
                .foregroundColor(.secondary)

            tasksForHour(hour)
                .padding(4)
                .background(Color.secondaryBackgroundColor)
                .cornerRadius(8)
                .shadow(radius: 1)
        }
        .frame(height: 60)
        .padding(.horizontal)
    }

    private func tasksForDate(_ date: Date) -> some View {
        let dayTasks = tasks.filter { calendar.isDate($0.deadline, inSameDayAs: date) }
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(dayTasks) { task in
                Text(task.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .padding(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(taskColor(for: task))
                    .foregroundColor(.white)
                    .cornerRadius(4)
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
                    .padding(4)
                    .background(taskColor(for: task))
                    .foregroundColor(.white)
                    .cornerRadius(4)
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
                    .background(Color.secondaryBackgroundColor)
                    .foregroundColor(.primary)
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
        // Assign colors based on task properties if available
        return Color.primaryColor.opacity(0.7)
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
        List {
            ForEach(tasks) { task in
                NavigationLink(destination: TaskDetailView(task: task)) {
                    TaskRow(task: task)
                }
                .listRowBackground(Color.secondaryBackgroundColor)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct TaskRow: View {
    let task: Task

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(task.name)
                .font(.headline)
                .foregroundColor(.primary)
            Text(task.taskDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Deadline: \(task.deadline, style: .date)")
                .font(.caption)
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color.secondaryBackgroundColor)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

struct TaskDetailView: View {
    @Bindable var task: Task
    @State private var showingEditView = false

    var body: some View {
        Form {
            Section(header: Text("Task Details").foregroundColor(.accentColor)) {
                Text(task.name)
                    .font(.headline)
                Text(task.taskDescription)
                Text("Deadline: \(task.deadline, style: .date)")
            }

            Section(header: Text("Subtasks").foregroundColor(.accentColor)) {
                if let subtasks = task.subtasks, !subtasks.isEmpty {
                    ForEach(subtasks) { subtask in
                        Text(subtask.name)
                    }
                } else {
                    Text("No subtasks")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Task Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditView = true
                }
                .foregroundColor(.accentColor)
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
                Section(header: Text("Task Details").foregroundColor(.accentColor)) {
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
                    .foregroundColor(.accentColor)
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
        .accentColor(.accentColor)
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
