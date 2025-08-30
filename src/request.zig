//! dia.request - HTTP Request handling module
//!
//! This module provides functionality for handling HTTP requests,
//! including parsing headers, query parameters, and request body.

const std = @import("std");

// FFI function declarations for request handling
extern "C" fn dia_request_new() ?*anyopaque;
extern "C" fn dia_request_get_method(req: ?*anyopaque) [*:0]const u8;
extern "C" fn dia_request_get_path(req: ?*anyopaque) [*:0]const u8;
extern "C" fn dia_request_get_header(req: ?*anyopaque, name: [*:0]const u8) [*:0]const u8;
extern "C" fn dia_request_get_query(req: ?*anyopaque, key: [*:0]const u8) [*:0]const u8;
extern "C" fn dia_request_get_body(req: ?*anyopaque) [*:0]const u8;
extern "C" fn dia_request_free(req: ?*anyopaque) void;

/// HTTP Request representation
pub const Request = struct {
    ptr: ?*anyopaque,

    const Self = @This();

    /// Create a new request (usually done internally by the framework)
    pub fn new() Self {
        return Self{
            .ptr = dia_request_new(),
        };
    }

    /// Get the HTTP method (GET, POST, etc.)
    pub fn method(self: *const Self) []const u8 {
        const c_str = dia_request_get_method(self.ptr);
        return std.mem.span(c_str);
    }

    /// Get the request path
    pub fn path(self: *const Self) []const u8 {
        const c_str = dia_request_get_path(self.ptr);
        return std.mem.span(c_str);
    }

    /// Get a header value by name
    pub fn header(self: *const Self, name: []const u8) ![]const u8 {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const c_name = try allocator.dupeZ(u8, name);
        const c_value = dia_request_get_header(self.ptr, c_name.ptr);

        return std.mem.span(c_value);
    }

    /// Get a query parameter value by key
    pub fn query(self: *const Self, key: []const u8) !?[]const u8 {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const c_key = try allocator.dupeZ(u8, key);
        const c_value = dia_request_get_query(self.ptr, c_key.ptr);

        if (c_value == null) return null;
        return std.mem.span(c_value);
    }

    /// Get the request body as string
    pub fn body(self: *const Self) []const u8 {
        const c_str = dia_request_get_body(self.ptr);
        return std.mem.span(c_str);
    }

    /// Parse JSON body into a structure
    pub fn json(self: *const Self, comptime T: type, allocator: std.mem.Allocator) !T {
        const body_str = self.body();
        return try std.json.parseFromSlice(T, allocator, body_str, .{});
    }

    /// Free the request resources
    pub fn deinit(self: *Self) void {
        if (self.ptr) |ptr| {
            dia_request_free(ptr);
            self.ptr = null;
        }
    }
};

/// Convenience function to create a request from context
pub fn from_context(ctx: ?*anyopaque) Request {
    return Request{ .ptr = ctx };
}
