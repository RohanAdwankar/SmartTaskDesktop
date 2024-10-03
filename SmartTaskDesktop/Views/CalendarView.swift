//
//  CalendarView.swift
//  SmartTaskDesktop
//
//  Created by Rohan Adwankar on 10/2/24.
//


import SwiftUI

struct CalendarView: View {
    let tasks: [Task]
    @Binding var mode: ContentView.CalendarMode
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack {
            Picker("Calendar Mode", selection: $mode) {
                Text("Month").tag(ContentView.CalendarMode.month)
                Text("Week").tag(ContentView.CalendarMode.week)
                Text("Day").tag(ContentView.CalendarMode.day)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // placeholder
            Text("Calendar View - \(mode.toString())")
            
        }
    }
}

extension ContentView.CalendarMode {
    func toString() -> String {
        switch self {
        case .month: return "Month"
        case .week: return "Week"
        case .day: return "Day"
        }
    }
}
