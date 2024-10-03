import Foundation
import SwiftData

@Model
final class Task {
    @Attribute(.unique) let id: UUID
    var name: String
    var taskDescription: String
    var deadline: Date
    @Relationship(deleteRule: .cascade) var subtasks: [Task]?

    init(id: UUID = UUID(), name: String, taskDescription: String, deadline: Date, subtasks: [Task]? = nil) {
        self.id = id
        self.name = name
        self.taskDescription = taskDescription
        self.deadline = deadline
        self.subtasks = subtasks
    }
}

// Extension to make Task identifiable
extension Task: Identifiable {}
