//! dia.controller - Controller and routing module
//! 
//! This module provides functionality for defining routes, controllers,
//! and handling HTTP endpoints with type-safe handlers.

const std = @import("std");
const Request = @import("request.zig").Request;
const Response = @import("response.zig").Response;

// FFI function declarations for controller handling
extern "C" fn dia_controller_new() ?*opaque;
extern "C" fn dia_controller_get(ctrl: ?*opaque, path: [*:0]const u8, handler: HandlerFn) c_int;
extern "C" fn dia_controller_post(ctrl: ?*opaque, path: [*:0]const u8, handler: HandlerFn) c_int;
extern "C" fn dia_controller_put(ctrl: ?*opaque, path: [*:0]const u8, handler: HandlerFn) c_int;
extern "C" fn dia_controller_delete(ctrl: ?*opaque, path: [*:0]const u8, handler: HandlerFn) c_int;
extern "C" fn dia_controller_middleware(ctrl: ?*opaque, middleware: MiddlewareFn) c_int;
extern "C" fn dia_controller_free(ctrl: ?*opaque) void;

/// Handler function type
pub const HandlerFn = *const fn() callconv(.C) ?*opaque;

/// Middleware function type
pub const MiddlewareFn = *const fn() callconv(.C) c_int;

/// Route context that handlers receive
pub const RouteContext = struct {
    request: Request,
    response: Response,
    params: std.StringHashMap([]const u8),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .request = Request.new(),
            .response = Response.new(),
            .params = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.request.deinit();
        self.response.deinit();
        self.params.deinit();
    }

    /// Get path parameter by name
    pub fn param(self: *const Self, name: []const u8) ?[]const u8 {
        return self.params.get(name);
    }
};

/// Controller for grouping related routes
pub const Controller = struct {
    ptr: ?*opaque,
    base_path: []const u8,

    const Self = @This();

    /// Create a new controller
    pub fn new() Self {
        return Self{
            .ptr = dia_controller_new(),
            .base_path = "",
        };
    }

    /// Create a controller with a base path
    pub fn withBasePath(base_path: []const u8) Self {
        return Self{
            .ptr = dia_controller_new(),
            .base_path = base_path,
        };
    }

    /// Add a GET route
    pub fn get(self: *Self, path: []const u8, handler: HandlerFn) !*Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const full_path = try std.fmt.allocPrintZ(allocator, "{s}{s}", .{ self.base_path, path });
        const result = dia_controller_get(self.ptr, full_path.ptr, handler);
        
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
        
        const full_path = try std.fmt.allocPrintZ(allocator, "{s}{s}", .{ self.base_path, path });
        const result = dia_controller_post(self.ptr, full_path.ptr, handler);
        
        if (result != 0) {
            return error.RouteAddFailed;
        }
        return self;
    }

    /// Add a PUT route
    pub fn put(self: *Self, path: []const u8, handler: HandlerFn) !*Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const full_path = try std.fmt.allocPrintZ(allocator, "{s}{s}", .{ self.base_path, path });
        const result = dia_controller_put(self.ptr, full_path.ptr, handler);
        
        if (result != 0) {
            return error.RouteAddFailed;
        }
        return self;
    }

    /// Add a DELETE route
    pub fn delete(self: *Self, path: []const u8, handler: HandlerFn) !*Self {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const allocator = arena.allocator();
        
        const full_path = try std.fmt.allocPrintZ(allocator, "{s}{s}", .{ self.base_path, path });
        const result = dia_controller_delete(self.ptr, full_path.ptr, handler);
        
        if (result != 0) {
            return error.RouteAddFailed;
        }
        return self;
    }

    /// Add middleware to this controller
    pub fn middleware(self: *Self, mw: MiddlewareFn) !*Self {
        const result = dia_controller_middleware(self.ptr, mw);
        if (result != 0) {
            return error.MiddlewareAddFailed;
        }
        return self;
    }

    /// Free the controller resources
    pub fn deinit(self: *Self) void {
        if (self.ptr) |ptr| {
            dia_controller_free(ptr);
            self.ptr = null;
        }
    }
};

/// Route definition helper
pub const Route = struct {
    method: []const u8,
    path: []const u8,
    handler: HandlerFn,

    pub fn init(method: []const u8, path: []const u8, handler: HandlerFn) Route {
        return Route{
            .method = method,
            .path = path,
            .handler = handler,
        };
    }
};

// Convenience functions for creating routes
pub fn GET(path: []const u8, handler: HandlerFn) Route {
    return Route.init("GET", path, handler);
}

pub fn POST(path: []const u8, handler: HandlerFn) Route {
    return Route.init("POST", path, handler);
}

pub fn PUT(path: []const u8, handler: HandlerFn) Route {
    return Route.init("PUT", path, handler);
}

pub fn DELETE(path: []const u8, handler: HandlerFn) Route {
    return Route.init("DELETE", path, handler);
}