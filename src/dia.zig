//! dia - A cross-platform backend framework for Zig
//! 
//! This library provides a high-level, easy-to-use interface for building
//! web applications in Zig, powered by Rust and actix-web under the hood.
//! 
//! ## Usage
//! 
//! ```zig
//! const dia = @import("dia");
//! 
//! // Or import specific modules
//! const request = @import("dia").request;
//! const response = @import("dia").response;
//! const controller = @import("dia").controller;
//! const middleware = @import("dia").middleware;
//! ```

const std = @import("std");
const print = std.debug.print;

// Export all modules for easy access
pub const request = @import("request.zig");
pub const response = @import("response.zig");
pub const controller = @import("controller.zig");
pub const middleware = @import("middleware.zig");

// Re-export key types for convenience
pub const Request = request.Request;
pub const Response = response.Response;
pub const Controller = controller.Controller;
pub const Middleware = middleware.Middleware;
pub const HandlerFn = controller.HandlerFn;
pub const MiddlewareHandler = middleware.MiddlewareHandler;

// FFI function declarations from dia-core
extern "C" fn dia_init() c_int;
extern "C" fn dia_version() [*:0]const u8;
extern "C" fn dia_free_string(s: [*]u8) void;

// Application FFI functions
extern "C" fn dia_application_new() ?*opaque;
extern "C" fn dia_application_host(app: ?*opaque, host: [*:0]const u8) c_int;
extern "C" fn dia_application_port(app: ?*opaque, port: u16) c_int;
extern "C" fn dia_application_run(app: ?*opaque) c_int;
extern "C" fn dia_application_free(app: ?*opaque) void;
extern "C" fn dia_application_get(app: ?*opaque, path: [*:0]const u8, handler: *const fn() callconv(.C) ?*opaque) c_int;
extern "C" fn dia_application_post(app: ?*opaque, path: [*:0]const u8, handler: *const fn() callconv(.C) ?*opaque) c_int;
extern "C" fn dia_application_controller(app: ?*opaque, controller: ?*opaque) c_int;

/// Initialize the dia framework
/// This must be called before using any other dia functions
pub fn init() !void {
    const result = dia_init();
    if (result != 0) {
        return error.InitializationFailed;
    }
}

/// Get the dia framework version
pub fn version() []const u8 {
    const c_str = dia_version();
    return std.mem.span(c_str);
}





/// Application builder for creating web servers
pub const Application = struct {
    ptr: ?*opaque,
    host_str: ?[]const u8 = null,
    port_num: u16 = 8080,

    const Self = @This();

    /// Create a new application
    pub fn new() Self {
        return Self{
            .ptr = dia_application_new(),
        };
    }

    /// Set the host address
    pub fn host(self: *Self, host_addr: []const u8) !*Self {
        // Store the host string for later use
        self.host_str = host_addr;
        
        // Convert to C string and call FFI
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const c_str = try allocator.dupeZ(u8, host_addr);
        const result = dia_application_host(self.ptr, c_str.ptr);
        
        if (result != 0) {
            return error.HostSetFailed;
        }
        return self;
    }

    /// Set the port number
    pub fn port(self: *Self, port_num: u16) !*Self {
        self.port_num = port_num;
        const result = dia_application_port(self.ptr, port_num);
        if (result != 0) {
            return error.PortSetFailed;
        }
        return self;
    }

    /// Add a GET route
    pub fn get(self: *Self, path: []const u8, handler: HandlerFn) !*Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const c_str = try allocator.dupeZ(u8, path);
        const result = dia_application_get(self.ptr, c_str.ptr, handler);
        
        if (result != 0) {
            return error.RouteAddFailed;
        }
        return self;
    }

    /// Add a POST route
    pub fn post(self: *Self, path: []const u8, handler: HandlerFn) !*Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const c_str = try allocator.dupeZ(u8, path);
        const result = dia_application_post(self.ptr, c_str.ptr, handler);
        
        if (result != 0) {
            return error.RouteAddFailed;
        }
        return self;
    }

    /// Add a controller to the application
    pub fn addController(self: *Self, ctrl: *Controller) !*Self {
        const result = dia_application_controller(self.ptr, ctrl.ptr);
        if (result != 0) {
            return error.ControllerAddFailed;
        }
        return self;
    }

    /// Run the application server
    pub fn run(self: *Self) !void {
        print("🚀 Starting dia server on {}:{}...\n", .{ self.host_str orelse "127.0.0.1", self.port_num });
        
        const result = dia_application_run(self.ptr);
        if (result != 0) {
            return error.ServerRunFailed;
        }
    }

    /// Free the application (called automatically by deinit)
    pub fn deinit(self: *Self) void {
        if (self.ptr) |ptr| {
            dia_application_free(ptr);
            self.ptr = null;
        }
    }
};

// Convenience functions and helpers

/// Create a simple text response
pub fn ok(content: []const u8) !Response {
    return response.ok(content);
}

/// Create a JSON response
pub fn okJson(json_content: []const u8) !Response {
    return response.okJson(json_content);
}

/// Create a JSON response from a Zig struct
pub fn okJsonStruct(data: anytype, allocator: std.mem.Allocator) !Response {
    return response.okJsonStruct(data, allocator);
}

/// Create an error response
pub fn errorResponse(status_code: u16, message: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.status(status_code);
    _ = try resp.text(message);
    return resp;
}

/// Create a route helper
pub fn route(method: []const u8, path: []const u8, handler: HandlerFn) controller.Route {
    return controller.Route.init(method, path, handler);
}

// Re-export route helpers for convenience
pub const GET = controller.GET;
pub const POST = controller.POST;
pub const PUT = controller.PUT;
pub const DELETE = controller.DELETE;

// Test function to verify the binding works
pub fn testConnection() !void {
    try init();
    print("✅ dia framework initialized successfully!\n", .{});
    print("📦 Version: {s}\n", .{version()});
}

// Version and compatibility info
pub const VERSION = "0.1.0";
pub const AUTHOR = "dia team";
pub const DESCRIPTION = "Cross-platform backend framework for Zig";

// Export test functionality
test "dia framework initialization" {
    try testConnection();
}