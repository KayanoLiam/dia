//! dia - A cross-platform backend framework for Zig
//! 
//! This library provides a high-level, easy-to-use interface for building
//! web applications in Zig, powered by Rust and actix-web under the hood.

const std = @import("std");
const print = std.debug.print;

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

// Response FFI functions
extern "C" fn dia_response_new() ?*opaque;
extern "C" fn dia_response_text(resp: ?*opaque, text: [*:0]const u8) c_int;
extern "C" fn dia_response_json(resp: ?*opaque, json_str: [*:0]const u8) c_int;
extern "C" fn dia_response_status(resp: ?*opaque, status: u16) c_int;
extern "C" fn dia_response_free(resp: ?*opaque) void;

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

/// Response builder for HTTP responses
pub const Response = struct {
    ptr: ?*opaque,

    const Self = @This();

    /// Create a new response
    pub fn new() Self {
        return Self{
            .ptr = dia_response_new(),
        };
    }

    /// Set response text content
    pub fn text(self: *Self, content: []const u8) !*Self {
        // Convert Zig string to null-terminated C string
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const c_str = try allocator.dupeZ(u8, content);
        const result = dia_response_text(self.ptr, c_str.ptr);
        
        if (result != 0) {
            return error.ResponseTextFailed;
        }
        return self;
    }

    /// Set response JSON content
    pub fn json(self: *Self, json_content: []const u8) !*Self {
        // Convert Zig string to null-terminated C string
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const c_str = try allocator.dupeZ(u8, json_content);
        const result = dia_response_json(self.ptr, c_str.ptr);
        
        if (result != 0) {
            return error.ResponseJsonFailed;
        }
        return self;
    }

    /// Set response status code
    pub fn status(self: *Self, status_code: u16) !*Self {
        const result = dia_response_status(self.ptr, status_code);
        if (result != 0) {
            return error.ResponseStatusFailed;
        }
        return self;
    }

    /// Free the response (called automatically by deinit)
    pub fn deinit(self: *Self) void {
        if (self.ptr) |ptr| {
            dia_response_free(ptr);
            self.ptr = null;
        }
    }
};

/// Handler function type
pub const HandlerFn = *const fn() callconv(.C) ?*opaque;

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

// Convenience functions for creating responses
pub fn ok_text(content: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.text(content);
    return resp;
}

pub fn ok_json(json_content: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.json(json_content);
    return resp;
}

pub fn error_response(status_code: u16, message: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.status(status_code);
    _ = try resp.text(message);
    return resp;
}

// Test function to verify the binding works
pub fn test_connection() !void {
    try init();
    print("✅ dia framework initialized successfully!\n", .{});
    print("📦 Version: {s}\n", .{version()});
}