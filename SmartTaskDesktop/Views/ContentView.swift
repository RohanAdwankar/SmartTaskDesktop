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
            VStack {
                Picker("View", selection: $selectedView) {
                    Text("Table").tag(ViewType.table)
                    Text("Calendar").tag(ViewType.calendar)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
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
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddEditTaskView()
            }
        }
    }
}
