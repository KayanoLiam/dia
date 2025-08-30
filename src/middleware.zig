//! dia.middleware - Middleware handling module
//!
//! This module provides functionality for creating and managing middleware,
//! including built-in middleware for common tasks like CORS, logging, and authentication.

const std = @import("std");
const Request = @import("request.zig").Request;
const Response = @import("response.zig").Response;

// FFI function declarations for middleware handling
extern "C" fn dia_middleware_new() ?*anyopaque;
extern "C" fn dia_middleware_cors(mw: ?*anyopaque) c_int;
extern "C" fn dia_middleware_logger(mw: ?*anyopaque) c_int;
extern "C" fn dia_middleware_custom(mw: ?*anyopaque, handler: MiddlewareHandler) c_int;
extern "C" fn dia_middleware_free(mw: ?*anyopaque) void;

/// Middleware handler function type
pub const MiddlewareHandler = *const fn (req: ?*anyopaque, resp: ?*anyopaque) callconv(.C) c_int;

/// Middleware context for custom middleware
pub const MiddlewareContext = struct {
    request: *Request,
    response: *Response,
    next_fn: *const fn () callconv(.C) c_int,

    const Self = @This();

    /// Call the next middleware in the chain
    pub fn next(self: *const Self) !void {
        const result = self.next_fn();
        if (result != 0) {
            return error.MiddlewareChainFailed;
        }
    }
};

/// Middleware builder
pub const Middleware = struct {
    ptr: ?*anyopaque,

    const Self = @This();

    /// Create a new middleware
    pub fn new() Self {
        return Self{
            .ptr = dia_middleware_new(),
        };
    }

    /// Add CORS middleware
    pub fn cors(self: *Self) !*Self {
        const result = dia_middleware_cors(self.ptr);
        if (result != 0) {
            return error.CorsMiddlewareFailed;
        }
        return self;
    }

    /// Add logging middleware
    pub fn logger(self: *Self) !*Self {
        const result = dia_middleware_logger(self.ptr);
        if (result != 0) {
            return error.LoggerMiddlewareFailed;
        }
        return self;
    }

    /// Add custom middleware
    pub fn custom(self: *Self, handler: MiddlewareHandler) !*Self {
        const result = dia_middleware_custom(self.ptr, handler);
        if (result != 0) {
            return error.CustomMiddlewareFailed;
        }
        return self;
    }

    /// Free the middleware resources
    pub fn deinit(self: *Self) void {
        if (self.ptr) |ptr| {
            dia_middleware_free(ptr);
            self.ptr = null;
        }
    }
};

// Built-in middleware functions

/// CORS middleware for cross-origin requests
pub fn corsMiddleware() !Middleware {
    var mw = Middleware.new();
    _ = try mw.cors();
    return mw;
}

/// Logger middleware for request logging
pub fn loggerMiddleware() !Middleware {
    var mw = Middleware.new();
    _ = try mw.logger();
    return mw;
}

/// Authentication middleware
pub fn authMiddleware(comptime auth_fn: fn (*Request) bool) MiddlewareHandler {
    const AuthWrapper = struct {
        fn handler(req: ?*anyopaque, resp: ?*anyopaque) callconv(.C) c_int {
            var request = Request{ .ptr = req };

            if (!auth_fn(&request)) {
                var response = Response{ .ptr = resp };
                _ = response.status(401) catch return -1;
                _ = response.text("Unauthorized") catch return -1;
                return -1; // Stop middleware chain
            }

            return 0; // Continue middleware chain
        }
    };

    return AuthWrapper.handler;
}

/// Rate limiting middleware
pub fn rateLimitMiddleware(requests_per_minute: u32) MiddlewareHandler {
    const RateLimit = struct {
        var request_counts = std.HashMap([]const u8, u32, std.hash_map.StringContext, 80).init(std.heap.page_allocator);
        var last_reset = std.time.timestamp();

        fn handler(req: ?*anyopaque, resp: ?*anyopaque) callconv(.C) c_int {
            var request = Request{ .ptr = req };

            const client_ip = request.header("X-Forwarded-For") catch "unknown";
            const current_time = std.time.timestamp();

            // Reset counts every minute
            if (current_time - last_reset > 60) {
                request_counts.clearAndFree();
                last_reset = current_time;
            }

            const current_count = request_counts.get(client_ip) orelse 0;
            if (current_count >= requests_per_minute) {
                var response = Response{ .ptr = resp };
                _ = response.status(429) catch return -1;
                _ = response.text("Too Many Requests") catch return -1;
                return -1;
            }

            request_counts.put(client_ip, current_count + 1) catch return -1;
            return 0;
        }
    };

    return RateLimit.handler;
}

/// JSON content type middleware
pub fn jsonContentTypeMiddleware() MiddlewareHandler {
    const JsonContentType = struct {
        fn handler(req: ?*anyopaque, resp: ?*anyopaque) callconv(.C) c_int {
            _ = req; // unused
            var response = Response{ .ptr = resp };
            _ = response.header("Content-Type", "application/json") catch return -1;
            return 0;
        }
    };

    return JsonContentType.handler;
}

/// Security headers middleware
pub fn securityHeadersMiddleware() MiddlewareHandler {
    const SecurityHeaders = struct {
        fn handler(req: ?*anyopaque, resp: ?*anyopaque) callconv(.C) c_int {
            _ = req; // unused
            var response = Response{ .ptr = resp };
            _ = response.header("X-Content-Type-Options", "nosniff") catch return -1;
            _ = response.header("X-Frame-Options", "DENY") catch return -1;
            _ = response.header("X-XSS-Protection", "1; mode=block") catch return -1;
            return 0;
        }
    };

    return SecurityHeaders.handler;
}
