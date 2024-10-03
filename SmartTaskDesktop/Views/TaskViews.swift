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
                    CalendarView(mode: $calendarMode)
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

struct TaskTableView: View {
    let tasks: [Task]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            ForEach(tasks) { task in
                NavigationLink(destination: TaskDetailView(task: task)) {
                    TaskRow(task: task)
                }
            }
            .onDelete(perform: deleteTasks)
        }
    }
    
    private func deleteTasks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tasks[index])
        }
        do {
            try modelContext.save()
        } catch {
            print("Error deleting task: \(error)")
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

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var tasks: [Task]
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
            Button(action: { moveDate(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(headerTitle)
                .font(.headline)
            Spacer()
            Button(action: { moveDate(by: 1) }) {
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
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
            HStack(spacing: 1) {
                ForEach(daysOfWeek, id: \.self) { date in
                    VStack {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.headline)
                        ScrollView {
                            VStack(spacing: 2) {
                                ForEach(tasksForDate(date)) { task in
                                    taskView(for: task)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .border(Color.gray.opacity(0.2), width: 0.5)
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
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        
        return VStack {
            Text(String(calendar.component(.day, from: date)))
                .font(.system(size: 14))
                .foregroundColor(isToday ? .blue : .primary)
                .frame(height: 20)
            
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(tasksForDate(date)) { task in
                        taskView(for: task)
                    }
                }
            }
        }
        .frame(height: 120)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .border(Color.gray.opacity(0.2), width: 0.5)
        .onTapGesture {
            selectedDate = date
        }
        .onDrop(of: [.plainText], delegate: DropViewDelegate(date: date, modelContext: modelContext))
    }
    
    private func hourRow(for hour: Int) -> some View {
        HStack(spacing: 0) {
            Text("\(hour):00")
                .frame(width: 50, alignment: .trailing)
                .padding(.trailing, 8)
            
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color.clear)
                    .border(Color.gray.opacity(0.2), width: 0.5)
                
                ForEach(tasksForHour(hour)) { task in
                    taskView(for: task)
                        .padding(.leading, 2)
                }
            }
        }
        .frame(height: 60)
    }
    
    private func taskView(for task: Task) -> some View {
        Text(task.name)
            .font(.system(size: 12))
            .lineLimit(1)
            .padding(4)
            .background(Color.blue.opacity(0.3))
            .cornerRadius(4)
            .onDrag {
                NSItemProvider(object: task.id.uuidString as NSString)
            }
    }
    
    private var dayOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .font(.caption)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
            }
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        return calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
        .map { date in
            if calendar.isDate(date, equalTo: monthInterval.start, toGranularity: .month) ||
               calendar.isDate(date, equalTo: monthInterval.end, toGranularity: .month) {
                return date
            }
            return nil
        }
    }
    
    private var daysOfWeek: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return calendar.generateDates(
            inside: weekInterval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }
    
    private func moveDate(by value: Int) {
        switch mode {
        case .month:
            currentMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) ?? currentMonth
        case .week:
            selectedDate = calendar.date(byAdding: .weekOfYear, value: value, to: selectedDate) ?? selectedDate
        case .day:
            selectedDate = calendar.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
        }
    }
    
    private func tasksForDate(_ date: Date) -> [Task] {
        tasks.filter { calendar.isDate($0.deadline, inSameDayAs: date) }
    }
    
    private func tasksForHour(_ hour: Int) -> [Task] {
        tasksForDate(selectedDate).filter { calendar.component(.hour, from: $0.deadline) == hour }
    }
    
    private var headerTitle: String {
        switch mode {
        case .month:
            return dateFormatter.string(from: currentMonth)
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            return "\(dateFormatter.string(from: startOfWeek)) - \(calendar.component(.day, from: endOfWeek))"
        case .day:
            return dateFormatter.string(from: selectedDate)
        }
    }
}

struct DropViewDelegate: DropDelegate {
    let date: Date
    let modelContext: ModelContext
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.plainText]).first else { return false }
        
        itemProvider.loadObject(ofClass: NSString.self) { (id, error) in
            if let id = id as? String,
               let uuid = UUID(uuidString: id) {
                DispatchQueue.main.async {
                    if let task = try? modelContext.fetch(FetchDescriptor<Task>(predicate: #Predicate { $0.id == uuid })).first {
                        task.deadline = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: task.deadline), minute: Calendar.current.component(.minute, from: task.deadline), second: 0, of: date) ?? date
                        try? modelContext.save()
                    }
                }
            }
        }
        
        return true
    }
}

extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(startingAfter: interval.start, matching: components, matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
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
            AddEditTaskView(taskToEdit: task)
        }
    }
}
struct AddEditTaskView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var taskDescription: String
    @State private var deadline: Date
    
    var taskToEdit: Task?
    
    init(taskToEdit: Task? = nil) {
        self.taskToEdit = taskToEdit
        _name = State(initialValue: taskToEdit?.name ?? "")
        _taskDescription = State(initialValue: taskToEdit?.taskDescription ?? "")
        _deadline = State(initialValue: taskToEdit?.deadline ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Task Name", text: $name)
                TextField("Description", text: $taskDescription)
                DatePicker("Deadline", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
            }
            .navigationTitle(taskToEdit == nil ? "Add Task" : "Edit Task")
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
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveTask() {
        if let taskToEdit = taskToEdit {
            taskToEdit.name = name
            taskToEdit.taskDescription = taskDescription
            taskToEdit.deadline = deadline
        } else {
            let newTask = Task(name: name, taskDescription: taskDescription, deadline: deadline)
            modelContext.insert(newTask)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}
