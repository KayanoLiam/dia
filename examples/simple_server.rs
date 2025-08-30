//! Simple server example using dia framework
//! 
//! This example demonstrates how to create a basic web server
//! with dia-core directly (without Zig integration).

use dia_core::{Application, Response, BasicController, Route};
use serde_json::json;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize the dia framework
    dia_core::dia_init();

    println!("🚀 Starting dia server...");

    // Create a simple controller with routes
    let controller = BasicController::new()
        .base_path("/api")
        .get("/", |_req, _resp| {
            Box::pin(async {
                Response::ok_text("Hello from dia! 🎉")
            })
        })
        .get("/health", |_req, _resp| {
            Box::pin(async {
                Response::ok_json(json!({
                    "status": "healthy",
                    "framework": "dia",
                    "version": env!("CARGO_PKG_VERSION")
                }))
            })
        })
        .get("/users", |_req, _resp| {
            Box::pin(async {
                Response::ok_json(json!({
                    "users": [
                        {"id": 1, "name": "Alice", "email": "alice@example.com"},
                        {"id": 2, "name": "Bob", "email": "bob@example.com"},
                        {"id": 3, "name": "Charlie", "email": "charlie@example.com"}
                    ]
                }))
            })
        });

    // Create and configure the application
    let app = Application::new()
        .host("127.0.0.1")
        .port(3000)
        .controller(controller);

    println!("✅ Server is running on http://127.0.0.1:3000");
    println!("📖 Try these endpoints:");
    println!("   • GET http://127.0.0.1:3000/api/");
    println!("   • GET http://127.0.0.1:3000/api/health");
    println!("   • GET http://127.0.0.1:3000/api/users");

    // Run the server
    app.run().await?;

    Ok(())
}