//! dia.response - HTTP Response handling module
//!
//! This module provides functionality for building HTTP responses,
//! including setting status codes, headers, and response body.

const std = @import("std");

// FFI function declarations for response handling
extern "C" fn dia_response_new() ?*anyopaque;
extern "C" fn dia_response_text(resp: ?*anyopaque, text: [*:0]const u8) c_int;
extern "C" fn dia_response_json(resp: ?*anyopaque, json_str: [*:0]const u8) c_int;
extern "C" fn dia_response_status(resp: ?*anyopaque, status: u16) c_int;
extern "C" fn dia_response_header(resp: ?*anyopaque, name: [*:0]const u8, value: [*:0]const u8) c_int;
extern "C" fn dia_response_cookie(resp: ?*anyopaque, name: [*:0]const u8, value: [*:0]const u8) c_int;
extern "C" fn dia_response_free(resp: ?*anyopaque) void;

/// HTTP Response builder
pub const Response = struct {
    ptr: ?*anyopaque,

    const Self = @This();

    /// Create a new response
    pub fn new() Self {
        return Self{
            .ptr = dia_response_new(),
        };
    }

    /// Set response text content
    pub fn text(self: *Self, content: []const u8) !*Self {
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

    /// Serialize and send JSON from a Zig structure
    pub fn jsonStruct(self: *Self, data: anytype, allocator: std.mem.Allocator) !*Self {
        const json_string = try std.json.stringifyAlloc(allocator, data, .{});
        defer allocator.free(json_string);

        return self.json(json_string);
    }

    /// Set response status code
    pub fn status(self: *Self, status_code: u16) !*Self {
        const result = dia_response_status(self.ptr, status_code);
        if (result != 0) {
            return error.ResponseStatusFailed;
        }
        return self;
    }

    /// Set response header
    pub fn header(self: *Self, name: []const u8, value: []const u8) !*Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const c_name = try allocator.dupeZ(u8, name);
        const c_value = try allocator.dupeZ(u8, value);
        const result = dia_response_header(self.ptr, c_name.ptr, c_value.ptr);

        if (result != 0) {
            return error.ResponseHeaderFailed;
        }
        return self;
    }

    /// Set a cookie
    pub fn cookie(self: *Self, name: []const u8, value: []const u8) !*Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();

        const c_name = try allocator.dupeZ(u8, name);
        const c_value = try allocator.dupeZ(u8, value);
        const result = dia_response_cookie(self.ptr, c_name.ptr, c_value.ptr);

        if (result != 0) {
            return error.ResponseCookieFailed;
        }
        return self;
    }

    /// Free the response resources
    pub fn deinit(self: *Self) void {
        if (self.ptr) |ptr| {
            dia_response_free(ptr);
            self.ptr = null;
        }
    }
};

// Convenience functions for creating common responses
pub fn ok(content: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.status(200);
    _ = try resp.text(content);
    return resp;
}

pub fn okJson(json_content: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.status(200);
    _ = try resp.header("Content-Type", "application/json");
    _ = try resp.json(json_content);
    return resp;
}

pub fn okJsonStruct(data: anytype, allocator: std.mem.Allocator) !Response {
    var resp = Response.new();
    _ = try resp.status(200);
    _ = try resp.header("Content-Type", "application/json");
    _ = try resp.jsonStruct(data, allocator);
    return resp;
}

pub fn badRequest(message: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.status(400);
    _ = try resp.text(message);
    return resp;
}

pub fn notFound(message: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.status(404);
    _ = try resp.text(message);
    return resp;
}

pub fn internalError(message: []const u8) !Response {
    var resp = Response.new();
    _ = try resp.status(500);
    _ = try resp.text(message);
    return resp;
}
