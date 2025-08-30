# dia 用户指南 📚

> 跨平台后端框架，为 Zig 开发者提供类似 Java Spring Boot 的直观 API

## 📖 目录

- [快速开始](#快速开始)
- [安装方式](#安装方式)
- [基础概念](#基础概念)
- [API 参考](#api-参考)
- [使用示例](#使用示例)
- [最佳实践](#最佳实践)
- [故障排除](#故障排除)

---

## 🚀 快速开始

### 第一个 Web 应用

```zig
const dia = @import("dia");

fn hello_handler() callconv(.C) ?*opaque {
    var response = dia.Response.new();
    _ = response.text("Hello, dia!") catch return null;
    return null;
}

pub fn main() !void {
    try dia.init();
    
    var app = dia.Application.new();
    defer app.deinit();
    
    _ = try app.host("127.0.0.1");
    _ = try app.port(3000);
    _ = try app.get("/", hello_handler);
    
    try app.run();
}
```

运行应用：
```bash
zig build run-hello
curl http://127.0.0.1:3000/
```

---

## 💾 安装方式

### 方法 1: 直接克隆（推荐）

```bash
# 克隆项目
git clone https://github.com/KayanoLiam/dia.git
cd dia

# 构建 Rust 核心
cargo build --release

# 运行示例
zig build run-hello
```

### 方法 2: 作为子模块

```bash
# 在你的项目中添加 dia 作为子模块
git submodule add https://github.com/KayanoLiam/dia.git vendor/dia
```

然后在你的 `build.zig` 中：

```zig
const dia_dep = b.dependency("dia", .{
    .target = target,
    .optimize = optimize,
});

exe.addModule("dia", dia_dep.module("dia"));
```

### 方法 3: Zig 包管理器（实验性）

```bash
zig fetch --save git+https://github.com/KayanoLiam/dia.git
```

---

## 🧭 基础概念

### 模块化架构

dia 框架采用模块化设计，类似 Zig 标准库的组织方式：

```zig
const dia = @import("dia");

// 完整导入
const Application = dia.Application;
const Response = dia.Response;

// 模块导入（推荐）
const request = dia.request;
const response = dia.response;
const controller = dia.controller;
const middleware = dia.middleware;
```

### 核心组件

| 组件 | 功能 | 类比 |
|------|------|------|
| `Application` | 应用程序入口 | Spring Boot Application |
| `Request` | HTTP 请求处理 | HttpServletRequest |
| `Response` | HTTP 响应构建 | HttpServletResponse |
| `Controller` | 路由控制器 | @RestController |
| `Middleware` | 中间件处理 | Filter/Interceptor |

---

## 📚 API 参考

### Application API

```zig
// 创建应用
var app = dia.Application.new();
defer app.deinit();

// 配置服务器
_ = try app.host("127.0.0.1");    // 设置主机
_ = try app.port(8080);           // 设置端口

// 添加路由
_ = try app.get("/", handler);        // GET 路由
_ = try app.post("/users", handler);  // POST 路由

// 添加控制器
var controller = dia.Controller.withBasePath("/api");
_ = try app.addController(&controller);

// 启动服务器
try app.run();
```

### Response API

```zig
var response = dia.Response.new();

// 文本响应
_ = try response.text("Hello World");

// JSON 响应
_ = try response.json("{\"message\": \"success\"}");

// 结构体序列化
const User = struct { id: u32, name: []const u8 };
const user = User{ .id = 1, .name = "Alice" };
_ = try response.jsonStruct(user, allocator);

// 设置状态码
_ = try response.status(200);

// 设置头部
_ = try response.header("Content-Type", "application/json");

// 设置 Cookie
_ = try response.cookie("session", "abc123");
```

### Request API

```zig
fn handler(req: *dia.Request) void {
    // 获取请求方法
    const method = req.method(); // "GET", "POST", etc.
    
    // 获取请求路径
    const path = req.path(); // "/users/123"
    
    // 获取头部
    const auth = try req.header("Authorization");
    
    // 获取查询参数
    const page = try req.query("page"); // ?page=1
    
    // 获取请求体
    const body = req.body();
    
    // 解析 JSON
    const User = struct { name: []const u8 };
    const user = try req.json(User, allocator);
}
```

### Controller API

```zig
// 创建控制器
var api = dia.Controller.withBasePath("/api");
defer api.deinit();

// 添加路由
_ = try api.get("/users", list_users);
_ = try api.post("/users", create_user);
_ = try api.put("/users/{id}", update_user);
_ = try api.delete("/users/{id}", delete_user);

// 添加中间件
_ = try api.middleware(auth_middleware);
```

### Middleware API

```zig
// 内置中间件
var cors = try dia.middleware.corsMiddleware();
var logger = try dia.middleware.loggerMiddleware();

// 自定义中间件
fn auth_middleware(req: ?*opaque, resp: ?*opaque) callconv(.C) c_int {
    // 验证逻辑
    return 0; // 继续执行
    // return -1; // 中断执行
}

var custom = dia.Middleware.new();
_ = try custom.custom(auth_middleware);
```

---

## 💡 使用示例

### 完整的 REST API

```zig
const std = @import("std");
const dia = @import("dia");

const User = struct {
    id: u32,
    name: []const u8,
    email: []const u8,
};

fn list_users() callconv(.C) ?*opaque {
    const users = [_]User{
        User{ .id = 1, .name = "Alice", .email = "alice@example.com" },
        User{ .id = 2, .name = "Bob", .email = "bob@example.com" },
    };
    
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    
    var response = dia.response.okJsonStruct(users, arena.allocator()) catch return null;
    defer response.deinit();
    
    return null;
}

fn create_user() callconv(.C) ?*opaque {
    var response = dia.response.ok("User created successfully") catch return null;
    defer response.deinit();
    return null;
}

pub fn main() !void {
    try dia.init();
    
    // 创建 API 控制器
    var api = dia.controller.Controller.withBasePath("/api/v1");
    defer api.deinit();
    
    _ = try api.get("/users", list_users);
    _ = try api.post("/users", create_user);
    
    // 添加中间件
    var cors = try dia.middleware.corsMiddleware();
    defer cors.deinit();
    
    // 创建应用
    var app = dia.Application.new();
    defer app.deinit();
    
    _ = try app.host("127.0.0.1");
    _ = try app.port(8080);
    _ = try app.addController(&api);
    
    std.debug.print("🚀 Server running on http://127.0.0.1:8080\n");
    try app.run();
}
```

### 带中间件的应用

```zig
const dia = @import("dia");

fn auth_middleware(req: ?*opaque, resp: ?*opaque) callconv(.C) c_int {
    // 检查 Authorization 头部
    var request = dia.Request{ .ptr = req };
    const auth_header = request.header("Authorization") catch return -1;
    
    if (auth_header.len == 0) {
        var response = dia.Response{ .ptr = resp };
        _ = response.status(401) catch return -1;
        _ = response.text("Unauthorized") catch return -1;
        return -1; // 中断请求
    }
    
    return 0; // 继续执行
}

pub fn main() !void {
    try dia.init();
    
    var app = dia.Application.new();
    defer app.deinit();
    
    // 添加全局中间件
    var cors = try dia.middleware.corsMiddleware();
    defer cors.deinit();
    
    var logger = try dia.middleware.loggerMiddleware();
    defer logger.deinit();
    
    // 受保护的路由
    var protected = dia.controller.Controller.withBasePath("/protected");
    defer protected.deinit();
    
    _ = try protected.middleware(auth_middleware);
    _ = try protected.get("/profile", profile_handler);
    
    _ = try app.addController(&protected);
    try app.run();
}
```

---

## ⭐ 最佳实践

### 1. 项目结构

```
my-app/
├── src/
│   ├── main.zig          # 应用入口
│   ├── handlers/         # 处理函数
│   │   ├── users.zig
│   │   └── auth.zig
│   ├── models/           # 数据模型
│   │   └── user.zig
│   └── middleware/       # 中间件
│       └── auth.zig
├── build.zig
└── vendor/dia/           # dia 框架
```

### 2. 错误处理

```zig
fn safe_handler() callconv(.C) ?*opaque {
    var response = dia.Response.new();
    
    // 使用 catch 处理错误
    const result = dangerous_operation() catch {
        _ = response.status(500) catch return null;
        _ = response.text("Internal Server Error") catch return null;
        return null;
    };
    
    _ = response.json(result) catch return null;
    return null;
}
```

### 3. 资源管理

```zig
fn handler_with_allocator() callconv(.C) ?*opaque {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit(); // 确保资源释放
    
    const allocator = arena.allocator();
    
    // 使用 allocator 进行内存分配
    var response = dia.response.okJsonStruct(data, allocator) catch return null;
    defer response.deinit();
    
    return null;
}
```

### 4. 模块化设计

```zig
// handlers/users.zig
const dia = @import("dia");

pub fn list() callconv(.C) ?*opaque {
    // 用户列表逻辑
}

pub fn create() callconv(.C) ?*opaque {
    // 创建用户逻辑
}

// main.zig
const users = @import("handlers/users.zig");

pub fn main() !void {
    var api = dia.controller.Controller.withBasePath("/api");
    _ = try api.get("/users", users.list);
    _ = try api.post("/users", users.create);
}
```

---

## 🔧 故障排除

### 常见问题

#### 1. 编译错误：找不到 dia 模块

**问题**：`error: unable to find 'dia'`

**解决**：确保正确配置了模块路径
```bash
# 检查 build.zig 是否正确配置
zig build --help

# 确保 dia 目录存在
ls vendor/dia/src/dia.zig
```

#### 2. 运行时错误：FFI 函数未找到

**问题**：`error: FFI function not found`

**解决**：确保 Rust 库已构建
```bash
cd vendor/dia
cargo build --release
```

#### 3. 链接错误

**问题**：`error: linking failed`

**解决**：检查系统依赖
```bash
# macOS
brew install rust

# Ubuntu
sudo apt install build-essential

# 重新构建
cargo clean && cargo build --release
```

### 调试技巧

#### 1. 启用详细输出

```bash
zig build --verbose
```

#### 2. 检查 Rust 日志

```bash
RUST_LOG=debug cargo run --example simple_server
```

#### 3. 使用测试模式

```zig
test "dia framework test" {
    try dia.testConnection();
}
```

```bash
zig build test
```

---

## 🤝 社区和支持

- **GitHub**: https://github.com/KayanoLiam/dia
- **Issues**: 报告 Bug 和功能请求
- **Discussions**: 技术讨论和问答

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

**Happy Coding with dia! 🎉**