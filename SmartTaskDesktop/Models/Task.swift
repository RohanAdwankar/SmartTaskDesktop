import Foundation
import SwiftData

@Model
final class Task {
    var name: String
    var taskDescription: String
    var deadline: Date
    @Relationship(deleteRule: .cascade) var subtasks: [Task]?

    init(name: String, taskDescription: String, deadline: Date, subtasks: [Task]? = nil) {
        self.name = name
        self.taskDescription = taskDescription
        self.deadline = deadline
        self.subtasks = subtasks
    }
}
