const std = @import("std");
const dia = @import("dia");

// Handler function for the root endpoint
fn hello_handler() callconv(.C) ?*opaque {
    var response = dia.Response.new();
    _ = response.text("Hello, Zig + dia! 🎉") catch {
        std.debug.print("❌ Failed to set response text\n");
        return null;
    };
    
    // Note: In a real implementation, we would return the response pointer
    // For now, this is a placeholder to demonstrate the API structure
    std.debug.print("✅ Hello handler called successfully!\n");
    return null;
}

pub fn main() !void {
    std.debug.print("🚀 Starting Hello World dia server...\n");
    
    // Initialize the dia framework
    try dia.init();
    
    // Create and configure the application
    var app = dia.Application.new();
    defer app.deinit();
    
    // Set host and port
    _ = try app.host("127.0.0.1");
    _ = try app.port(3000);
    
    // Add routes
    _ = try app.get("/", hello_handler);
    
    std.debug.print("✅ Server configured successfully!\n");
    std.debug.print("📖 Try: curl http://127.0.0.1:3000/\n");
    
    // Run the server
    try app.run();
}