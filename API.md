# dia API 参考文档 📖

> dia 框架完整 API 参考，包含所有模块、类型和函数的详细说明

## 📋 目录

- [核心模块](#核心模块)
- [Application](#application)
- [Request](#request)
- [Response](#response)
- [Controller](#controller)
- [Middleware](#middleware)
- [类型定义](#类型定义)
- [错误处理](#错误处理)

---

## 🔧 核心模块

### dia

主模块，提供框架的核心功能和便捷函数。

```zig
const dia = @import("dia");
```

#### 函数

##### `init() !void`

初始化 dia 框架。必须在使用其他功能前调用。

```zig
try dia.init();
```

**返回值**：
- `void` - 成功
- `error.InitializationFailed` - 初始化失败

##### `version() []const u8`

获取框架版本信息。

```zig
const ver = dia.version();
std.debug.print("Version: {s}\n", .{ver});
```

**返回值**：版本字符串

##### `testConnection() !void`

测试框架连接状态，用于调试。

```zig
try dia.testConnection();
```

#### 便捷函数

##### `ok(content: []const u8) !Response`

创建 200 状态的文本响应。

```zig
var resp = try dia.ok("Success!");
defer resp.deinit();
```

##### `okJson(json_content: []const u8) !Response`

创建 200 状态的 JSON 响应。

```zig
var resp = try dia.okJson("{\"status\": \"ok\"}");
defer resp.deinit();
```

##### `okJsonStruct(data: anytype, allocator: std.mem.Allocator) !Response`

将 Zig 结构体序列化为 JSON 响应。

```zig
const User = struct { id: u32, name: []const u8 };
const user = User{ .id = 1, .name = "Alice" };
var resp = try dia.okJsonStruct(user, allocator);
defer resp.deinit();
```

##### `errorResponse(status_code: u16, message: []const u8) !Response`

创建错误响应。

```zig
var resp = try dia.errorResponse(404, "Not Found");
defer resp.deinit();
```

#### 路由助手

##### `GET(path: []const u8, handler: HandlerFn) Route`
##### `POST(path: []const u8, handler: HandlerFn) Route`  
##### `PUT(path: []const u8, handler: HandlerFn) Route`
##### `DELETE(path: []const u8, handler: HandlerFn) Route`

创建路由定义。

```zig
const route = dia.GET("/users", list_users_handler);
```

---

## 🏠 Application

应用程序主类，管理服务器的生命周期和路由。

```zig
const Application = dia.Application;
```

### 构造函数

#### `new() Application`

创建新的应用程序实例。

```zig
var app = Application.new();
defer app.deinit();
```

### 方法

#### `host(self: *Self, host_addr: []const u8) !*Self`

设置服务器监听地址。

```zig
_ = try app.host("127.0.0.1");
_ = try app.host("0.0.0.0"); // 监听所有接口
```

**参数**：
- `host_addr` - 主机地址字符串

**返回值**：
- `*Self` - 链式调用支持
- `error.HostSetFailed` - 设置失败

#### `port(self: *Self, port_num: u16) !*Self`

设置服务器监听端口。

```zig
_ = try app.port(3000);
_ = try app.port(8080);
```

**参数**：
- `port_num` - 端口号 (1-65535)

**返回值**：
- `*Self` - 链式调用支持  
- `error.PortSetFailed` - 设置失败

#### `get(self: *Self, path: []const u8, handler: HandlerFn) !*Self`

添加 GET 路由。

```zig
_ = try app.get("/", home_handler);
_ = try app.get("/users/{id}", get_user_handler);
```

**参数**：
- `path` - 路由路径，支持参数占位符
- `handler` - 处理函数

#### `post(self: *Self, path: []const u8, handler: HandlerFn) !*Self`

添加 POST 路由。

```zig
_ = try app.post("/users", create_user_handler);
```

#### `addController(self: *Self, ctrl: *Controller) !*Self`

添加控制器到应用。

```zig
var api_controller = Controller.withBasePath("/api");
_ = try app.addController(&api_controller);
```

#### `run(self: *Self) !void`

启动服务器，开始监听请求。

```zig
try app.run(); // 阻塞运行
```

**错误**：
- `error.ServerRunFailed` - 服务器启动失败

#### `deinit(self: *Self) void`

释放应用程序资源。

```zig
defer app.deinit(); // 自动释放
app.deinit(); // 手动释放
```

---

## 📥 Request

HTTP 请求对象，提供访问请求数据的方法。

```zig
const Request = dia.Request;
```

### 构造函数

#### `new() Request`

创建新的请求对象（通常由框架内部使用）。

```zig
var req = Request.new();
defer req.deinit();
```

#### `from_context(ctx: ?*opaque) Request`

从上下文创建请求对象。

```zig
var req = dia.request.from_context(context);
```

### 方法

#### `method(self: *const Self) []const u8`

获取 HTTP 请求方法。

```zig
const method = req.method(); // "GET", "POST", "PUT", "DELETE"
```

**返回值**：HTTP 方法字符串

#### `path(self: *const Self) []const u8`

获取请求路径。

```zig
const path = req.path(); // "/users/123"
```

**返回值**：请求路径字符串

#### `header(self: *const Self, name: []const u8) ![]const u8`

获取请求头部值。

```zig
const auth = try req.header("Authorization");
const content_type = try req.header("Content-Type");
```

**参数**：
- `name` - 头部名称

**返回值**：头部值字符串

#### `query(self: *const Self, key: []const u8) !?[]const u8`

获取查询参数值。

```zig
const page = try req.query("page"); // ?page=1
const limit = try req.query("limit"); // ?limit=10
```

**参数**：
- `key` - 参数名称

**返回值**：
- `[]const u8` - 参数值
- `null` - 参数不存在

#### `body(self: *const Self) []const u8`

获取请求体内容。

```zig
const body = req.body();
```

**返回值**：请求体字符串

#### `json(self: *const Self, comptime T: type, allocator: std.mem.Allocator) !T`

将请求体解析为 JSON 对象。

```zig
const User = struct { name: []const u8, email: []const u8 };
const user = try req.json(User, allocator);
```

**参数**：
- `T` - 目标类型
- `allocator` - 内存分配器

**返回值**：解析后的对象

#### `deinit(self: *Self) void`

释放请求资源。

```zig
defer req.deinit();
```

---

## 📤 Response

HTTP 响应构建器，用于构造和发送响应。

```zig
const Response = dia.Response;
```

### 构造函数

#### `new() Response`

创建新的响应对象。

```zig
var resp = Response.new();
defer resp.deinit();
```

### 方法

#### `text(self: *Self, content: []const u8) !*Self`

设置文本响应内容。

```zig
_ = try resp.text("Hello, World!");
```

**参数**：
- `content` - 文本内容

**返回值**：
- `*Self` - 链式调用支持
- `error.ResponseTextFailed` - 设置失败

#### `json(self: *Self, json_content: []const u8) !*Self`

设置 JSON 响应内容。

```zig
_ = try resp.json("{\"message\": \"success\"}");
```

**参数**：
- `json_content` - JSON 字符串

#### `jsonStruct(self: *Self, data: anytype, allocator: std.mem.Allocator) !*Self`

将结构体序列化为 JSON 响应。

```zig
const user = User{ .id = 1, .name = "Alice" };
_ = try resp.jsonStruct(user, allocator);
```

**参数**：
- `data` - 要序列化的数据
- `allocator` - 内存分配器

#### `status(self: *Self, status_code: u16) !*Self`

设置 HTTP 状态码。

```zig
_ = try resp.status(200); // OK
_ = try resp.status(404); // Not Found  
_ = try resp.status(500); // Internal Server Error
```

**参数**：
- `status_code` - HTTP 状态码

#### `header(self: *Self, name: []const u8, value: []const u8) !*Self`

设置响应头部。

```zig
_ = try resp.header("Content-Type", "application/json");
_ = try resp.header("Cache-Control", "no-cache");
```

**参数**：
- `name` - 头部名称
- `value` - 头部值

#### `cookie(self: *Self, name: []const u8, value: []const u8) !*Self`

设置 Cookie。

```zig
_ = try resp.cookie("session_id", "abc123");
_ = try resp.cookie("user_pref", "dark_mode");
```

**参数**：
- `name` - Cookie 名称
- `value` - Cookie 值

#### `deinit(self: *Self) void`

释放响应资源。

```zig
defer resp.deinit();
```

### 便捷函数

```zig
// 在 dia.response 模块中
const response = dia.response;

// 创建成功响应
var resp = try response.ok("Success");
var resp = try response.okJson("{\"ok\": true}");
var resp = try response.okJsonStruct(data, allocator);

// 创建错误响应  
var resp = try response.badRequest("Invalid input");
var resp = try response.notFound("Resource not found");
var resp = try response.internalError("Server error");
```

---

## 🎮 Controller

路由控制器，用于组织和管理相关的路由。

```zig
const Controller = dia.Controller;
```

### 构造函数

#### `new() Controller`

创建新的控制器。

```zig
var ctrl = Controller.new();
defer ctrl.deinit();
```

#### `withBasePath(base_path: []const u8) Controller`

创建带基础路径的控制器。

```zig
var api = Controller.withBasePath("/api/v1");
defer api.deinit();
```

### 方法

#### `get(self: *Self, path: []const u8, handler: HandlerFn) !*Self`

添加 GET 路由。

```zig
_ = try ctrl.get("/users", list_users);
_ = try ctrl.get("/users/{id}", get_user);
```

#### `post(self: *Self, path: []const u8, handler: HandlerFn) !*Self`

添加 POST 路由。

```zig
_ = try ctrl.post("/users", create_user);
```

#### `put(self: *Self, path: []const u8, handler: HandlerFn) !*Self`

添加 PUT 路由。

```zig
_ = try ctrl.put("/users/{id}", update_user);
```

#### `delete(self: *Self, path: []const u8, handler: HandlerFn) !*Self`

添加 DELETE 路由。

```zig
_ = try ctrl.delete("/users/{id}", delete_user);
```

#### `middleware(self: *Self, mw: MiddlewareFn) !*Self`

为控制器添加中间件。

```zig
_ = try ctrl.middleware(auth_middleware);
```

#### `deinit(self: *Self) void`

释放控制器资源。

```zig
defer ctrl.deinit();
```

---

## 🔌 Middleware

中间件系统，用于请求预处理和后处理。

```zig
const Middleware = dia.Middleware;
```

### 构造函数

#### `new() Middleware`

创建新的中间件。

```zig
var mw = Middleware.new();
defer mw.deinit();
```

### 方法

#### `cors(self: *Self) !*Self`

添加 CORS 中间件。

```zig
_ = try mw.cors();
```

#### `logger(self: *Self) !*Self`

添加日志中间件。

```zig
_ = try mw.logger();
```

#### `custom(self: *Self, handler: MiddlewareHandler) !*Self`

添加自定义中间件。

```zig
fn my_middleware(req: ?*opaque, resp: ?*opaque) callconv(.C) c_int {
    // 中间件逻辑
    return 0; // 继续执行
}

_ = try mw.custom(my_middleware);
```

### 内置中间件

```zig
const middleware = dia.middleware;

// CORS 中间件
var cors = try middleware.corsMiddleware();

// 日志中间件
var logger = try middleware.loggerMiddleware();

// 认证中间件
var auth = middleware.authMiddleware(auth_function);

// 限流中间件
var rate_limit = middleware.rateLimitMiddleware(100); // 每分钟100次

// JSON 内容类型中间件
var json_ct = middleware.jsonContentTypeMiddleware();

// 安全头部中间件
var security = middleware.securityHeadersMiddleware();
```

---

## 🏷️ 类型定义

### HandlerFn

请求处理函数类型。

```zig
pub const HandlerFn = *const fn() callconv(.C) ?*opaque;

fn my_handler() callconv(.C) ?*opaque {
    // 处理逻辑
    return null;
}
```

### MiddlewareHandler

中间件处理函数类型。

```zig
pub const MiddlewareHandler = *const fn(req: ?*opaque, resp: ?*opaque) callconv(.C) c_int;

fn my_middleware(req: ?*opaque, resp: ?*opaque) callconv(.C) c_int {
    // 中间件逻辑
    return 0; // 继续执行
    // return -1; // 中断执行
}
```

### Route

路由定义类型。

```zig
pub const Route = struct {
    method: []const u8,
    path: []const u8,
    handler: HandlerFn,
};

const route = Route.init("GET", "/users", list_users);
```

### RouteContext

路由上下文，包含请求、响应和参数。

```zig
pub const RouteContext = struct {
    request: Request,
    response: Response,
    params: std.StringHashMap([]const u8),
    
    pub fn param(self: *const Self, name: []const u8) ?[]const u8;
};
```

### MiddlewareContext

中间件上下文。

```zig
pub const MiddlewareContext = struct {
    request: *Request,
    response: *Response,
    next: *const fn() callconv(.C) c_int,
    
    pub fn next(self: *const Self) !void;
};
```

---

## ❌ 错误处理

### 错误类型

```zig
// 初始化错误
error.InitializationFailed

// 应用程序错误
error.HostSetFailed
error.PortSetFailed  
error.RouteAddFailed
error.ControllerAddFailed
error.ServerRunFailed

// 响应错误
error.ResponseTextFailed
error.ResponseJsonFailed
error.ResponseStatusFailed
error.ResponseHeaderFailed
error.ResponseCookieFailed

// 中间件错误
error.MiddlewareChainFailed
error.CorsMiddlewareFailed
error.LoggerMiddlewareFailed
error.CustomMiddlewareFailed
```

### 错误处理模式

```zig
// 基本错误处理
const result = risky_operation() catch |err| {
    std.debug.print("Error: {}\n", .{err});
    return;
};

// 链式调用错误处理
var app = dia.Application.new();
_ = app.host("127.0.0.1") catch |err| {
    std.debug.print("Failed to set host: {}\n", .{err});
    return;
};

// 响应错误处理
fn safe_handler() callconv(.C) ?*opaque {
    var response = dia.Response.new();
    
    _ = response.text("Hello") catch {
        // 创建错误响应
        _ = response.status(500) catch return null;
        _ = response.text("Internal Error") catch return null;
        return null;
    };
    
    return null;
}
```

---

## 📚 常量

```zig
// 框架信息
pub const VERSION = "0.1.0";
pub const AUTHOR = "dia team";
pub const DESCRIPTION = "Cross-platform backend framework for Zig";

// HTTP 状态码常量（建议使用）
const HTTP_OK = 200;
const HTTP_CREATED = 201;
const HTTP_BAD_REQUEST = 400;
const HTTP_UNAUTHORIZED = 401;
const HTTP_FORBIDDEN = 403;
const HTTP_NOT_FOUND = 404;
const HTTP_INTERNAL_ERROR = 500;
```

---

这就是 dia 框架的完整 API 参考。所有函数都经过精心设计，提供类型安全和内存安全的 Web 开发体验。

**Happy Coding! 🚀**