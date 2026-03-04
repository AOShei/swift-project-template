import Hummingbird
import SQLite
import Foundation

// 1. Define the Data Model
struct TaskItem: Codable, Sendable {
    let id: Int64?
    var title: String
    var isCompleted: Bool
}

@main
struct Swift6App {
    static func main() async throws {
        // 2. Setup SQLite Database
        // In Codespaces, this persists in the project folder
        let path = "db.sqlite3"
        let db = try Connection(path)
        
        // Define Table Structure
        let tasks = Table("tasks")
        let id = Expression<Int64>("id")
        let title = Expression<String>("title")
        let isCompleted = Expression<Bool>("is_completed")
        
        // Create table if it doesn't exist
        try db.run(tasks.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(title)
            t.column(isCompleted, defaultValue: false)
        })

        // 3. Setup Web Server (Hummingbird)
        let router = Router()
        
        // Root Page - Simple HTML Response
        router.get("/") { _, _ -> HTML in
            let allTasks = try db.prepare(tasks).map { row in
                TaskItem(id: row[id], title: row[title], isCompleted: row[isCompleted])
            }
            return renderIndex(items: allTasks)
        }
        
        // API: Add Task
        router.post("/add") { request, _ -> Response in
            struct AddRequest: Decodable { let title: String }
            let input = try await request.decode(as: AddRequest.self)
            
            try db.run(tasks.insert(title <- input.title))
            
            // Redirect back to home
            return Response(status: .seeOther, headers: [.location: "/"])
        }

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("0.0.0.0", port: 8080))
        )
        
        print("🚀 Server started at http://localhost:8080")
        try await app.runService()
    }
}

// 4. Simple View Logic (No heavy template engines needed)
struct HTML: ResponseGenerator {
    let content: String
    public func response(from request: Request, context: some RequestContext) throws -> Response {
        return Response(
            status: .ok,
            headers: [.contentType: "text/html"],
            body: .init(byteBuffer: .init(string: content))
        )
    }
}

func renderIndex(items: [TaskItem]) -> HTML {
    let rows = items.map { item in
        """
        <li>
            \(item.isCompleted ? "✅" : "⭕️") \(item.title)
        </li>
        """
    }.joined()

    return HTML(content: """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
        <title>Swift Project</title>
    </head>
    <body class="container">
        <h1>Task Manager</h1>
        <form action="/add" method="post">
            <input type="text" name="title" placeholder="What needs to be done?" required>
            <button type="submit">Add Task</button>
        </form>
        <ul>\(rows)</ul>
    </body>
    </html>
    """)
}