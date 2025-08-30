const std = @import("std");
const dia = @import("dia");

// Handler for GET /users endpoint
fn get_users_handler() callconv(.C) ?*opaque {
    const users_json = 
        \\{
        \\  "users": [
        \\    {"id": 1, "name": "Alice", "email": "alice@example.com"},
        \\    {"id": 2, "name": "Bob", "email": "bob@example.com"},
        \\    {"id": 3, "name": "Charlie", "email": "charlie@example.com"}
        \\  ]
        \\}
    ;
    
    var response = dia.Response.new();
    _ = response.json(users_json) catch {
        std.debug.print("❌ Failed to set JSON response\n");
        return null;
    };
    
    std.debug.print("✅ Users endpoint called successfully!\n");
    return null;
}

// Handler for GET /health endpoint
fn health_handler() callconv(.C) ?*opaque {
    const health_json = 
        \\{
        \\  "status": "healthy",
        \\  "framework": "dia",
        \\  "language": "zig",
        \\  "version": "0.1.0"
        \\}
    ;
    
    var response = dia.Response.new();
    _ = response.json(health_json) catch {
        std.debug.print("❌ Failed to set health response\n");
        return null;
    };
    
    std.debug.print("✅ Health check endpoint called successfully!\n");
    return null;
}

// Handler for GET / (root) endpoint
fn root_handler() callconv(.C) ?*opaque {
    const welcome_json = 
        \\{
        \\  "message": "Welcome to dia REST API!",
        \\  "endpoints": [
        \\    "GET /",
        \\    "GET /health",
        \\    "GET /users"
        \\  ]
        \\}
    ;
    
    var response = dia.Response.new();
    _ = response.json(welcome_json) catch {
        std.debug.print("❌ Failed to set welcome response\n");
        return null;
    };
    
    std.debug.print("✅ Root endpoint called successfully!\n");
    return null;
}

pub fn main() !void {
    std.debug.print("🚀 Starting REST API dia server...\n");
    
    // Initialize the dia framework
    try dia.init();
    
    // Create and configure the application
    var app = dia.Application.new();
    defer app.deinit();
    
    // Set host and port
    _ = try app.host("127.0.0.1");
    _ = try app.port(3001);
    
    // Add API routes
    _ = try app.get("/", root_handler);
    _ = try app.get("/health", health_handler);
    _ = try app.get("/users", get_users_handler);
    
    std.debug.print("✅ REST API server configured successfully!\n");
    std.debug.print("📖 Available endpoints:\n");
    std.debug.print("   • GET http://127.0.0.1:3001/ - API overview\n");
    std.debug.print("   • GET http://127.0.0.1:3001/health - Health check\n");
    std.debug.print("   • GET http://127.0.0.1:3001/users - User list\n");
    
    // Run the server
    try app.run();
}