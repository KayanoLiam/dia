const std = @import("std");
const dia = @import("dia");

// Different ways to import dia modules (like std)

// Method 1: Import entire dia framework
// const dia = @import("dia");
// Usage: dia.Application.new(), dia.Response.new(), etc.

// Method 2: Import specific modules
const request = @import("dia").request;
const response = @import("dia").response;
const controller = @import("dia").controller;
const middleware = @import("dia").middleware;

// Method 3: Import specific types
const Application = dia.Application;
const Response = dia.Response;
const Request = dia.Request;

// Example 1: Simple server using full dia import
fn example1() !void {
    try dia.init();
    
    var app = dia.Application.new();
    defer app.deinit();
    
    _ = try app.host("127.0.0.1");
    _ = try app.port(3000);
    _ = try app.get("/", hello_handler);
    
    try app.run();
}

// Example 2: Using modular imports (like std.json, std.http, etc.)
fn example2() !void {
    try dia.init();
    
    // Using controller module
    var api_controller = controller.Controller.withBasePath("/api");
    defer api_controller.deinit();
    
    _ = try api_controller.get("/users", users_handler);
    _ = try api_controller.post("/users", create_user_handler);
    
    // Using middleware module
    var cors_mw = try middleware.corsMiddleware();
    defer cors_mw.deinit();
    
    var logger_mw = try middleware.loggerMiddleware();
    defer logger_mw.deinit();
    
    // Create application with modular components
    var app = Application.new();
    defer app.deinit();
    
    _ = try app.host("127.0.0.1");
    _ = try app.port(3001);
    _ = try app.addController(&api_controller);
    
    try app.run();
}

// Example 3: Using convenience functions (like std.ArrayList.init, etc.)
fn example3() !void {
    try dia.init();
    
    var app = dia.Application.new();
    defer app.deinit();
    
    // Using convenience route helpers (like std.json.stringify)
    _ = try app.get("/", hello_handler);
    _ = try app.get("/json", json_handler);
    
    try app.run();
}

// Handler functions
fn hello_handler() callconv(.C) ?*opaque {
    // Method 1: Using dia convenience functions
    var resp = dia.ok("Hello from dia framework!") catch {
        std.debug.print("Failed to create response\n");
        return null;
    };
    defer resp.deinit();
    
    std.debug.print("Hello handler called!\n");
    return null;
}

fn json_handler() callconv(.C) ?*opaque {
    // Method 2: Using response module directly
    const json_data = 
        \{"message": "Hello JSON!", "framework": "dia"}
    ;
    
    var resp = response.okJson(json_data) catch {
        std.debug.print("Failed to create JSON response\n");
        return null;
    };
    defer resp.deinit();
    
    std.debug.print("JSON handler called!\n");
    return null;
}

fn users_handler() callconv(.C) ?*opaque {
    // Method 3: Using struct serialization (like std.json)
    const User = struct {
        id: u32,
        name: []const u8,
        email: []const u8,
    };
    
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const users = [_]User{
        User{ .id = 1, .name = "Alice", .email = "alice@example.com" },
        User{ .id = 2, .name = "Bob", .email = "bob@example.com" },
    };
    
    var resp = response.okJsonStruct(users, allocator) catch {
        std.debug.print("Failed to create JSON struct response\n");
        return null;
    };
    defer resp.deinit();
    
    std.debug.print("Users handler called!\n");
    return null;
}

fn create_user_handler() callconv(.C) ?*opaque {
    // Method 4: Using error responses (like std.errors)
    var resp = dia.errorResponse(501, "Not implemented yet") catch {
        std.debug.print("Failed to create error response\n");
        return null;
    };
    defer resp.deinit();
    
    std.debug.print("Create user handler called!\n");
    return null;
}

// Main function demonstrating different usage patterns
pub fn main() !void {
    std.debug.print("=== Dia Framework Usage Examples ===\n");
    
    // Test framework initialization
    try dia.testConnection();
    
    std.debug.print("\n=== Example 1: Simple usage ===\n");
    // Uncomment to run: try example1();
    
    std.debug.print("\n=== Example 2: Modular usage ===\n");
    // Uncomment to run: try example2();
    
    std.debug.print("\n=== Example 3: Convenience functions ===\n");
    // Uncomment to run: try example3();
    
    std.debug.print("\n✅ All examples compiled successfully!\n");
}

// Test that demonstrates the std-like API
test "dia framework std-like API" {
    // Test initialization (like std.testing)
    try dia.testConnection();
    
    // Test that all modules are accessible (like std.json, std.http)
    const req_module = @import("dia").request;
    const resp_module = @import("dia").response;
    const ctrl_module = @import("dia").controller;
    const mw_module = @import("dia").middleware;
    
    // Test that types are accessible (like std.ArrayList, std.HashMap)
    const AppType = dia.Application;
    const ReqType = dia.Request;
    const RespType = dia.Response;
    
    std.debug.print("✅ All dia modules and types accessible like std!\n");
}